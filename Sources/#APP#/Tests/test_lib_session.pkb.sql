prompt File: test_lib_session.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_session.pkb.sql
-- Object:   test_lib_session (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_session.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_session: Creating test package body
create or replace package body test_lib_session is

procedure reset_session is
begin
   sys.dbms_session.clear_identifier;
   sys.dbms_application_info.set_module(module_name => null, action_name => null);
end reset_session;

procedure current_actor_not_null is
begin
   ut.expect(lib_session.current_actor).to_be_not_null;
end current_actor_not_null;

procedure set_step_sets_module is
begin
   lib_session.set_step(i_module => 'UTMOD', i_action => 'UTACT');
   ut.expect(lib_session.current_module).to_equal('UTMOD');
   ut.expect(lib_session.current_action).to_equal('UTACT');
end set_step_sets_module;

procedure set_client_drives_actor is
begin
   lib_session.set_client(i_identifier => 'enduser');
   ut.expect(lib_session.current_actor).to_equal('enduser');
end set_client_drives_actor;

end test_lib_session;
/
show errors package body test_lib_session

prompt File: test_lib_session.pkb.sql <end>
