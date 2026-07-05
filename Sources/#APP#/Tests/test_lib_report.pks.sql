prompt File: test_lib_report.pks.sql <start>
-- =============================================================================
-- File:     test_lib_report.pks.sql
-- Object:   test_lib_report (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_report rendering. run_report is verified by
--           manual integration test (needs cfg_reports and delivery).
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_report: Creating test package specification
create or replace package test_lib_report is

   --%suite(lib_report)
   --%suitepath(#APP#.base)

   --%test(render_csv emits a header and data rows)
   procedure csv_header_and_rows;

   --%test(render_csv quotes a field containing a comma)
   procedure csv_quotes_comma;

   --%test(render_html emits a table with cells)
   procedure html_table;

end test_lib_report;
/
show errors package test_lib_report

prompt File: test_lib_report.pks.sql <end>
