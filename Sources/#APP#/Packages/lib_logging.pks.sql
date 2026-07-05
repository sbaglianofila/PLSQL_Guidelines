prompt File: lib_logging.pks.sql <start>
-- =============================================================================
-- File:     lib_logging.pks.sql
-- Object:   lib_logging (package specification)
-- Schema:   #APP#
-- Purpose:  Structured logging engine underpinning diagnosis and the AM control
--           queries. Writes to the log_* tables in an AUTONOMOUS TRANSACTION so
--           the log survives a rollback of the application transaction. The
--           minimum level is configurable at runtime (via lib_config) so debug
--           can be switched on in production without recompiling.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_logging: Creating package specification
create or replace package lib_logging is

-- Records an INFO-level entry. Convenience alias of log_info, used by the
-- start/end tracing pattern.
-- i_text  : message to record.
-- i_scope : logical scope (package.subprogram); optional.
procedure log(i_text in varchar2, i_scope in lib_types.scope_sbt default null);

-- Records an error in log_errors together with sqlcode, sqlerrm,
-- format_error_backtrace and the call stack. Always written (never filtered).
-- Intended to be called from an exception handler.
-- i_text  : caller-supplied context message.
-- i_scope : logical scope (package.subprogram); optional.
procedure log_error(i_text in varchar2, i_scope in lib_types.scope_sbt default null);

-- Records a WARN-level entry (written when the minimum level <= WARN).
procedure log_warn(i_text in varchar2, i_scope in lib_types.scope_sbt default null);

-- Records an INFO-level entry (written when the minimum level <= INFO).
procedure log_info(i_text in varchar2, i_scope in lib_types.scope_sbt default null);

-- Records a DEBUG-level entry (written only when the minimum level = DEBUG).
procedure log_debug(i_text in varchar2, i_scope in lib_types.scope_sbt default null);

-- Clears the cached minimum level so the next call re-reads it from
-- lib_config. Lets an operator change verbosity in production and have it
-- take effect without recompiling.
procedure refresh;

-- Deletes log rows older than the retention window. Meant for a scheduled
-- job. When i_retention_days is null the value comes from configuration
-- (parameter LOG_RETENTION_DAYS, defaulting to lib_constants.k_LOG_RETENTION).
-- i_retention_days : age in days beyond which rows are purged.
procedure purge(i_retention_days in number default null);

end lib_logging;
/
show errors package lib_logging

prompt File: lib_logging.pks.sql <end>
