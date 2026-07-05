prompt File: test_<name>.pks.sql <start>
-- =============================================================================
-- File:     test_<name>.pks.sql
-- Object:   test_<name> (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for <name>. Requires utPLSQL installed.
--           utPLSQL annotations are the --%... comments below.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt test_<name>: Creating test package specification
create or replace package test_<name> is

   --%suite(<suite title>)
   --%suitepath(#APP#.<module>)

   --%test(<describe the expected behaviour>)
   procedure <test_procedure_name>;

end test_<name>;
/
show errors package test_<name>

prompt File: test_<name>.pks.sql <end>
