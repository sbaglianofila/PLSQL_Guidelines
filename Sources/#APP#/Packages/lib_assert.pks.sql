prompt File: lib_assert.pks.sql <start>
-- =============================================================================
-- File:     lib_assert.pks.sql
-- Object:   lib_assert (package specification)
-- Schema:   #APP#
-- Purpose:  Argument validation - the application complement to dbms_assert
--           (which validates SQL identifiers, not business arguments). Turns
--           parameter checks at API entry into one readable line instead of a
--           hand-written if/raise. Small by construction: it must not grow to
--           duplicate database constraints - data integrity stays with the
--           constraints; here we validate the arguments of calls.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_assert: Creating package specification
create or replace package lib_assert is

-- Asserts a text argument is not null; raises lib_err.e_invalid_parameter
-- naming the parameter otherwise.
-- i_value      : value to check.
-- i_param_name : parameter name reported in the error.
procedure not_null(i_value in varchar2, i_param_name in varchar2);

-- Asserts a numeric argument is not null.
procedure not_null(i_value in number, i_param_name in varchar2);

-- Asserts a date argument is not null.
procedure not_null(i_value in date, i_param_name in varchar2);

-- Generic assertion: raises the given catalog error when the condition is
-- false or null.
-- i_condition : condition that must hold.
-- i_error     : catalog code to raise on failure.
-- i_message   : optional detail substituted into the error message.
procedure is_true( i_condition in boolean
                 , i_error     in pls_integer default lib_err.k_INVALID_PARAMETER
                 , i_message   in varchar2 default null
                 );

-- Asserts a numeric value lies within [i_min, i_max]; raises
-- lib_err.e_invalid_parameter otherwise.
-- i_value      : value to check.
-- i_min        : inclusive lower bound.
-- i_max        : inclusive upper bound.
-- i_param_name : parameter name reported in the error.
procedure in_range(i_value in number, i_min in number, i_max in number, i_param_name in varchar2);

-- Asserts a text value is no longer than i_max; raises
-- lib_err.e_param_too_large otherwise.
-- i_value      : value to check.
-- i_max        : maximum length in characters.
-- i_param_name : parameter name reported in the error.
procedure max_length(i_value in varchar2, i_max in number, i_param_name in varchar2);

end lib_assert;
/
show errors package lib_assert

prompt File: lib_assert.pks.sql <end>
