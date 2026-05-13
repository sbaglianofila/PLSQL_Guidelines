# Patterns

Questo capitolo raccoglie pattern ricorrenti che, se applicati in modo errato, producono codice scorretto, fragile o inefficiente. Non si tratta di regole stilistiche ma di soluzioni a problemi reali: verifica dell'esistenza di righe, prevenzione dei duplicati, accesso a schemi esterni, validazione degli input e controllo della concorrenza.

---

## Verifica dell'esistenza di righe

### Non usare `count(*)` per verificare l'esistenza di una riga

*Aspetti: Efficienza — Livello: Critical*

`select count(*)` legge tutte le righe che soddisfano la condizione `where` prima di restituire il conteggio. Se lo scopo è solo sapere se esiste almeno una riga, questo è uno spreco significativo: Oracle deve scandire l'intero risultato anche se la risposta è determinabile dalla prima riga trovata.

La soluzione corretta è usare una subquery con `exists` nella query principale, oppure — quando si opera in PL/SQL — un singolo `fetch` su un cursore (come mostrato nel capitolo Control Structures). La clausola `exists` si ferma alla prima riga che soddisfa la condizione.

```sql
-- Errato: count(*) legge tutte le righe per poi controllare se il risultato è > 0
declare
    l_count     pls_integer;
    k_ZERO      constant    simple_integer          := 0;
    k_SALARY    constant    employees.salary%type   := 5000;
begin
    select  count(*)
      into  l_count
      from  employees  emp
     where  emp.salary < k_SALARY;

    if l_count > k_ZERO then
        <<emp_loop>>
        for r_emp in (
            select  emp.employee_id
              from  employees  emp
             where  emp.salary < k_SALARY
        )
        loop
            my_package.my_proc(in_employee_id => r_emp.employee_id);
        end loop emp_loop;
    end if;
end;
/
```

```sql
-- Corretto: exists si ferma alla prima riga trovata
declare
    k_SALARY    constant    employees.salary%type   := 5000;
begin
    <<emp_loop>>
    for r_emp in (
        select  e1.employee_id
          from  employees  e1
         where  exists (
                    select  e2.salary
                      from  employees  e2
                     where  e2.salary < k_SALARY
                )
    )
    loop
        my_package.my_proc(in_employee_id => r_emp.employee_id);
    end loop emp_loop;
end;
/
```

---

### Non verificare l'esistenza di una riga prima di inserirla

*Aspetti: Efficienza, Affidabilità — Livello: Critical*

Il risultato di una verifica di esistenza è una fotografia istantanea: tra il momento in cui si controlla e il momento in cui si inserisce, un'altra sessione potrebbe aver inserito la stessa riga. La sequenza `select count(*) → if non esiste → insert` non è atomica e lascia aperta una finestra di race condition.

La soluzione corretta è tentare direttamente l'inserimento e gestire l'eccezione `dup_val_on_index` se si vuole tollerare i duplicati. Questa logica è atomica e garantita dai vincoli del database, che sono l'unico meccanismo affidabile per prevenire righe duplicate.

```sql
-- Errato: la finestra tra check e insert consente inserimenti duplicati concorrenti
create or replace
package body department_api
as
    procedure ins
        ( in_r_department   in  departments%rowtype )
    is
        l_count     pls_integer;
    begin
        select  count(*)
          into  l_count
          from  departments  dep
         where  dep.department_id = in_r_department.department_id;

        if l_count = 0 then
            insert into departments
            values in_r_department;
        end if;
    end ins;
end department_api;
/
```

```sql
-- Corretto: insert diretto con gestione di dup_val_on_index
create or replace
package body department_api
as
    procedure ins
        ( in_r_department   in  departments%rowtype )
    is
    begin
        insert into departments
        values in_r_department;
    exception
        when dup_val_on_index then
            null;  -- riga già presente: comportamento atteso
    end ins;
end department_api;
/
```

---

## Accesso a oggetti di schemi esterni

### Usare i sinonimi per accedere a oggetti di altri schemi

*Aspetti: Modificabilità, Manutenibilità — Livello: Minor*

Referenziare direttamente oggetti di uno schema esterno con la notazione `schema.tabella` distribuisce la dipendenza in tutto il codice: se la tabella viene rinominata, spostata in un altro schema, o sostituita da una vista, ogni riferimento deve essere aggiornato. Un sinonimo centralizza questa dipendenza in un unico punto: la definizione del sinonimo stesso.

I sinonimi offrono anche flessibilità operativa: in ambienti di test si può puntare il sinonimo a una tabella locale invece che a quella di produzione, senza modificare il codice applicativo.

