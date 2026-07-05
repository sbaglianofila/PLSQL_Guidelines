prompt File: test_lib_lock.pks.sql <start>
-- =============================================================================
-- File:     test_lib_lock.pks.sql
-- Object:   test_lib_lock (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_lock. Contention across sessions cannot be
--           exercised from a single utPLSQL session, so these cover the
--           acquire/release round-trip.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_lock: Creating test package specification
create or replace package test_lib_lock is

--%suite(lib_lock)
--%suitepath(#APP#.base)

--%test(request_lock returns a non-null handle)
procedure request_returns_handle;

--%test(a lock can be re-acquired after release)
procedure reacquire_after_release;

end test_lib_lock;
/
show errors package test_lib_lock

prompt File: test_lib_lock.pks.sql <end>
