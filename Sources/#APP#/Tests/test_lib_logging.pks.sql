prompt File: test_lib_logging.pks.sql <start>
-- =============================================================================
-- File:     test_lib_logging.pks.sql
-- Object:   test_lib_logging (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_logging.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_logging: Creating test package specification
create or replace package test_lib_logging is

--%suite(lib_logging)
--%suitepath(#APP#.base)

--%beforeall
procedure reset_level;

-- Removes the autonomously committed rows written with the test scope.
--%aftereach
procedure cleanup;

--%test(log_info writes an entry)
procedure log_info_writes;

--%test(log_debug is filtered out at the default INFO level)
procedure log_debug_filtered;

--%test(log_error writes an error row)
procedure log_error_writes;

end test_lib_logging;
/
show errors package test_lib_logging

prompt File: test_lib_logging.pks.sql <end>
