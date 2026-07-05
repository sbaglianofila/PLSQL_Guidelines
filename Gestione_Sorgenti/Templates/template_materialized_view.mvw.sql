prompt File: <mview_name>.mvw.sql <start>
-- =============================================================================
-- File:     <mview_name>.mvw.sql
-- Object:   <mview_name> (materialized view)
-- Schema:   #APP#
-- Purpose:  <purpose>
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <mview_name>: Creating materialized view
create materialized view <mview_name>
   build immediate
   refresh complete on demand
as
   select <column_name>
        , <column_name>
     from <table_name>;

prompt File: <mview_name>.mvw.sql <end>
