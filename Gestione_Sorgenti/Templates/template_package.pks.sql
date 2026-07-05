prompt File: pkg_<name>.pks.sql <start>
-- =============================================================================
-- File:     pkg_<name>.pks.sql
-- Object:   pkg_<name> (package specification)
-- Schema:   #APP#
-- Purpose:  Logic package for <name>: holds the real logic. Keeps the clean
--           name and is NEVER granted. When it must be exposed to a consumer,
--           add the pkg_<name>_shell shell and grant EXECUTE on THAT, never on
--           this package. See schemi.md.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt pkg_<name>: Creating package specification
create or replace package pkg_<name> is

-- <describe the subprogram>
function <function_name>(i_<param_name> in <datatype>) return <datatype>;

end pkg_<name>;
/
show errors package pkg_<name>

prompt File: pkg_<name>.pks.sql <end>
