prompt File: lib_report.pks.sql <start>
-- =============================================================================
-- File:     lib_report.pks.sql
-- Object:   lib_report (package specification)
-- Schema:   #APP#
-- Purpose:  Automatic tabular reports. Ties together control queries, scheduler
--           and delivery: turns any cursor into CSV or HTML and delivers it via
--           lib_mail or lib_file, so reporting needs no ad-hoc development. The
--           prime use case is AM monitoring: run control queries periodically
--           and speak up only when there is something to look at.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_report: Creating package specification
create or replace package lib_report is

   -- Renders any cursor as CSV, describing its columns dynamically (works with
   -- any query). Consumes the cursor.
   -- i_cursor : open cursor to render.
   -- return   : CSV document.
   function render_csv(i_cursor in sys_refcursor) return clob;

   -- Renders any cursor as an HTML table. Consumes the cursor.
   -- i_cursor : open cursor to render.
   -- return   : HTML document.
   function render_html(i_cursor in sys_refcursor) return clob;

   -- Runs a registered report: reads its definition from cfg_reports, executes
   -- the query, formats it and delivers it by mail and/or file. Each run is
   -- tracked through lib_batch. For "anomalies only" reports, delivery happens
   -- solely when the query returns rows. Raises lib_err.e_report_not_found for
   -- an unknown code.
   -- i_report_code : report to run.
   procedure run_report(i_report_code in varchar2);

end lib_report;
/
show errors package lib_report

prompt File: lib_report.pks.sql <end>
