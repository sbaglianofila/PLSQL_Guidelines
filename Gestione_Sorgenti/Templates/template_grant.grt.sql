prompt File: <object_name>.grt.sql <start>
-- =============================================================================
-- File:     <object_name>.grt.sql
-- Object:   Grants for <object_name>
-- Schema:   #APP# (grants issued by the owner to consumer roles)
-- Purpose:  Expose <object_name> to the appropriate consumer role(s). Grant the
--           shell (API / shell view), never the implementation. See schemi.md.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <object_name>: Granting privileges to roles
grant execute on <object_name> to #APP#_app_role;
-- grant select on <object_name> to #APP#_ro_role;
-- grant select, insert, update, delete on <object_name> to #APP#_am_role;

prompt File: <object_name>.grt.sql <end>
