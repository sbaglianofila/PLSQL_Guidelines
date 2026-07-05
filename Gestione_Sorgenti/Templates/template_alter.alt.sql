prompt File: <table_name>.<YYYYMMDD_NN>.alt.sql <start>
-- =============================================================================
-- File:     <table_name>.<YYYYMMDD_NN>.alt.sql
-- Object:   <table_name> (table) - migration
-- Schema:   #APP#
-- Purpose:  <describe the structural change>
-- Note:     Migrations are IMMUTABLE once merged. To correct a mistake, add a
--           new migration; never edit this file after it has been integrated.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <table_name>: Altering table
alter table <table_name> add (<column_name> <datatype>);
-- alter table <table_name> modify (<column_name> <datatype>);
-- alter table <table_name> add constraint <table_name>_ck_<column_name> check (<condition>);

prompt <table_name>: Commenting affected columns
-- comment on column <table_name>.<column_name> is '<purpose>';

prompt File: <table_name>.<YYYYMMDD_NN>.alt.sql <end>
