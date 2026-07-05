prompt File: <tablespace_name>.tbs.sql <start>
-- =============================================================================
-- File:     <tablespace_name>.tbs.sql
-- Object:   <tablespace_name> (tablespace)
-- Schema:   run as a privileged/DBA user
-- Purpose:  Dedicated data tablespace (e.g. #APP#_DATA, #APP#_AM_DATA).
-- Note:     Datafile path and sizing depend on the target environment and are
--           typically decided by the DBA. Adjust the values below accordingly.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <tablespace_name>: Creating tablespace
create tablespace <tablespace_name>
   datafile '<datafile_path>' size <initial_size>
   autoextend on next <next_size> maxsize <max_size>
   extent management local
   segment space management auto;

prompt File: <tablespace_name>.tbs.sql <end>
