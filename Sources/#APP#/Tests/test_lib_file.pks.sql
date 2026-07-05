prompt File: test_lib_file.pks.sql <start>
-- =============================================================================
-- File:     test_lib_file.pks.sql
-- Object:   test_lib_file (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_file. Cover filename validation (no filesystem
--           needed); actual read/write is verified by manual integration test
--           against a configured DIRECTORY.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_file: Creating test package specification
create or replace package test_lib_file is

   --%suite(lib_file)
   --%suitepath(#APP#.base)

   -- Removes the log_errors rows written by the rejected calls.
   --%aftereach
   procedure cleanup;

   --%test(read_clob rejects a name with a path separator)
   --%throws(-20008)
   procedure rejects_slash;

   --%test(write_clob rejects a parent-directory reference)
   --%throws(-20008)
   procedure rejects_parent;

   --%test(read_clob rejects a null name)
   --%throws(-20008)
   procedure rejects_null;

end test_lib_file;
/
show errors package test_lib_file

prompt File: test_lib_file.pks.sql <end>
