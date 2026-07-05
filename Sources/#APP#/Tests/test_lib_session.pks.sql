prompt File: test_lib_session.pks.sql <start>
-- =============================================================================
-- File:     test_lib_session.pks.sql
-- Object:   test_lib_session (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_session.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_session: Creating test package specification
create or replace package test_lib_session is

--%suite(lib_session)
--%suitepath(#APP#.base)

-- Resets the session attributes touched by the tests.
--%aftereach
procedure reset_session;

--%test(current_actor is never null)
procedure current_actor_not_null;

--%test(set_step publishes module and action)
procedure set_step_sets_module;

--%test(set_client drives the effective actor)
procedure set_client_drives_actor;

end test_lib_session;
/
show errors package test_lib_session

prompt File: test_lib_session.pks.sql <end>
