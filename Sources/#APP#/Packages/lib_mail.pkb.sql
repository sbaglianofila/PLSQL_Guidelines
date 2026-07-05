prompt File: lib_mail.pkb.sql <start>
-- =============================================================================
-- File:     lib_mail.pkb.sql
-- Object:   lib_mail (package body)
-- Schema:   #APP#
-- Purpose:  Queue, environment guard, templates and retry/backoff on top of the
--           engine-independent lib_mail_engine.deliver.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_mail: Creating package body
create or replace package body lib_mail is

k_SCOPE                constant lib_types.scope_sbt := 'lib_mail';
k_PARAM_ENABLED        constant lib_types.name_sbt  := 'MAIL_ENABLED';
k_PARAM_FROM           constant lib_types.name_sbt  := 'MAIL_FROM_DEFAULT';
k_PARAM_TEST_RECIPIENT constant lib_types.name_sbt  := 'MAIL_TEST_RECIPIENT';
k_PARAM_MAX_ATTEMPTS   constant lib_types.name_sbt  := 'MAIL_MAX_ATTEMPTS';
k_PARAM_BACKOFF_MIN    constant lib_types.name_sbt  := 'MAIL_RETRY_BACKOFF_MIN';

k_DEFAULT_MAX_ATTEMPTS constant pls_integer := 3;
k_DEFAULT_BACKOFF_MIN  constant pls_integer := 5;
k_DEFAULT_BATCH        constant pls_integer := 1000;
k_STATUS_PENDING       constant wrk_mail_queue.status%type := 'PENDING';
k_STATUS_SENT          constant wrk_mail_queue.status%type := 'SENT';
k_STATUS_FAILED        constant wrk_mail_queue.status%type := 'FAILED';

type t_ids_type is table of wrk_mail_queue.mail_id%type;

-- Maps a boolean to the 'Y'/'N' flag stored in the tables.
function to_flag(i_bool in boolean) return varchar2 is
begin
   return ( case when i_bool then lib_constants.k_YES else lib_constants.k_NO end );
end to_flag;

-- Rewrites recipients and marks the subject when not in production, so real
-- mail cannot leave a non-production environment. Non-bypassable.
-- io_to / io_cc / io_bcc / io_subject : message fields, adjusted in place.
procedure apply_guard( io_to      in out varchar2
                     , io_cc      in out varchar2
                     , io_bcc     in out varchar2
                     , io_subject in out varchar2
                     )
is
   l_original  varchar2(2000 char);
begin
   if ( not lib_config.is_production )
   then
      l_original :=    'to=' || io_to
                    || nvl2(io_cc,  ' cc='  || io_cc,  null)
                    || nvl2(io_bcc, ' bcc=' || io_bcc, null);

      io_subject := substrb('[TEST ' || l_original || '] ' || io_subject, 1, 998);
      io_to      := lib_config.get_string(k_PARAM_TEST_RECIPIENT);
      io_cc      := null;
      io_bcc     := null;
   end if;
end apply_guard;

procedure send( i_to        in varchar2
              , i_subject   in varchar2
              , i_body      in clob
              , i_cc        in varchar2 default null
              , i_bcc       in varchar2 default null
              , i_is_html   in boolean  default false
              , i_from      in varchar2 default null
              , i_immediate in boolean  default false
              )
is
   l_to       varchar2(4000 char) := i_to;
   l_cc       varchar2(4000 char) := i_cc;
   l_bcc      varchar2(4000 char) := i_bcc;
   l_subject  varchar2(998 char)  := i_subject;
   k_FROM     constant varchar2(256 char) := coalesce(i_from, lib_config.get_string(k_PARAM_FROM));
begin
   apply_guard(io_to => l_to, io_cc => l_cc, io_bcc => l_bcc, io_subject => l_subject);

   if ( i_immediate )
   then
      lib_mail_engine.deliver( i_from    => k_FROM
                             , i_to      => l_to
                             , i_cc      => l_cc
                             , i_bcc     => l_bcc
                             , i_subject => l_subject
                             , i_body    => i_body
                             , i_is_html => i_is_html
                             );

      lib_logging.log_info(i_text => 'Mail sent immediately to ' || l_to, i_scope => k_SCOPE);
   else
      insert
        into wrk_mail_queue (  from_addr
                             , to_addr
                             , cc_addr
                             , bcc_addr
                             , subject
                             , body
                             , is_html
                            )
      values (  k_FROM
              , l_to
              , l_cc
              , l_bcc
              , l_subject
              , i_body
              , to_flag(i_is_html)
             );

      lib_logging.log_info(i_text => 'Mail queued to ' || l_to, i_scope => k_SCOPE);
   end if;
