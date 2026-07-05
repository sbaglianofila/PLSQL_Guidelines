prompt File: <script_name>.<YYYYMMDD_NN>.scr.sql <start>
-- =============================================================================
-- File:     <script_name>.<YYYYMMDD_NN>.scr.sql
-- Object:   One-off data migration / fix (DML)
-- Schema:   #APP#
-- Purpose:  <describe the action and why it is needed>
-- Note:     One-shot migration, run once and in order. IMMUTABLE once merged:
--           to fix a mistake add a new script, do not edit this one.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

whenever sqlerror exit failure rollback

prompt <script_name>: Applying data change
-- <DML statement(s)>

prompt <script_name>: Committing
commit;

prompt File: <script_name>.<YYYYMMDD_NN>.scr.sql <end>
