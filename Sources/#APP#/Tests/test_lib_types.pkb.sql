prompt File: test_lib_types.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_types.pkb.sql
-- Object:   test_lib_types (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_types.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_types: Creating test package body
create or replace package body test_lib_types is

procedure code_sbt_holds_32 is
   l_code  lib_types.code_sbt;
begin
   l_code := rpad('X', 32, 'X');
   ut.expect(length(l_code)).to_equal(32);
end code_sbt_holds_32;

procedure code_sbt_rejects_over_32 is
   l_code  lib_types.code_sbt;
begin
   -- Assigning 33 characters must raise value_error (ORA-06502).
   l_code := rpad('X', 33, 'X');
   ut.fail('expected ORA-06502, none raised for value [' || l_code || ']');
end code_sbt_rejects_over_32;

procedure flag_sbt_holds_one is
   l_flag  lib_types.flag_sbt;
begin
   l_flag := lib_constants.k_YES;
   ut.expect(l_flag).to_equal('Y');
end flag_sbt_holds_one;

end test_lib_types;
/
show errors package body test_lib_types

prompt File: test_lib_types.pkb.sql <end>
