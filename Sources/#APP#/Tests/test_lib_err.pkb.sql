prompt File: test_lib_err.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_err.pkb.sql
-- Object:   test_lib_err (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_err. Uses a dedicated scope so the autonomously
--           committed log rows can be cleaned up after each test.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_err: Creating test package body
create or replace package body test_lib_err is

k_SCOPE  constant lib_types.scope_sbt := 'test_lib_err';

procedure cleanup is
   pragma autonomous_transaction;
begin
   delete from log_errors ler where ler.scope = k_SCOPE;
   commit;
end cleanup;

procedure message_of_substitutes is
   l_actual  varchar2(4000 char);
begin
   l_actual := lib_err.message_of( i_error => lib_err.k_INVALID_PARAMETER
                                 , i_p1    => 'age'
                                 , i_p2    => '-1'
                                 );
   ut.expect(l_actual).to_equal('Invalid parameter age: -1');
end message_of_substitutes;

procedure raise_signals_code is
begin
   lib_err.raise(i_error => lib_err.k_LOCK_REQUEST_FAILED, i_p1 => 'UT', i_scope => k_SCOPE);
end raise_signals_code;

procedure raise_writes_error_row is
   l_count  pls_integer;
begin
   begin
      lib_err.raise(i_error => lib_err.k_STALE_DATA, i_scope => k_SCOPE);
   exception
      when lib_err.e_stale_data
      then
         null;
   end;

   select count(*)
     into l_count
     from log_errors ler
    where ler.scope = k_SCOPE;

   ut.expect(l_count).to_be_greater_than(0);
end raise_writes_error_row;

end test_lib_err;
/
show errors package body test_lib_err

prompt File: test_lib_err.pkb.sql <end>
