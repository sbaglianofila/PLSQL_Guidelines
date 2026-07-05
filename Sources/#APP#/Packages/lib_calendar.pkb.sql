prompt File: lib_calendar.pkb.sql <start>
-- =============================================================================
-- File:     lib_calendar.pkb.sql
-- Object:   lib_calendar (package body)
-- Schema:   #APP#
-- Purpose:  Working-day arithmetic over the weekend rule and ref_holidays.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_calendar: Creating package body
create or replace package body lib_calendar is

-- Day-of-week index relative to the ISO week (0=Mon .. 6=Sun), independent
-- of NLS settings. Saturday and Sunday are indices 5 and 6.
k_FIRST_WEEKEND_DOW  constant pls_integer := 5;

function is_working_day(i_date in date, i_calendar in varchar2 default 'DEFAULT') return boolean is
   k_DAY   constant date := trunc(i_date);
   l_dow            pls_integer := k_DAY - trunc(k_DAY, 'IW');
   l_holidays       pls_integer;
begin
   if ( l_dow >= k_FIRST_WEEKEND_DOW )
   then
      return (false);
   end if;

   select count(*)
     into l_holidays
     from ref_holidays rfh
    where rfh.calendar_code = i_calendar
      and rfh.holiday_date  = k_DAY;

   return (l_holidays = 0);
end is_working_day;

function next_working_day(i_date in date, i_calendar in varchar2 default 'DEFAULT') return date is
   l_day  date := trunc(i_date) + 1;
begin
   while ( not is_working_day(i_date => l_day, i_calendar => i_calendar) )
   loop
      l_day := l_day + 1;
   end loop;

   return (l_day);
end next_working_day;

function previous_working_day(i_date in date, i_calendar in varchar2 default 'DEFAULT') return date is
   l_day  date := trunc(i_date) - 1;
begin
   while ( not is_working_day(i_date => l_day, i_calendar => i_calendar) )
   loop
      l_day := l_day - 1;
   end loop;

   return (l_day);
end previous_working_day;

function add_working_days(i_date in date, i_days in number, i_calendar in varchar2 default 'DEFAULT') return date is
   l_day        date := trunc(i_date);
   k_STEP       constant pls_integer := sign(i_days);
   l_remaining  pls_integer := abs(i_days);
begin
   while ( l_remaining > 0 )
   loop
      l_day := l_day + k_STEP;

      if ( is_working_day(i_date => l_day, i_calendar => i_calendar) )
      then
         l_remaining := l_remaining - 1;
      end if;
   end loop;

   return (l_day);
end add_working_days;

function working_days_between(i_from in date, i_to in date, i_calendar in varchar2 default 'DEFAULT') return number is
   k_LOW   constant date := trunc(least(i_from, i_to));
   k_HIGH  constant date := trunc(greatest(i_from, i_to));
   l_day            date := k_LOW;
   l_count          pls_integer := 0;
begin
   while ( l_day < k_HIGH )
   loop
      l_day := l_day + 1;

      if ( is_working_day(i_date => l_day, i_calendar => i_calendar) )
      then
         l_count := l_count + 1;
      end if;
   end loop;

   return ( case
               when trunc(i_to) < trunc(i_from) then -l_count
               else l_count
            end
          );
end working_days_between;

end lib_calendar;
/
show errors package body lib_calendar

prompt File: lib_calendar.pkb.sql <end>
