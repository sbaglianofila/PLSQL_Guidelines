prompt File: lib_lock.pkb.sql <start>
-- =============================================================================
-- File:     lib_lock.pkb.sql
-- Object:   lib_lock (package body)
-- Schema:   #APP#
-- Purpose:  Exclusive application locks on top of sys.dbms_lock.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_lock: Creating package body
create or replace package body lib_lock is

k_SCOPE  constant lib_types.scope_sbt := 'lib_lock';

function request_lock( i_lock_name         in lib_types.lock_name_sbt
                     , i_timeout_seconds   in number  default lib_constants.k_DEFAULT_LOCK_WAIT
                     , i_release_on_commit in boolean default false
                     ) return lib_types.lock_handle_sbt
is
   k_LOCK_NAME     constant lib_types.lock_name_sbt := i_lock_name;
   l_lock_handle            lib_types.lock_handle_sbt;
   l_result                 pls_integer;
begin
   sys.dbms_lock.allocate_unique( lockname        => k_LOCK_NAME
                                , lockhandle      => l_lock_handle
                                , expiration_secs => lib_constants.k_ONE_WEEK
                                );

   l_result := sys.dbms_lock.request( lockhandle        => l_lock_handle
                                    , lockmode          => sys.dbms_lock.x_mode
                                    , timeout           => i_timeout_seconds
                                    , release_on_commit => i_release_on_commit
                                    );

   -- request returns 0 on success; any positive value is a failure
   -- (1 timeout, 2 deadlock, 3 parameter error, 4 already held, 5 illegal).
   if ( l_result > 0 )
   then
      lib_err.raise(i_error => lib_err.k_LOCK_REQUEST_FAILED, i_p1 => i_lock_name, i_scope => k_SCOPE);
   end if;

   return (l_lock_handle);
end request_lock;

procedure release_lock(i_lock_handle in lib_types.lock_handle_sbt) is
   k_LOCK_HANDLE  constant lib_types.lock_handle_sbt := i_lock_handle;
   l_result                pls_integer;
begin
   l_result := sys.dbms_lock.release(lockhandle => k_LOCK_HANDLE);

   if ( l_result > 0 )
   then
      lib_err.raise(i_error => lib_err.k_LOCK_REQUEST_FAILED, i_p1 => i_lock_handle, i_scope => k_SCOPE);
   end if;
end release_lock;

end lib_lock;
/
show errors package body lib_lock

prompt File: lib_lock.pkb.sql <end>
