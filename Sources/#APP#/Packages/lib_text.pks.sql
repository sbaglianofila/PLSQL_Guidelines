prompt File: lib_text.pks.sql <start>
-- =============================================================================
-- File:     lib_text.pks.sql
-- Object:   lib_text (package specification)
-- Schema:   #APP#
-- Purpose:  Text helpers - only what Oracle does not offer, or offers awkwardly.
--           The package most at risk of being a bad copy, hence the strictest
--           closed list. Explicitly out of scope: wrappers of upper/trim/lpad,
--           is_number/is_date (validate_conversion exists), trivial replaces.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_text: Creating package specification
create or replace package lib_text is

-- Collection of strings, the return type of split and the input of join.
type t_strings_type is table of varchar2(4000 char);

-- Splits a string into a collection on a separator (the inverse of listagg,
-- which has no native counterpart before APEX). Returns an empty collection
-- for a null input; a single element when the separator is absent.
-- i_text      : string to split.
-- i_separator : separator; defaults to comma.
-- return      : the pieces, in order.
function split(i_text in varchar2, i_separator in varchar2 default ',') return t_strings_type;

-- Joins a collection into a string with a separator, for cases where the
-- data is not already in a query.
-- i_strings   : pieces to join.
-- i_separator : separator; defaults to comma.
-- return      : the joined string.
function join(i_strings in t_strings_type, i_separator in varchar2 default ',') return varchar2;

-- Substitutes the %1..%5 placeholders in a template. The general-purpose
-- primitive behind message templates.
-- i_template : template with %1..%5 placeholders.
-- i_p1..5    : substitution values.
-- return     : the composed string.
function format( i_template in varchar2
               , i_p1       in varchar2 default null
               , i_p2       in varchar2 default null
               , i_p3       in varchar2 default null
               , i_p4       in varchar2 default null
               , i_p5       in varchar2 default null
               ) return varchar2;

-- Normalises text into a mnemonic code: uppercase, accents folded, runs of
-- non-alphanumeric characters collapsed to a single underscore and trimmed.
-- i_text : text to normalise.
-- return : the normalised code.
function normalize_code(i_text in varchar2) return varchar2;

end lib_text;
/
show errors package lib_text

prompt File: lib_text.pks.sql <end>
