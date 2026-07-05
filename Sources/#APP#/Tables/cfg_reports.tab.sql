prompt File: cfg_reports.tab.sql <start>
-- =============================================================================
-- File:     cfg_reports.tab.sql
-- Object:   cfg_reports (table)
-- Schema:   #APP#
-- Purpose:  Registry of tabular reports run by lib_report.run_report: the query
--           to execute, the output format, and how to deliver it (mail and/or
--           file). The "anomalies only" flag suppresses delivery when the query
--           returns no rows (silence = all good), for reports built on control
--           queries.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt cfg_reports: Creating table
create table cfg_reports
   ( report_code      varchar2(64 char)   constraint cfg_reports_pk primary key
   , description      varchar2(512 char)
   , query_text       clob                constraint cfg_reports_nn_query not null
   , format           varchar2(8 char)    default 'CSV'
                                           constraint cfg_reports_nn_format not null
   , recipients       varchar2(4000 char)
   , output_directory varchar2(128 char)
   , output_filename  varchar2(512 char)
   , anomalies_only   varchar2(1 char)    default 'N'
                                           constraint cfg_reports_nn_anomalies not null
   , is_enabled       varchar2(1 char)    default 'Y'
                                           constraint cfg_reports_nn_enabled not null
   , constraint cfg_reports_ck_format    check (format in ('CSV', 'HTML'))
   , constraint cfg_reports_ck_anomalies check (anomalies_only in ('Y', 'N'))
   , constraint cfg_reports_ck_enabled   check (is_enabled in ('Y', 'N'))
   );

prompt cfg_reports: Adding comments
comment on table  cfg_reports                  is 'Registry of tabular reports produced and delivered by lib_report.';
comment on column cfg_reports.report_code      is 'Report code (natural key) passed to run_report.';
comment on column cfg_reports.description      is 'Description; also used as the mail subject.';
comment on column cfg_reports.query_text       is 'SQL query executed to produce the report rows.';
comment on column cfg_reports.format           is 'Output format: CSV or HTML.';
comment on column cfg_reports.recipients       is 'Mail recipients (comma-separated); null to skip mail delivery.';
comment on column cfg_reports.output_directory is 'Oracle DIRECTORY for file delivery; null to skip file delivery.';
comment on column cfg_reports.output_filename  is 'File name for file delivery (within output_directory).';
comment on column cfg_reports.anomalies_only   is 'Y to deliver only when the query returns rows (silence = all good).';
comment on column cfg_reports.is_enabled       is 'Y when the report may run.';

prompt File: cfg_reports.tab.sql <end>
