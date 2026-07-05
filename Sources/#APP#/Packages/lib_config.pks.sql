prompt File: lib_config.pks.sql <start>
-- =============================================================================
-- File:     lib_config.pks.sql
-- Object:   lib_config (package specification)
-- Schema:   #APP#
-- Purpose:  Disciplined access to cfg_parameters: typed getters, explicit
--           defaults, cache. Avoids the two classic drifts - parameters read
--           with selects scattered through the code, and values "temporarily"
--           hardcoded. Also exposes the environment identity used as a guard by
--           lib_mail, jobs and tooling.
--           Convention: when a parameter is absent, i_default is returned; a
--           null i_default marks the parameter as mandatory, so its absence
--           raises lib_err.e_config_param_missing.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_config: Creating package specification
create or replace package lib_config is

-- Returns a string parameter (see the mandatory/default convention above).
-- i_name    : parameter name.
-- i_default : value returned when the parameter is absent.
function get_string(i_name in varchar2, i_default in varchar2 default null) return varchar2;

-- Returns a numeric parameter, converted from its stored text. Raises
-- lib_err.e_config_param_invalid if the stored value is not a number.
function get_number(i_name in varchar2, i_default in number default null) return number;

-- Returns a date parameter, converted with lib_constants.k_DATE_FMT. Raises
-- lib_err.e_config_param_invalid if the stored value is not a valid date.
function get_date(i_name in varchar2, i_default in date default null) return date;

-- Returns a flag parameter ('Y'/'N'). Raises lib_err.e_config_param_invalid
-- if the stored value is neither.
function get_flag(i_name in varchar2, i_default in varchar2 default null) return varchar2;

-- The only write path. Updates a modifiable parameter, records the change in
-- the log (who, when) and invalidates the cache. Does not commit: the caller
-- controls the transaction.
-- i_name  : parameter to update.
-- i_value : new text value.
procedure set_value(i_name in varchar2, i_value in varchar2);

-- Environment identity (DEV / TEST / PROD), from the ENVIRONMENT parameter
-- set at provisioning; defaults to DEV when unset.
-- return : the environment code.
function environment return varchar2;

-- True only in production. The guard used by lib_mail, jobs and tooling to
-- behave differently outside production.
-- return : true when environment = 'PROD'.
function is_production return boolean;

-- Clears the cache so the next read reloads from cfg_parameters.
procedure refresh;

end lib_config;
/
show errors package lib_config

prompt File: lib_config.pks.sql <end>
