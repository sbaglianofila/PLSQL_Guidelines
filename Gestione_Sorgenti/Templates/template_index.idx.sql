prompt File: <table_name>.idx.sql <start>
-- =============================================================================
-- File:     <table_name>.idx.sql
-- Object:   Standalone index(es) on <table_name>
-- Schema:   #APP#
-- Purpose:  <purpose>
-- Note:     If added after the initial baseline, date the file as
--           <table_name>.<YYYYMMDD_NN>.idx.sql (it is then a migration).
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <table_name>: Creating index <table_name>_idx_<column_name>
create index <table_name>_idx_<column_name> on <table_name> (<column_name>);

prompt File: <table_name>.idx.sql <end>
