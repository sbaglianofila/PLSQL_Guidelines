prompt File: test_lib_assert.pks.sql <start>
-- =============================================================================
-- File:     test_lib_assert.pks.sql
-- Object:   test_lib_assert (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_assert.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_assert: Creating test package specification
create or replace package test_lib_assert is

--%suite(lib_assert)
--%suitepath(#APP#.base)

-- Removes the log_errors rows written by the raising assertions.
--%aftereach
procedure cleanup;

--%test(not_null passes for a non-null value)
procedure not_null_passes;

--%test(not_null raises for a null value)
--%throws(-20000)
procedure not_null_raises;

--%test(in_range raises when the value is out of range)
--%throws(-20000)
procedure in_range_raises;

--%test(max_length raises when the value is too long)
--%throws(-20007)
procedure max_length_raises;

--%test(is_true raises when the condition is false)
--%throws(-20000)
procedure is_true_raises;

end test_lib_assert;
/
show errors package test_lib_assert

prompt File: test_lib_assert.pks.sql <end>
