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
            my_package.my_proc(i_employee_id => r_emp.employee_id);
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
        select  emp.employee_id
          from  employees  emp
         where  exists (
                    select  inn.salary
                      from  employees  inn
                     where  inn.salary < k_SALARY
                )
    )
    loop
        my_package.my_proc(i_employee_id => r_emp.employee_id);
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
package body pkg_department
as
    procedure ins
        ( i_department_row   in  departments%rowtype )
    is
        l_count     pls_integer;
    begin
        select  count(*)
          into  l_count
          from  departments  dep
         where  dep.department_id = i_department_row.department_id;

        if l_count = 0 then
            insert into departments
            values i_department_row;
        end if;
    end ins;
end pkg_department;
/
```

```sql
-- Corretto: insert diretto con gestione di dup_val_on_index
create or replace
package body pkg_department
as
    procedure ins
        ( i_department_row   in  departments%rowtype )
    is
    begin
        insert into departments
        values i_department_row;
    exception
        when dup_val_on_index then
            null;  -- riga già presente: comportamento atteso
    end ins;
end pkg_department;
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
package body pkg_department
as
    function dept_by_name
        ( i_dept_name  in  departments.department_name%type )
        return departments%rowtype
    is
        k_MAX_LEN   constant    integer := 20;
        r_return                departments%rowtype;
    begin
        if i_dept_name is null or length(i_dept_name) > k_MAX_LEN then
            raise lib_err.e_param_too_large;
        end if;

        select  *
          into  r_return
          from  departments  dep
         where  dep.department_name = i_dept_name;

        return r_return;
    exception
        when no_data_found  then return null;
        when too_many_rows  then raise;
    end dept_by_name;
end pkg_department;
/
```

```sql
-- Corretto: l'assegnazione a costante tipizzata not null valida dimensione e nullità
-- automaticamente; value_error viene sollevato prima che il corpo inizi
create or replace
package body pkg_department
as
    function dept_by_name
        ( i_dept_name  in  departments.department_name%type )
        return departments%rowtype
    is
        k_DEPT_NAME     constant    departments.department_name%type
                            not null := i_dept_name;
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
end pkg_department;
/
```

Il chiamante gestisce `value_error` nel proprio blocco:

```sql
declare
    k_DEPT_NAME     constant    lib_types.text_sbt := 'Nome di dipartimento troppo lungo';
    r_department                departments%rowtype;
begin
    pre_processing();
    r_department := pkg_department.dept_by_name(i_dept_name => k_DEPT_NAME);
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

Va tenuto presente che `dbms_lock` **non è eseguibile di default** dalle utenze normali: serve un `grant execute on sys.dbms_lock` esplicito all'owner, da richiedere ai DBA in fase di provisioning. Il grant è previsto nel template dei privilegi di sistema (`template_system_grant.grt.sql`) e il razionale è in `schemi.md`: si concedono i singoli package di sistema che servono, mai ruoli o privilegi di dizionario ampi.

```sql
-- Errato: lock basato su tabella — richiede cleanup manuale in caso di errore
create or replace
package body lib_lock
as
    procedure request_lock
        ( i_lock_name  in  varchar2 )
    is
        k_LOCK_NAME     constant    app_locks.lock_name%type := i_lock_name;
    begin
        insert into app_locks (lock_name) values (k_LOCK_NAME);
        -- se il processo fallisce, la riga rimane e blocca future esecuzioni
    end request_lock;

    procedure release_lock
        ( i_lock_name  in  varchar2 )
    is
        k_LOCK_NAME     constant    app_locks.lock_name%type := i_lock_name;
    begin
        delete from app_locks  lck
              where lck.lock_name = k_LOCK_NAME;
    end release_lock;
end lib_lock;
/
```

