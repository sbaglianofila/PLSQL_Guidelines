prompt File: pkg_orders.pkb.sql <start>
-- =============================================================================
-- File:     pkg_orders.pkb.sql
-- Object:   PKG_ORDERS (package body)
-- Schema:   #APP# (owner)
-- Purpose:  Real logic (joins, filters) for the orders API. Not granted;
--           reached from consumers only through PKG_ORDERS_SHELL.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260701  AA   Creation
-- =============================================================================

prompt PKG_ORDERS: Creating package body
create or replace package body pkg_orders is

k_STATUS_OPEN constant orders.status%type := 'OPEN';

function open_orders_by_customer(i_customer_id in number) return sys_refcursor is
   l_result sys_refcursor;
begin
   open l_result for
      select o.order_id
           , o.order_date
           , o.total_amount
        --
        from orders o
        --
       where o.customer_id = i_customer_id
         and o.status      = k_STATUS_OPEN;
   return l_result;
end open_orders_by_customer;

end pkg_orders;
/
show errors package body pkg_orders

prompt File: pkg_orders.pkb.sql <end>
