prompt File: cfg_email_templates.tab.sql <start>
-- =============================================================================
-- File:     cfg_email_templates.tab.sql
-- Object:   cfg_email_templates (table)
-- Schema:   #APP#
-- Purpose:  Subject and body templates used by lib_mail.send_template, with %1..
--           placeholders resolved via lib_text.format. Lets email texts be
--           changed by configuration instead of by code.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt cfg_email_templates: Creating table
create table cfg_email_templates
   ( template_code  varchar2(64 char)   constraint cfg_email_templates_pk primary key
   , subject        varchar2(998 char)  constraint cfg_email_templates_nn_subject not null
   , body           clob                constraint cfg_email_templates_nn_body not null
   , is_html        varchar2(1 char)    default 'N'
                                        constraint cfg_email_templates_nn_html not null
   , description    varchar2(512 char)
   , constraint cfg_email_templates_ck_html check (is_html in ('Y', 'N'))
   );

prompt cfg_email_templates: Adding comments
comment on table  cfg_email_templates              is 'Email subject/body templates resolved by lib_mail.send_template via lib_text.format.';
comment on column cfg_email_templates.template_code is 'Template code (natural key) referenced by send_template.';
comment on column cfg_email_templates.subject       is 'Subject template with %1..%5 placeholders.';
comment on column cfg_email_templates.body          is 'Body template with %1..%5 placeholders.';
comment on column cfg_email_templates.is_html       is 'Y when the body is HTML, N for plain text.';
comment on column cfg_email_templates.description    is 'Description of the template and its intended use.';

prompt File: cfg_email_templates.tab.sql <end>
