prompt File: lib_constants.pks.sql <start>
-- =============================================================================
-- File:     lib_constants.pks.sql
-- Object:   lib_constants (package specification)
-- Schema:   #APP#
-- Purpose:  Single home for cross-cutting literal values, plus the deterministic
--           functions that expose to SQL the constants also needed in queries.
--           Holds only truly cross-cutting constants: state values of a single
--           business entity live in that entity's API package, not here.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_constants: Creating package specification
create or replace package lib_constants is

-- Flag values (varchar2 'Y'/'N', pre-23ai boolean).
k_YES               constant lib_types.flag_sbt := 'Y';
k_NO                constant lib_types.flag_sbt := 'N';

-- Numeric truth values, for the number(1) boolean encoding.
k_NUMERIC_TRUE      constant pls_integer := 1;
k_NUMERIC_FALSE     constant pls_integer := 0;

-- Canonical conversion formats (FX enforces exact-format matching).
k_DATE_FMT          constant lib_types.code_sbt := 'FXYYYY-MM-DD';
k_TIMESTAMP_FMT     constant lib_types.code_sbt := 'FXYYYY-MM-DD HH24:MI:SS';

-- Shared thresholds and limits.
k_BULK_LIMIT        constant pls_integer := 1000;     -- default bulk fetch size
k_ONE_WEEK          constant pls_integer := 604800;   -- seconds; default lock expiration
k_DEFAULT_LOCK_WAIT constant pls_integer := 5;        -- seconds; default lock request timeout
k_LOG_RETENTION     constant pls_integer := 90;       -- days; default log retention

-- Exposes k_YES to SQL (e.g. where flag = lib_constants.yes).
-- return : the 'Y' flag value.
function yes return varchar2 deterministic;

-- Exposes k_NO to SQL.
-- return : the 'N' flag value.
function no return varchar2 deterministic;

end lib_constants;
/
show errors package lib_constants

prompt File: lib_constants.pks.sql <end>
