prompt File: log_entries.tab.sql <start>
-- =============================================================================
-- File:     log_entries.tab.sql
-- Object:   log_entries (table)
-- Schema:   #APP#
-- Purpose:  Structured application log flow written by lib_logging at the
--           DEBUG / INFO / WARN levels. Errors carry a backtrace and go to the
--           separate log_errors table. Rows are inserted in an autonomous
--           transaction so they survive a rollback of the caller.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt log_entries: Creating table
create table log_entries
   ( entry_id   number(24)          generated always as identity
                                     constraint log_entries_pk primary key
   , logged_at  timestamp(6)        default systimestamp
                                     constraint log_entries_nn_logged_at not null
   , log_level  varchar2(5 char)    constraint log_entries_nn_log_level not null
   , scope      varchar2(128 char)
   , message    varchar2(4000 char)
   , actor      varchar2(128 char)
   , constraint log_entries_ck_log_level check (log_level in ('DEBUG', 'INFO', 'WARN'))
   );

prompt log_entries: Adding comments
comment on table  log_entries               is 'Structured application log flow (DEBUG/INFO/WARN) written by lib_logging in an autonomous transaction.';
comment on column log_entries.entry_id      is 'Surrogate key, generated identity.';
comment on column log_entries.logged_at     is 'Instant the entry was recorded (autonomous transaction time).';
comment on column log_entries.log_level     is 'Severity of the entry: DEBUG, INFO or WARN. Errors go to log_errors.';
comment on column log_entries.scope         is 'Logical scope of the entry, typically package.subprogram.';
comment on column log_entries.message       is 'Free-text log message.';
comment on column log_entries.actor         is 'Effective actor (proxy-aware) resolved by lib_session.current_actor.';

prompt log_entries: Creating indexes
create index log_entries_idx_logged_at on log_entries (logged_at);

prompt File: log_entries.tab.sql <end>
