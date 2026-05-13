# Uso del linguaggio — Dynamic SQL

Il SQL dinamico — istruzioni SQL costruite e eseguite a runtime tramite `execute immediate` o i package `dbms_sql` — è uno strumento potente ma delicato. Le regole di questo capitolo riguardano due aspetti complementari: la leggibilità e il debugging del codice dinamico, e il modo corretto di gestire i valori restituiti dalle operazioni DML dinamiche.

---

## Usare una variabile di tipo carattere per eseguire SQL dinamico

*Aspetti: Manutenibilità, Verificabilità — Livello: Major*

Passare una stringa letterale direttamente a `execute immediate` impedisce di ispezionare l'istruzione SQL al momento dell'errore: non è possibile loggarla, includerla nel messaggio di eccezione o stamparla per il debug. Assegnare prima l'istruzione a una costante (o variabile, se costruita dinamicamente) permette di registrare il testo esatto dell'istruzione che ha fallito.

```sql
-- Errato: la stringa SQL è inline, impossibile registrarla in caso di errore
declare
    l_next_val  employees.employee_id%type;
begin
    execute immediate 'select employees_seq.nextval from dual'
        into l_next_val;
end;
/
```

```sql
-- Corretto: l'istruzione è assegnata a una costante, disponibile per logging e debug
declare
    l_next_val  employees.employee_id%type;
    k_SQL       constant    types_up.big_string_type :=
        'select employees_seq.nextval from dual';
begin
    execute immediate k_SQL
        into l_next_val;
end;
/
```

---

## Usare `returning into` invece di `using` per i valori restituiti da DML dinamico

*Aspetti: Manutenibilità — Livello: Minor*

Quando un `insert`, `update` o `delete` dinamico ha una clausola `returning`, i valori restituiti possono essere catturati sia nella clausola `returning into` sia come parametri `out` nella clausola `using`. Le due sintassi sono equivalenti, ma le convenzioni di utilizzo sono diverse:

- `returning into` è la forma semanticamente corretta per i valori prodotti da una DML;
- i parametri `out` nella clausola `using` sono riservati ai blocchi PL/SQL dinamici che restituiscono valori attraverso variabili PL/SQL.

Usare `returning into` per le DML rende il codice più leggibile e coerente con il SQL statico, dove la stessa clausola svolge la stessa funzione.

```sql
-- Errato: il valore restituito è gestito come parametro out nella clausola using
create or replace
package body employee_api
as
    procedure upd_salary
        (   in_employee_id  in      employees.employee_id%type
          , in_increase_pct in      types_up.percentage
          , out_new_salary  out     employees.salary%type
        )
    is
        k_EMPLOYEE_ID   constant    employees.employee_id%type  := in_employee_id;
        k_INCREASE_PCT  constant    types_up.percentage         := in_increase_pct;
        k_SQL           constant    types_up.big_string_type    :=
            'update employees
                set salary = salary + (salary / 100 * :1)
              where employee_id = :2
          returning salary into :3';
    begin
        execute immediate k_SQL
            using k_INCREASE_PCT, k_EMPLOYEE_ID, out out_new_salary;
    end upd_salary;
end employee_api;
/
```

```sql
-- Corretto: il valore restituito dalla DML va in returning into
create or replace
package body employee_api
as
    procedure upd_salary
        (   in_employee_id  in      employees.employee_id%type
          , in_increase_pct in      types_up.percentage
          , out_new_salary  out     employees.salary%type
        )
    is
        k_EMPLOYEE_ID   constant    employees.employee_id%type  := in_employee_id;
        k_INCREASE_PCT  constant    types_up.percentage         := in_increase_pct;
        k_SQL           constant    types_up.big_string_type    :=
            'update employees
                set salary = salary + (salary / 100 * :1)
              where employee_id = :2
          returning salary into :3';
    begin
        execute immediate k_SQL
            using k_INCREASE_PCT, k_EMPLOYEE_ID
            returning into out_new_salary;
    end upd_salary;
end employee_api;
/
```
