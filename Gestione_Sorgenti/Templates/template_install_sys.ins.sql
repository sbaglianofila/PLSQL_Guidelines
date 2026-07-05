prompt File: install.ins.sql <start>
-- =============================================================================
-- File:     install.ins.sql  (SYS provisioning orchestrator)
-- Object:   Privileged provisioning for the #APP# schema set
-- Schema:   run as a privileged/DBA user (or handed to the customer's DBAs)
-- Purpose:  Creates tablespaces, users, roles and system grants in order.
--           Contains NO real passwords: users are created with placeholders.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

whenever sqlerror exit failure rollback
whenever oserror  exit failure
set echo    off
set feedback on
set define  off

prompt ============================================================
prompt Provision #APP# (privileged): start
prompt ============================================================

prompt SYS: Tablespaces
-- @@../Tablespaces/<tablespace_name>.tbs.sql

prompt SYS: Users
-- @@../Users/#APP#.usr.sql
-- @@../Users/#APP#_app.usr.sql
-- @@../Users/#APP#_batch.usr.sql
-- @@../Users/#APP#_ro.usr.sql
-- @@../Users/#APP#_am.usr.sql
-- @@../Users/#APP#_ext_<name>.usr.sql
-- @@../Users/#APP#_gen.usr.sql        -- dev/test only

prompt SYS: Roles
-- @@../Roles/#APP#_app_role.rol.sql
-- @@../Roles/#APP#_ro_role.rol.sql
-- @@../Roles/#APP#_am_role.rol.sql

prompt SYS: System grants, role membership and proxy
-- @@../Grants/#APP#.grt.sql
-- @@../Grants/#APP#_am.grt.sql
-- @@../Grants/#APP#_app.grt.sql

prompt ============================================================
prompt Provision #APP#: completed
prompt ============================================================
prompt File: install.ins.sql <end>
