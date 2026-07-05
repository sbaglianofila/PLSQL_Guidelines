prompt File: <sequence_name>.seq.sql <start>
-- =============================================================================
-- File:     <sequence_name>.seq.sql
-- Object:   <sequence_name> (sequence)
-- Schema:   #APP#
-- Purpose:  <purpose>
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <sequence_name>: Creating sequence
create sequence <sequence_name>
   start with 1
   increment by 1
   cache 20
   nocycle;

prompt File: <sequence_name>.seq.sql <end>
