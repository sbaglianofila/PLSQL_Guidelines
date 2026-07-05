prompt File: install.ins.sql <start>
-- =============================================================================
-- File:     install.ins.sql
-- Object:   Install orchestrator for schema #APP# (base packages)
-- Schema:   #APP#
-- Purpose:  Runs the base-package object scripts in dependency order. Execute
--           while connected as the target schema (directly or through the
--           proxy). The order of the sections below is the canonical install
--           order. Test suites are installed separately by install_tests.ins.sql
--           in dev/test environments only.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

whenever sqlerror exit failure rollback
whenever oserror  exit failure
set echo        off
set feedback     on
set define       off
set serveroutput on size unlimited

prompt ============================================================
prompt Install #APP# base packages: start
prompt ============================================================

prompt #APP#: Tables
@@../Tables/log_entries.tab.sql
@@../Tables/log_errors.tab.sql
@@../Tables/cfg_parameters.tab.sql
@@../Tables/log_process_runs.tab.sql
@@../Tables/ref_holidays.tab.sql
@@../Tables/cfg_email_templates.tab.sql
@@../Tables/wrk_mail_queue.tab.sql
@@../Tables/cfg_reports.tab.sql

prompt #APP#: Package specifications (foundations first)
@@../Packages/lib_types.pks.sql
@@../Packages/lib_constants.pks.sql
@@../Packages/lib_session.pks.sql
@@../Packages/lib_err.pks.sql
@@../Packages/lib_config.pks.sql
@@../Packages/lib_logging.pks.sql
@@../Packages/lib_lock.pks.sql
@@../Packages/lib_batch.pks.sql
@@../Packages/lib_assert.pks.sql
@@../Packages/lib_text.pks.sql
@@../Packages/lib_calendar.pks.sql
@@../Packages/lib_mail_engine.pks.sql
@@../Packages/lib_mail.pks.sql
@@../Packages/lib_file.pks.sql
@@../Packages/lib_report.pks.sql

prompt #APP#: Package bodies
@@../Packages/lib_constants.pkb.sql
@@../Packages/lib_session.pkb.sql
@@../Packages/lib_logging.pkb.sql
@@../Packages/lib_err.pkb.sql
@@../Packages/lib_config.pkb.sql
@@../Packages/lib_lock.pkb.sql
@@../Packages/lib_batch.pkb.sql
@@../Packages/lib_assert.pkb.sql
@@../Packages/lib_text.pkb.sql
@@../Packages/lib_calendar.pkb.sql
-- Mail engine: install EXACTLY ONE backend body (comment/uncomment to switch).
@@../Packages/lib_mail_engine.utl_smtp.pkb.sql
-- @@../Packages/lib_mail_engine.apex.pkb.sql
@@../Packages/lib_mail.pkb.sql
@@../Packages/lib_file.pkb.sql
@@../Packages/lib_report.pkb.sql

prompt #APP#: Seed and configuration data
@@../Data/cfg_parameters.dat.sql

prompt ============================================================
prompt Install #APP# base packages: completed
prompt ============================================================
prompt File: install.ins.sql <end>
