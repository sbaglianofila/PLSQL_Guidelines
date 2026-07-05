prompt File: lib_batch.pkb.sql <start>
-- =============================================================================
-- File:     lib_batch.pkb.sql
-- Object:   lib_batch (package body)
-- Schema:   #APP#
-- Purpose:  Tracks batch runs on log_process_runs and wires session
--           instrumentation and single-instance locking.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_batch: Creating package body
create or replace package body lib_batch is

k_SCOPE           constant lib_types.scope_sbt := 'lib_batch';
k_STATUS_RUNNING  constant log_process_runs.status%type := 'RUNNING';
k_STATUS_SUCCESS  constant log_process_runs.status%type := 'SUCCESS';
k_STATUS_FAILED   constant log_process_runs.status%type := 'FAILED';
k_ACTION_START    constant lib_types.code_sbt := 'START';
k_NO_WAIT         constant pls_integer := 0;

-- Single-instance lock handles, keyed by run id (as text).
type t_locks_type is table of lib_types.lock_handle_sbt index by varchar2(40 char);
g_locks  t_locks_type;

-- Releases the single-instance lock associated with a run, if any.
-- i_run_id : run whose lock is released.
procedure release_if_locked(i_run_id in number) is
   k_KEY  constant varchar2(40 char) := to_char(i_run_id);
begin
   if ( g_locks.exists(k_KEY) )
   then
      lib_lock.release_lock(i_lock_handle => g_locks(k_KEY));
      g_locks.delete(k_KEY);
   end if;
end release_if_locked;

function start_run( i_process_name    in varchar2
                  , i_single_instance in boolean default false
                  ) return number
is
   l_run_id   log_process_runs.run_id%type;
   l_handle   lib_types.lock_handle_sbt;
begin
   -- Acquire the single-instance lock before creating the run, so a blocked
   -- start does not leave a spurious run behind.
   if ( i_single_instance )
   then
      begin
         l_handle := lib_lock.request_lock( i_lock_name       => i_process_name
                                          , i_timeout_seconds => k_NO_WAIT
                                          );
      exception
         when lib_err.e_lock_request_failed
         then
            lib_err.raise(i_error => lib_err.k_ALREADY_RUNNING, i_p1 => i_process_name, i_scope => k_SCOPE);
      end;
   end if;

   insert
     into log_process_runs (  process_name
                            , status
                            , previous_run_id
                            , actor
                           )
   values (  i_process_name
           , k_STATUS_RUNNING
           , ( select max(lpr.run_id)
                 from log_process_runs lpr
                where lpr.process_name = i_process_name
             )
           , lib_session.current_actor
          )
   returning run_id into l_run_id;

   if ( i_single_instance )
   then
      g_locks(to_char(l_run_id)) := l_handle;
   end if;

   lib_session.set_step(i_module => i_process_name, i_action => k_ACTION_START);
   lib_logging.log_info(i_text => 'Run ' || l_run_id || ' started for ' || i_process_name, i_scope => k_SCOPE);

   return (l_run_id);
end start_run;

procedure end_run( i_run_id         in number
                 , i_status         in varchar2 default 'SUCCESS'
                 , i_rows_processed in number default null
                 , i_rows_rejected  in number default null
                 )
is
begin
   update log_process_runs lpr
      set lpr.status         = i_status
        , lpr.ended_at       = systimestamp
        , lpr.rows_processed = coalesce(i_rows_processed, lpr.rows_processed)
        , lpr.rows_rejected  = coalesce(i_rows_rejected, lpr.rows_rejected)
    where lpr.run_id = i_run_id;

   release_if_locked(i_run_id => i_run_id);

   lib_logging.log_info(i_text => 'Run ' || i_run_id || ' ended with status ' || i_status, i_scope => k_SCOPE);
end end_run;

procedure fail_run(i_run_id in number, i_error_message in varchar2 default null) is
   k_MESSAGE  constant varchar2(4000 char) := substrb(coalesce(i_error_message, sqlerrm), 1, 4000);
begin
   lib_logging.log_error(i_text => 'Run ' || i_run_id || ' failed: ' || k_MESSAGE, i_scope => k_SCOPE);

   update log_process_runs lpr
      set lpr.status        = k_STATUS_FAILED
        , lpr.ended_at      = systimestamp
        , lpr.error_message = k_MESSAGE
    where lpr.run_id = i_run_id;

   release_if_locked(i_run_id => i_run_id);
end fail_run;

procedure checkpoint(i_run_id in number, i_step in varchar2, i_counter in number default null) is
begin
   lib_session.set_step(i_module => lib_session.current_module, i_action => i_step);

   if ( i_counter is not null )
   then
      update log_process_runs lpr
         set lpr.rows_processed = i_counter
       where lpr.run_id = i_run_id;
   end if;
end checkpoint;

end lib_batch;
/
show errors package body lib_batch

prompt File: lib_batch.pkb.sql <end>
