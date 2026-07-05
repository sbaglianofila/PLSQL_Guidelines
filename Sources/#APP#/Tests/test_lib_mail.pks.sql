prompt File: test_lib_mail.pks.sql <start>
-- =============================================================================
-- File:     test_lib_mail.pks.sql
-- Object:   test_lib_mail (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_mail. Cover the engine-independent behaviour:
--           queueing, the environment guard and template resolution. Actual
--           delivery (lib_mail_engine) is verified by manual integration test.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_mail: Creating test package specification
create or replace package test_lib_mail is

   --%suite(lib_mail)
   --%suitepath(#APP#.base)

   --%beforeall
   procedure seed_template;

   --%afterall
   procedure remove_template;

   -- Removes the autonomously committed log rows written with the lib_mail scope.
   --%aftereach
   procedure cleanup;

   --%test(send enqueues a PENDING message and applies the environment guard)
   procedure send_queues_and_guards;

   --%test(send_template resolves the placeholders into the queued message)
   procedure send_template_substitutes;

   --%test(send_template raises for an unknown template)
   --%throws(-20011)
   procedure template_missing_raises;

end test_lib_mail;
/
show errors package test_lib_mail

prompt File: test_lib_mail.pks.sql <end>
