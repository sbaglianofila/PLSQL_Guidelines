prompt File: pkg_orders_shell.pkb.sql <start>
-- =============================================================================
-- File:     pkg_orders_shell.pkb.sql
-- Object:   PKG_ORDERS_SHELL (package body)
-- Schema:   #APP# (owner)
-- Purpose:  Shell body: pure delegation to PKG_ORDERS, no logic. Runs with
--           definer rights (the default) so it can reach the logic package.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260701  AA   Creation
-- =============================================================================

prompt PKG_ORDERS_SHELL: Creating package body
create or replace package body pkg_orders_shell is

function open_orders_by_customer(i_customer_id in number) return sys_refcursor is
begin
   return pkg_orders.open_orders_by_customer(i_customer_id);
end open_orders_by_customer;

end pkg_orders_shell;
/
show errors package body pkg_orders_shell

prompt File: pkg_orders_shell.pkb.sql <end>
