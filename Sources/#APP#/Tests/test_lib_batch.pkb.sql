prompt File: test_lib_batch.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_batch.pkb.sql
-- Object:   test_lib_batch (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_batch. The run rows are ordinary DML rolled back
--           by utPLSQL; only the autonomous log entries need cleanup.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_batch: Creating test package body
create or replace package body test_lib_batch is

k_PROCESS  constant lib_types.name_sbt := 'UT_LIB_BATCH';

procedure cleanup is
   pragma autonomous_transaction;
begin
   delete from log_entries lge where lge.message like '%' || k_PROCESS || '%';
   delete from log_errors  ler where ler.error_message like '%' || k_PROCESS || '%';
   commit;
end cleanup;

procedure start_run_opens_running is
   l_run_id  log_process_runs.run_id%type;
   l_status  log_process_runs.status%type;
begin
   l_run_id := lib_batch.start_run(i_process_name => k_PROCESS);
   ut.expect(l_run_id).to_be_not_null;

   select lpr.status
     into l_status
     from log_process_runs lpr
    where lpr.run_id = l_run_id;

   ut.expect(l_status).to_equal('RUNNING');
end start_run_opens_running;

procedure end_run_closes_success is
   l_run_id  log_process_runs.run_id%type;
   l_status  log_process_runs.status%type;
   l_rows    log_process_runs.rows_processed%type;
begin
   l_run_id := lib_batch.start_run(i_process_name => k_PROCESS);
   lib_batch.end_run(i_run_id => l_run_id, i_rows_processed => 5);

   select lpr.status
        , lpr.rows_processed
     into l_status
        , l_rows
     from log_process_runs lpr
    where lpr.run_id = l_run_id;

   ut.expect(l_status).to_equal('SUCCESS');
   ut.expect(l_rows).to_equal(5);
end end_run_closes_success;

procedure fail_run_closes_failed is
   l_run_id  log_process_runs.run_id%type;
   l_status  log_process_runs.status%type;
begin
   l_run_id := lib_batch.start_run(i_process_name => k_PROCESS);
   lib_batch.fail_run(i_run_id => l_run_id, i_error_message => 'boom ' || k_PROCESS);

   select lpr.status
     into l_status
     from log_process_runs lpr
    where lpr.run_id = l_run_id;

   ut.expect(l_status).to_equal('FAILED');
end fail_run_closes_failed;

end test_lib_batch;
/
show errors package body test_lib_batch

prompt File: test_lib_batch.pkb.sql <end>
