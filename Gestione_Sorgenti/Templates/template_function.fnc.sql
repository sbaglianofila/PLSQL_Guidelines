prompt File: <function_name>.fnc.sql <start>
-- =============================================================================
-- File:     <function_name>.fnc.sql
-- Object:   <function_name> (standalone function)
-- Schema:   #APP#
-- Purpose:  <purpose>
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <function_name>: Creating function
create or replace function <function_name>
   ( i_<param_name> in <datatype> )
   return <datatype>
is
   l_result <datatype>;
begin
   -- <logic>
   return l_result;
end <function_name>;
/
show errors function <function_name>

prompt File: <function_name>.fnc.sql <end>
