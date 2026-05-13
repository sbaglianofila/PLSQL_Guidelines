# Uso del linguaggio — DML e SQL

Le istruzioni DML — `insert`, `update`, `delete`, `merge` — e le query SQL embedded nel codice PL/SQL sono il punto in cui il codice tocca i dati. Una piccola imprecisione in questo strato — un `select *` in una query, un alias omesso, un commit nel posto sbagliato — può produrre conseguenze che vanno dal dato errato silenzioso al blocco dell'intera transazione sotto carico. Le regole di questo capitolo non sono convenzioni stilistiche: la maggior parte ha un livello di gravità Blocker o Critical proprio perché la loro violazione tende a emergere in produzione, non in sviluppo.

---

## Regole generali

### Specificare sempre le colonne target in una INSERT

*Aspetti: Manutenibilità, Affidabilità — Livello: Blocker*

Una `insert` senza la lista esplicita delle colonne dipende dall'ordine in cui le colonne sono definite nella tabella. Se la struttura della tabella cambia — una colonna aggiunta, riordinata o rimossa — l'istruzione compilò ancora ma inserisce i valori nelle colonne sbagliate, senza alcun errore visibile fino a quando i dati vengono letti.

Specificare sempre la lista delle colonne rende la `insert` immune alle modifiche strutturali della tabella e rende immediatamente leggibile la corrispondenza tra colonne e valori.

```sql
-- Errato: l'ordine delle colonne è implicito; una modifica alla tabella rompe i dati silenziosamente
create or replace
package body dept_api
is
    procedure ins_dept (  i_dept_row  in  dept%rowtype  )
    is
    begin
        insert
          into departments
        values (  departments_seq.nextval
               , i_dept_row.department_name
               , i_dept_row.manager_id
               , i_dept_row.location_id
              );
    end ins_dept;
end dept_api;
/
```

```sql
-- Corretto: la lista colonne è esplicita; l'istruzione è resistente ai cambiamenti strutturali
create or replace
package body dept_api
is
    procedure ins_dept (  i_dept_row  in  dept%rowtype  )
    is
    begin
        insert
          into departments (  department_id
                            , department_name
                            , manager_id
                            , location_id
                           )
        values (  departments_seq.nextval
               , i_dept_row.department_name
               , i_dept_row.manager_id
               , i_dept_row.location_id
              );
    end ins_dept;
end dept_api;
/
```

---

### Auto-assegnazione di colonna in UPDATE

*Aspetti: Manutenibilità — Livello: Blocker*

Assegnare una colonna a se stessa in una `update` — `set first_name = first_name` — è quasi sempre un errore di copia/incolla. Non produce un errore Oracle, ma l'istruzione non ha effetto utile e genera lavoro inutile sul database. L'unica eccezione documentata è l'attivazione di trigger cross-edition in scenari di Edition Based Redefinition, che è un caso raro e specifico.

```sql
-- Errato: la colonna viene assegnata a se stessa, nessun effetto reale
update employees
   set first_name = first_name;
```

```sql
-- Corretto: il valore aggiornato è significativamente diverso da quello originale
update employees
   set first_name = initcap(first_name);
```

---

### Sintassi JOIN ANSI SQL-92

*Aspetti: Manutenibilità, Portabilità — Livello: Major*

La sintassi tradizionale di join — tabelle separate da virgola nella clausola `from` con le condizioni di join nel `where` — mischia in un unico predicato le condizioni strutturali (la relazione tra tabelle) e le condizioni di filtro (i criteri di ricerca). Questo rende le query più difficili da leggere e da modificare, e non supporta il `full outer join`.

La sintassi ANSI SQL-92 con `join ... on` separa le due categorie: le condizioni di join stanno nel `on`, i filtri nel `where`. La struttura della query diventa immediatamente leggibile, e l'aggiunta o la rimozione di una tabella non richiede di toccare le condizioni di filtro.

```sql
-- Errato: condizioni di join e filtri mescolati nel where
select emp.employee_id
     , emp.last_name
     , emp.first_name
     , dept.department_name
  from employees    emp
     , departments  dept
 where emp.department_id  = dept.department_id
   and extract(month from emp.hire_date) = extract(month from sysdate);
```

