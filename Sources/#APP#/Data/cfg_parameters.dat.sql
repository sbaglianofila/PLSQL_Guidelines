prompt File: cfg_parameters.dat.sql <start>
-- =============================================================================
-- File:     cfg_parameters.dat.sql
-- Object:   Seed / configuration data for cfg_parameters
-- Schema:   #APP#
-- Purpose:  Baseline parameters consumed by the base packages. ENVIRONMENT is
--           provisioning-only (is_modifiable = N) and must be set to the real
--           value (DEV/TEST/PROD) per environment. Logging parameters are
--           runtime-modifiable through lib_config.set_value.
-- Note:     Uses MERGE so the script is idempotent and safe to re-run. The
--           merge does not overwrite an existing value, only inserts missing
--           rows, so per-environment changes are preserved on re-run.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

whenever sqlerror exit failure rollback

prompt cfg_parameters: Seeding rows
merge into cfg_parameters t
using ( select 'ENVIRONMENT'        as param_name
             , 'DEV'                 as param_value
             , 'STRING'              as param_type
             , 'Environment identity (DEV/TEST/PROD); set at provisioning.' as description
             , 'N'                   as is_modifiable
          from dual
        union all
        select 'LOG_MIN_LEVEL'
             , 'INFO'
             , 'STRING'
             , 'Minimum level written by lib_logging: DEBUG, INFO or WARN.'
             , 'Y'
          from dual
        union all
        select 'LOG_RETENTION_DAYS'
             , '90'
             , 'NUMBER'
             , 'Age in days beyond which lib_logging.purge deletes log rows.'
             , 'Y'
          from dual
        union all
        select 'MAIL_ENABLED'
             , 'N'
             , 'FLAG'
             , 'Master switch: lib_mail.process_queue delivers only when Y.'
             , 'Y'
          from dual
        union all
        select 'MAIL_FROM_DEFAULT'
             , 'no-reply@example.com'
             , 'STRING'
             , 'Default sender address used by lib_mail when none is supplied.'
             , 'Y'
          from dual
        union all
        select 'MAIL_TEST_RECIPIENT'
             , 'devnull@example.com'
             , 'STRING'
             , 'Mailbox all non-production mail is redirected to by the lib_mail environment guard.'
             , 'Y'
          from dual
        union all
        select 'MAIL_SMTP_HOST'
             , 'localhost'
             , 'STRING'
             , 'SMTP server host (UTL_SMTP engine only).'
             , 'Y'
          from dual
        union all
        select 'MAIL_SMTP_PORT'
             , '25'
             , 'NUMBER'
             , 'SMTP server port (UTL_SMTP engine only).'
             , 'Y'
          from dual
        union all
        select 'MAIL_MAX_ATTEMPTS'
             , '3'
             , 'NUMBER'
             , 'Delivery attempts before lib_mail marks a queued message FAILED.'
             , 'Y'
          from dual
        union all
        select 'MAIL_RETRY_BACKOFF_MIN'
             , '5'
             , 'NUMBER'
             , 'Base minutes between delivery retries (multiplied by attempt number).'
             , 'Y'
          from dual
        union all
        select 'MAIL_APEX_WORKSPACE'
             , cast(null as varchar2(1))
             , 'STRING'
             , 'APEX workspace for apex_mail outside an APEX session (APEX_MAIL engine only); leave empty otherwise.'
             , 'Y'
          from dual
      ) s
   on (t.param_name = s.param_name)
 when not matched then
    insert (  t.param_name
            , t.param_value
            , t.param_type
            , t.description
            , t.is_modifiable
           )
    values (  s.param_name
            , s.param_value
            , s.param_type
            , s.description
            , s.is_modifiable
           );

prompt cfg_parameters: Committing seed data
commit;

prompt File: cfg_parameters.dat.sql <end>