end send;

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
                       )
is
   l_subject  cfg_email_templates.subject%type;
   l_body     cfg_email_templates.body%type;
   l_is_html  cfg_email_templates.is_html%type;
begin
   begin
      select cet.subject
           , cet.body
           , cet.is_html
        into l_subject
           , l_body
           , l_is_html
        from cfg_email_templates cet
       where cet.template_code = i_template_code;
   exception
      when no_data_found
      then
         lib_err.raise(i_error => lib_err.k_MAIL_TEMPLATE_MISSING, i_p1 => i_template_code, i_scope => k_SCOPE);
   end;

   -- Subject fits varchar2; the body is a CLOB, so substitute placeholders on
   -- the CLOB directly (replace preserves the CLOB type).
   l_subject := lib_text.format(l_subject, i_p1, i_p2, i_p3, i_p4, i_p5);
   l_body    := replace(l_body, '%1', i_p1);
   l_body    := replace(l_body, '%2', i_p2);
   l_body    := replace(l_body, '%3', i_p3);
   l_body    := replace(l_body, '%4', i_p4);
   l_body    := replace(l_body, '%5', i_p5);

   send( i_to        => i_to
       , i_subject   => l_subject
       , i_body      => l_body
       , i_cc        => i_cc
       , i_bcc       => i_bcc
       , i_is_html   => (l_is_html = lib_constants.k_YES)
       , i_immediate => i_immediate
       );
end send_template;

procedure process_queue(i_max_messages in number default null) is
   k_LIMIT        constant pls_integer := coalesce(i_max_messages, k_DEFAULT_BATCH);
   k_MAX_ATTEMPTS constant pls_integer := lib_config.get_number(k_PARAM_MAX_ATTEMPTS, k_DEFAULT_MAX_ATTEMPTS);
   k_BACKOFF_MIN  constant pls_integer := lib_config.get_number(k_PARAM_BACKOFF_MIN, k_DEFAULT_BACKOFF_MIN);
   l_ids          t_ids_type;
   l_msg          wrk_mail_queue%rowtype;
begin
   if ( lib_config.get_flag(k_PARAM_ENABLED, lib_constants.k_NO) = lib_constants.k_NO )
   then
      return;
   end if;

   -- Candidate messages due for delivery (unlocked read).
   select lmq.mail_id
     bulk collect into l_ids
     from wrk_mail_queue lmq
    where lmq.status          = k_STATUS_PENDING
      and lmq.next_attempt_at <= systimestamp
    order by lmq.next_attempt_at
    fetch first k_LIMIT rows only;

   for i in 1 .. l_ids.count
   loop
      -- Lock this message alone, skipping it if another worker holds it or it
      -- is no longer pending.
      begin
         select *
           into l_msg
           from wrk_mail_queue lmq
          where lmq.mail_id = l_ids(i)
            and lmq.status  = k_STATUS_PENDING
            for update skip locked;
      exception
         when no_data_found
         then
            continue;
      end;

      begin
         lib_mail_engine.deliver( i_from    => l_msg.from_addr
                                , i_to      => l_msg.to_addr
                                , i_cc      => l_msg.cc_addr
                                , i_bcc     => l_msg.bcc_addr
                                , i_subject => l_msg.subject
                                , i_body    => l_msg.body
                                , i_is_html => (l_msg.is_html = lib_constants.k_YES)
                                );

         update wrk_mail_queue lmq
            set lmq.status          = k_STATUS_SENT
              , lmq.sent_at         = systimestamp
              , lmq.last_attempt_at = systimestamp
              , lmq.attempts        = lmq.attempts + 1
          where lmq.mail_id = l_msg.mail_id;
      exception
         when others
         then
            update wrk_mail_queue lmq
               set lmq.attempts        = lmq.attempts + 1
                 , lmq.last_attempt_at = systimestamp
                 , lmq.error_message   = substrb(sqlerrm, 1, 4000)
                 , lmq.status          = case
                                            when lmq.attempts + 1 >= k_MAX_ATTEMPTS then k_STATUS_FAILED
                                            else k_STATUS_PENDING
                                         end
                 , lmq.next_attempt_at = systimestamp + numtodsinterval((lmq.attempts + 1) * k_BACKOFF_MIN * 60, 'SECOND')
             where lmq.mail_id = l_msg.mail_id;

            lib_logging.log_error(i_text => 'Mail ' || l_msg.mail_id || ' delivery failed', i_scope => k_SCOPE);
      end;

      commit;
   end loop;
end process_queue;

end lib_mail;
/
show errors package body lib_mail

prompt File: lib_mail.pkb.sql <end>
