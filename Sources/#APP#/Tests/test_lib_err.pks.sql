prompt File: test_lib_err.pks.sql <start>
-- =============================================================================
-- File:     test_lib_err.pks.sql
-- Object:   test_lib_err (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_err (catalog and engine).
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_err: Creating test package specification
create or replace package test_lib_err is

--%suite(lib_err)
--%suitepath(#APP#.base)

-- Removes the log_errors rows written by raise() during the tests.
--%aftereach
procedure cleanup;

--%test(message_of substitutes the %1 and %2 placeholders)
procedure message_of_substitutes;

--%test(raise signals the requested catalog code)
--%throws(-20002)
procedure raise_signals_code;

--%test(raise writes an error row before signalling)
procedure raise_writes_error_row;

end test_lib_err;
/
show errors package test_lib_err

prompt File: test_lib_err.pks.sql <end>
