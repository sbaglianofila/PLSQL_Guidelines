prompt File: <table_name>_br_iud.trg.sql <start>
-- =============================================================================
-- File:     <table_name>_br_iud.trg.sql
-- Object:   <table_name>_br_iud (trigger)
-- Schema:   #APP#
-- Purpose:  <purpose>
-- Note:     For logic spanning multiple timing points, prefer a compound
--           trigger (<table_name>_cmpd_trg); see 02_naming_conventions.md.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <table_name>_br_iud: Creating trigger
create or replace trigger <table_name>_br_iud
   before insert or update or delete on <table_name>
   for each row
begin
   -- <logic>
   null;
end <table_name>_br_iud;
/
show errors trigger <table_name>_br_iud

prompt File: <table_name>_br_iud.trg.sql <end>
