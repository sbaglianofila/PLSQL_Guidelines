prompt File: <table_name>.dat.sql <start>
-- =============================================================================
-- File:     <table_name>.dat.sql
-- Object:   Seed / configuration data for <table_name>
-- Schema:   #APP#
-- Purpose:  <purpose>
-- Note:     Uses MERGE so the script is idempotent and safe to re-run.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

whenever sqlerror exit failure rollback

prompt <table_name>: Seeding rows
merge into <table_name> t
using ( select <key_value>   as <key_column>
             , <value>       as <column_name>
          from dual
        -- union all select ...
      ) s
   on (t.<key_column> = s.<key_column>)
 when not matched then
    insert (<key_column>, <column_name>) values (s.<key_column>, s.<column_name>)
 when matched then
    update set t.<column_name> = s.<column_name>;

prompt <table_name>: Committing seed data
commit;

prompt File: <table_name>.dat.sql <end>
