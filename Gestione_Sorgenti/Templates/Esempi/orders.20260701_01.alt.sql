prompt File: orders.20260701_01.alt.sql <start>
-- =============================================================================
-- File:     orders.20260701_01.alt.sql
-- Object:   ORDERS (table) - migration
-- Schema:   #APP# (owner)
-- Purpose:  Add SHIPPING_DATE to ORDERS.
-- Note:     Migrations are IMMUTABLE once merged. To correct a mistake, add a
--           new migration; never edit this file after it has been integrated.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260701  AA   Creation
-- =============================================================================

prompt ORDERS: Adding column SHIPPING_DATE
alter table orders add (shipping_date date);

prompt ORDERS: Commenting column SHIPPING_DATE
comment on column orders.shipping_date is 'Date the order was shipped; null while not yet shipped.';

prompt File: orders.20260701_01.alt.sql <end>
