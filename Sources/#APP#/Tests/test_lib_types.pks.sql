prompt File: test_lib_types.pks.sql <start>
-- =============================================================================
-- File:     test_lib_types.pks.sql
-- Object:   test_lib_types (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_types: verify the size of the shared subtypes so
--           a change to a domain size is caught here.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_types: Creating test package specification
create or replace package test_lib_types is

--%suite(lib_types)
--%suitepath(#APP#.base)

--%test(code_sbt holds a 32-character code)
procedure code_sbt_holds_32;

--%test(code_sbt rejects a value longer than 32 characters)
--%throws(-6502)
procedure code_sbt_rejects_over_32;

--%test(flag_sbt holds a single character)
procedure flag_sbt_holds_one;

end test_lib_types;
/
show errors package test_lib_types

prompt File: test_lib_types.pks.sql <end>
