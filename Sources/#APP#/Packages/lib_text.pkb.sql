prompt File: lib_text.pkb.sql <start>
-- =============================================================================
-- File:     lib_text.pkb.sql
-- Object:   lib_text (package body)
-- Schema:   #APP#
-- Purpose:  Implementation of the closed set of text helpers.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_text: Creating package body
create or replace package body lib_text is

-- Accented characters folded to their plain ASCII counterpart (from/to must
-- be the same length for translate).
k_ACCENTED  constant varchar2(64 char) := 'ÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇÑàáâãäåèéêëìíîïòóôõöùúûüçñ';
k_PLAIN     constant varchar2(64 char) := 'AAAAAAEEEEIIIIOOOOOUUUUCNAAAAAAEEEEIIIIOOOOOUUUUCN';

function split(i_text in varchar2, i_separator in varchar2 default ',') return t_strings_type is
   l_result  t_strings_type := t_strings_type();
   l_pos     pls_integer := 1;
   l_hit     pls_integer;
   l_seplen  pls_integer := length(i_separator);
begin
   if ( i_text is null )
   then
      return (l_result);
   end if;

   if ( i_separator is null or l_seplen = 0 )
   then
      l_result.extend;
      l_result(l_result.last) := i_text;
      return (l_result);
   end if;

   loop
      l_hit := instr(i_text, i_separator, l_pos);

      l_result.extend;

      if ( l_hit = 0 )
      then
         l_result(l_result.last) := substr(i_text, l_pos);
         exit;
      end if;

      l_result(l_result.last) := substr(i_text, l_pos, l_hit - l_pos);
      l_pos := l_hit + l_seplen;
   end loop;

   return (l_result);
end split;

function join(i_strings in t_strings_type, i_separator in varchar2 default ',') return varchar2 is
   l_result  varchar2(32767 char);
begin
   if ( i_strings is null )
   then
      return (null);
   end if;

   for i in 1 .. i_strings.count
   loop
      if ( i > 1 )
      then
         l_result := l_result || i_separator;
      end if;

      l_result := l_result || i_strings(i);
   end loop;

   return (l_result);
end join;

function format( i_template in varchar2
               , i_p1       in varchar2 default null
               , i_p2       in varchar2 default null
               , i_p3       in varchar2 default null
               , i_p4       in varchar2 default null
               , i_p5       in varchar2 default null
               ) return varchar2
is
   l_result  varchar2(32767 char) := i_template;
begin
   l_result := replace(l_result, '%1', i_p1);
   l_result := replace(l_result, '%2', i_p2);
   l_result := replace(l_result, '%3', i_p3);
   l_result := replace(l_result, '%4', i_p4);
   l_result := replace(l_result, '%5', i_p5);

   return (l_result);
end format;

function normalize_code(i_text in varchar2) return varchar2 is
   l_result  varchar2(4000 char);
begin
   if ( i_text is null )
   then
      return (null);
   end if;

   l_result := upper(translate(i_text, k_ACCENTED, k_PLAIN));
   l_result := regexp_replace(l_result, '[^A-Z0-9]+', '_');
   l_result := trim('_' from l_result);

   return (l_result);
end normalize_code;

end lib_text;
/
show errors package body lib_text

prompt File: lib_text.pkb.sql <end>
