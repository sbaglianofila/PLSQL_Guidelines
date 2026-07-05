prompt File: lib_calendar.pks.sql <start>
-- =============================================================================
-- File:     lib_calendar.pks.sql
-- Object:   lib_calendar (package specification)
-- Schema:   #APP#
-- Purpose:  Business calendar - a genuine complement: Oracle knows nothing about
--           working days and holidays. Serves any project with due dates, SLAs
--           or "first working day of the month" processing. The weekend is
--           Saturday and Sunday (locale-independent); holidays come from
--           ref_holidays, optionally per calendar.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt lib_calendar: Creating package specification
create or replace package lib_calendar is

-- True when the date is neither a weekend nor a holiday of the calendar.
-- i_date     : date to test (time component ignored).
-- i_calendar : calendar code; defaults to 'DEFAULT'.
-- return     : true when it is a working day.
function is_working_day(i_date in date, i_calendar in varchar2 default 'DEFAULT') return boolean;

-- First working day strictly after i_date.
function next_working_day(i_date in date, i_calendar in varchar2 default 'DEFAULT') return date;

-- Last working day strictly before i_date.
function previous_working_day(i_date in date, i_calendar in varchar2 default 'DEFAULT') return date;

-- Adds i_days working days to i_date (negative to go backwards). Weekends and
-- holidays are skipped; a zero offset returns the truncated date unchanged.
-- i_date     : starting date.
-- i_days     : number of working days to add (may be negative).
-- i_calendar : calendar code; defaults to 'DEFAULT'.
-- return     : the resulting working date.
function add_working_days(i_date in date, i_days in number, i_calendar in varchar2 default 'DEFAULT') return date;

-- Count of working days between two dates, exclusive of the earlier and
-- inclusive of the later; negative when i_to precedes i_from.
-- i_from     : first date.
-- i_to       : second date.
-- i_calendar : calendar code; defaults to 'DEFAULT'.
-- return     : signed count of working days.
function working_days_between(i_from in date, i_to in date, i_calendar in varchar2 default 'DEFAULT') return number;

end lib_calendar;
/
show errors package lib_calendar

prompt File: lib_calendar.pks.sql <end>
