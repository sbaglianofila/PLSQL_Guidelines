prompt File: <view_name>_shell_v.vue.sql <start>
-- =============================================================================
-- File:     <view_name>_shell_v.vue.sql
-- Object:   <view_name>_shell_v (shell view)
-- Schema:   #APP#
-- Purpose:  Shell view exposed to consumers. Explicit column list, no logic:
--           selects from <view_name>_v. Grant SELECT on THIS view.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <view_name>_shell_v: Creating shell view
create or replace view <view_name>_shell_v as
   select <column_name>
        , <column_name>
     from <view_name>_v;
/
show errors view <view_name>_shell_v

prompt File: <view_name>_shell_v.vue.sql <end>