```sql
-- Corretto: join separato dal filtro, struttura immediatamente leggibile
select emp.employee_id
     , emp.last_name
     , emp.first_name
     , dept.department_name
  from employees  emp
       join departments  dept
         on ( dept.department_id = emp.department_id )
    --
 where extract(month from emp.hire_date) = extract(month from sysdate);
```

---

### Record ancorati come target dei cursori

*Aspetti: Manutenibilità, Affidabilità — Livello: Major*

Quando si esegue un `fetch` da un cursore esplicito, il target dell'istruzione dovrebbe essere un record ancorato al cursore con `%rowtype`, non un insieme di variabili scalari separate. Usare variabili scalari crea un accoppiamento rigido tra la lista di colonne del cursore e l'elenco delle variabili nel `fetch`: se il cursore viene modificato — una colonna aggiunta, una rimossa — anche il `fetch` deve essere aggiornato. Un record ancorato con `%rowtype` segue la struttura del cursore automaticamente.

```sql
-- Errato: tre variabili scalari devono rispecchiare esattamente la select del cursore
declare
    cursor c_employees
    is
        select emp.employee_id
             , emp.first_name
             , emp.last_name
          from employees  emp;
    --
    l_employee_id   employees.employee_id%type;
    l_first_name    employees.first_name%type;
    l_last_name     employees.last_name%type;
begin
    open c_employees;
    fetch c_employees into l_employee_id, l_first_name, l_last_name;

    <<process_employees>>
    while ( c_employees%found )
    loop
        fetch c_employees into l_employee_id, l_first_name, l_last_name;
    end loop process_employees;

    close c_employees;
end;
/
```

```sql
-- Corretto: un solo record ancorato al cursore; cambiare la select non richiede modifiche al fetch
declare
    cursor c_employees
    is
        select emp.employee_id
             , emp.first_name
             , emp.last_name
          from employees  emp;
    --
    r_employee  c_employees%rowtype;
begin
    open c_employees;
    fetch c_employees into r_employee;

    <<process_employees>>
    while ( c_employees%found )
    loop
        fetch c_employees into r_employee;
    end loop process_employees;

    close c_employees;
end;
/
```

---

### Evitare SELECT *

*Aspetti: Efficienza, Manutenibilità, Affidabilità, Verificabilità — Livello: Blocker*

Usare `select *` impedisce all'ottimizzatore di sapere quali colonne saranno effettivamente usate dall'applicazione, potenzialmente portando a piani di esecuzione subottimali — ad esempio una full table scan dove un index scan sarebbe sufficiente. Più concretamente: se la struttura della tabella cambia — una colonna aggiunta, una resa invisibile — il `select *` può restituire colonne diverse da quelle attese, rompendo il codice che legge il risultato per posizione o il `%rowtype` che vi è associato.

Ogni `select` deve elencare esplicitamente le colonne necessarie. L'unica eccezione accettabile è `select *` in una vista inline quando la vista stessa seleziona già le colonne esatte, o quando il fetch avviene in un record dichiarato con `tabella%rowtype` con l'intenzione esplicita di elaborare tutte le colonne della riga.

```sql
-- Errato: select * porta tutti i campi, ottimizzatore penalizzato, struttura fragile
begin
    <<aggiorna_stipendi>>
    for r_employee in (
        select *
          from employees
    )
    loop
        employee_api.calculate_raise_by_seniority(
              id_in       => r_employee.employee_id
            , salary_in   => r_employee.salary
            , hiredate_in => r_employee.hire_date
        );
    end loop aggiorna_stipendi;
end;
/
```

```sql
-- Corretto: solo le colonne necessarie, esplicite e qualificate
begin
    <<aggiorna_stipendi>>
    for r_employee in (
        select emp.employee_id
             , emp.salary
             , emp.hire_date
          from employees  emp
    )
    loop
        employee_api.calculate_raise_by_seniority(
              id_in       => r_employee.employee_id
            , salary_in   => r_employee.salary
            , hiredate_in => r_employee.hire_date
        );
    end loop aggiorna_stipendi;
end;
/
```

---

### Colonne identity per le chiavi surrogate

*Aspetti: Manutenibilità, Affidabilità — Livello: Critical — Requisito: Oracle 12c*

