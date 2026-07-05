prompt File: test_lib_logging.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_logging.pkb.sql
-- Object:   test_lib_logging (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_logging. lib_logging commits in an autonomous
--           transaction, so the written rows are cleaned up explicitly.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_logging: Creating test package body
create or replace package body test_lib_logging is

k_SCOPE  constant lib_types.scope_sbt := 'test_lib_logging';

procedure reset_level is
begin
   -- Ensure the minimum level reflects the current configuration (INFO).
   lib_logging.refresh;
end reset_level;

procedure cleanup is
   pragma autonomous_transaction;
begin
   delete from log_entries lge where lge.scope = k_SCOPE;
   delete from log_errors  ler where ler.scope = k_SCOPE;
   commit;
end cleanup;

procedure log_info_writes is
   l_count  pls_integer;
begin
   lib_logging.log_info(i_text => 'unit test info', i_scope => k_SCOPE);

   select count(*)
     into l_count
     from log_entries lge
    where lge.scope = k_SCOPE;

   ut.expect(l_count).to_equal(1);
end log_info_writes;

procedure log_debug_filtered is
   l_count  pls_integer;
begin
   lib_logging.log_debug(i_text => 'unit test debug', i_scope => k_SCOPE);

   select count(*)
     into l_count
     from log_entries lge
    where lge.scope     = k_SCOPE
      and lge.log_level = 'DEBUG';

   ut.expect(l_count).to_equal(0);
end log_debug_filtered;

procedure log_error_writes is
   l_count  pls_integer;
begin
   lib_logging.log_error(i_text => 'unit test error', i_scope => k_SCOPE);

   select count(*)
     into l_count
     from log_errors ler
    where ler.scope = k_SCOPE;

   ut.expect(l_count).to_equal(1);
end log_error_writes;

end test_lib_logging;
/
show errors package body test_lib_logging

prompt File: test_lib_logging.pkb.sql <end>
