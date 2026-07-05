prompt File: test_pkg_orders.pks.sql <start>
-- =============================================================================
-- File:     test_pkg_orders.pks.sql
-- Object:   TEST_PKG_ORDERS (utPLSQL suite specification)
-- Schema:   #APP# (dev/test environments only)
-- Purpose:  Unit tests for PKG_ORDERS. Requires utPLSQL installed.
--           utPLSQL annotations are the --%... comments below.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260701  AA   Creation
-- =============================================================================

prompt TEST_PKG_ORDERS: Creating test package specification
create or replace package test_pkg_orders is

   --%suite(Orders API)
   --%suitepath(#APP#.orders)

   --%test(Returns only OPEN orders for the given customer)
   procedure returns_open_only;

   --%test(Returns no rows for a customer with no open orders)
   procedure returns_empty_when_none;

end test_pkg_orders;
/
show errors package test_pkg_orders

prompt File: test_pkg_orders.pks.sql <end>
