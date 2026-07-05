prompt File: cleanup_orphan_orders.20260701_01.scr.sql <start>
-- =============================================================================
-- File:     cleanup_orphan_orders.20260701_01.scr.sql
-- Object:   One-off data cleanup (DML migration)
-- Schema:   #APP# (owner)
-- Purpose:  Remove ORDERS rows that reference a non-existent customer.
-- Note:     One-shot migration, run once and in order. IMMUTABLE once merged:
--           to fix a mistake add a new script, do not edit this one.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260701  AA   Creation
-- =============================================================================

whenever sqlerror exit failure rollback

prompt CLEANUP_ORPHAN_ORDERS: Deleting orders without a matching customer
delete from orders o
 where not exists (select 1
                     from customers c
                    where c.customer_id = o.customer_id);

prompt CLEANUP_ORPHAN_ORDERS: Rows deleted are reported above; committing
commit;

prompt File: cleanup_orphan_orders.20260701_01.scr.sql <end>
