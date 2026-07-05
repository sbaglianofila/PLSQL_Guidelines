prompt File: install.ins.sql <start>
-- =============================================================================
-- File:     install.ins.sql
-- Object:   Install orchestrator for schema #APP# (owner)
-- Schema:   #APP#
-- Purpose:  Runs the owner object scripts in dependency order.
--           Execute while connected as #APP# (directly or through the proxy).
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260701  AA   Creation
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
-- @@../Sequences/order_number.seq.sql

prompt #APP#: Types (specs and bodies)
-- @@../Types/<type>.typ.sql
-- @@../Types/<type>.tyb.sql

prompt #APP#: Tables
@@../Tables/orders.tab.sql

prompt #APP#: Foreign keys
@@../FKs/orders.fky.sql

prompt #APP#: Views (logic, then shell)
-- @@../Views/orders_v.vue.sql
-- @@../Views/orders_shell_v.vue.sql

prompt #APP#: Package specifications (logic then shell)
@@../Packages/pkg_orders.pks.sql
@@../Packages/pkg_orders_shell.pks.sql

prompt #APP#: Package bodies (logic then shell)
@@../Packages/pkg_orders.pkb.sql
@@../Packages/pkg_orders_shell.pkb.sql

prompt #APP#: Triggers
@@../Triggers/orders_audit_trg.trg.sql

prompt #APP#: Grants (to roles)
-- @@../Grants/<grant>.grt.sql

prompt #APP#: Seed and configuration data
-- @@../Data/<data>.dat.sql

prompt ============================================================
prompt Install #APP#: completed
prompt ============================================================
prompt File: install.ins.sql <end>
