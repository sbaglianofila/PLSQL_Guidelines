prompt File: lib_constants.pkb.sql <start>
-- =============================================================================
-- File:     lib_constants.pkb.sql
-- Object:   lib_constants (package body)
-- Schema:   #APP#
-- Purpose:  Implements the deterministic accessors that expose the flag
--           constants to SQL. No state.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_constants: Creating package body
create or replace package body lib_constants is

-- The DETERMINISTIC property is declared in the specification; the body
-- must not repeat it.
function yes return varchar2 is
begin
   return (k_YES);
end yes;

function no return varchar2 is
begin
   return (k_NO);
end no;

end lib_constants;
/
show errors package body lib_constants

prompt File: lib_constants.pkb.sql <end>
