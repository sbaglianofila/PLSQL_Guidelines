prompt File: <type_name>_ot.typ.sql <start>
-- =============================================================================
-- File:     <type_name>_ot.typ.sql
-- Object:   <type_name>_ot (object type specification)
-- Schema:   #APP#
-- Purpose:  <purpose>
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <type_name>_ot: Creating type specification
create or replace type <type_name>_ot as object
   ( <attribute_name>  <datatype>
   -- , <attribute_name>  <datatype>
   -- , member function <method_name> return <datatype>
   );
/
show errors type <type_name>_ot

prompt File: <type_name>_ot.typ.sql <end>
