prompt File: <table_name>.mvl.sql <start>
-- =============================================================================
-- File:     <table_name>.mvl.sql
-- Object:   Materialized view log on <table_name>
-- Schema:   #APP#
-- Purpose:  Support fast refresh of materialized views built on <table_name>.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <table_name>: Creating materialized view log
create materialized view log on <table_name>
   with primary key, rowid, sequence
   including new values;

prompt File: <table_name>.mvl.sql <end>
