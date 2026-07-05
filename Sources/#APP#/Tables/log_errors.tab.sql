prompt File: log_errors.tab.sql <start>
-- =============================================================================
-- File:     log_errors.tab.sql
-- Object:   log_errors (table)
-- Schema:   #APP#
-- Purpose:  Error log written by lib_logging.log_error (and by lib_err.raise
--           before an application error is signalled). Keeps the full context
--           needed to locate the origin: sqlcode, message, backtrace and call
--           stack. Written in an autonomous transaction so it survives the
--           rollback of the failing transaction. Read by the AM control queries.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt log_errors: Creating table
create table log_errors
   ( error_id        number(24)          generated always as identity
                                          constraint log_errors_pk primary key
   , logged_at       timestamp(6)        default systimestamp
                                          constraint log_errors_nn_logged_at not null
   , process_name    varchar2(128 char)
   , scope           varchar2(128 char)
   , error_code      number
   , error_message   varchar2(4000 char)
   , error_backtrace varchar2(4000 char)
   , call_stack      varchar2(4000 char)
   , actor           varchar2(128 char)
   );

prompt log_errors: Adding comments
comment on table  log_errors                 is 'Application error log with full diagnostic context, written in an autonomous transaction. Read by the AM control queries.';
comment on column log_errors.error_id        is 'Surrogate key, generated identity.';
comment on column log_errors.logged_at       is 'Instant the error was recorded.';
comment on column log_errors.process_name    is 'Owning process (dbms_application_info module), set by lib_batch; used by the control queries to filter a run.';
comment on column log_errors.scope           is 'Logical scope passed by the caller, typically package.subprogram.';
comment on column log_errors.error_code      is 'Oracle sqlcode at the moment of logging (negative for application errors).';
comment on column log_errors.error_message   is 'Error text (sqlerrm) or caller-supplied message.';
comment on column log_errors.error_backtrace is 'dbms_utility.format_error_backtrace: line where the exception was raised.';
comment on column log_errors.call_stack      is 'dbms_utility.format_call_stack at logging time.';
comment on column log_errors.actor           is 'Effective actor (proxy-aware) resolved by lib_session.current_actor.';

prompt log_errors: Creating indexes
create index log_errors_idx_logged_at    on log_errors (logged_at);
create index log_errors_idx_process_name on log_errors (process_name);

prompt File: log_errors.tab.sql <end>
