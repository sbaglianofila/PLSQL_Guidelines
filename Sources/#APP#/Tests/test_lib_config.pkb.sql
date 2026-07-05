prompt File: test_lib_config.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_config.pkb.sql
-- Object:   test_lib_config (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_config. Seeds dedicated parameters, refreshing
--           the cache so the reads see them.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_config: Creating test package body
create or replace package body test_lib_config is

procedure seed_params is
   pragma autonomous_transaction;
begin
   insert into cfg_parameters (param_name, param_value, param_type, is_modifiable)
   values ('UT_STR', 'hello', 'STRING', 'Y');

   insert into cfg_parameters (param_name, param_value, param_type, is_modifiable)
   values ('UT_NUM_BAD', 'abc', 'NUMBER', 'Y');

   commit;
   lib_config.refresh;
end seed_params;

procedure remove_params is
   pragma autonomous_transaction;
begin
   delete from cfg_parameters cfp where cfp.param_name in ('UT_STR', 'UT_NUM_BAD');
   commit;
   lib_config.refresh;
end remove_params;

procedure get_string_returns_value is
begin
   ut.expect(lib_config.get_string(i_name => 'UT_STR')).to_equal('hello');
end get_string_returns_value;

procedure default_when_missing is
begin
   ut.expect(lib_config.get_string(i_name => 'UT_MISSING', i_default => 'fallback')).to_equal('fallback');
end default_when_missing;

procedure missing_mandatory_raises is
   l_dummy  varchar2(100 char);
begin
   l_dummy := lib_config.get_string(i_name => 'UT_MISSING');
   ut.fail('expected config_param_missing, got [' || l_dummy || ']');
end missing_mandatory_raises;

procedure number_invalid_raises is
   l_dummy  number;
begin
   l_dummy := lib_config.get_number(i_name => 'UT_NUM_BAD');
   ut.fail('expected config_param_invalid, got [' || l_dummy || ']');
end number_invalid_raises;

end test_lib_config;
/
show errors package body test_lib_config

prompt File: test_lib_config.pkb.sql <end>