```sql
-- Errato: riferimento diretto allo schema esterno diffuso nel codice
declare
    l_product_name  oe.products.product_name%type;
    k_PRICE         constant    oe.products.list_price%type := 1000;
begin
    select  p.product_name
      into  l_product_name
      from  oe.products  p
     where  p.list_price > k_PRICE;
exception
    when no_data_found  then null;
    when too_many_rows  then null;
end;
/
```

```sql
-- Corretto: il sinonimo isola la dipendenza dallo schema esterno
create synonym oe_products for oe.products;

declare
    l_product_name  oe_products.product_name%type;
    k_PRICE         constant    oe_products.list_price%type := 1000;
begin
    select  p.product_name
      into  l_product_name
      from  oe_products  p
     where  p.list_price > k_PRICE;
exception
    when no_data_found  then null;
    when too_many_rows  then null;
end;
/
```

---

## Validazione della dimensione dei parametri

### Validare la dimensione dei parametri stringa tramite assegnazione a costante tipizzata

*Aspetti: Manutenibilità, Affidabilità, Riusabilità, Verificabilità — Livello: Major*

Un parametro di tipo `varchar2` senza validazione esplicita accetta qualsiasi stringa, indipendentemente dalla lunghezza. Se il codice passa poi quel valore a una colonna o a una variabile con una dimensione definita, l'errore viene sollevato in un punto lontano dall'origine.

La tecnica corretta è copiare il parametro in una costante dichiarata con il tipo ancorato alla colonna di destinazione — `departments.department_name%type` — nella sezione dichiarativa. Oracle valuta l'assegnazione al momento della dichiarazione: se il valore supera la dimensione dichiarata, viene sollevato `value_error` immediatamente, prima che il corpo della funzione inizi. L'errore viene così segnalato al chiamante, che è il responsabile dell'input, non al codice interno.

```sql
-- Errato: il parametro viene usato direttamente senza validazione della dimensione;
-- la procedura deve fare un controllo manuale e sollevare un errore applicativo
create or replace
package body department_api
as
    function dept_by_name
        ( in_dept_name  in  departments.department_name%type )
        return departments%rowtype
    is
        k_MAX_LEN   constant    integer := 20;
        r_return                departments%rowtype;
    begin
        if in_dept_name is null or length(in_dept_name) > k_MAX_LEN then
            raise err.e_param_too_large;
        end if;

        select  *
          into  r_return
          from  departments  dep
         where  dep.department_name = in_dept_name;

        return r_return;
    exception
        when no_data_found  then return null;
        when too_many_rows  then raise;
    end dept_by_name;
end department_api;
/
```

```sql
-- Corretto: l'assegnazione a costante tipizzata not null valida dimensione e nullità
-- automaticamente; value_error viene sollevato prima che il corpo inizi
create or replace
package body department_api
as
    function dept_by_name
        ( in_dept_name  in  departments.department_name%type )
        return departments%rowtype
    is
        k_DEPT_NAME     constant    departments.department_name%type
                            not null := in_dept_name;
        r_return                    departments%rowtype;
    begin
        <<trap>>
        begin
            select  *
              into  r_return
              from  departments  dep
             where  dep.department_name = k_DEPT_NAME;

            return r_return;
        exception
            when no_data_found  then return null;
            when too_many_rows  then raise;
        end trap;
    end dept_by_name;
end department_api;
/
```

Il chiamante gestisce `value_error` nel proprio blocco:

```sql
declare
    k_DEPT_NAME     constant    types_up.text   := 'Nome di dipartimento troppo lungo';
    r_department                departments%rowtype;
begin
    pre_processing();
    r_department := department_api.dept_by_name(in_dept_name => k_DEPT_NAME);
    post_processing();
exception
    when value_error then
        handle_error();
end;
/
```

---

## Esecuzione singola di un'unità di programma

### Usare i lock applicativi per garantire che un'unità di programma sia in esecuzione una sola volta

*Aspetti: Efficienza, Affidabilità — Livello: Blocker*

Certi processi — batch notturni, job di sincronizzazione, procedure di manutenzione — non devono mai essere eseguiti contemporaneamente da più sessioni. Usare una tabella di lock (una riga inserita come flag) è una soluzione comune ma fragile: se il processo termina con un'eccezione non gestita, la riga rimane e blocca le esecuzioni successive fino a un intervento manuale.

La soluzione corretta è usare `sys.dbms_lock`, che gestisce i lock a livello di sessione Oracle. Oracle rilascia automaticamente il lock al termine della sessione — anche in caso di crash — eliminando la necessità di cleanup manuale. Il lock è acquisito con `dbms_lock.request` e rilasciato con `dbms_lock.release`; un handle univoco per ogni lock logico viene ottenuto tramite `dbms_lock.allocate_unique`.

