prompt File: <type_name>_ot.tyb.sql <start>
-- =============================================================================
-- File:     <type_name>_ot.tyb.sql
-- Object:   <type_name>_ot (object type body)
-- Schema:   #APP#
-- Purpose:  Method implementations for <type_name>_ot.
--           Needed only if the type specification declares member methods.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <type_name>_ot: Creating type body
create or replace type body <type_name>_ot as

   member function <method_name> return <datatype> is
   begin
      -- <implementation logic>
      return null;
   end <method_name>;

end;
/
show errors type body <type_name>_ot

prompt File: <type_name>_ot.tyb.sql <end>
