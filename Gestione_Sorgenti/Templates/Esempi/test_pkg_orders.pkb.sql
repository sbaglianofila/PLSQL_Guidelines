prompt File: test_pkg_orders.pkb.sql <start>
-- =============================================================================
-- File:     test_pkg_orders.pkb.sql
-- Object:   TEST_PKG_ORDERS (utPLSQL suite body)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Skeleton unit tests for PKG_ORDERS. Replace the fixtures and
--           expectations with the real ones for your data set.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260701  AA   Creation
-- =============================================================================

prompt TEST_PKG_ORDERS: Creating test package body
create or replace package body test_pkg_orders is

   procedure returns_open_only is
      l_actual sys_refcursor;
   begin
      -- Arrange: set up a known fixture (customer with OPEN and non-OPEN orders).
      -- Act
      l_actual := pkg_orders.open_orders_by_customer(i_customer_id => -1);
      -- Assert: replace with the expected result for your fixture.
      ut.expect(l_actual).to_have_count(0);
   end returns_open_only;

   procedure returns_empty_when_none is
      l_actual sys_refcursor;
   begin
      l_actual := pkg_orders.open_orders_by_customer(i_customer_id => -1);
      ut.expect(l_actual).to_have_count(0);
   end returns_empty_when_none;

end test_pkg_orders;
/
show errors package body test_pkg_orders

prompt File: test_pkg_orders.pkb.sql <end>