```sql
-- Corretto: dbms_lock — Oracle rilascia il lock automaticamente alla fine della sessione
create or replace
package body lib_lock
as
    function request_lock
        (   i_lock_name         in  varchar2
          , i_release_on_commit in  boolean     default false
        )
        return varchar2
    is
        k_LOCK_NAME         constant    lib_types.lock_name_sbt   := i_lock_name;
        k_RELEASE_ON_COMMIT constant    boolean             := i_release_on_commit;
        l_lock_handle                   lib_types.lock_handle_sbt;
    begin
        sys.dbms_lock.allocate_unique(
              lockname        => k_LOCK_NAME
            , lockhandle      => l_lock_handle
            , expiration_secs => lib_constants.k_ONE_WEEK
        );

        if sys.dbms_lock.request(
                  lockhandle        => l_lock_handle
                , lockmode          => sys.dbms_lock.x_mode
                , timeout           => sys.dbms_lock.maxwait
                , release_on_commit => k_RELEASE_ON_COMMIT
           ) > 0
        then
            raise lib_err.e_lock_request_failed;
        end if;

        return l_lock_handle;
    end request_lock;

    procedure release_lock
        ( i_lock_handle    in  varchar2 )
    is
        k_LOCK_HANDLE   constant    lib_types.lock_handle_sbt := i_lock_handle;
    begin
        if sys.dbms_lock.release(lockhandle => k_LOCK_HANDLE) > 0 then
            raise lib_err.e_lock_request_failed;
        end if;
    end release_lock;
end lib_lock;
/

-- Chiamata con gestione delle eccezioni e rilascio garantito del lock
declare
    l_handle        lib_types.lock_handle_sbt;
    k_LOCK_NAME     constant    lib_types.lock_name_sbt := 'APPLICATION_LOCK';
begin
    l_handle := lib_lock.request_lock(i_lock_name => k_LOCK_NAME);
    -- elaborazione
    lib_lock.release_lock(i_lock_handle => l_handle);
exception
    when lib_err.e_lock_request_failed then
        lib_lock.release_lock(i_lock_handle => l_handle);
        raise;
    when others then
        lib_lock.release_lock(i_lock_handle => l_handle);
        raise;
end;
/
```

---

## Monitoraggio del progresso

### Usare `dbms_application_info` per tracciare il progresso di un processo

*Aspetti: Efficienza, Affidabilità — Livello: Critical*

Scrivere log su tabelle o file per monitorare il progresso di un processo genera I/O persistente e può rallentare il processo stesso. `sys.dbms_application_info` offre un'alternativa: aggiorna le colonne `module` e `action` della sessione corrente in `v$session`, visibili in tempo reale senza alcuna scrittura su disco. È lo strumento ideale per monitorare processi batch di lunga durata: un DBA può osservare l'avanzamento interrogando `v$session` senza interferire con il processo.

Due precisazioni sui privilegi. Il package è eseguibile da qualsiasi utenza senza grant aggiuntivi (l'`EXECUTE` è concesso a `PUBLIC`), quindi *scrivere* le informazioni non richiede nulla. *Leggere* `v$session`, invece, richiede privilegi di dizionario che nel nostro modello ha chi monitora (il DBA, l'AM), non l'owner: per questo nel codice dell'applicazione le costanti non si ancorano a `v$session.action%type` — l'ancoraggio farebbe fallire la compilazione sotto il privilegio minimo — ma si dichiarano con un tipo esplicito. Le colonne `module` e `action` accettano rispettivamente fino a 64 byte; testi più lunghi vengono troncati.

```sql
-- Errato: il progresso è visibile solo attraverso dbms_output, non persistente
create or replace
package body pkg_employee
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
end pkg_employee;
/
```

```sql
-- Corretto: il progresso è visibile in v$session tramite dbms_application_info
create or replace
package body pkg_employee
as
    procedure process_emps
    is
        -- non ancorare a v$session.action%type: leggere v$session richiede
        -- privilegi di dizionario che l'owner deliberatamente non ha (schemi.md)
        k_ACTION_INIT   constant    varchar2(64 char)       := 'init';
        k_LABEL         constant    varchar2(64 char)       := 'Processing ';
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
end pkg_employee;
/
```
