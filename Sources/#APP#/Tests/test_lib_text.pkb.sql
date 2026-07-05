prompt File: test_lib_text.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_text.pkb.sql
-- Object:   test_lib_text (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_text.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_text: Creating test package body
create or replace package body test_lib_text is

procedure split_basic is
   l_parts  lib_text.t_strings_type;
begin
   l_parts := lib_text.split('a,b,c');
   ut.expect(l_parts.count).to_equal(3);
   ut.expect(l_parts(1)).to_equal('a');
   ut.expect(l_parts(3)).to_equal('c');
end split_basic;

procedure split_single is
   l_parts  lib_text.t_strings_type;
begin
   l_parts := lib_text.split('abc', ',');
   ut.expect(l_parts.count).to_equal(1);
   ut.expect(l_parts(1)).to_equal('abc');
end split_single;

procedure join_roundtrip is
begin
   ut.expect(lib_text.join(lib_text.split('a,b,c'))).to_equal('a,b,c');
end join_roundtrip;

procedure format_substitutes is
begin
   ut.expect(lib_text.format('%1-%2', 'x', 'y')).to_equal('x-y');
end format_substitutes;

procedure normalize_code_works is
begin
   ut.expect(lib_text.normalize_code('Città di São!')).to_equal('CITTA_DI_SAO');
end normalize_code_works;

end test_lib_text;
/
show errors package body test_lib_text

prompt File: test_lib_text.pkb.sql <end>
