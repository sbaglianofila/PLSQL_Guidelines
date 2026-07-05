prompt File: <table_name>.fky.sql <start>
-- =============================================================================
-- File:     <table_name>.fky.sql
-- Object:   Foreign keys for <table_name>
-- Schema:   #APP#
-- Purpose:  Foreign key constraints, applied after all referenced tables exist
--           (which is why FKs live in their own folder).
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <table_name>: Creating foreign key <table_name>_fk_<referenced_table>
alter table <table_name> add constraint <table_name>_fk_<referenced_table>
   foreign key (<column_name>) references <referenced_table> (<referenced_column>);

prompt File: <table_name>.fky.sql <end>
