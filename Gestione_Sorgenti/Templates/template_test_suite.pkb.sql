prompt File: test_<name>.pkb.sql <start>
-- =============================================================================
-- File:     test_<name>.pkb.sql
-- Object:   test_<name> (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for <name>. Follow the Arrange / Act / Assert structure.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt test_<name>: Creating test package body
create or replace package body test_<name> is

   procedure <test_procedure_name> is
      -- <declarations>
   begin
      -- Arrange: set up the fixture
      -- Act:     invoke the object under test
      -- Assert:  state the expectation
      ut.expect(<actual>).to_equal(<expected>);
   end <test_procedure_name>;

end test_<name>;
/
show errors package body test_<name>

prompt File: test_<name>.pkb.sql <end>
