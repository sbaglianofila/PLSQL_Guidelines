prompt File: <username>.usr.sql <start>
-- =============================================================================
-- File:     <username>.usr.sql
-- Object:   <username> (database user / schema)
-- Schema:   run as a privileged/DBA user
-- Purpose:  Create the user. Pick the variant that matches the profile
--           (see schemi.md). Two shapes exist: schemas that CREATE objects get
--           a dedicated tablespace and a scoped quota; consumers get neither.
-- Note:     NO real password here. Use a placeholder; the real secret is set
--           and managed in the target environment, never in version control.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <username>: Creating user

-- Variant A - owner (#APP#) and AM (#APP#_AM): they create objects.
-- Dedicated data tablespace + quota scoped to that tablespace (never the
-- global UNLIMITED TABLESPACE privilege).
create user <username> identified by "<placeholder_password>"
   default tablespace   <data_tablespace>
   temporary tablespace temp
   quota unlimited on   <data_tablespace>;

-- Variant B - consumers (#APP#_APP, #APP#_BATCH, #APP#_RO, #APP#_EXT_*):
-- they create nothing, so no quota on any tablespace.
-- create user <username> identified by "<placeholder_password>"
--    default tablespace   users
--    temporary tablespace temp;

-- Variant C - dev/test tooling (#APP#_GEN): creates its own throwaway objects
-- on the default tablespace.
-- create user <username> identified by "<placeholder_password>"
--    default tablespace   users
--    temporary tablespace temp
--    quota unlimited on   users;

prompt File: <username>.usr.sql <end>
