prompt File: lib_mail_engine.utl_smtp.pkb.sql <start>
-- =============================================================================
-- File:     lib_mail_engine.utl_smtp.pkb.sql
-- Object:   lib_mail_engine (package body - UTL_SMTP backend)
-- Schema:   #APP#
-- Purpose:  Direct-SMTP implementation of lib_mail_engine. Install THIS body OR
--           lib_mail_engine.apex.pkb.sql, never both. Sends a single-part
--           text/HTML message; attachments are a planned extension.
--           Prerequisites: grant execute on sys.utl_smtp, a network ACL to the
--           mail server, and the configuration parameters MAIL_SMTP_HOST /
--           MAIL_SMTP_PORT.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_mail_engine (UTL_SMTP): Creating package body
create or replace package body lib_mail_engine is

k_SCOPE        constant lib_types.scope_sbt := 'lib_mail_engine';
k_BACKEND      constant varchar2(9 char)    := 'UTL_SMTP';
k_CRLF         constant varchar2(2 char)    := chr(13) || chr(10);
k_CHUNK        constant pls_integer         := 1900;
k_PARAM_HOST   constant lib_types.name_sbt  := 'MAIL_SMTP_HOST';
k_PARAM_PORT   constant lib_types.name_sbt  := 'MAIL_SMTP_PORT';
k_DEFAULT_PORT constant pls_integer         := 25;

function backend return varchar2 is
begin
   return (k_BACKEND);
end backend;

-- Adds each address of a comma-separated list as an SMTP recipient.
-- io_conn : open SMTP connection.
-- i_list  : comma-separated address list (may be null).
procedure add_recipients(io_conn in out nocopy sys.utl_smtp.connection, i_list in varchar2) is
   l_addrs  lib_text.t_strings_type;
begin
   if ( i_list is null )
   then
      return;
   end if;

   l_addrs := lib_text.split(i_list, ',');

   for i in 1 .. l_addrs.count
   loop
      if ( trim(l_addrs(i)) is not null )
      then
         sys.utl_smtp.rcpt(io_conn, trim(l_addrs(i)));
      end if;
   end loop;
end add_recipients;

-- Writes a CLOB body to the open DATA stream in chunks.
-- io_conn : open SMTP connection with DATA started.
-- i_body  : message body.
procedure write_body(io_conn in out nocopy sys.utl_smtp.connection, i_body in clob) is
   k_LEN    constant pls_integer := dbms_lob.getlength(i_body);
   l_offset          pls_integer := 1;
begin
   while ( l_offset <= k_LEN )
   loop
      sys.utl_smtp.write_data(io_conn, dbms_lob.substr(i_body, k_CHUNK, l_offset));
      l_offset := l_offset + k_CHUNK;
   end loop;
end write_body;

procedure deliver( i_from    in varchar2
                 , i_to      in varchar2
                 , i_cc      in varchar2
                 , i_bcc     in varchar2
                 , i_subject in varchar2
                 , i_body    in clob
                 , i_is_html in boolean
                 )
is
   k_HOST         constant varchar2(256 char) := lib_config.get_string(k_PARAM_HOST);
   k_PORT         constant number             := lib_config.get_number(k_PARAM_PORT, k_DEFAULT_PORT);
   k_CONTENT_TYPE constant varchar2(40 char)  := case when i_is_html then 'text/html' else 'text/plain' end;
   l_conn                  sys.utl_smtp.connection;
begin
   l_conn := sys.utl_smtp.open_connection(k_HOST, k_PORT);
   sys.utl_smtp.helo(l_conn, k_HOST);
   sys.utl_smtp.mail(l_conn, i_from);

   add_recipients(io_conn => l_conn, i_list => i_to);
   add_recipients(io_conn => l_conn, i_list => i_cc);
   add_recipients(io_conn => l_conn, i_list => i_bcc);

   sys.utl_smtp.open_data(l_conn);
   sys.utl_smtp.write_data(l_conn, 'From: '         || i_from    || k_CRLF);
   sys.utl_smtp.write_data(l_conn, 'To: '           || i_to      || k_CRLF);

   if ( i_cc is not null )
   then
      sys.utl_smtp.write_data(l_conn, 'Cc: ' || i_cc || k_CRLF);
   end if;

   sys.utl_smtp.write_data(l_conn, 'Subject: '      || i_subject || k_CRLF);
   sys.utl_smtp.write_data(l_conn, 'MIME-Version: 1.0' || k_CRLF);
   sys.utl_smtp.write_data(l_conn, 'Content-Type: ' || k_CONTENT_TYPE || '; charset="UTF-8"' || k_CRLF);
   sys.utl_smtp.write_data(l_conn, k_CRLF);

   write_body(io_conn => l_conn, i_body => i_body);

   sys.utl_smtp.close_data(l_conn);
   sys.utl_smtp.quit(l_conn);
exception
   when others
   then
      -- Best-effort teardown, then surface a speaking error.
      begin
         sys.utl_smtp.quit(l_conn);
      exception
         when others
         then
            null;
      end;

      lib_err.raise(i_error => lib_err.k_MAIL_SEND_FAILED, i_p1 => sqlerrm, i_scope => k_SCOPE);
end deliver;

end lib_mail_engine;
/
show errors package body lib_mail_engine

prompt File: lib_mail_engine.utl_smtp.pkb.sql <end>
