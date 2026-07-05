prompt File: pkg_orders_shell.pks.sql <start>
-- =============================================================================
-- File:     pkg_orders_shell.pks.sql
-- Object:   PKG_ORDERS_SHELL (package specification)
-- Schema:   #APP# (owner)
-- Purpose:  Public shell API for orders. Contains no logic: every subprogram
--           delegates to PKG_ORDERS. Grant EXECUTE on THIS shell to consumer
--           roles; never grant PKG_ORDERS. See the encapsulation layer in
--           schemi.md.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260701  AA   Creation
-- =============================================================================

prompt PKG_ORDERS_SHELL: Creating package specification
create or replace package pkg_orders_shell is

-- Returns the OPEN orders of a customer.
-- i_customer_id : customer whose open orders are requested.
function open_orders_by_customer(i_customer_id in number) return sys_refcursor;

end pkg_orders_shell;
/
show errors package pkg_orders_shell

prompt File: pkg_orders_shell.pks.sql <end>
