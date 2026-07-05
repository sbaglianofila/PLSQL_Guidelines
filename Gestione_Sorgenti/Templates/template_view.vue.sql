prompt File: <view_name>_v.vue.sql <start>
-- =============================================================================
-- File:     <view_name>_v.vue.sql
-- Object:   <view_name>_v (logic view)
-- Schema:   #APP#
-- Purpose:  Holds the real query logic (joins, filters). Keeps the clean name
--           and is NEVER granted: consumers reach it only through the
--           <view_name>_shell_v shell view. See schemi.md.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <view_name>_v: Creating logic view
create or replace view <view_name>_v as
   select a.<column_name>
        , b.<column_name>
     --
     from <table_a> a
     join <table_b> b on b.<key_column> = a.<key_column>
     --
    where <filter_condition>;
/
show errors view <view_name>_v

prompt File: <view_name>_v.vue.sql <end>
