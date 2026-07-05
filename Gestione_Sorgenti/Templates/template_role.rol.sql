prompt File: <role_name>.rol.sql <start>
-- =============================================================================
-- File:     <role_name>.rol.sql
-- Object:   <role_name> (role)
-- Schema:   run as a privileged/DBA user
-- Purpose:  Profile role that bundles the grants for a class of consumers
--           (e.g. #APP#_app_role, #APP#_ro_role, #APP#_am_role). Object grants
--           are assigned to the role in the owner's Grants scripts.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <role_name>: Creating role
create role <role_name>;

prompt File: <role_name>.rol.sql <end>
