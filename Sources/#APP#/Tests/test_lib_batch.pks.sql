prompt File: test_lib_batch.pks.sql <start>
-- =============================================================================
-- File:     test_lib_batch.pks.sql
-- Object:   test_lib_batch (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_batch.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_batch: Creating test package specification
create or replace package test_lib_batch is

--%suite(lib_batch)
--%suitepath(#APP#.base)

-- Removes the autonomously committed log rows referring to the test process.
--%aftereach
procedure cleanup;

--%test(start_run opens a RUNNING run)
procedure start_run_opens_running;

--%test(end_run closes the run as SUCCESS with counters)
procedure end_run_closes_success;

--%test(fail_run closes the run as FAILED)
procedure fail_run_closes_failed;

end test_lib_batch;
/
show errors package test_lib_batch

prompt File: test_lib_batch.pks.sql <end>
