prompt File: lib_file.pkb.sql <start>
-- =============================================================================
-- File:     lib_file.pkb.sql
-- Object:   lib_file (package body)
-- Schema:   #APP#
-- Purpose:  Whole-file CLOB I/O over sys.utl_file, with filename validation,
--           guaranteed handle close and mapping of utl_file errors onto the
--           lib_err catalog.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_file: Creating package body
create or replace package body lib_file is

k_SCOPE      constant lib_types.scope_sbt := 'lib_file';
k_MAX_LINE   constant pls_integer := 32767;

-- Rejects null or path-bearing file names, to prevent path traversal.
-- i_filename : file name to validate.
procedure validate_filename(i_filename in varchar2) is
begin
   if (    i_filename is null
        or instr(i_filename, '/')  > 0
        or instr(i_filename, '\')  > 0
        or instr(i_filename, '..') > 0
      )
   then
      lib_err.raise(i_error => lib_err.k_INVALID_FILENAME, i_p1 => i_filename, i_scope => k_SCOPE);
   end if;
end validate_filename;

-- Maps the utl_file error currently on the stack onto a catalog error and
-- raises it. Must be called from an exception handler.
-- i_directory : directory involved.
-- i_filename  : file involved.
procedure raise_file_error(i_directory in varchar2, i_filename in varchar2) is
begin
   -- ORA-29280 invalid path, ORA-29283 invalid file operation (e.g. missing
   -- file on read), ORA-29289 access denied: treat as "not found / no access".
   if ( sqlcode in (-29280, -29283, -29289) )
   then
      lib_err.raise(i_error => lib_err.k_FILE_NOT_FOUND, i_p1 => i_filename, i_p2 => i_directory, i_scope => k_SCOPE);
   else
      lib_err.raise( i_error => lib_err.k_FILE_IO_ERROR
                   , i_p1    => i_directory
                   , i_p2    => i_filename
                   , i_p3    => sqlerrm
                   , i_scope => k_SCOPE
                   );
   end if;
end raise_file_error;

function read_clob(i_directory in varchar2, i_filename in varchar2) return clob is
   l_file    sys.utl_file.file_type;
   l_line    varchar2(32767 char);
   l_result  clob;
begin
   validate_filename(i_filename);
   sys.dbms_lob.createtemporary(lob_loc => l_result, cache => true);

   -- Inner block so a validation error is not remapped by the I/O handler.
   begin
      l_file := sys.utl_file.fopen(i_directory, i_filename, 'r', k_MAX_LINE);

      loop
         begin
            sys.utl_file.get_line(l_file, l_line);
         exception
            when no_data_found
            then
               exit;
         end;

         sys.dbms_lob.append(l_result, l_line || chr(10));
      end loop;

      sys.utl_file.fclose(l_file);
   exception
      when others
      then
         if ( sys.utl_file.is_open(l_file) )
         then
            sys.utl_file.fclose(l_file);
         end if;

         raise_file_error(i_directory => i_directory, i_filename => i_filename);
   end;

   return (l_result);
end read_clob;

procedure write_clob(i_directory in varchar2, i_filename in varchar2, i_content in clob) is
   l_file    sys.utl_file.file_type;
   k_LEN     constant pls_integer := sys.dbms_lob.getlength(i_content);
   l_offset           pls_integer := 1;
begin
   validate_filename(i_filename);

   -- Inner block so a validation error is not remapped by the I/O handler.
   begin
      l_file := sys.utl_file.fopen(i_directory, i_filename, 'w', k_MAX_LINE);

      while ( l_offset <= k_LEN )
      loop
         sys.utl_file.put(l_file, sys.dbms_lob.substr(i_content, k_MAX_LINE, l_offset));
         l_offset := l_offset + k_MAX_LINE;
      end loop;

      sys.utl_file.fflush(l_file);
      sys.utl_file.fclose(l_file);
   exception
      when others
      then
         if ( sys.utl_file.is_open(l_file) )
         then
            sys.utl_file.fclose(l_file);
         end if;

         raise_file_error(i_directory => i_directory, i_filename => i_filename);
   end;
end write_clob;

function file_exists(i_directory in varchar2, i_filename in varchar2) return boolean is
   l_exists     boolean;
   l_length     number;
   l_blocksize  number;
begin
   validate_filename(i_filename);
   sys.utl_file.fgetattr(i_directory, i_filename, l_exists, l_length, l_blocksize);

   return (l_exists);
end file_exists;

procedure remove_file(i_directory in varchar2, i_filename in varchar2) is
begin
   validate_filename(i_filename);

   begin
      sys.utl_file.fremove(i_directory, i_filename);
   exception
      when others
      then
         raise_file_error(i_directory => i_directory, i_filename => i_filename);
   end;
end remove_file;

procedure rename_file( i_src_directory in varchar2
                     , i_src_filename  in varchar2
                     , i_dst_directory in varchar2
                     , i_dst_filename  in varchar2
                     , i_overwrite     in boolean default false
                     )
is
begin
   validate_filename(i_src_filename);
   validate_filename(i_dst_filename);

   begin
      sys.utl_file.frename( src_location  => i_src_directory
                          , src_filename  => i_src_filename
                          , dest_location => i_dst_directory
                          , dest_filename => i_dst_filename
                          , overwrite     => i_overwrite
                          );
   exception
      when others
      then
         raise_file_error(i_directory => i_src_directory, i_filename => i_src_filename);
   end;
end rename_file;

end lib_file;
/
show errors package body lib_file

prompt File: lib_file.pkb.sql <end>