Fino a Oracle 11g il modo standard per generare chiavi surrogate era una sequenza popolata da un trigger `before insert`. A partire da Oracle 12c, la colonna identity — `generated always as identity` — assolve allo stesso compito in modo nativo: la sequenza è integrata nella definizione della colonna, il trigger non serve, e le prestazioni sono superiori perché l'assegnazione avviene a livello di SQL senza il contesto switch del trigger PL/SQL.

`generated always as identity` garantisce che il valore sia sempre generato dal database, senza possibilità di sovrascriverlo dall'applicazione. Se un framework inserisce righe includendo il valore della colonna identity nella lista delle colonne, va usato `generated by default on null as identity`, che assegna la sequenza solo quando il valore passato è `null`.

```sql
-- Errato: sequenza + trigger è il pattern pre-12c, più lento e più codice da mantenere
create table locations
(   location_id     number(10)          not null
  , location_name   varchar2(60 char)   not null
  , city            varchar2(30 char)   not null
  , constraint locations_pk primary key ( location_id )
)
/
create sequence location_seq start with 1 cache 20
/
create or replace
trigger location_br_i
before insert on locations
for each row
begin
    :new.location_id := location_seq.nextval;
end;
/
```

```sql
-- Corretto: colonna identity, nessun trigger, prestazioni migliori
create table locations
(   location_id     number(10)          generated always as identity
  , location_name   varchar2(60 char)   not null
  , city            varchar2(30 char)   not null
  , constraint locations_pk primary key ( location_id )
)
/
```

---

### Colonne virtuali come invisibili

*Aspetti: Manutenibilità, Affidabilità — Livello: Blocker — Requisito: Oracle 12c*

Una colonna virtuale — calcolata da un'espressione sulle altre colonne — non può essere scritta direttamente da una `update` o `insert`. Se la colonna virtuale è visibile, viene inclusa nel record generato da `%rowtype` e un tentativo di aggiornare la tabella con `set row = r_record` andrà in errore con `ORA-54017: update operation disallowed on virtual columns`.

Dichiarare la colonna virtuale come `invisible` la esclude automaticamente dal `%rowtype`, eliminando il problema. La colonna rimane accessibile nelle query che la nominano esplicitamente nella `select`.

```sql
-- Errato: total_salary è visibile, entra nel %rowtype e blocca l'update con set row
alter table employees
  add total_salary generated always as ( salary + nvl(commission_pct, 0) * salary );
```

```sql
-- Corretto: total_salary è invisibile, non entra nel %rowtype
alter table employees
  add total_salary invisible generated always as ( salary + nvl(commission_pct, 0) * salary );
```

---

### DEFAULT ON NULL per i valori di default

*Aspetti: Affidabilità — Livello: Blocker — Requisito: Oracle 12c*

Prima di Oracle 12c, un valore di default su una colonna veniva ignorato quando l'applicazione passava esplicitamente `null` per quella colonna: il `null` sovrascriveva il default. A partire da Oracle 12c, la clausola `default on null` assegna il valore di default anche quando il valore passato è `null`, garantendo che la colonna non resti mai vuota contro l'intenzione.

```sql
-- Errato: il default viene bypassato se il chiamante passa null esplicitamente
create table null_test
(   test_case        number(2)           not null
  , column_defaulted varchar2(10 char)   default 'Default'
)
/
```

```sql
-- Corretto: default on null garantisce che null non bypasisi il valore predefinito
create table null_test
(   test_case        number(2)           not null
  , column_defaulted varchar2(10 char)   default on null 'Default'
)
/
```

---

### Riferimenti posizionali in ORDER BY e GROUP BY

*Aspetti: Modificabilità, Affidabilità — Livello: Major (ORDER BY) / Blocker (GROUP BY)*

Usare un numero intero al posto di un nome di colonna in `order by` o `group by` — `order by 3, 1` invece di `order by hire_date, last_name` — è fragile: se la lista `select` viene modificata e le colonne cambiano posizione, l'ordinamento o il raggruppamento cambia silenziosamente senza errori.

In `order by` si usano sempre i nomi delle colonne o gli alias definiti nella `select`. In `group by`, a partire da Oracle 23c, è possibile referenziare direttamente l'alias della `select` invece di ripetere l'espressione.

```sql
-- Errato: order by e group by con riferimenti posizionali
select upper(emp.first_name)    first_name
     , emp.last_name
     , emp.salary
     , emp.hire_date
  from employees  emp
 order by 4, 1, 3;
```

