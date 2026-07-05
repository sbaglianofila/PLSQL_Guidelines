prompt File: lib_session.pkb.sql <start>
-- =============================================================================
-- File:     lib_session.pkb.sql
-- Object:   lib_session (package body)
-- Schema:   #APP#
-- Purpose:  Resolves the effective identity and instruments the session on top
--           of sys_context, dbms_session and dbms_application_info.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_session: Creating package body
create or replace package body lib_session is

k_USERENV       constant varchar2(7 char)  := 'USERENV';
k_MODULE_LIMIT  constant pls_integer       := 48;   -- dbms_application_info module max
k_ACTION_LIMIT  constant pls_integer       := 32;   -- dbms_application_info action max

function current_actor return varchar2 is
begin
   -- Most specific identity wins: end user, then proxy account, then schema.
   return ( coalesce( sys_context(k_USERENV, 'CLIENT_IDENTIFIER')
                    , sys_context(k_USERENV, 'PROXY_USER')
                    , sys_context(k_USERENV, 'SESSION_USER')
                    )
          );
end current_actor;

function current_module return varchar2 is
begin
   return (sys_context(k_USERENV, 'MODULE'));
end current_module;

function current_action return varchar2 is
begin
   return (sys_context(k_USERENV, 'ACTION'));
end current_action;

procedure set_client(i_identifier in varchar2, i_info in varchar2 default null) is
begin
   sys.dbms_session.set_identifier(i_identifier);

   if ( i_info is not null )
   then
      sys.dbms_application_info.set_client_info(client_info => i_info);
   end if;
end set_client;

procedure set_step(i_module in varchar2, i_action in varchar2 default null) is
begin
   sys.dbms_application_info.set_module( module_name => substrb(i_module, 1, k_MODULE_LIMIT)
                                       , action_name => substrb(i_action, 1, k_ACTION_LIMIT)
                                       );
end set_step;

end lib_session;
/
show errors package body lib_session

prompt File: lib_session.pkb.sql <end>
