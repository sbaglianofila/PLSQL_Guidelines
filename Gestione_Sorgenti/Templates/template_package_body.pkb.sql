prompt File: pkg_<name>.pkb.sql <start>
-- =============================================================================
-- File:     pkg_<name>.pkb.sql
-- Object:   pkg_<name> (package body)
-- Schema:   #APP#
-- Purpose:  Real logic (joins, filters, algorithms) for <name>. Not granted;
--           reached from inside the owner by name, and from consumers only
--           through the pkg_<name>_shell shell.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt pkg_<name>: Creating package body
create or replace package body pkg_<name> is

function <function_name>(i_<param_name> in <datatype>) return <datatype> is
   l_result <datatype>;
begin
   -- <implementation logic>
   return l_result;
end <function_name>;

end pkg_<name>;
/
show errors package body pkg_<name>

prompt File: pkg_<name>.pkb.sql <end>