```sql
-- Corretto: nomi espliciti in order by
select upper(emp.first_name)    first_name
     , emp.last_name
     , emp.salary
     , emp.hire_date
  from employees  emp
 order by emp.hire_date
        , first_name
        , emp.salary;
```

```sql
-- Errato: espressione ripetuta nel group by (pre-23c inevitabile, ma ora evitabile)
select lower(emp.job_id)    job
     , sum(emp.salary)      sum_salary
  from employees  emp
 group by lower(emp.job_id)
 order by job;
```

```sql
-- Corretto (Oracle 23c+): alias nella group by, l'espressione non va ripetuta
select lower(emp.job_id)    job
     , sum(emp.salary)      sum_salary
  from employees  emp
 group by job
 order by job;
```

---

### ROWNUM e ORDER BY allo stesso livello

*Aspetti: Affidabilità, Verificabilità — Livello: Blocker*

`rownum` è uno pseudocolonna assegnato alle righe prima che `order by` venga applicato. Usare `rownum` nello stesso livello di query di un `order by` non produce le prime N righe ordinate, ma N righe scelte arbitrariamente prima dell'ordinamento — un risultato non deterministico e quasi certamente sbagliato.

Per ottenere le prime N righe di un risultato ordinato, ci sono due approcci corretti. Il primo, pre-12c, è spostare l'`order by` in una vista inline e applicare `rownum` nella query esterna. Il secondo, preferito su Oracle 12c e successivi, è usare la clausola `fetch first N rows only`.

```sql
-- Errato: rownum viene applicato prima dell'order by, le 5 righe non sono le 5 con salary più alto
select emp.first_name
     , emp.last_name
     , emp.salary
     , emp.hire_date
     , rownum  salary_rank
  from employees  emp
 where rownum <= 5
 order by emp.salary desc;
```

```sql
-- Corretto (pre-12c): order by nella vista inline, rownum nella query esterna
select emp.first_name
     , emp.last_name
     , emp.salary
     , emp.hire_date
     , rownum  salary_rank
  from (
        select inn.first_name
             , inn.last_name
             , inn.salary
             , inn.hire_date
          from employees  inn
         order by inn.salary desc
       )  emp
 where rownum <= 5;
```

```sql
-- Corretto (Oracle 12c+): fetch first, più leggibile e senza vista inline
select emp.first_name
     , emp.last_name
     , emp.salary
     , emp.hire_date
     , rank() over ( order by emp.salary desc )  salary_rank
  from employees  emp
 order by emp.salary desc
 fetch first 5 rows only;
```

---

### NATURAL JOIN

*Aspetti: Modificabilità, Affidabilità — Livello: Blocker*

`natural join` esegue il join su tutte le colonne con lo stesso nome nelle due tabelle, senza che il nome delle colonne sia scritto esplicitamente nel codice. Questo può sembrare conveniente, ma è una bomba a orologeria: se in futuro viene aggiunta una colonna con lo stesso nome a entrambe le tabelle — ad esempio `modified_at` per l'audit — il join acquisisce silenziosamente una condizione aggiuntiva, restituendo zero righe invece del risultato atteso, senza alcun errore.

Si usa sempre `join ... on` con le condizioni esplicite.

```sql
-- Errato: natural join si unisce su tutte le colonne con lo stesso nome, incluse quelle future
select dept.department_name
     , emp.last_name
     , emp.first_name
  from employees   emp
natural join departments  dept
 order by dept.department_name
        , emp.last_name;
-- dopo un alter table che aggiunge modified_at a entrambe le tabelle:
-- questa query restituisce 0 righe
```

```sql
-- Corretto: join esplicito, immune alle modifiche strutturali future
select dept.department_name
     , emp.last_name
     , emp.first_name
  from employees   emp
  join departments  dept
    on ( emp.department_id = dept.department_id )
 order by dept.department_name
        , emp.last_name;
```

---

### Wildcard nelle clausole LIKE

*Aspetti: Manutenibilità — Livello: Blocker*

