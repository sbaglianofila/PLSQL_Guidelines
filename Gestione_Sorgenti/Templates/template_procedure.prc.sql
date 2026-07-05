prompt File: <procedure_name>.prc.sql <start>
-- =============================================================================
-- File:     <procedure_name>.prc.sql
-- Object:   <procedure_name> (standalone procedure)
-- Schema:   #APP#
-- Purpose:  <purpose>
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <procedure_name>: Creating procedure
create or replace procedure <procedure_name>
   ( i_<param_name>  in     <datatype>
   -- , o_<param_name>  out    <datatype>
   -- , io_<param_name> in out <datatype>
   )
is
   -- <local declarations>
begin
   -- <logic>
   null;
end <procedure_name>;
/
show errors procedure <procedure_name>

prompt File: <procedure_name>.prc.sql <end>
