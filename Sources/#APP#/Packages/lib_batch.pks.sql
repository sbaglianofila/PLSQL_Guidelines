prompt File: lib_batch.pks.sql <start>
-- =============================================================================
-- File:     lib_batch.pks.sql
-- Object:   lib_batch (package specification)
-- Schema:   #APP#
-- Purpose:  Lifecycle of batch processes. Gives every run a tracked identity on
--           log_process_runs (start, end, outcome, counters), so the AM can
--           answer "how did last night's batch go?" with a query. Sets the
--           session module/action via lib_session and can hold a single-instance
--           lock via lib_lock.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_batch: Creating package specification
create or replace package lib_batch is

-- Opens a run on log_process_runs and returns its id. Instruments the session
-- (module = process name) and, when i_single_instance is true, acquires a
-- non-waiting lock on the process name, raising lib_err.e_already_running if
-- another run holds it.
-- i_process_name    : logical process name.
-- i_single_instance : true to forbid concurrent runs of the same process.
-- return            : the new run id.
function start_run( i_process_name    in varchar2
                  , i_single_instance in boolean default false
                  ) return number;

-- Closes a run with an outcome and statistics, releasing the single-instance
-- lock if held.
-- i_run_id         : run to close.
-- i_status         : final status (SUCCESS by default).
-- i_rows_processed : rows successfully processed.
-- i_rows_rejected  : rows rejected.
procedure end_run( i_run_id         in number
                 , i_status         in varchar2 default 'SUCCESS'
                 , i_rows_processed in number default null
                 , i_rows_rejected  in number default null
                 );

-- Closes a run as FAILED, recording the current error, and releases the
-- single-instance lock if held. Meant to be called from an exception handler.
-- i_run_id        : run to close.
-- i_error_message : error text; defaults to sqlerrm.
procedure fail_run(i_run_id in number, i_error_message in varchar2 default null);

-- Records intermediate progress of a long-running process: updates the
-- session action and, when provided, the processed-row counter.
-- i_run_id  : run being advanced.
-- i_step    : current step label (published as the session action).
-- i_counter : running count of processed rows, if tracked.
procedure checkpoint(i_run_id in number, i_step in varchar2, i_counter in number default null);

end lib_batch;
/
show errors package lib_batch

prompt File: lib_batch.pks.sql <end>
