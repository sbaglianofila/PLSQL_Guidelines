prompt File: test_lib_report.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_report.pkb.sql
-- Object:   test_lib_report (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_report rendering over cursors on dual.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_report: Creating test package body
create or replace package body test_lib_report is

procedure csv_header_and_rows is
   l_cursor  sys_refcursor;
   l_csv     clob;
   l_text    varchar2(4000 char);
begin
   open l_cursor for select 'a' as col1, 'b' as col2 from dual;
   l_csv  := lib_report.render_csv(l_cursor);
   l_text := sys.dbms_lob.substr(l_csv, 4000, 1);

   ut.expect(l_text).to_be_like('%COL1,COL2%');
   ut.expect(l_text).to_be_like('%a,b%');
end csv_header_and_rows;

procedure csv_quotes_comma is
   l_cursor  sys_refcursor;
   l_csv     clob;
   l_text    varchar2(4000 char);
begin
   open l_cursor for select 'x,y' as col1 from dual;
   l_csv  := lib_report.render_csv(l_cursor);
   l_text := sys.dbms_lob.substr(l_csv, 4000, 1);

   ut.expect(l_text).to_be_like('%"x,y"%');
end csv_quotes_comma;

procedure html_table is
   l_cursor  sys_refcursor;
   l_html    clob;
   l_text    varchar2(4000 char);
begin
   open l_cursor for select 'a' as col1 from dual;
   l_html := lib_report.render_html(l_cursor);
   l_text := sys.dbms_lob.substr(l_html, 4000, 1);

   ut.expect(l_text).to_be_like('%<table>%');
   ut.expect(l_text).to_be_like('%<td>a</td>%');
end html_table;

end test_lib_report;
/
show errors package body test_lib_report

prompt File: test_lib_report.pkb.sql <end>
