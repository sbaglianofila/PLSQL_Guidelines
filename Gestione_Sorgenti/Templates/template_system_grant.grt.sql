prompt File: <username>.grt.sql <start>
-- =============================================================================
-- File:     <username>.grt.sql
-- Object:   System privileges, role membership and proxy for <username>
-- Schema:   run as a privileged/DBA user
-- Purpose:  Grant only the minimum each profile needs. Uncomment the block that
--           matches the user's profile; leave the others out. See schemi.md.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <username>: Granting CREATE SESSION
grant create session to <username>;

-- --- Owner (#APP#) --------------------------------------------------------
-- Object creation only. No PUBLIC SYNONYM, no dictionary privileges.
-- grant create table, create view, create sequence, create procedure,
--       create trigger, create type, create synonym to <username>;
-- grant create materialized view to <username>;   -- if used
-- grant create job to <username>;                  -- if the Scheduler is used

-- --- Owner (#APP#): SYS packages ------------------------------------------
-- EXECUTE on the specific SYS packages the application uses, granted one by
-- one (rationale in schemi.md). NEVER select_catalog_role or select any
-- dictionary on the owner: dictionary-wide privileges stay confined to AM
-- and to the dev/test tooling schema.
-- Already granted to PUBLIC by default (no grant needed): dbms_output,
-- dbms_utility, dbms_application_info, dbms_scheduler, dbms_sql.
-- grant execute on sys.dbms_lock   to <username>;  -- application locks (11_patterns.md)
-- grant execute on sys.utl_file    to <username>;  -- file I/O; often revoked from
--                                                  -- PUBLIC on hardened DBs. Also
--                                                  -- needs a DIRECTORY object with
--                                                  -- read/write granted to the owner
-- grant execute on sys.dbms_crypto to <username>;  -- hashing/encryption, if used
-- grant execute on sys.utl_http    to <username>;  -- outbound HTTP, if used; also
-- grant execute on sys.utl_smtp    to <username>;  -- mail, if used; both require a
--                                                  -- network ACL (dbms_network_acl_admin)

-- --- AM (#APP#_AM) --------------------------------------------------------
-- Own work objects + dictionary introspection for diagnosis.
-- grant create table, create view, create procedure, create sequence,
--       create synonym to <username>;
-- grant select_catalog_role   to <username>;
-- grant select any dictionary to <username>;

-- --- Dev tooling (#APP#_GEN, dev/test only) -------------------------------
-- grant create procedure, create table, create view to <username>;
-- grant select_catalog_role   to <username>;
-- grant select any dictionary to <username>;

prompt <username>: Assigning application role(s)
-- grant <role_name> to <username>;
-- alter user <username> default role all;

prompt <username>: Proxy authentication (optional; for the owner)
-- alter user #APP# grant connect through #APP#_proxy;

prompt File: <username>.grt.sql <end>
