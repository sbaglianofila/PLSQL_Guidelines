prompt File: <object_name>.syn.sql <start>
-- =============================================================================
-- File:     <object_name>.syn.sql
-- Object:   Private synonym for <object_name>
-- Schema:   created inside a consumer schema (e.g. #APP#_APP)
-- Purpose:  Let the consumer reference the owner's object without qualifying it.
-- Note:     Private synonyms in a consumer schema are created at provisioning
--           by an installer account holding CREATE ANY SYNONYM, so the consumer
--           keeps only CREATE SESSION at runtime. See schemi.md.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <object_name>: Creating private synonym in #APP#_APP
create or replace synonym #APP#_app.<object_name> for #APP#.<object_name>;

prompt File: <object_name>.syn.sql <end>
