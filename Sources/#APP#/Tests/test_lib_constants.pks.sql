prompt File: test_lib_constants.pks.sql <start>
-- =============================================================================
-- File:     test_lib_constants.pks.sql
-- Object:   test_lib_constants (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_constants. Requires utPLSQL installed.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_constants: Creating test package specification
create or replace package test_lib_constants is

--%suite(lib_constants)
--%suitepath(#APP#.base)

--%test(yes() exposes the 'Y' flag value to SQL)
procedure yes_returns_y;

--%test(no() exposes the 'N' flag value to SQL)
procedure no_returns_n;

--%test(k_DATE_FMT round-trips a date to canonical text)
procedure date_fmt_roundtrips;

end test_lib_constants;
/
show errors package test_lib_constants

prompt File: test_lib_constants.pks.sql <end>
