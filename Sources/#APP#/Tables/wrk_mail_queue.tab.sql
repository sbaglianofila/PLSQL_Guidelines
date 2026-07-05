prompt File: wrk_mail_queue.tab.sql <start>
-- =============================================================================
-- File:     wrk_mail_queue.tab.sql
-- Object:   wrk_mail_queue (table)
-- Schema:   #APP#
-- Purpose:  Outbound mail queue written by lib_mail.send and drained by
--           lib_mail.process_queue (a scheduled job) with retry and backoff, so
--           sending never lengthens nor fails the application transaction.
--           Recipients are already environment-guarded when stored.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt wrk_mail_queue: Creating table
create table wrk_mail_queue
   ( mail_id         number(24)          generated always as identity
                                         constraint wrk_mail_queue_pk primary key
   , created_at      timestamp(6)        default systimestamp
                                         constraint wrk_mail_queue_nn_created not null
   , from_addr       varchar2(256 char)
   , to_addr         varchar2(4000 char) constraint wrk_mail_queue_nn_to not null
   , cc_addr         varchar2(4000 char)
   , bcc_addr        varchar2(4000 char)
   , subject         varchar2(998 char)
   , body            clob
   , is_html         varchar2(1 char)    default 'N'
                                         constraint wrk_mail_queue_nn_html not null
   , status          varchar2(32 char)   default 'PENDING'
                                         constraint wrk_mail_queue_nn_status not null
   , attempts        number              default 0
   , next_attempt_at timestamp(6)        default systimestamp
   , last_attempt_at timestamp(6)
   , sent_at         timestamp(6)
   , error_message   varchar2(4000 char)
   , constraint wrk_mail_queue_ck_status check (status in ('PENDING', 'SENT', 'FAILED'))
   , constraint wrk_mail_queue_ck_html   check (is_html in ('Y', 'N'))
   );

prompt wrk_mail_queue: Adding comments
comment on table  wrk_mail_queue                 is 'Outbound mail queue drained by lib_mail.process_queue with retry and backoff.';
comment on column wrk_mail_queue.mail_id         is 'Surrogate key, generated identity.';
comment on column wrk_mail_queue.created_at      is 'Instant the message was enqueued.';
comment on column wrk_mail_queue.from_addr       is 'Sender address; defaults from configuration when null at enqueue.';
comment on column wrk_mail_queue.to_addr         is 'Recipient list (comma-separated), already environment-guarded.';
comment on column wrk_mail_queue.cc_addr         is 'Cc recipient list (comma-separated).';
comment on column wrk_mail_queue.bcc_addr        is 'Bcc recipient list (comma-separated).';
comment on column wrk_mail_queue.subject         is 'Message subject.';
comment on column wrk_mail_queue.body            is 'Message body (plain text or HTML per is_html).';
comment on column wrk_mail_queue.is_html         is 'Y when the body is HTML, N for plain text.';
comment on column wrk_mail_queue.status          is 'PENDING, SENT or FAILED.';
comment on column wrk_mail_queue.attempts        is 'Number of delivery attempts made so far.';
comment on column wrk_mail_queue.next_attempt_at is 'Earliest instant the next delivery attempt may run (backoff).';
comment on column wrk_mail_queue.last_attempt_at is 'Instant of the last delivery attempt.';
comment on column wrk_mail_queue.sent_at         is 'Instant the message was successfully sent.';
comment on column wrk_mail_queue.error_message   is 'Error text of the last failed attempt.';

prompt wrk_mail_queue: Creating indexes
create index wrk_mail_queue_idx_pending on wrk_mail_queue (status, next_attempt_at);

prompt File: wrk_mail_queue.tab.sql <end>
