prompt File: lib_err.pkb.sql <start>
-- =============================================================================
-- File:     lib_err.pkb.sql
-- Object:   lib_err (package body)
-- Schema:   #APP#
-- Purpose:  The error engine: composes catalog messages, logs and signals.
--           Placeholder substitution is done in-package (no dependency on
--           lib_text) so the foundations stay self-contained.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_err: Creating package body
create or replace package body lib_err is

k_SCOPE  constant lib_types.scope_sbt := 'lib_err';

-- Returns the message template for a catalog code.
-- i_error : catalog code.
-- return  : template with %1..%3 placeholders.
function template_of(i_error in pls_integer) return varchar2 is
begin
   return ( case i_error
               when k_INVALID_PARAMETER    then 'Invalid parameter %1: %2'
               when k_STALE_DATA           then 'Data was modified by another session; please retry.'
               when k_LOCK_REQUEST_FAILED  then 'Could not acquire application lock %1.'
               when k_ALREADY_RUNNING      then 'Process %1 is already running.'
               when k_CONFIG_PARAM_MISSING then 'Configuration parameter %1 not found.'
               when k_CONFIG_PARAM_INVALID then 'Configuration parameter %1 is not a valid %2: %3'
               when k_INVALID_TABLE_NAME   then 'Invalid table name: %1'
               when k_PARAM_TOO_LARGE      then 'Parameter %1 exceeds the maximum allowed size.'
               when k_INVALID_FILENAME     then 'Invalid file name: %1'
               when k_FILE_NOT_FOUND       then 'File %1 not found in directory %2.'
               when k_MAIL_SEND_FAILED     then 'Mail send failed: %1'
               when k_MAIL_TEMPLATE_MISSING then 'Email template %1 not found.'
               when k_FILE_IO_ERROR        then 'File I/O error on %1/%2: %3'
               when k_REPORT_NOT_FOUND     then 'Report %1 not found.'
               when k_UNEXPECTED           then 'Unexpected error: %1'
               else 'Application error %1'
            end
          );
end template_of;

-- Substitutes %1..%3 in a template with the supplied values.
-- i_template : message template.
-- i_p1..3    : substitution values.
-- return     : the composed message.
function format_message( i_template in varchar2
                       , i_p1       in varchar2
                       , i_p2       in varchar2
                       , i_p3       in varchar2
                       ) return varchar2
is
   l_message  varchar2(4000 char) := i_template;
begin
   l_message := replace(l_message, '%1', i_p1);
   l_message := replace(l_message, '%2', i_p2);
   l_message := replace(l_message, '%3', i_p3);

   return (l_message);
end format_message;

function message_of( i_error in pls_integer
                   , i_p1    in varchar2 default null
                   , i_p2    in varchar2 default null
                   , i_p3    in varchar2 default null
                   ) return varchar2
is
   k_TEMPLATE  constant varchar2(4000 char) := template_of(i_error);
begin
   return ( format_message( i_template => k_TEMPLATE
                          , i_p1       => i_p1
                          , i_p2       => i_p2
                          , i_p3       => i_p3
                          )
          );
end message_of;

procedure raise( i_error in pls_integer
               , i_p1    in varchar2 default null
               , i_p2    in varchar2 default null
               , i_p3    in varchar2 default null
               , i_scope in lib_types.scope_sbt default null
               )
is
   k_MESSAGE  constant varchar2(4000 char) := message_of( i_error => i_error
                                                        , i_p1    => i_p1
                                                        , i_p2    => i_p2
                                                        , i_p3    => i_p3
                                                        );
begin
   -- Signal inside a sub-block so the error is logged with its real code and
   -- backtrace, then re-raised preserving the stack.
   raise_application_error(i_error, k_MESSAGE, true);
exception
   when others
   then
      lib_logging.log_error(i_text => k_MESSAGE, i_scope => coalesce(i_scope, k_SCOPE));
      raise;
end raise;

procedure reraise(i_scope in lib_types.scope_sbt default null) is
   k_CODE  constant pls_integer := sqlcode;
   k_MSG   constant varchar2(4000 char) := sqlerrm;
begin
   lib_logging.log_error(i_text => k_MSG, i_scope => coalesce(i_scope, k_SCOPE));

   if ( k_CODE between -20999 and -20000 )
   then
      -- Preserve our own application errors verbatim (strip the ORA- prefix
      -- that sqlerrm adds, since raise_application_error re-adds it).
      raise_application_error(k_CODE, regexp_replace(k_MSG, '^ORA-[0-9]{5}: ', ''), true);
   else
      -- Wrap an unexpected Oracle error, keeping the original on the stack.
      raise_application_error(k_UNEXPECTED, k_MSG, true);
   end if;
end reraise;

end lib_err;
/
show errors package body lib_err

prompt File: lib_err.pkb.sql <end>
