prompt File: test_lib_constants.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_constants.pkb.sql
-- Object:   test_lib_constants (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_constants.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_constants: Creating test package body
create or replace package body test_lib_constants is

procedure yes_returns_y is
begin
   ut.expect(lib_constants.yes).to_equal('Y');
end yes_returns_y;

procedure no_returns_n is
begin
   ut.expect(lib_constants.no).to_equal('N');
end no_returns_n;

procedure date_fmt_roundtrips is
   l_actual  varchar2(20 char);
begin
   l_actual := to_char(date '2026-07-05', lib_constants.k_DATE_FMT);
   ut.expect(l_actual).to_equal('2026-07-05');
end date_fmt_roundtrips;

end test_lib_constants;
/
show errors package body test_lib_constants

prompt File: test_lib_constants.pkb.sql <end>
