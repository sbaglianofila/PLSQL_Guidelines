prompt File: test_lib_lock.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_lock.pkb.sql
-- Object:   test_lib_lock (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_lock.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_lock: Creating test package body
create or replace package body test_lib_lock is

k_LOCK_NAME  constant lib_types.lock_name_sbt := 'UT_LIB_LOCK';

procedure request_returns_handle is
   l_handle  lib_types.lock_handle_sbt;
begin
   l_handle := lib_lock.request_lock(i_lock_name => k_LOCK_NAME);
   ut.expect(l_handle).to_be_not_null;
   lib_lock.release_lock(i_lock_handle => l_handle);
end request_returns_handle;

procedure reacquire_after_release is
   l_handle  lib_types.lock_handle_sbt;
begin
   l_handle := lib_lock.request_lock(i_lock_name => k_LOCK_NAME);
   lib_lock.release_lock(i_lock_handle => l_handle);

   -- Re-acquiring the same lock after release must succeed.
   l_handle := lib_lock.request_lock(i_lock_name => k_LOCK_NAME);
   ut.expect(l_handle).to_be_not_null;
   lib_lock.release_lock(i_lock_handle => l_handle);
end reacquire_after_release;

end test_lib_lock;
/
show errors package body test_lib_lock

prompt File: test_lib_lock.pkb.sql <end>
