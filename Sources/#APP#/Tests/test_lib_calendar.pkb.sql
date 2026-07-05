prompt File: test_lib_calendar.pkb.sql <start>
-- =============================================================================
-- File:     test_lib_calendar.pkb.sql
-- Object:   test_lib_calendar (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for lib_calendar. 2024-01-01 is a Monday: 05 Fri, 06 Sat,
--           07 Sun, 08 Mon.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt test_lib_calendar: Creating test package body
create or replace package body test_lib_calendar is

procedure seed_holiday is
   pragma autonomous_transaction;
begin
   merge into ref_holidays t
   using ( select 'DEFAULT'            as calendar_code
                , date '2024-01-01'    as holiday_date
                , 'UT New Year'        as description
             from dual
         ) s
      on (t.calendar_code = s.calendar_code and t.holiday_date = s.holiday_date)
    when not matched then
       insert (t.calendar_code, t.holiday_date, t.description)
       values (s.calendar_code, s.holiday_date, s.description);
   commit;
end seed_holiday;

procedure remove_holiday is
   pragma autonomous_transaction;
begin
   delete from ref_holidays rfh
    where rfh.calendar_code = 'DEFAULT'
      and rfh.holiday_date  = date '2024-01-01';
   commit;
end remove_holiday;

procedure weekend_is_not_working is
begin
   ut.expect(lib_calendar.is_working_day(date '2024-01-06')).to_be_false;
end weekend_is_not_working;

procedure holiday_is_not_working is
begin
   ut.expect(lib_calendar.is_working_day(date '2024-01-01')).to_be_false;
end holiday_is_not_working;

procedure weekday_is_working is
begin
   ut.expect(lib_calendar.is_working_day(date '2024-01-02')).to_be_true;
end weekday_is_working;

procedure next_working_day_skips_weekend is
   l_next  date;
begin
   l_next := lib_calendar.next_working_day(date '2024-01-05');
   ut.expect(to_char(l_next, 'YYYY-MM-DD')).to_equal('2024-01-08');
end next_working_day_skips_weekend;

procedure working_days_between_counts is
begin
   ut.expect(lib_calendar.working_days_between(date '2024-01-05', date '2024-01-08')).to_equal(1);
end working_days_between_counts;

end test_lib_calendar;
/
show errors package body test_lib_calendar

prompt File: test_lib_calendar.pkb.sql <end>