Usare `like` senza almeno un wildcard (`%` o `_`) è ambiguo: non è chiaro al lettore se il wildcard sia stato dimenticato o se l'intenzione fosse un confronto esatto. Quando l'intenzione è un confronto esatto, si usa `=`; quando l'intenzione è un confronto parziale, si include sempre almeno un wildcard. Mescolare i due casi con `like` crea codice che si comporta in modo diverso a seconda del tipo delle colonne coinvolte e che può restituire righe inattese quando `_` viene interpretato come wildcard.

```sql
-- Errato: like senza wildcard — intenzione ambigua, comportamento dipendente dal datatype
select emp.employee_id
     , emp.last_name
  from employees  emp
 where emp.last_name like 'Smith';
```

```sql
-- Corretto (confronto parziale): wildcard esplicito, intenzione chiara
select emp.employee_id
     , emp.last_name
  from employees  emp
 where emp.last_name like 'Smith%';
```

```sql
-- Corretto (confronto esatto): uso di = al posto di like
select emp.employee_id
     , emp.last_name
  from employees  emp
 where emp.last_name = 'Smith';
```

---

## Operazioni bulk

### BULK COLLECT e FORALL per DML ripetuto

*Aspetti: Efficienza — Livello: Critical*

Ogni istruzione DML eseguita nel corpo di un loop comporta un context switch tra il motore PL/SQL e il motore SQL. Questo overhead è significativo: per poche decine di righe è trascurabile, ma per centinaia o migliaia di righe diventa il collo di bottiglia principale.

`forall` risolve il problema trasferendo in un'unica operazione un array di valori al motore SQL, che esegue il DML su tutti gli elementi senza tornare in PL/SQL per ogni riga. `bulk collect` fa lo stesso nella direzione opposta, recuperando un intero resultset in una collection con una singola query.

La soglia pratica indicata nelle linee guida è quattro iterazioni: se un DML viene eseguito più di quattro volte nel ciclo di vita di un blocco, va usata la versione bulk.

```sql
-- Errato: update eseguita N volte nel loop, N context switch PL/SQL↔SQL
declare
    t_employee_ids  employee_api.t_employee_ids_type;
    k_INCREASE      constant    employees.salary%type       := 0.1;
    k_DEPT_ID       constant    departments.department_id%type := 10;
begin
    t_employee_ids := employee_api.employee_ids_by_department(id_in => k_DEPT_ID);

    <<update_employees>>
    for i in 1..t_employee_ids.count()
    loop
        update employees
           set salary = salary + ( salary * k_INCREASE )
         where employee_id = t_employee_ids(i);
    end loop update_employees;
end;
/
```

```sql
-- Corretto: forall trasferisce l'intero array al SQL engine con un solo context switch
declare
    t_employee_ids  employee_api.t_employee_ids_type;
    k_INCREASE      constant    employees.salary%type           := 0.1;
    k_DEPT_ID       constant    departments.department_id%type  := 10;
begin
    t_employee_ids := employee_api.employee_ids_by_department(id_in => k_DEPT_ID);

    <<update_employees>>
    forall i in 1..t_employee_ids.count()
        update employees
           set salary = salary + ( salary * k_INCREASE )
         where employee_id = t_employee_ids(i);
end;
/
```

---

### Gestire le eccezioni salvate in FORALL

*Aspetti: Affidabilità, Verificabilità — Livello: Critical*

La clausola `save exceptions` di un `forall` istruisce Oracle a continuare l'elaborazione anche quando una singola riga genera un errore, raccogliendo tutte le eccezioni in `sql%bulk_exceptions`. Se `save exceptions` è specificata ma il blocco `exception` non elabora `sql%bulk_exceptions`, gli errori vengono scartati silenziosamente: il `forall` appare completato con successo, ma alcune righe potrebbero non essere state elaborate.

La regola è semplice: se si usa `save exceptions`, si deve sempre includere un handler per `e_bulk_errors` che itera su `sql%bulk_exceptions` e gestisce ogni eccezione — tipicamente loggandola o rilanciandola.

```sql
-- Errato: save exceptions dichiarata ma sql%bulk_exceptions non viene mai letto
declare
    t_employee_ids  employee_api.t_employee_ids_type;
    k_INCREASE      constant    employees.salary%type           := 0.1;
    k_DEPT_ID       constant    departments.department_id%type  := 10;
    e_bulk_errors   exception;
    pragma exception_init(e_bulk_errors, -24381);
begin
    t_employee_ids := employee_api.employee_ids_by_department(id_in => k_DEPT_ID);

    <<update_employees>>
    forall i in 1..t_employee_ids.count() save exceptions
        update employees
           set salary = salary + ( salary * k_INCREASE )
         where employee_id = t_employee_ids(i);
end;
/
```

