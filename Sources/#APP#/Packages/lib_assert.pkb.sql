prompt File: lib_assert.pkb.sql <start>
-- =============================================================================
-- File:     lib_assert.pkb.sql
-- Object:   lib_assert (package body)
-- Schema:   #APP#
-- Purpose:  Argument assertions on top of the lib_err catalog.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_assert: Creating package body
create or replace package body lib_assert is

k_SCOPE      constant lib_types.scope_sbt := 'lib_assert';
k_NULL_MSG   constant lib_types.name_sbt  := 'must not be null';

procedure not_null(i_value in varchar2, i_param_name in varchar2) is
begin
   if ( i_value is null )
   then
      lib_err.raise(i_error => lib_err.k_INVALID_PARAMETER, i_p1 => i_param_name, i_p2 => k_NULL_MSG, i_scope => k_SCOPE);
   end if;
end not_null;

procedure not_null(i_value in number, i_param_name in varchar2) is
begin
   if ( i_value is null )
   then
      lib_err.raise(i_error => lib_err.k_INVALID_PARAMETER, i_p1 => i_param_name, i_p2 => k_NULL_MSG, i_scope => k_SCOPE);
   end if;
end not_null;

procedure not_null(i_value in date, i_param_name in varchar2) is
begin
   if ( i_value is null )
   then
      lib_err.raise(i_error => lib_err.k_INVALID_PARAMETER, i_p1 => i_param_name, i_p2 => k_NULL_MSG, i_scope => k_SCOPE);
   end if;
end not_null;

procedure is_true( i_condition in boolean
                 , i_error     in pls_integer default lib_err.k_INVALID_PARAMETER
                 , i_message   in varchar2 default null
                 )
is
begin
   -- A null condition is treated as a failed assertion.
   if ( not nvl(i_condition, false) )
   then
      lib_err.raise(i_error => i_error, i_p1 => i_message, i_scope => k_SCOPE);
   end if;
end is_true;

procedure in_range(i_value in number, i_min in number, i_max in number, i_param_name in varchar2) is
begin
   if (    i_value is null
        or i_value < i_min
        or i_value > i_max
      )
   then
      lib_err.raise( i_error => lib_err.k_INVALID_PARAMETER
                   , i_p1    => i_param_name
                   , i_p2    => 'out of range [' || i_min || '..' || i_max || ']'
                   , i_scope => k_SCOPE
                   );
   end if;
end in_range;

procedure max_length(i_value in varchar2, i_max in number, i_param_name in varchar2) is
begin
   if ( length(i_value) > i_max )
   then
      lib_err.raise(i_error => lib_err.k_PARAM_TOO_LARGE, i_p1 => i_param_name, i_scope => k_SCOPE);
   end if;
end max_length;

end lib_assert;
/
show errors package body lib_assert

prompt File: lib_assert.pkb.sql <end>
