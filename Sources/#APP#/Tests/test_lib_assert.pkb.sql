prompt File: test_lib_assert.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_assert.pkb.sql
-- Object:   test_lib_assert (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_assert.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_assert: Creating test package body
create or replace package body test_lib_assert is

procedure cleanup is
   pragma autonomous_transaction;
begin
   delete from log_errors ler where ler.scope = 'lib_assert';
   commit;
end cleanup;

procedure not_null_passes is
begin
   lib_assert.not_null(i_value => 'x', i_param_name => 'p');
   ut.expect(1).to_equal(1);
end not_null_passes;

procedure not_null_raises is
begin
   lib_assert.not_null(cast(null as varchar2), 'p');
   ut.fail('expected e_invalid_parameter, none raised');
end not_null_raises;

procedure in_range_raises is
begin
   lib_assert.in_range(i_value => 5, i_min => 1, i_max => 3, i_param_name => 'p');
   ut.fail('expected e_invalid_parameter, none raised');
end in_range_raises;

procedure max_length_raises is
begin
   lib_assert.max_length(i_value => rpad('x', 10, 'x'), i_max => 5, i_param_name => 'p');
   ut.fail('expected e_param_too_large, none raised');
end max_length_raises;

procedure is_true_raises is
begin
   lib_assert.is_true(i_condition => (1 = 2), i_message => 'one is not two');
   ut.fail('expected e_invalid_parameter, none raised');
end is_true_raises;

end test_lib_assert;
/
show errors package body test_lib_assert

prompt File: test_lib_assert.pkb.sql <end>
