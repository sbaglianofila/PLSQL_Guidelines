prompt File: install_tests.ins.sql <start>
-- =============================================================================
-- File:     install_tests.ins.sql
-- Object:   Install orchestrator for the base-package utPLSQL suites
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Installs the test suites for the base packages. Requires utPLSQL to
--           be installed in the database. NEVER run in production and NEVER
--           include in a release package: test suites live only in dev/test.
--           Run after install.ins.sql has created the base packages.
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
prompt Install #APP# base-package test suites: start
prompt ============================================================

prompt #APP#: Test suite specifications
@@../Tests/test_lib_types.pks.sql
@@../Tests/test_lib_constants.pks.sql
@@../Tests/test_lib_session.pks.sql
@@../Tests/test_lib_err.pks.sql
@@../Tests/test_lib_config.pks.sql
@@../Tests/test_lib_logging.pks.sql
@@../Tests/test_lib_lock.pks.sql
@@../Tests/test_lib_batch.pks.sql
@@../Tests/test_lib_assert.pks.sql
@@../Tests/test_lib_text.pks.sql
@@../Tests/test_lib_calendar.pks.sql
@@../Tests/test_lib_mail.pks.sql
@@../Tests/test_lib_file.pks.sql
@@../Tests/test_lib_report.pks.sql

prompt #APP#: Test suite bodies
@@../Tests/test_lib_types.pkb.sql
@@../Tests/test_lib_constants.pkb.sql
@@../Tests/test_lib_session.pkb.sql
@@../Tests/test_lib_err.pkb.sql
@@../Tests/test_lib_config.pkb.sql
@@../Tests/test_lib_logging.pkb.sql
@@../Tests/test_lib_lock.pkb.sql
@@../Tests/test_lib_batch.pkb.sql
@@../Tests/test_lib_assert.pkb.sql
@@../Tests/test_lib_text.pkb.sql
@@../Tests/test_lib_calendar.pkb.sql
@@../Tests/test_lib_mail.pkb.sql
@@../Tests/test_lib_file.pkb.sql
@@../Tests/test_lib_report.pkb.sql

prompt ============================================================
prompt Install #APP# base-package test suites: completed
prompt Run with:  exec ut.run('#APP#.base')
prompt ============================================================
prompt File: install_tests.ins.sql <end>
