prompt File: lib_lock.pks.sql <start>
-- =============================================================================
-- File:     lib_lock.pks.sql
-- Object:   lib_lock (package specification)
-- Schema:   #APP#
-- Purpose:  Application locks. Serialises processes that must not run in
--           parallel, leaning on sys.dbms_lock so Oracle guarantees release
--           even if the session crashes. Signatures follow the chapter-11
--           pattern (request_lock / release_lock), extended with an explicit
--           request timeout.
--           Prerequisite: grant execute on sys.dbms_lock (see
--           template_system_grant.grt.sql).
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_lock: Creating package specification
create or replace package lib_lock is

-- Acquires the named exclusive lock and returns its handle. Raises
-- lib_err.e_lock_request_failed if the lock cannot be obtained within
-- i_timeout_seconds. The lock name is resolved to a stable handle with
-- allocate_unique, so callers only ever deal with the logical name.
-- i_lock_name         : logical lock name.
-- i_timeout_seconds   : seconds to wait before giving up.
-- i_release_on_commit : true to release the lock on the next commit;
--                       false (default) to hold it until explicit release
--                       or session end.
-- return              : the lock handle to pass to release_lock.
function request_lock( i_lock_name         in lib_types.lock_name_sbt
                     , i_timeout_seconds   in number  default lib_constants.k_DEFAULT_LOCK_WAIT
                     , i_release_on_commit in boolean default false
                     ) return lib_types.lock_handle_sbt;

-- Releases a lock previously acquired with request_lock.
-- i_lock_handle : handle returned by request_lock.
procedure release_lock(i_lock_handle in lib_types.lock_handle_sbt);

end lib_lock;
/
show errors package lib_lock

prompt File: lib_lock.pks.sql <end>
