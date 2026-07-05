prompt File: test_lib_config.pks.sql <start>
-- =============================================================================
-- File:     test_lib_config.pks.sql
-- Object:   test_lib_config (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_config.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_config: Creating test package specification
create or replace package test_lib_config is

--%suite(lib_config)
--%suitepath(#APP#.base)

-- Seeds and removes the dedicated test parameters.
--%beforeall
procedure seed_params;

--%afterall
procedure remove_params;

--%test(get_string returns the stored value)
procedure get_string_returns_value;

--%test(get_string returns the default when the parameter is absent)
procedure default_when_missing;

--%test(a missing mandatory parameter raises config_param_missing)
--%throws(-20004)
procedure missing_mandatory_raises;

--%test(a non-numeric value raises config_param_invalid)
--%throws(-20005)
procedure number_invalid_raises;

end test_lib_config;
/
show errors package test_lib_config

prompt File: test_lib_config.pks.sql <end>
