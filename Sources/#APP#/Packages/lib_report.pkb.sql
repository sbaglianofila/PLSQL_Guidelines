prompt File: lib_report.pkb.sql <start>
-- =============================================================================
-- File:     lib_report.pkb.sql
-- Object:   lib_report (package body)
-- Schema:   #APP#
-- Purpose:  Cursor-to-CSV/HTML rendering via sys.dbms_sql, and registered
--           report execution with lib_batch tracking and lib_mail / lib_file
--           delivery.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_report: Creating package body
create or replace package body lib_report is

k_SCOPE     constant lib_types.scope_sbt := 'lib_report';
k_FMT_CSV   constant varchar2(4 char)    := 'CSV';
k_FMT_HTML  constant varchar2(4 char)    := 'HTML';
k_CRLF      constant varchar2(2 char)    := chr(13) || chr(10);
k_MAX_COL   constant pls_integer         := 32767;

-- Quotes a CSV field when it contains a separator, quote or newline.
-- i_value : raw field value.
-- return  : CSV-safe field.
function csv_quote(i_value in varchar2) return varchar2 is
begin
   if ( instr(i_value, ',') > 0
        or instr(i_value, '"') > 0
        or instr(i_value, chr(10)) > 0
        or instr(i_value, chr(13)) > 0 )
   then
      return ( '"' || replace(i_value, '"', '""') || '"' );
   end if;

   return (i_value);
end csv_quote;

-- Escapes the HTML-significant characters of a cell value.
-- i_value : raw cell value.
-- return  : HTML-safe text.
function html_escape(i_value in varchar2) return varchar2 is
   l_value  varchar2(32767 char) := i_value;
begin
   l_value := replace(l_value, '&', '&amp;');
   l_value := replace(l_value, '<', '&lt;');
   l_value := replace(l_value, '>', '&gt;');

   return (l_value);
end html_escape;

-- Renders a cursor to CSV or HTML and reports the row count. Consumes the
-- cursor and closes the underlying dbms_sql cursor.
-- i_cursor    : open cursor to render.
-- i_format    : k_FMT_CSV or k_FMT_HTML.
-- o_row_count : number of data rows rendered.
-- return      : the rendered document.
function render_internal( i_cursor    in sys_refcursor
                        , i_format    in varchar2
                        , o_row_count out number
                        ) return clob
is
   l_rc       sys_refcursor := i_cursor;
   l_cursor   integer;
   l_col_cnt  integer;
   l_desc     sys.dbms_sql.desc_tab;
   l_val      varchar2(32767 char);
   l_result   clob;
begin
   l_cursor := sys.dbms_sql.to_cursor_number(l_rc);
   sys.dbms_sql.describe_columns(l_cursor, l_col_cnt, l_desc);

   for i in 1 .. l_col_cnt
   loop
      sys.dbms_sql.define_column(l_cursor, i, l_val, k_MAX_COL);
   end loop;

   sys.dbms_lob.createtemporary(lob_loc => l_result, cache => true);
   o_row_count := 0;

   -- Header.
   if ( i_format = k_FMT_HTML )
   then
      sys.dbms_lob.append(l_result, '<table>' || k_CRLF || '<thead><tr>');
   end if;

   for i in 1 .. l_col_cnt
   loop
      if ( i_format = k_FMT_HTML )
      then
         sys.dbms_lob.append(l_result, '<th>' || html_escape(l_desc(i).col_name) || '</th>');
      else
         if ( i > 1 )
         then
            sys.dbms_lob.append(l_result, ',');
         end if;

         sys.dbms_lob.append(l_result, csv_quote(l_desc(i).col_name));
      end if;
   end loop;

   if ( i_format = k_FMT_HTML )
   then
      sys.dbms_lob.append(l_result, '</tr></thead>' || k_CRLF || '<tbody>' || k_CRLF);
   else
      sys.dbms_lob.append(l_result, k_CRLF);
   end if;

   -- Rows.
   while ( sys.dbms_sql.fetch_rows(l_cursor) > 0 )
   loop
      o_row_count := o_row_count + 1;

      if ( i_format = k_FMT_HTML )
      then
         sys.dbms_lob.append(l_result, '<tr>');
      end if;

      for i in 1 .. l_col_cnt
      loop
         sys.dbms_sql.column_value(l_cursor, i, l_val);

         if ( i_format = k_FMT_HTML )
         then
            sys.dbms_lob.append(l_result, '<td>' || html_escape(l_val) || '</td>');
         else
            if ( i > 1 )
            then
               sys.dbms_lob.append(l_result, ',');
            end if;

            sys.dbms_lob.append(l_result, csv_quote(l_val));
         end if;
      end loop;

      if ( i_format = k_FMT_HTML )
      then
         sys.dbms_lob.append(l_result, '</tr>' || k_CRLF);
      else
         sys.dbms_lob.append(l_result, k_CRLF);
      end if;
   end loop;

   if ( i_format = k_FMT_HTML )
   then
      sys.dbms_lob.append(l_result, '</tbody></table>' || k_CRLF);
   end if;

   sys.dbms_sql.close_cursor(l_cursor);

   return (l_result);
end render_internal;

function render_csv(i_cursor in sys_refcursor) return clob is
   l_rows  number;
begin
   return (render_internal(i_cursor => i_cursor, i_format => k_FMT_CSV, o_row_count => l_rows));
end render_csv;

function render_html(i_cursor in sys_refcursor) return clob is
   l_rows  number;
begin
   return (render_internal(i_cursor => i_cursor, i_format => k_FMT_HTML, o_row_count => l_rows));
end render_html;

procedure run_report(i_report_code in varchar2) is
   l_run_id   number;
   l_rec      cfg_reports%rowtype;
   l_cursor   sys_refcursor;
   l_content  clob;
   l_rows     number;
begin
   l_run_id := lib_batch.start_run(i_process_name => 'REPORT_' || i_report_code);

   begin
      select *
        into l_rec
        from cfg_reports crp
       where crp.report_code = i_report_code
         and crp.is_enabled  = lib_constants.k_YES;
   exception
      when no_data_found
      then
         lib_err.raise(i_error => lib_err.k_REPORT_NOT_FOUND, i_p1 => i_report_code, i_scope => k_SCOPE);
   end;

   open l_cursor for l_rec.query_text;
   l_content := render_internal(i_cursor => l_cursor, i_format => l_rec.format, o_row_count => l_rows);

   -- "Anomalies only": silence is the good news.
   if ( l_rec.anomalies_only = lib_constants.k_YES and l_rows = 0 )
   then
      lib_batch.end_run(i_run_id => l_run_id, i_rows_processed => 0);
      return;
   end if;

   if ( l_rec.recipients is not null )
   then
      lib_mail.send( i_to      => l_rec.recipients
                   , i_subject => coalesce(l_rec.description, i_report_code)
                   , i_body    => l_content
                   , i_is_html => (l_rec.format = k_FMT_HTML)
                   );
   end if;

   if ( l_rec.output_directory is not null and l_rec.output_filename is not null )
   then
      lib_file.write_clob( i_directory => l_rec.output_directory
                         , i_filename  => l_rec.output_filename
                         , i_content   => l_content
                         );
   end if;

   lib_batch.end_run(i_run_id => l_run_id, i_rows_processed => l_rows);
exception
   when others
   then
      lib_batch.fail_run(i_run_id => l_run_id);
      lib_err.reraise(i_scope => k_SCOPE);
end run_report;

end lib_report;
/
show errors package body lib_report

prompt File: lib_report.pkb.sql <end>