```sql
-- Corretto: ogni eccezione salvata viene elaborata nell'handler
declare
    t_employee_ids  employee_api.t_employee_ids_type;
    k_INCREASE      constant    employees.salary%type           := 0.1;
    k_DEPT_ID       constant    departments.department_id%type  := 10;
    e_bulk_errors   exception;
    pragma exception_init(e_bulk_errors, -24381);
begin
    t_employee_ids := employee_api.employee_ids_by_department(id_in => k_DEPT_ID);

    <<update_employees>>
    forall i in 1..t_employee_ids.count() save exceptions
        update employees
           set salary = salary + ( salary * k_INCREASE )
         where employee_id = t_employee_ids(i);
exception
    when e_bulk_errors
    then
        <<gestisci_eccezioni_bulk>>
        for i in 1..sql%bulk_exceptions.count
        loop
            logger.log(sql%bulk_exceptions(i).error_code);
        end loop gestisci_eccezioni_bulk;
end;
/
```

---

## Gestione delle transazioni

### Commit all'interno di un loop su cursore

*Aspetti: Efficienza, Affidabilità — Livello: Blocker*

Eseguire un `commit` all'interno di un loop che itera su un cursore — implicito o esplicito — è pericoloso per tre motivi distinti. Il primo è il rischio di `ORA-01555: snapshot too old`: Oracle deve mantenere una versione consistente dei dati per tutta la durata del cursore; un commit frequente può invalidare l'undo necessario a quel fine. Il secondo è la perdita di atomicità: se il processo si interrompe a metà, i dati restano in uno stato parzialmente aggiornato non facilmente recuperabile. Il terzo è la performance: ogni commit è un'operazione costosa che include la scrittura sui redo log.

La soluzione dipende dal caso. Se tutte le iterazioni formano una singola transazione logica, il `commit` va spostato dopo la fine del loop. Se ogni iterazione è una transazione indipendente con necessità di riavviabilità, la logica va ristrutturata: raccogliere i dati in una collection, poi iterare sulla collection (non sul cursore) chiamando una procedura che contiene la transazione e il `commit`.

```sql
-- Errato: commit ogni 100 righe dentro un loop su cursore — rischio ORA-01555 e stato inconsistente
declare
    l_counter           pls_integer         := 0;
    l_discount          discount.percentage%type;
    k_STATUS_NEW        constant    orders.order_status%type    := 'New';
    k_COMMIT_INTERVAL   constant    pls_integer                 := 100;
begin
    <<nuovi_ordini>>
    for r_order in (
        select ord.order_id
             , ord.customer_id
          from orders  ord
         where ord.order_status = k_STATUS_NEW
    )
    loop
        l_discount := sales_api.calculate_discount(p_customer_id => r_order.customer_id);

        update order_lines  orl
           set orl.discount = l_discount
         where orl.order_id = r_order.order_id;

        l_counter := l_counter + 1;

        if ( l_counter = k_COMMIT_INTERVAL )
        then
            commit;
            l_counter := 0;
        end if;
    end loop nuovi_ordini;

    if ( l_counter > 0 )
    then
        commit;
    end if;
end;
/
```

```sql
-- Corretto: un solo commit dopo il loop; se possibile, riscrivere come singolo DML
declare
    l_discount      discount.percentage%type;
    k_STATUS_NEW    constant    orders.order_status%type    := 'New';
begin
    <<nuovi_ordini>>
    for r_order in (
        select ord.order_id
             , ord.customer_id
          from orders  ord
         where ord.order_status = k_STATUS_NEW
    )
    loop
        l_discount := sales_api.calculate_discount(p_customer_id => r_order.customer_id);

        update order_lines  orl
           set orl.discount = l_discount
         where orl.order_id = r_order.order_id;
    end loop nuovi_ordini;

    commit;
end;
/
```

---

### Transazioni nei loop non-cursore

*Aspetti: Manutenibilità, Riusabilità, Verificabilità — Livello: Major*

