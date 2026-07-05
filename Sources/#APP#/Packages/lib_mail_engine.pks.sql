prompt File: lib_mail_engine.pks.sql <start>
-- =============================================================================
-- File:     lib_mail_engine.pks.sql
-- Object:   lib_mail_engine (package specification)
-- Schema:   #APP#
-- Purpose:  Low-level mail transmission behind lib_mail. This is the only piece
--           that differs between mail backends: exactly one body is installed -
--           lib_mail_engine.utl_smtp.pkb.sql (direct SMTP) OR
--           lib_mail_engine.apex.pkb.sql (APEX_MAIL). All the higher-level
--           logic (queue, environment guard, templates, logging) lives in
--           lib_mail and is engine-independent.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_mail_engine: Creating package specification
create or replace package lib_mail_engine is

   -- Transmits one already-composed, already-environment-guarded message
   -- synchronously through the configured backend. Recipient lists are
   -- comma-separated. Raises lib_err.e_mail_send_failed on any transport error.
   -- i_from    : sender address.
   -- i_to      : recipient list (comma-separated).
   -- i_cc      : cc list (comma-separated), or null.
   -- i_bcc     : bcc list (comma-separated), or null.
   -- i_subject : message subject.
   -- i_body    : message body (plain text or HTML per i_is_html).
   -- i_is_html : true when the body is HTML.
   procedure deliver( i_from    in varchar2
                    , i_to      in varchar2
                    , i_cc      in varchar2
                    , i_bcc     in varchar2
                    , i_subject in varchar2
                    , i_body    in clob
                    , i_is_html in boolean
                    );

   -- Backend identifier, for diagnostics ('UTL_SMTP' or 'APEX_MAIL').
   function backend return varchar2;

end lib_mail_engine;
/
show errors package lib_mail_engine

prompt File: lib_mail_engine.pks.sql <end>
