prompt File: lib_config.pkb.sql <start>
-- =============================================================================
-- File:     lib_config.pkb.sql
-- Object:   lib_config (package body)
-- Schema:   #APP#
-- Purpose:  Cached, typed access to cfg_parameters with controlled conversion
--           and speaking errors from the lib_err catalog.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_config: Creating package body
create or replace package body lib_config is

k_SCOPE       constant lib_types.scope_sbt := 'lib_config';
k_PARAM_ENV   constant lib_types.name_sbt  := 'ENVIRONMENT';
k_ENV_DEV     constant lib_types.code_sbt  := 'DEV';
k_ENV_PROD    constant lib_types.code_sbt  := 'PROD';
k_TYPE_NUMBER constant lib_types.code_sbt  := 'NUMBER';
k_TYPE_DATE   constant lib_types.code_sbt  := 'DATE';
k_TYPE_FLAG   constant lib_types.code_sbt  := 'FLAG';

-- Cache of raw parameter values, keyed by name.
type t_cache_type is table of cfg_parameters.param_value%type
   index by cfg_parameters.param_name%type;

g_cache   t_cache_type;
g_loaded  boolean := false;

-- Loads all parameters into the cache in one pass.
procedure load_cache is
begin
   g_cache.delete;

   for r_param in ( select cfp.param_name
                         , cfp.param_value
                      from cfg_parameters cfp
                  )
   loop
      g_cache(r_param.param_name) := r_param.param_value;
   end loop;

   g_loaded := true;
end load_cache;

-- Returns the raw text value of a parameter and whether it exists.
-- i_name  : parameter name.
-- o_found : set to true when the parameter exists.
-- return  : the raw stored value (may be null).
function raw_value(i_name in varchar2, o_found out boolean) return varchar2 is
begin
   if ( not g_loaded )
   then
      load_cache;
   end if;

   o_found := g_cache.exists(i_name);

   if ( o_found )
   then
      return (g_cache(i_name));
   else
      return (null);
   end if;
end raw_value;

function get_string(i_name in varchar2, i_default in varchar2 default null) return varchar2 is
   l_found  boolean;
   l_value  cfg_parameters.param_value%type;
begin
   l_value := raw_value(i_name => i_name, o_found => l_found);

   if ( not l_found )
   then
      if ( i_default is not null )
      then
         return (i_default);
      end if;

      lib_err.raise(i_error => lib_err.k_CONFIG_PARAM_MISSING, i_p1 => i_name, i_scope => k_SCOPE);
   end if;

   return (l_value);
end get_string;

function get_number(i_name in varchar2, i_default in number default null) return number is
   l_str  cfg_parameters.param_value%type := get_string(i_name => i_name, i_default => to_char(i_default));
   l_num  number;
begin
   if ( l_str is null )
   then
      return (i_default);
   end if;

   l_num := to_number(l_str default null on conversion error);

   if ( l_num is null )
   then
      lib_err.raise( i_error => lib_err.k_CONFIG_PARAM_INVALID
                   , i_p1    => i_name
                   , i_p2    => k_TYPE_NUMBER
                   , i_p3    => l_str
                   , i_scope => k_SCOPE
                   );
   end if;

   return (l_num);
end get_number;

function get_date(i_name in varchar2, i_default in date default null) return date is
   -- FX is a to_date modifier only; strip it for the to_char of the default.
   l_str   cfg_parameters.param_value%type := get_string( i_name    => i_name
                                                        , i_default => to_char(i_default, replace(lib_constants.k_DATE_FMT, 'FX'))
                                                        );
   l_date  date;
begin
   if ( l_str is null )
   then
      return (i_default);
   end if;

   l_date := to_date(l_str default null on conversion error, lib_constants.k_DATE_FMT);

   if ( l_date is null )
   then
      lib_err.raise( i_error => lib_err.k_CONFIG_PARAM_INVALID
                   , i_p1    => i_name
                   , i_p2    => k_TYPE_DATE
                   , i_p3    => l_str
                   , i_scope => k_SCOPE
                   );
   end if;

   return (l_date);
end get_date;

function get_flag(i_name in varchar2, i_default in varchar2 default null) return varchar2 is
   l_flag  cfg_parameters.param_value%type := get_string(i_name => i_name, i_default => i_default);
begin
   if ( l_flag is not null
        and l_flag not in (lib_constants.k_YES, lib_constants.k_NO) )
   then
      lib_err.raise( i_error => lib_err.k_CONFIG_PARAM_INVALID
                   , i_p1    => i_name
                   , i_p2    => k_TYPE_FLAG
                   , i_p3    => l_flag
                   , i_scope => k_SCOPE
                   );
   end if;

   return (l_flag);
end get_flag;

procedure set_value(i_name in varchar2, i_value in varchar2) is
   l_previous  cfg_parameters.param_value%type;
begin
   -- Capture the previous value of a modifiable parameter; also validates
   -- that the parameter exists and may be changed.
   begin
      select cfp.param_value
        into l_previous
        from cfg_parameters cfp
       where cfp.param_name    = i_name
         and cfp.is_modifiable = lib_constants.k_YES
         for update of cfp.param_value;
   exception
      when no_data_found
      then
         lib_err.raise(i_error => lib_err.k_CONFIG_PARAM_MISSING, i_p1 => i_name, i_scope => k_SCOPE);
   end;

   update cfg_parameters cfp
      set cfp.param_value = i_value
        , cfp.updated_at  = systimestamp
        , cfp.updated_by  = lib_session.current_actor
    where cfp.param_name  = i_name;

   lib_logging.log_info( i_text  =>    'Parameter ' || i_name
                                    || ' changed from [' || l_previous || '] to [' || i_value || ']'
                       , i_scope => k_SCOPE
                       );

   -- The stored value changed: force a reload on the next read.
   g_loaded := false;
end set_value;

function environment return varchar2 is
begin
   return (get_string(i_name => k_PARAM_ENV, i_default => k_ENV_DEV));
end environment;

function is_production return boolean is
begin
   return (environment = k_ENV_PROD);
end is_production;

procedure refresh is
begin
   g_loaded := false;
end refresh;

end lib_config;
/
show errors package body lib_config

prompt File: lib_config.pkb.sql <end>
