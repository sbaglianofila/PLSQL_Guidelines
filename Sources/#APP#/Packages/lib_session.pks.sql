prompt File: lib_session.pks.sql <start>
-- =============================================================================
-- File:     lib_session.pks.sql
-- Object:   lib_session (package specification)
-- Schema:   #APP#
-- Purpose:  Session identity, context and instrumentation. Answers "who is
--           operating" and "what is the session doing", and centralises the use
--           of dbms_session / dbms_application_info. It is the project
--           complement to sys_context, not a wrapper of it: the value is in
--           fixing which identity counts under proxy and technical accounts.
--           Application-context support (create context #APP#_ctx) is an
--           optional second step that requires CREATE ANY CONTEXT.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_session: Creating package specification
create or replace package lib_session is

-- Effective identity per the project convention: the client_identifier set
-- by the front end for the end user, else the proxy_user when connected
-- through a proxy, else the session_user. This is the value that will
-- populate created_by / updated_by.
-- return : the effective actor, never null.
function current_actor return varchar2;

-- Current dbms_application_info module of the session (null if unset).
-- Used by lib_logging and lib_batch to tag entries with the running process.
-- return : the current module name.
function current_module return varchar2;

-- Current dbms_application_info action of the session (null if unset).
-- return : the current action name.
function current_action return varchar2;

-- Declares the end business user the connection is serving. Sets the session
-- client_identifier (and optional client_info) so current_actor can resolve
-- the real user behind a shared application account.
-- i_identifier : end-user identifier to publish on the session.
-- i_info       : optional free-text client information.
procedure set_client(i_identifier in varchar2, i_info in varchar2 default null);

-- Instruments the session via dbms_application_info with safe truncation to
-- the Oracle limits (module 48 / action 32 bytes). Turns the chapter-11
-- progress-tracking pattern into a single call.
-- i_module : logical module / process name.
-- i_action : current step within the module.
procedure set_step(i_module in varchar2, i_action in varchar2 default null);

end lib_session;
/
show errors package lib_session

prompt File: lib_session.pks.sql <end>
