prompt File: install.ins.sql <start>
-- =============================================================================
-- File:     install.ins.sql
-- Object:   Install orchestrator for schema #APP#
-- Schema:   #APP#
-- Purpose:  Runs the object scripts in dependency order. Execute while
--           connected as the target schema (directly or through the proxy).
--           The order of the sections below is the canonical install order.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

whenever sqlerror exit failure rollback
whenever oserror  exit failure
set echo        off
set feedback     on
set define       off
set serveroutput on size unlimited

prompt ============================================================
prompt Install #APP#: start
prompt ============================================================

prompt #APP#: Sequences
-- @@../Sequences/<sequence_name>.seq.sql

prompt #APP#: Types (specs then bodies)
-- @@../Types/<type_name>_ot.typ.sql
-- @@../Types/<type_name>_ot.tyb.sql

prompt #APP#: Tables
-- @@../Tables/<table_name>.tab.sql

prompt #APP#: Standalone indexes
-- @@../Tables/<table_name>.idx.sql

prompt #APP#: Foreign keys
-- @@../FKs/<table_name>.fky.sql

prompt #APP#: Materialized view logs
-- @@../MVLogs/<table_name>.mvl.sql

prompt #APP#: Views (logic then shell)
-- @@../Views/<view_name>_v.vue.sql
-- @@../Views/<view_name>_shell_v.vue.sql

prompt #APP#: Materialized views
-- @@../MaterializedViews/<mview_name>.mvw.sql

prompt #APP#: Package specifications (logic then shell)
-- @@../Packages/pkg_<name>.pks.sql
-- @@../Packages/pkg_<name>_shell.pks.sql

prompt #APP#: Standalone procedures and functions
-- @@../Procedures/<procedure_name>.prc.sql
-- @@../Functions/<function_name>.fnc.sql

prompt #APP#: Package bodies (logic then shell)
-- @@../Packages/pkg_<name>.pkb.sql
-- @@../Packages/pkg_<name>_shell.pkb.sql

prompt #APP#: Triggers
-- @@../Triggers/<table_name>_br_iud.trg.sql

prompt #APP#: Grants
-- @@../Grants/<object_name>.grt.sql

prompt #APP#: Synonyms
-- @@../Synonyms/<object_name>.syn.sql

prompt #APP#: Seed and configuration data
-- @@../Data/<table_name>.dat.sql

prompt ============================================================
prompt Install #APP#: completed
prompt ============================================================
prompt File: install.ins.sql <end>
