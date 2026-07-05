prompt File: lib_err.pks.sql <start>
-- =============================================================================
-- File:     lib_err.pks.sql
-- Object:   lib_err (package specification)
-- Schema:   #APP#
-- Purpose:  Error catalog and engine. The specification is the catalog: one
--           constant per application error (codes assigned by bands in the
--           reserved -20000..-20999 range) and the named exceptions bound to
--           them via pragma exception_init, so callers can trap by name. The
--           body is the engine (raise / reraise / message_of).
--           Band assignment:
--             -20000 .. -20099  infrastructure (this package / base packages)
--             -20100 .. -20199  first functional domain
--             ...               one band per domain, guaranteeing uniqueness
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_err: Creating package specification
create or replace package lib_err is

-- --- Error codes (the catalog) --------------------------------------------
k_INVALID_PARAMETER      constant pls_integer := -20000;
k_STALE_DATA             constant pls_integer := -20001;
k_LOCK_REQUEST_FAILED    constant pls_integer := -20002;
k_ALREADY_RUNNING        constant pls_integer := -20003;
k_CONFIG_PARAM_MISSING   constant pls_integer := -20004;
k_CONFIG_PARAM_INVALID   constant pls_integer := -20005;
k_INVALID_TABLE_NAME     constant pls_integer := -20006;
k_PARAM_TOO_LARGE        constant pls_integer := -20007;
k_INVALID_FILENAME       constant pls_integer := -20008;
k_FILE_NOT_FOUND         constant pls_integer := -20009;
k_MAIL_SEND_FAILED       constant pls_integer := -20010;
k_MAIL_TEMPLATE_MISSING  constant pls_integer := -20011;
k_FILE_IO_ERROR          constant pls_integer := -20012;
k_REPORT_NOT_FOUND       constant pls_integer := -20013;
k_UNEXPECTED             constant pls_integer := -20099;

-- --- Named exceptions -----------------------------------------------------
-- The literals in the pragmas must match the constants above; keep them in
-- sync (Oracle requires a numeric literal in pragma exception_init).
e_invalid_parameter      exception;
e_stale_data             exception;
e_lock_request_failed    exception;
e_already_running        exception;
e_config_param_missing   exception;
e_config_param_invalid   exception;
e_param_too_large        exception;
e_invalid_filename       exception;
e_file_not_found         exception;
e_mail_send_failed       exception;
e_mail_template_missing  exception;
e_file_io_error          exception;
e_report_not_found       exception;

pragma exception_init(e_invalid_parameter,     -20000);
pragma exception_init(e_stale_data,            -20001);
pragma exception_init(e_lock_request_failed,   -20002);
pragma exception_init(e_already_running,       -20003);
pragma exception_init(e_config_param_missing,  -20004);
pragma exception_init(e_config_param_invalid,  -20005);
pragma exception_init(e_param_too_large,       -20007);
pragma exception_init(e_invalid_filename,      -20008);
pragma exception_init(e_file_not_found,        -20009);
pragma exception_init(e_mail_send_failed,      -20010);
pragma exception_init(e_mail_template_missing, -20011);
pragma exception_init(e_file_io_error,         -20012);
pragma exception_init(e_report_not_found,      -20013);

-- Raises a catalog error, substituting the %1..%3 placeholders in its
-- message and logging it (with the real code and backtrace) before
-- signalling. This is the only place in the project that calls
-- raise_application_error.
-- i_error : one of the k_ codes above.
-- i_p1..3 : values substituted for %1..%3 in the message.
-- i_scope : logical scope for the log entry.
procedure raise( i_error in pls_integer
               , i_p1    in varchar2 default null
               , i_p2    in varchar2 default null
               , i_p3    in varchar2 default null
               , i_scope in lib_types.scope_sbt default null
               );

-- Re-raises the exception currently being handled after logging it. Must be
-- called from within an exception handler. Catalog errors are preserved
-- verbatim; any other Oracle error is wrapped as k_UNEXPECTED while keeping
-- the original error on the stack.
-- i_scope : logical scope for the log entry.
procedure reraise(i_scope in lib_types.scope_sbt default null);

-- Returns the composed message of a catalog error without raising it, for
-- callers that must display it.
-- i_error : one of the k_ codes above.
-- i_p1..3 : values substituted for %1..%3.
-- return  : the composed message.
function message_of( i_error in pls_integer
                   , i_p1    in varchar2 default null
                   , i_p2    in varchar2 default null
                   , i_p3    in varchar2 default null
                   ) return varchar2;

end lib_err;
/
show errors package lib_err

prompt File: lib_err.pks.sql <end>
