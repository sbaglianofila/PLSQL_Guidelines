prompt File: orders.tab.sql <start>
-- =============================================================================
-- File:     orders.tab.sql
-- Object:   ORDERS (table)
-- Schema:   #APP# (owner)
-- Purpose:  Order headers. One row per customer order.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   20260701  AA   Creation
-- =============================================================================

prompt ORDERS: Creating table
create table orders
   ( order_id     number             constraint orders_pk primary key
   , customer_id  number             constraint orders_nn_customer_id not null
   , order_date   date               constraint orders_nn_order_date  not null
   , status       varchar2(20 char)  constraint orders_nn_status      not null
   , total_amount number(14,2)
   , constraint orders_ck_status check (status in ('OPEN', 'PROCESSED', 'CANCELLED'))
   -- administrative columns (populated by orders_audit_trg) -------------------
   , created_by        varchar2(64 char)  invisible  constraint orders_nn_created_by      not null
   , created_at        timestamp(6)       invisible  constraint orders_nn_created_at      not null
   , created_program   varchar2(64 char)  invisible  constraint orders_nn_created_program not null
   , modified_by       varchar2(64 char)  invisible
   , modified_at       timestamp(6)       invisible
   , modified_program  varchar2(64 char)  invisible
   , row_version       number             default 1  constraint orders_nn_row_version     not null
   );

prompt ORDERS: Adding comments
comment on table  orders             is 'Order headers. One row per customer order.';
comment on column orders.order_id    is 'Surrogate primary key.';
comment on column orders.customer_id is 'Owning customer. FK created in the FKs folder.';
comment on column orders.order_date  is 'Business date of the order.';
comment on column orders.status      is 'Lifecycle status; allowed values enforced by orders_ck_status.';
comment on column orders.total_amount is 'Gross order total.';
-- administrative columns (standard on every table; see colonne_amministrative.md)
comment on column orders.created_by       is 'Application user that inserted the row (invisible; set by trigger).';
comment on column orders.created_at       is 'Timestamp of insertion (invisible; set by trigger).';
comment on column orders.created_program  is 'Program/module that inserted the row (invisible; set by trigger).';
comment on column orders.modified_by      is 'Application user of the last update (invisible; null until first update).';
comment on column orders.modified_at      is 'Timestamp of the last update (invisible; null until first update).';
comment on column orders.modified_program is 'Program/module of the last update (invisible; null until first update).';
comment on column orders.row_version      is 'Optimistic-locking row version; incremented by trigger on every change.';

prompt ORDERS: Creating indexes
create index orders_idx_customer_id on orders (customer_id);

-- Reminder: the audit trigger lives in orders_audit_trg.trg.sql.

prompt File: orders.tab.sql <end>
