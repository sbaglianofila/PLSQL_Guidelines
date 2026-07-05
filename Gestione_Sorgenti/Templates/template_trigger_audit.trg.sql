prompt File: <table_name>_audit_trg.trg.sql <start>
-- =============================================================================
-- File:     <table_name>_audit_trg.trg.sql
-- Object:   <table_name>_audit_trg (trigger)
-- Schema:   #APP#
-- Purpose:  Maintains the standard administrative columns of <table_name>:
--           creation audit (insert), modification audit (update) and the
--           optimistic-locking row version. See colonne_amministrative.md.
-- Note:     Creation columns are immutable across updates; row_version is
--           server-authoritative and ignores any client-supplied value.
-- -----------------------------------------------------------------------------
-- Changelog (authoritative history: version control)
--   Date      Aut  Change
--   <YYYYMMDD> <AA>  Creation
-- =============================================================================

prompt <table_name>_audit_trg: Creating trigger
create or replace trigger <table_name>_audit_trg
   before insert or update on <table_name>
   for each row
begin
   if inserting then
      :new.created_by       := nvl( sys_context('userenv', 'client_identifier')
                                  , sys_context('userenv', 'session_user') );
      :new.created_at       := systimestamp;
      :new.created_program  := sys_context('userenv', 'module');
      :new.modified_by      := null;
      :new.modified_at      := null;
      :new.modified_program := null;
      :new.row_version      := 1;
   elsif updating then
      -- creation columns are immutable: carry them over untouched
      :new.created_by       := :old.created_by;
      :new.created_at       := :old.created_at;
      :new.created_program  := :old.created_program;
      --
      :new.modified_by      := nvl( sys_context('userenv', 'client_identifier')
                                  , sys_context('userenv', 'session_user') );
      :new.modified_at      := systimestamp;
      :new.modified_program := sys_context('userenv', 'module');
      :new.row_version      := nvl(:old.row_version, 0) + 1;
   end if;
end <table_name>_audit_trg;
/
show errors trigger <table_name>_audit_trg

prompt File: <table_name>_audit_trg.trg.sql <end>
