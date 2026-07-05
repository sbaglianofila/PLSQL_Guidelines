prompt File: lib_types.pks.sql <start>
-- =============================================================================
-- File:     lib_types.pks.sql
-- Object:   lib_types (package specification)
-- Schema:   #APP#
-- Purpose:  Shared PL/SQL subtypes, aligned with the domains in Catalogo/domini.md.
--           Specification only, no body. Deliberately small: a subtype belongs
--           here only if it represents a recurring concept, never "for
--           completeness". This is the most cited base package.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_types: Creating package specification
create or replace package lib_types is

-- Textual subtypes by size, aligned with the text domains (code, name,
-- description, note). big_string_sbt is the PL/SQL-only large buffer.
subtype code_sbt        is varchar2(32 char);      -- domain: code
subtype name_sbt        is varchar2(128 char);     -- domain: name
subtype short_text_sbt  is varchar2(512 char);     -- domain: description
subtype text_sbt        is varchar2(4000 char);    -- domain: note
subtype big_string_sbt  is varchar2(32767 char);   -- PL/SQL large buffer

-- Technical subtypes used by the base packages.
subtype flag_sbt        is varchar2(1 char);       -- domain: flag ('Y'/'N')
subtype scope_sbt       is varchar2(128 char);     -- logging scope (package.subprogram)
subtype lock_name_sbt   is varchar2(128 char);     -- sys.dbms_lock lock name
subtype lock_handle_sbt is varchar2(128 char);     -- sys.dbms_lock lock handle

-- Numeric domain subtype.
subtype percentage_sbt  is number(5,2);            -- domain: percentage (0..100)

-- Note: numeric domain subtypes such as amount_sbt / quantity_sbt are added
-- here only when a project actually adopts them, not up front.

end lib_types;
/
show errors package lib_types

prompt File: lib_types.pks.sql <end>
