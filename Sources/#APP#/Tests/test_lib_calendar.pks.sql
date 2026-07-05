prompt File: test_lib_calendar.pks.sql <start>
-- =============================================================================
-- File:     test_lib_calendar.pks.sql
-- Object:   test_lib_calendar (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_calendar. Uses fixed reference dates around a
--           known Monday (2024-01-01) and a seeded holiday.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_calendar: Creating test package specification
create or replace package test_lib_calendar is

--%suite(lib_calendar)
--%suitepath(#APP#.base)

--%beforeall
procedure seed_holiday;

--%afterall
procedure remove_holiday;

--%test(a Saturday is not a working day)
procedure weekend_is_not_working;

--%test(a seeded holiday is not a working day)
procedure holiday_is_not_working;

--%test(a plain weekday is a working day)
procedure weekday_is_working;

--%test(next_working_day skips the weekend)
procedure next_working_day_skips_weekend;

--%test(working_days_between counts inclusive of the later date)
procedure working_days_between_counts;

end test_lib_calendar;
/
show errors package test_lib_calendar

prompt File: test_lib_calendar.pks.sql <end>
