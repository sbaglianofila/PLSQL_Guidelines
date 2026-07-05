prompt File: log_process_runs.tab.sql <start>
-- =============================================================================
-- File:     log_process_runs.tab.sql
-- Object:   log_process_runs (table)
-- Schema:   #APP#
-- Purpose:  One tracked run per batch execution, managed by lib_batch: start,
--           end, outcome and counters. Lets the AM answer "how did last night's
--           batch go?" with a query instead of an investigation. Read by the
--           "outcome and duration of the latest runs" control query.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt log_process_runs: Creating table
create table log_process_runs
   ( run_id          number(24)          generated always as identity
                                          constraint log_process_runs_pk primary key
   , process_name    varchar2(128 char)  constraint log_process_runs_nn_process not null
   , started_at      timestamp(6)        default systimestamp
                                          constraint log_process_runs_nn_started not null
   , ended_at        timestamp(6)
   , status          varchar2(32 char)   constraint log_process_runs_nn_status not null
   , rows_processed  number              default 0
   , rows_rejected   number              default 0
   , error_message   varchar2(4000 char)
   , previous_run_id number(24)
   , actor           varchar2(128 char)
   , constraint log_process_runs_ck_status check (status in ('RUNNING', 'SUCCESS', 'FAILED'))
   );

prompt log_process_runs: Adding comments
comment on table  log_process_runs                 is 'Lifecycle of batch runs managed by lib_batch: start, end, outcome and counters.';
comment on column log_process_runs.run_id          is 'Surrogate key, generated identity; returned by lib_batch.start_run.';
comment on column log_process_runs.process_name    is 'Logical name of the process being run.';
comment on column log_process_runs.started_at      is 'Instant the run started.';
comment on column log_process_runs.ended_at        is 'Instant the run ended; null while RUNNING.';
comment on column log_process_runs.status          is 'Run outcome: RUNNING, SUCCESS or FAILED.';
comment on column log_process_runs.rows_processed  is 'Number of rows successfully processed.';
comment on column log_process_runs.rows_rejected   is 'Number of rows rejected during processing.';
comment on column log_process_runs.error_message   is 'Error text captured when the run is closed as FAILED.';
comment on column log_process_runs.previous_run_id is 'run_id of the previous run of the same process, for chaining.';
comment on column log_process_runs.actor           is 'Effective actor that opened the run.';

prompt log_process_runs: Creating indexes
create index log_process_runs_idx_process on log_process_runs (process_name, started_at);

prompt File: log_process_runs.tab.sql <end>
