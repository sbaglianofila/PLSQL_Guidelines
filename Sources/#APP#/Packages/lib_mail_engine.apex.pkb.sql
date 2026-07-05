prompt File: lib_mail_engine.apex.pkb.sql <start>
-- =============================================================================
-- File:     lib_mail_engine.apex.pkb.sql
-- Object:   lib_mail_engine (package body - APEX_MAIL backend)
-- Schema:   #APP#
-- Purpose:  APEX_MAIL implementation of lib_mail_engine. Install THIS body OR
--           lib_mail_engine.utl_smtp.pkb.sql, never both. Uses the APEX mail
--           stack (SMTP settings configured in APEX Instance Administration).
--           Prerequisites: APEX installed, apex_mail executable by the owner,
--           and - to run outside an APEX session (e.g. a batch job) - a
--           workspace context, taken from the optional configuration parameter
--           MAIL_APEX_WORKSPACE.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_mail_engine (APEX_MAIL): Creating package body
create or replace package body lib_mail_engine is

k_SCOPE           constant lib_types.scope_sbt := 'lib_mail_engine';
k_BACKEND         constant varchar2(9 char)    := 'APEX_MAIL';
k_PARAM_WORKSPACE constant lib_types.name_sbt  := 'MAIL_APEX_WORKSPACE';
k_HTML_FALLBACK   constant varchar2(80 char)   := 'This message requires an HTML-capable email client.';

function backend return varchar2 is
begin
   return (k_BACKEND);
end backend;

-- Establishes the APEX workspace context when MAIL_APEX_WORKSPACE is configured,
-- so apex_mail can run outside an APEX session.
procedure ensure_context is
   k_WORKSPACE  constant varchar2(256 char) := lib_config.get_string(k_PARAM_WORKSPACE, i_default => null);
begin
   if ( k_WORKSPACE is not null )
   then
      apex_util.set_workspace(p_workspace => k_WORKSPACE);
   end if;
end ensure_context;

procedure deliver( i_from    in varchar2
                 , i_to      in varchar2
                 , i_cc      in varchar2
                 , i_bcc     in varchar2
                 , i_subject in varchar2
                 , i_body    in clob
                 , i_is_html in boolean
                 )
is
   l_mail_id  number;
begin
   ensure_context;

   if ( i_is_html )
   then
      l_mail_id := apex_mail.send( p_to        => i_to
                                 , p_from      => i_from
                                 , p_body      => to_clob(k_HTML_FALLBACK)
                                 , p_body_html => i_body
                                 , p_subj      => i_subject
                                 , p_cc        => i_cc
                                 , p_bcc       => i_bcc
                                 );
   else
      l_mail_id := apex_mail.send( p_to    => i_to
                                 , p_from  => i_from
                                 , p_body  => i_body
                                 , p_subj  => i_subject
                                 , p_cc    => i_cc
                                 , p_bcc   => i_bcc
                                 );
   end if;

   -- Force immediate delivery; lib_mail already provides the queue on top.
   apex_mail.push_queue;
exception
   when others
   then
      lib_err.raise(i_error => lib_err.k_MAIL_SEND_FAILED, i_p1 => sqlerrm, i_scope => k_SCOPE);
end deliver;

end lib_mail_engine;
/
show errors package body lib_mail_engine

prompt File: lib_mail_engine.apex.pkb.sql <end>
