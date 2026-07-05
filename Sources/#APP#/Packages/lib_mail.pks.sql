prompt File: lib_mail.pks.sql <start>
-- =============================================================================
-- File:     lib_mail.pks.sql
-- Object:   lib_mail (package specification)
-- Schema:   #APP#
-- Purpose:  Generic mail package. Its value is not "calling the backend" but
--           everything around it: correct message construction, templates,
--           queue, and the environment guard that prevents real mail from
--           being sent outside production. The actual transmission is delegated
--           to lib_mail_engine, so the backend (UTL_SMTP or APEX_MAIL) can be
--           swapped without touching this package.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_mail: Creating package specification
create or replace package lib_mail is

   -- Sends a message. Queued by default (written to wrk_mail_queue and delivered
   -- later by process_queue); set i_immediate to true to deliver synchronously.
   -- Outside production the recipients are rewritten to the test mailbox and the
   -- subject is marked - this guard cannot be bypassed by the caller.
   -- i_to        : recipient list (comma-separated).
   -- i_subject   : message subject.
   -- i_body      : message body (plain text or HTML per i_is_html).
   -- i_cc        : cc list (comma-separated), or null.
   -- i_bcc       : bcc list (comma-separated), or null.
   -- i_is_html   : true when the body is HTML.
   -- i_from      : sender address; defaults from configuration when null.
   -- i_immediate : true to send now, false (default) to enqueue.
   procedure send( i_to        in varchar2
                 , i_subject   in varchar2
                 , i_body      in clob
                 , i_cc        in varchar2 default null
                 , i_bcc       in varchar2 default null
                 , i_is_html   in boolean  default false
                 , i_from      in varchar2 default null
                 , i_immediate in boolean  default false
                 );

   -- Sends a message whose subject and body come from cfg_email_templates, with
   -- the %1..%5 placeholders resolved. Same queue and guard behaviour as send.
   -- i_template_code : template to use.
   -- i_to            : recipient list (comma-separated).
   -- i_p1..5         : placeholder values.
   -- i_cc            : cc list, or null.
   -- i_bcc           : bcc list, or null.
   -- i_immediate     : true to send now, false (default) to enqueue.
   procedure send_template( i_template_code in varchar2
                          , i_to            in varchar2
                          , i_p1            in varchar2 default null
                          , i_p2            in varchar2 default null
                          , i_p3            in varchar2 default null
                          , i_p4            in varchar2 default null
                          , i_p5            in varchar2 default null
                          , i_cc            in varchar2 default null
                          , i_bcc           in varchar2 default null
                          , i_immediate     in boolean  default false
                          );

   -- Drains the queue: delivers pending messages via lib_mail_engine with retry
   -- and backoff, committing per message. Meant for a scheduled job. Does
   -- nothing when the MAIL_ENABLED parameter is 'N'.
   -- i_max_messages : maximum messages to process in this run; null for a
   --                  default batch size.
   procedure process_queue(i_max_messages in number default null);

end lib_mail;
/
show errors package lib_mail

prompt File: lib_mail.pks.sql <end>
