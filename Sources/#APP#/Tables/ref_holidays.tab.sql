prompt File: ref_holidays.tab.sql <start>
-- =============================================================================
-- File:     ref_holidays.tab.sql
-- Object:   ref_holidays (table)
-- Schema:   #APP#
-- Purpose:  Holiday calendar consumed by lib_calendar. Oracle knows nothing
--           about working days and holidays; this lookup fills the gap. The
--           calendar_code column supports multiple calendars (e.g. per site);
--           the default calendar is 'DEFAULT'. Populated per project - no seed
--           is shipped because holidays (and movable feasts) are project- and
--           year-specific.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260705  AA   Creation
-- =============================================================================

prompt ref_holidays: Creating table
create table ref_holidays
   ( calendar_code  varchar2(32 char)   default 'DEFAULT'
                                         constraint ref_holidays_nn_calendar not null
   , holiday_date   date                constraint ref_holidays_nn_date not null
   , description    varchar2(512 char)
   , constraint ref_holidays_pk primary key (calendar_code, holiday_date)
   );

prompt ref_holidays: Adding comments
comment on table  ref_holidays               is 'Holiday calendar consumed by lib_calendar; supports multiple calendars via calendar_code.';
comment on column ref_holidays.calendar_code is 'Calendar this holiday belongs to; DEFAULT for the single-calendar case.';
comment on column ref_holidays.holiday_date  is 'Date of the holiday (time component ignored).';
comment on column ref_holidays.description   is 'Human-readable name of the holiday.';

prompt File: ref_holidays.tab.sql <end>
