prompt File: lib_logging.pkb.sql <start>
-- =============================================================================
-- File:     lib_logging.pkb.sql
-- Object:   lib_logging (package body)
-- Schema:   #APP#
-- Purpose:  Autonomous-transaction writers for log_entries / log_errors, with a
--           cached, configurable minimum level. The minimum level is read from
--           lib_config with a default, so logging never raises and never
--           recurses into lib_err. log_error is never filtered.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_logging: Creating package body
create or replace package body lib_logging is

-- Level names and their numeric severity ranking.
k_LEVEL_DEBUG   constant log_entries.log_level%type := 'DEBUG';
k_LEVEL_INFO    constant log_entries.log_level%type := 'INFO';
k_LEVEL_WARN    constant log_entries.log_level%type := 'WARN';

k_SEV_DEBUG     constant pls_integer := 10;
k_SEV_INFO      constant pls_integer := 20;
k_SEV_WARN      constant pls_integer := 30;

k_PARAM_MIN_LEVEL constant lib_types.name_sbt := 'LOG_MIN_LEVEL';
k_PARAM_RETENTION constant lib_types.name_sbt := 'LOG_RETENTION_DAYS';

-- Cached minimum severity; refreshed on demand via refresh.
g_min_severity  pls_integer;

-- Maps a level name to its severity ranking.
-- i_level : level name.
-- return  : numeric severity, or k_SEV_INFO for an unknown name.
function severity_of(i_level in varchar2) return pls_integer is
begin
   return ( case upper(i_level)
               when k_LEVEL_DEBUG then k_SEV_DEBUG
               when k_LEVEL_INFO  then k_SEV_INFO
               when k_LEVEL_WARN  then k_SEV_WARN
               else k_SEV_INFO
            end
          );
end severity_of;

-- Returns the cached minimum severity, reading it from configuration on the
-- first call. Uses a defaulted read so a missing parameter cannot raise.
-- return : the minimum severity below which entries are discarded.
function min_severity return pls_integer is
begin
   if ( g_min_severity is null )
   then
      g_min_severity := severity_of( lib_config.get_string( i_name    => k_PARAM_MIN_LEVEL
                                                          , i_default => k_LEVEL_INFO
                                                          )
                                   );
   end if;

   return (g_min_severity);
end min_severity;

-- Inserts one row in log_entries in an autonomous transaction.
-- i_level : DEBUG / INFO / WARN.
-- i_text  : message.
-- i_scope : logical scope.
procedure write_entry( i_level in varchar2
                     , i_text  in varchar2
                     , i_scope in varchar2
                     )
is
   pragma autonomous_transaction;
begin
   insert
     into log_entries (  log_level
                       , scope
                       , message
                       , actor
                      )
   values (  i_level
           , i_scope
           , i_text
           , lib_session.current_actor
          );

   commit;
exception
   when others
   then
      -- Logging must never break the caller.
      rollback;
end write_entry;

-- Inserts one row in log_errors in an autonomous transaction, capturing the
-- current error context (sqlcode, sqlerrm, backtrace, call stack).
-- i_text  : caller-supplied context message.
-- i_scope : logical scope.
procedure write_error( i_text  in varchar2
                     , i_scope in varchar2
                     )
is
   pragma autonomous_transaction;
begin
   insert
     into log_errors (  process_name
                      , scope
                      , error_code
                      , error_message
                      , error_backtrace
                      , call_stack
                      , actor
                     )
   values (  lib_session.current_module
           , i_scope
           , sqlcode
           , substrb(i_text || case when sqlerrm is not null then ' - ' || sqlerrm end, 1, 4000)
           , substrb(sys.dbms_utility.format_error_backtrace, 1, 4000)
           , substrb(sys.dbms_utility.format_call_stack,      1, 4000)
           , lib_session.current_actor
          );

   commit;
exception
   when others
   then
      rollback;
end write_error;

procedure log(i_text in varchar2, i_scope in lib_types.scope_sbt default null) is
begin
   log_info(i_text => i_text, i_scope => i_scope);
end log;

procedure log_error(i_text in varchar2, i_scope in lib_types.scope_sbt default null) is
begin
   write_error(i_text => i_text, i_scope => i_scope);
end log_error;

procedure log_warn(i_text in varchar2, i_scope in lib_types.scope_sbt default null) is
begin
   if ( k_SEV_WARN >= min_severity )
   then
      write_entry(i_level => k_LEVEL_WARN, i_text => i_text, i_scope => i_scope);
   end if;
end log_warn;

procedure log_info(i_text in varchar2, i_scope in lib_types.scope_sbt default null) is
begin
   if ( k_SEV_INFO >= min_severity )
   then
      write_entry(i_level => k_LEVEL_INFO, i_text => i_text, i_scope => i_scope);
   end if;
end log_info;

procedure log_debug(i_text in varchar2, i_scope in lib_types.scope_sbt default null) is
begin
   if ( k_SEV_DEBUG >= min_severity )
   then
      write_entry(i_level => k_LEVEL_DEBUG, i_text => i_text, i_scope => i_scope);
   end if;
end log_debug;

procedure refresh is
begin
   g_min_severity := null;
end refresh;

procedure purge(i_retention_days in number default null) is
   k_RETENTION  constant number := coalesce( i_retention_days
                                           , lib_config.get_number( i_name    => k_PARAM_RETENTION
                                                                  , i_default => lib_constants.k_LOG_RETENTION
                                                                  )
                                           );
   k_CUTOFF     constant timestamp := systimestamp - numtodsinterval(k_RETENTION, 'DAY');
begin
   delete
     from log_entries lge
    where lge.logged_at < k_CUTOFF;

   delete
     from log_errors ler
    where ler.logged_at < k_CUTOFF;

   commit;
end purge;

end lib_logging;
/
show errors package body lib_logging

prompt File: lib_logging.pkb.sql <end>
