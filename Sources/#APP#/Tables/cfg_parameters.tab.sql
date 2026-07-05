prompt File: cfg_parameters.tab.sql <start>
-- =============================================================================
-- File:     cfg_parameters.tab.sql
-- Object:   cfg_parameters (table)
-- Schema:   #APP#
-- Purpose:  Single home for application parameters read through lib_config.
--           Each row declares a typed value; lib_config performs the controlled
--           conversion (explicit formats) and caches the values. The only
--           supported write path is lib_config.set_value.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt cfg_parameters: Creating table
create table cfg_parameters
   ( param_name    varchar2(128 char)  constraint cfg_parameters_pk primary key
   , param_value   varchar2(4000 char)
   , param_type    varchar2(32 char)   default 'STRING'
                                        constraint cfg_parameters_nn_param_type not null
   , description   varchar2(512 char)
   , is_modifiable varchar2(1 char)    default 'Y'
                                        constraint cfg_parameters_nn_modifiable not null
   , updated_at    timestamp(6)
   , updated_by    varchar2(128 char)
   , constraint cfg_parameters_ck_param_type check (param_type in ('STRING', 'NUMBER', 'DATE', 'FLAG'))
   , constraint cfg_parameters_ck_modifiable check (is_modifiable in ('Y', 'N'))
   );

prompt cfg_parameters: Adding comments
comment on table  cfg_parameters               is 'Application parameters read through lib_config; typed values with controlled conversion and caching.';
comment on column cfg_parameters.param_name    is 'Parameter name (natural key).';
comment on column cfg_parameters.param_value   is 'Parameter value stored as text; converted by lib_config according to param_type.';
comment on column cfg_parameters.param_type    is 'Declared type driving conversion: STRING, NUMBER, DATE or FLAG.';
comment on column cfg_parameters.description    is 'Human-readable description of the parameter and its effect.';
comment on column cfg_parameters.is_modifiable is 'Y if the value may be changed through lib_config.set_value, N if provisioning-only.';
comment on column cfg_parameters.updated_at    is 'Instant of the last change made through lib_config.set_value.';
comment on column cfg_parameters.updated_by    is 'Effective actor that performed the last change.';

prompt File: cfg_parameters.tab.sql <end>
