prompt File: lib_file.pks.sql <start>
-- =============================================================================
-- File:     lib_file.pks.sql
-- Object:   lib_file (package specification)
-- Schema:   #APP#
-- Purpose:  File I/O on top of sys.utl_file, only where utl_file is awkward or
--           risky to use raw: whole-file read/write to and from CLOB, speaking
--           errors, filename validation (no path traversal). Directories are
--           the Oracle DIRECTORY object names; callers resolve them from
--           configuration (lib_config) rather than hardcoding.
--           Prerequisites: grant execute on sys.utl_file, and DIRECTORY objects
--           with read/write granted to the owner.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_file: Creating package specification
create or replace package lib_file is

   -- Reads a whole text file into a CLOB. Raises lib_err.e_file_not_found when
   -- the file is missing, lib_err.e_file_io_error on other I/O failures. The
   -- returned temporary CLOB is the caller's to free.
   -- i_directory : Oracle DIRECTORY object name.
   -- i_filename  : file name (no path separators).
   -- return      : file content as a CLOB.
   function read_clob(i_directory in varchar2, i_filename in varchar2) return clob;

   -- Writes a CLOB to a text file, overwriting it. Raises lib_err.e_file_io_error
   -- on failure; the file handle is closed even on error.
   -- i_directory : Oracle DIRECTORY object name.
   -- i_filename  : file name (no path separators).
   -- i_content   : content to write.
   procedure write_clob(i_directory in varchar2, i_filename in varchar2, i_content in clob);

   -- True when the file exists in the directory.
   -- i_directory : Oracle DIRECTORY object name.
   -- i_filename  : file name (no path separators).
   -- return      : true when the file exists.
   function file_exists(i_directory in varchar2, i_filename in varchar2) return boolean;

   -- Deletes a file. Raises lib_err.e_file_io_error on failure.
   -- i_directory : Oracle DIRECTORY object name.
   -- i_filename  : file name (no path separators).
   procedure remove_file(i_directory in varchar2, i_filename in varchar2);

   -- Renames/moves a file. Raises lib_err.e_file_io_error on failure.
   -- i_src_directory : source DIRECTORY object name.
   -- i_src_filename  : source file name.
   -- i_dst_directory : destination DIRECTORY object name.
   -- i_dst_filename  : destination file name.
   -- i_overwrite     : true to overwrite an existing destination.
   procedure rename_file( i_src_directory in varchar2
                        , i_src_filename  in varchar2
                        , i_dst_directory in varchar2
                        , i_dst_filename  in varchar2
                        , i_overwrite     in boolean default false
                        );

end lib_file;
/
show errors package lib_file

prompt File: lib_file.pks.sql <end>
