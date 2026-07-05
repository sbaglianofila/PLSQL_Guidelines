prompt File: pkg_orders.pks.sql <start>
-- =============================================================================
-- File:     pkg_orders.pks.sql
-- Object:   PKG_ORDERS (package specification)
-- Schema:   #APP# (owner)
-- Purpose:  Logic package for orders. Holds the real logic and keeps the clean
--           name. NEVER granted: consumers reach it only through the
--           PKG_ORDERS_SHELL shell. See the encapsulation layer in schemi.md.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260701  AA   Creation
-- =============================================================================

prompt PKG_ORDERS: Creating package specification
create or replace package pkg_orders is

-- Returns the OPEN orders of a customer.
-- i_customer_id : customer whose open orders are requested.
function open_orders_by_customer(i_customer_id in number) return sys_refcursor;

end pkg_orders;
/
show errors package pkg_orders

prompt File: pkg_orders.pks.sql <end>