Un `commit` all'interno di un loop che non itera su un cursore — un `loop` semplice, un `while`, un `for` numerico — indica quasi sempre che ogni iterazione è una transazione autonoma. In questo caso, la logica di quella transazione dovrebbe vivere in una procedura separata, che contiene sia il DML che il `commit`. Il loop chiama la procedura.

Questo approccio ha tre vantaggi: la procedura può essere testata indipendentemente, può essere riusata da altri chiamanti, e il codice del loop diventa più leggibile perché non mescola logica di iterazione e logica transazionale.

```sql
-- Errato: logica di inserimento e commit mescolati nel corpo del loop
declare
    k_UPPER_BOUND   constant    integer := 5;
    k_MAX_LEVEL     constant    integer := 3;
    k_NUMBER        constant    types_up.short_string := 'Number';
    k_LINE          constant    types_up.short_string := 'Line';
    k_SPACE         constant    types_up.short_string := ' ';
    l_counter                   integer := 0;
begin
    <<crea_intestazioni>>
    loop
        insert into headers (id, text)
        values ( l_counter, k_NUMBER || k_SPACE || l_counter );

        insert into lines (header_id, line_no, text)
        select l_counter
             , rownum
             , k_LINE || k_SPACE || rownum
          from dual
         connect by level <= k_MAX_LEVEL;

        commit;
        l_counter := l_counter + 1;
        exit crea_intestazioni when l_counter > k_UPPER_BOUND;
    end loop crea_intestazioni;
end;
/
```

```sql
-- Corretto: la transazione è incapsulata in una procedura, il loop chiama la procedura
declare
    k_UPPER_BOUND   constant    integer := 5;
    k_MAX_LEVEL     constant    integer := 3;
    k_NUMBER        constant    types_up.short_string := 'Number';
    k_LINE          constant    types_up.short_string := 'Line';
    k_SPACE         constant    types_up.short_string := ' ';

    procedure crea_righe ( i_header_id  in  headers.id%type )
    is
        k_HEADER_ID constant    headers.id%type := i_header_id;
    begin
        insert into headers (id, text)
        values ( k_HEADER_ID, k_NUMBER || k_SPACE || k_HEADER_ID );

        insert into lines (header_id, line_no, text)
        select k_HEADER_ID
             , rownum
             , k_LINE || k_SPACE || rownum
          from dual
         connect by level <= k_MAX_LEVEL;

        commit;
    end crea_righe;
begin
    <<crea_intestazioni>>
    for l_counter in 1..k_UPPER_BOUND
    loop
        crea_righe(i_header_id => l_counter);
    end loop crea_intestazioni;
end;
/
```

---

### Transazioni autonome

*Aspetti: Affidabilità, Verificabilità — Livello: Blocker*

`pragma autonomous_transaction` separa la transazione del sottoprogramma dalla transazione chiamante: le istruzioni DML della procedura vengono committate (o rollbackate) indipendentemente dallo stato della transazione principale. È una funzionalità potente e pericolosa: usata nel posto sbagliato introduce problemi di consistenza dei dati difficili da diagnosticare, perché i dati scritti dalla transazione autonoma vengono resi permanenti anche se la transazione principale viene annullata.

L'unico uso legittimo e universalmente accettato è la scrittura di log di errore o di messaggi diagnostici in una tabella di log, dove è desiderabile che il log venga salvato anche se la transazione principale va in rollback. In tutti gli altri casi, il `pragma autonomous_transaction` è quasi certamente un sintomo di un'architettura transazionale mal progettata.

```sql
-- Errato: autonomous_transaction usato per una insert ordinaria — la transazione principale
-- può essere annullata, ma l'insert in dept rimane committata: inconsistenza garantita
create or replace
package body dept_api
is
    procedure ins_dept ( i_dept_row  in  dept%rowtype )
    is
        pragma autonomous_transaction;
    begin
        insert into dept
        values i_dept_row;

        commit;
    end ins_dept;
end dept_api;
/
```

```sql
-- Corretto: nessuna transazione autonoma; il commit avviene nel modulo chiamante
-- al termine dell'intera unità di lavoro
create or replace
package body dept_api
is
    procedure ins_dept ( i_dept_row  in  dept%rowtype )
    is
    begin
        insert into dept
        values i_dept_row;
        -- la transazione viene confermata dal chiamante dopo il completamento del lavoro
    end ins_dept;
end dept_api;
/
```
