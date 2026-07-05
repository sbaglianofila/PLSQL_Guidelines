prompt File: pkg_<name>_shell.pks.sql <start>
-- =============================================================================
-- File:     pkg_<name>_shell.pks.sql
-- Object:   pkg_<name>_shell (package specification)
-- Schema:   #APP#
-- Purpose:  Public shell for <name>. Contains no logic: every subprogram
--           delegates to pkg_<name>. Grant EXECUTE on THIS shell to consumer
--           roles; never grant pkg_<name>. See schemi.md.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt pkg_<name>_shell: Creating package specification
create or replace package pkg_<name>_shell is

-- <describe the subprogram>
function <function_name>(i_<param_name> in <datatype>) return <datatype>;

end pkg_<name>_shell;
/
show errors package pkg_<name>_shell

prompt File: pkg_<name>_shell.pks.sql <end>
