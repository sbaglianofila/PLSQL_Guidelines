prompt File: <table_name>.tab.sql <start>
-- =============================================================================
-- File:     <table_name>.tab.sql
-- Object:   <table_name> (table)
-- Schema:   #APP#
-- Purpose:  <purpose>
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <table_name>: Creating table
create table <table_name>
   ( <column_name>  <datatype>  constraint <table_name>_pk primary key
   , <column_name>  <datatype>  constraint <table_name>_nn_<column_name> not null
   -- , <column_name>  <datatype>
   -- , constraint <table_name>_uk_<column_name> unique (<column_name>)
   -- , constraint <table_name>_ck_<column_name> check (<condition>)
   -- administrative columns (populated by <table_name>_audit_trg) --------------
   , created_by        varchar2(64 char)  invisible  constraint <table_name>_nn_created_by      not null
   , created_at        timestamp(6)       invisible  constraint <table_name>_nn_created_at      not null
   , created_program   varchar2(64 char)  invisible  constraint <table_name>_nn_created_program not null
   , modified_by       varchar2(64 char)  invisible
   , modified_at       timestamp(6)       invisible
   , modified_program  varchar2(64 char)  invisible
   , row_version       number             default 1  constraint <table_name>_nn_row_version     not null
   );

prompt <table_name>: Adding comments
comment on table  <table_name> is '<purpose>';
comment on column <table_name>.<column_name> is '<column purpose>';
-- administrative columns (standard on every table; see colonne_amministrative.md)
comment on column <table_name>.created_by       is 'Application user that inserted the row (invisible; set by trigger).';
comment on column <table_name>.created_at       is 'Timestamp of insertion (invisible; set by trigger).';
comment on column <table_name>.created_program  is 'Program/module that inserted the row (invisible; set by trigger).';
comment on column <table_name>.modified_by      is 'Application user of the last update (invisible; null until first update).';
comment on column <table_name>.modified_at      is 'Timestamp of the last update (invisible; null until first update).';
comment on column <table_name>.modified_program is 'Program/module of the last update (invisible; null until first update).';
comment on column <table_name>.row_version      is 'Optimistic-locking row version; incremented by trigger on every change.';

prompt <table_name>: Creating indexes
-- create index <table_name>_idx_<column_name> on <table_name> (<column_name>);

-- Reminder: create the audit trigger <table_name>_audit_trg from
-- template_trigger_audit.trg.sql to populate the administrative columns.

prompt File: <table_name>.tab.sql <end>
