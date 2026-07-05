prompt File: test_lib_text.pks.sql <start>
-- =============================================================================
-- File:     test_lib_text.pks.sql
-- Object:   test_lib_text (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_text.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_text: Creating test package specification
create or replace package test_lib_text is

--%suite(lib_text)
--%suitepath(#APP#.base)

--%test(split breaks a delimited string into its pieces)
procedure split_basic;

--%test(split returns a single element when the separator is absent)
procedure split_single;

--%test(join is the inverse of split)
procedure join_roundtrip;

--%test(format substitutes the placeholders)
procedure format_substitutes;

--%test(normalize_code folds accents and collapses separators)
procedure normalize_code_works;

end test_lib_text;
/
show errors package test_lib_text

prompt File: test_lib_text.pks.sql <end>
