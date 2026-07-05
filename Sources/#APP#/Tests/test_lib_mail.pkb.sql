prompt File: test_lib_mail.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_mail.pkb.sql
-- Object:   test_lib_mail (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_mail. Queue rows are ordinary DML rolled back by
--           utPLSQL; only the autonomous log entries and the seeded template
--           need explicit cleanup. Assumes a non-production environment so the
--           guard is active.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_mail: Creating test package body
create or replace package body test_lib_mail is

k_TEMPLATE  constant varchar2(64 char) := 'UT_TPL';

procedure seed_template is
   pragma autonomous_transaction;
begin
   merge into cfg_email_templates t
   using ( select k_TEMPLATE as template_code from dual ) s
      on (t.template_code = s.template_code)
    when not matched then
       insert (t.template_code, t.subject, t.body, t.is_html)
       values (k_TEMPLATE, 'Hello %1', to_clob('Dear %1,'), 'N');
   commit;
   lib_config.refresh;
end seed_template;

procedure remove_template is
   pragma autonomous_transaction;
begin
   delete from cfg_email_templates cet where cet.template_code = k_TEMPLATE;
   commit;
end remove_template;

procedure cleanup is
   pragma autonomous_transaction;
begin
   delete from log_entries lge where lge.scope = 'lib_mail';
   delete from log_errors  ler where ler.scope = 'lib_mail';
   commit;
end cleanup;

procedure send_queues_and_guards is
   l_to      wrk_mail_queue.to_addr%type;
   l_subject wrk_mail_queue.subject%type;
   l_status  wrk_mail_queue.status%type;
begin
   lib_mail.send(i_to => 'real@example.com', i_subject => 'Hi', i_body => to_clob('body'));

   select lmq.to_addr
        , lmq.subject
        , lmq.status
     into l_to
        , l_subject
        , l_status
     from wrk_mail_queue lmq
    where rownum = 1;

   ut.expect(l_to).to_equal(lib_config.get_string('MAIL_TEST_RECIPIENT'));
   ut.expect(l_subject).to_be_like('[TEST%');
   ut.expect(l_status).to_equal('PENDING');
end send_queues_and_guards;

procedure send_template_substitutes is
   l_subject  wrk_mail_queue.subject%type;
begin
   lib_mail.send_template(i_template_code => k_TEMPLATE, i_to => 'x@example.com', i_p1 => 'World');

   select lmq.subject
     into l_subject
     from wrk_mail_queue lmq
    where rownum = 1;

   ut.expect(l_subject).to_be_like('%Hello World%');
end send_template_substitutes;

procedure template_missing_raises is
begin
   lib_mail.send_template(i_template_code => 'NOPE_TEMPLATE', i_to => 'x@example.com');
   ut.fail('expected e_mail_template_missing, none raised');
end template_missing_raises;

end test_lib_mail;
/
show errors package body test_lib_mail

prompt File: test_lib_mail.pkb.sql <end>
