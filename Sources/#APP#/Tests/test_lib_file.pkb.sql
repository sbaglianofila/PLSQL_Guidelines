prompt File: test_lib_file.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_file.pkb.sql
-- Object:   test_lib_file (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_file filename validation.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_file: Creating test package body
create or replace package body test_lib_file is

procedure cleanup is
   pragma autonomous_transaction;
begin
   delete from log_errors ler where ler.scope = 'lib_file';
   commit;
end cleanup;

procedure rejects_slash is
   l_dummy  clob;
begin
   l_dummy := lib_file.read_clob(i_directory => 'UT_DIR', i_filename => 'sub/name.txt');
   ut.fail('expected e_invalid_filename, none raised');
end rejects_slash;

procedure rejects_parent is
begin
   lib_file.write_clob(i_directory => 'UT_DIR', i_filename => '../name.txt', i_content => to_clob('x'));
   ut.fail('expected e_invalid_filename, none raised');
end rejects_parent;

procedure rejects_null is
   l_dummy  clob;
begin
   l_dummy := lib_file.read_clob(i_directory => 'UT_DIR', i_filename => null);
   ut.fail('expected e_invalid_filename, none raised');
end rejects_null;

end test_lib_file;
/
show errors package body test_lib_file

prompt File: test_lib_file.pkb.sql <end>
