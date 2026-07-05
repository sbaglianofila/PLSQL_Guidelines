prompt File: pkg_<name>_shell.pkb.sql <start>
-- =============================================================================
-- File:     pkg_<name>_shell.pkb.sql
-- Object:   pkg_<name>_shell (package body)
-- Schema:   #APP#
-- Purpose:  Shell body: pure delegation to pkg_<name>, no logic. Runs with
--           definer rights (the default) so it can reach the logic package.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt pkg_<name>_shell: Creating package body
create or replace package body pkg_<name>_shell is

function <function_name>(i_<param_name> in <datatype>) return <datatype> is
begin
   return pkg_<name>.<function_name>(i_<param_name>);
end <function_name>;

end pkg_<name>_shell;
/
show errors package body pkg_<name>_shell

prompt File: pkg_<name>_shell.pkb.sql <end>