```sql
-- Errato: lock basato su tabella — richiede cleanup manuale in caso di errore
create or replace
package body lock_up
as
    procedure request_lock
        ( in_lock_name  in  varchar2 )
    is
        k_LOCK_NAME     constant    app_locks.lock_name%type := in_lock_name;
    begin
        insert into app_locks (lock_name) values (k_LOCK_NAME);
        -- se il processo fallisce, la riga rimane e blocca future esecuzioni
    end request_lock;

    procedure release_lock
        ( in_lock_name  in  varchar2 )
    is
        k_LOCK_NAME     constant    app_locks.lock_name%type := in_lock_name;
    begin
        delete from app_locks  lck
              where lck.lock_name = k_LOCK_NAME;
    end release_lock;
end lock_up;
/
```

```sql
-- Corretto: dbms_lock — Oracle rilascia il lock automaticamente alla fine della sessione
create or replace
package body lock_up
as
    function request_lock
        (   in_lock_name         in  varchar2
          , in_release_on_commit in  boolean     default false
        )
        return varchar2
    is
        k_LOCK_NAME         constant    type_up.lock_name   := in_lock_name;
        k_RELEASE_ON_COMMIT constant    boolean             := in_release_on_commit;
        l_lock_handle                   type_up.lock_handle;
    begin
        sys.dbms_lock.allocate_unique(
              lockname        => k_LOCK_NAME
            , lockhandle      => l_lock_handle
            , expiration_secs => constants_up.k_ONE_WEEK
        );

        if sys.dbms_lock.request(
                  lockhandle        => l_lock_handle
                , lockmode          => sys.dbms_lock.x_mode
                , timeout           => sys.dbms_lock.maxwait
                , release_on_commit => k_RELEASE_ON_COMMIT
           ) > 0
        then
            raise err.e_lock_request_failed;
        end if;

        return l_lock_handle;
    end request_lock;

    procedure release_lock
        ( in_lock_handle    in  varchar2 )
    is
        k_LOCK_HANDLE   constant    type_up.lock_handle := in_lock_handle;
    begin
        if sys.dbms_lock.release(lockhandle => k_LOCK_HANDLE) > 0 then
            raise err.e_lock_request_failed;
        end if;
    end release_lock;
end lock_up;
/

-- Chiamata con gestione delle eccezioni e rilascio garantito del lock
declare
    l_handle        type_up.lock_handle;
    k_LOCK_NAME     constant    type_up.lock_name := 'APPLICATION_LOCK';
begin
    l_handle := lock_up.request_lock(in_lock_name => k_LOCK_NAME);
    -- elaborazione
    lock_up.release_lock(in_lock_handle => l_handle);
exception
    when err.e_lock_request_failed then
        lock_up.release_lock(in_lock_handle => l_handle);
        raise;
    when others then
        lock_up.release_lock(in_lock_handle => l_handle);
        raise;
end;
/
```

---

## Monitoraggio del progresso

### Usare `dbms_application_info` per tracciare il progresso di un processo

*Aspetti: Efficienza, Affidabilità — Livello: Critical*

Scrivere log su tabelle o file per monitorare il progresso di un processo genera I/O persistente e può rallentare il processo stesso. `sys.dbms_application_info` offre un'alternativa: aggiorna le colonne `module` e `action` della sessione corrente in `v$session`, visibili in tempo reale senza alcuna scrittura su disco. È lo strumento ideale per monitorare processi batch di lunga durata: un DBA può osservare l'avanzamento interrogando `v$session` senza interferire con il processo.

```sql
-- Errato: il progresso è visibile solo attraverso dbms_output, non persistente
create or replace
package body employee_api
as
    procedure process_emps
    is
    begin
        <<employees>>
        for emp_rec in (
            select  emp.employee_id
              from  employees  emp
             order  by emp.employee_id
        )
        loop
            sys.dbms_output.put_line(emp_rec.employee_id);
        end loop employees;
    end process_emps;
end employee_api;
/
```

```sql
-- Corretto: il progresso è visibile in v$session tramite dbms_application_info
create or replace
package body employee_api
as
    procedure process_emps
    is
        k_ACTION_INIT   constant    v$session.action%type   := 'init';
        k_LABEL         constant    v$session.action%type   := 'Processing ';
    begin
        sys.dbms_application_info.set_module(
              module_name => $$plsql_unit
            , action_name => k_ACTION_INIT
        );

        <<employees>>
        for emp_rec in (
            select  emp.employee_id
              from  employees  emp
             order  by emp.employee_id
        )
        loop
            sys.dbms_application_info.set_action(
                action_name => k_LABEL || emp_rec.employee_id
            );
            -- elaborazione
        end loop employees;
    end process_emps;
end employee_api;
/
```
