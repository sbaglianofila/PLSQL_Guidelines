prompt File: orders.fky.sql <start>
-- =============================================================================
-- File:     orders.fky.sql
-- Object:   ORDERS foreign keys
-- Schema:   #APP# (owner)
-- Purpose:  Foreign key constraints for ORDERS. Applied after all referenced
--           tables exist, which is why FKs live in their own folder.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260701  AA   Creation
-- =============================================================================

prompt ORDERS: Creating foreign key ORDERS_FK_CUSTOMER
alter table orders add constraint orders_fk_customer
   foreign key (customer_id) references customers (customer_id);

prompt File: orders.fky.sql <end>
