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
package body pkg_dept
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
end pkg_dept;
/
```

```sql
-- Corretto: la lista colonne è esplicita; l'istruzione è resistente ai cambiamenti strutturali
create or replace
package body pkg_dept
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
end pkg_dept;
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
     , dpt.department_name
  from employees    emp
     , departments  dpt
 where emp.department_id  = dpt.department_id
   and extract(month from emp.hire_date) = extract(month from sysdate);
```

```sql
-- Corretto: join separato dal filtro, struttura immediatamente leggibile
select emp.employee_id
     , emp.last_name
     , emp.first_name
     , dpt.department_name
  from employees  emp
       join departments  dpt
         on ( dpt.department_id = emp.department_id )
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
        pkg_employee.calculate_raise_by_seniority(
              i_id       => r_employee.employee_id
            , i_salary   => r_employee.salary
            , i_hiredate => r_employee.hire_date
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
        pkg_employee.calculate_raise_by_seniority(
              i_id       => r_employee.employee_id
            , i_salary   => r_employee.salary
            , i_hiredate => r_employee.hire_date
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
select dpt.department_name
     , emp.last_name
     , emp.first_name
  from employees   emp
       natural join departments  dpt
 order by dpt.department_name
        , emp.last_name;
-- dopo un alter table che aggiunge modified_at a entrambe le tabelle:
-- questa query restituisce 0 righe
```

```sql
-- Corretto: join esplicito, immune alle modifiche strutturali future
select dpt.department_name
     , emp.last_name
     , emp.first_name
  from employees   emp
       join departments  dpt
         on ( emp.department_id = dpt.department_id )
 order by dpt.department_name
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
    t_employee_ids  pkg_employee.t_employee_ids_type;
    k_INCREASE      constant    employees.salary%type       := 0.1;
    k_DEPT_ID       constant    departments.department_id%type := 10;
begin
    t_employee_ids := pkg_employee.employee_ids_by_department(i_department_id => k_DEPT_ID);

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
    t_employee_ids  pkg_employee.t_employee_ids_type;
    k_INCREASE      constant    employees.salary%type           := 0.1;
    k_DEPT_ID       constant    departments.department_id%type  := 10;
begin
    t_employee_ids := pkg_employee.employee_ids_by_department(i_department_id => k_DEPT_ID);

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
    t_employee_ids  pkg_employee.t_employee_ids_type;
    k_INCREASE      constant    employees.salary%type           := 0.1;
    k_DEPT_ID       constant    departments.department_id%type  := 10;
    e_bulk_errors   exception;
    pragma exception_init(e_bulk_errors, -24381);
begin
    t_employee_ids := pkg_employee.employee_ids_by_department(i_department_id => k_DEPT_ID);

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
    t_employee_ids  pkg_employee.t_employee_ids_type;
    k_INCREASE      constant    employees.salary%type           := 0.1;
    k_DEPT_ID       constant    departments.department_id%type  := 10;
    e_bulk_errors   exception;
    pragma exception_init(e_bulk_errors, -24381);
begin
    t_employee_ids := pkg_employee.employee_ids_by_department(i_department_id => k_DEPT_ID);

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
            lib_logging.log_error(i_text => sql%bulk_exceptions(i).error_code);
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
        l_discount := pkg_sales.calculate_discount(i_customer_id => r_order.customer_id);

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
        l_discount := pkg_sales.calculate_discount(i_customer_id => r_order.customer_id);

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
    k_NUMBER        constant    lib_types.short_string_sbt := 'Number';
    k_LINE          constant    lib_types.short_string_sbt := 'Line';
    k_SPACE         constant    lib_types.short_string_sbt := ' ';
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
    k_NUMBER        constant    lib_types.short_string_sbt := 'Number';
    k_LINE          constant    lib_types.short_string_sbt := 'Line';
    k_SPACE         constant    lib_types.short_string_sbt := ' ';

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
package body pkg_dept
is
    procedure ins_dept ( i_dept_row  in  dept%rowtype )
    is
        pragma autonomous_transaction;
    begin
        insert into dept
        values i_dept_row;

        commit;
    end ins_dept;
end pkg_dept;
/
```

```sql
-- Corretto: nessuna transazione autonoma; il commit avviene nel modulo chiamante
-- al termine dell'intera unità di lavoro
create or replace
package body pkg_dept
is
    procedure ins_dept ( i_dept_row  in  dept%rowtype )
    is
    begin
        insert into dept
        values i_dept_row;
        -- la transazione viene confermata dal chiamante dopo il completamento del lavoro
    end ins_dept;
end pkg_dept;
/
```

---

### Uso dei savepoint per il rollback parziale

*Aspetti: Affidabilità, Manutenibilità — Livello: Major*

Un `savepoint` marca un punto intermedio all'interno di una transazione: l'istruzione `rollback to savepoint <nome>` annulla soltanto il lavoro svolto dopo quel punto, lasciando intatto tutto ciò che è stato fatto prima e senza chiudere la transazione. È l'unico strumento che PL/SQL offre per un annullamento *parziale*, e il suo uso corretto è circoscritto a un caso ben preciso: garantire l'atomicità di una sotto-unità di lavoro senza sacrificare quella dell'intera transazione.

Il caso d'uso legittimo per eccellenza è l'elaborazione a lotti in cui ogni elemento deve essere trattato in modo indipendente — tipicamente un import o una pipeline ETL. Si vuole che una singola riga non valida venga scartata e registrata senza compromettere le righe valide già elaborate, e che al termine tutte le righe buone vengano confermate insieme con un solo `commit`. La soluzione naïve — intercettare l'errore e fare un `rollback` completo — è sbagliata: annulla l'intera transazione, comprese tutte le righe corrette elaborate fino a quel momento. La soluzione corretta è porre un `savepoint` prima di ogni elemento e, in caso di errore, tornare a quel savepoint con `rollback to savepoint`, registrare lo scarto (ad esempio in una tabella `err_`) e proseguire.

Rispetto alla strategia del `commit` per ogni elemento — discussa nelle sezioni precedenti e sconsigliata perché frammenta l'atomicità ed espone all'`ORA-01555` — il savepoint offre un compromesso migliore quando il requisito è "elabora ciò che puoi, scarta il resto, ma conferma tutto in un colpo solo": la transazione resta unica e viene confermata una sola volta, pur tollerando il fallimento dei singoli elementi.

Due proprietà del meccanismo vanno tenute presenti. Un `commit` (o un `rollback` completo) cancella tutti i savepoint definiti fino a quel momento: un savepoint non sopravvive alla chiusura della transazione. Inoltre `rollback to savepoint` rilascia soltanto i lock acquisiti *dopo* il savepoint, mentre quelli acquisiti prima restano attivi fino alla fine della transazione — comportamento desiderabile nel pattern a lotti, ma da conoscere per non introdurre contese impreviste.

Al di fuori di questo scenario, la comparsa di savepoint sparsi nel codice è quasi sempre un segnale che i confini transazionali sono mal disegnati: se una porzione di lavoro ha bisogno di essere annullata indipendentemente, spesso è perché avrebbe dovuto vivere in una transazione a sé, incapsulata in una procedura separata. Il savepoint è la risposta giusta al problema "un lotto, molti elementi, un solo commit finale", non un sostituto di una corretta modularizzazione transazionale.

```sql
-- Errato: su una riga non valida si esegue un rollback completo, che annulla
-- anche tutte le righe valide già elaborate nella stessa transazione
declare
    k_STATUS_PENDING    constant    ext_crm_contacts.status%type    := 'PENDING';
    k_STATUS_IMPORTED   constant    ext_crm_contacts.status%type    := 'IMPORTED';
begin
    <<importa_contatti>>
    for r_contact in (
        select ctc.contact_id
             , ctc.email
          from ext_crm_contacts  ctc
         where ctc.status = k_STATUS_PENDING
    )
    loop
        begin
            insert into contacts (  contact_id
                                  , email
                                 )
            values (  r_contact.contact_id
                   , r_contact.email
                  );

            update ext_crm_contacts  ctc
               set ctc.status = k_STATUS_IMPORTED
             where ctc.contact_id = r_contact.contact_id;
        exception
            when others then
                rollback;   -- annulla l'intero batch, non solo la riga corrente
                lib_logging.log_error(i_text => sqlerrm);
        end;
    end loop importa_contatti;

    commit;
end;
/
```

```sql
-- Corretto: un savepoint prima di ogni riga permette di annullare solo il lavoro
-- della riga fallita e di proseguire; un unico commit conferma le righe valide
declare
    k_STATUS_PENDING    constant    ext_crm_contacts.status%type    := 'PENDING';
    k_STATUS_IMPORTED   constant    ext_crm_contacts.status%type    := 'IMPORTED';
begin
    <<importa_contatti>>
    for r_contact in (
        select ctc.contact_id
             , ctc.email
          from ext_crm_contacts  ctc
         where ctc.status = k_STATUS_PENDING
    )
    loop
        savepoint sp_contatto;

        begin
            insert into contacts (  contact_id
                                  , email
                                 )
            values (  r_contact.contact_id
                   , r_contact.email
                  );

            update ext_crm_contacts  ctc
               set ctc.status = k_STATUS_IMPORTED
             where ctc.contact_id = r_contact.contact_id;
        exception
            when others then
                rollback to savepoint sp_contatto;   -- annulla solo la riga corrente
                lib_logging.log_error(i_text => sqlerrm);
        end;
    end loop importa_contatti;

    commit;
end;
/
```

---

### Il rollback appartiene al chiamante, non al sottoprogramma

*Aspetti: Affidabilità, Verificabilità — Livello: Blocker*

Un `rollback` senza clausola annulla l'intera transazione corrente: non solo il lavoro del sottoprogramma che lo esegue, ma tutto ciò che il chiamante — e i chiamanti del chiamante — hanno scritto e non ancora committato nella stessa transazione. Per questo motivo vale per il `rollback` la stessa regola già stabilita per il `commit`: la decisione di confermare o annullare una transazione appartiene al modulo che possiede il confine transazionale, tipicamente l'unità di lavoro di livello più alto, e non a una procedura di basso livello o riutilizzabile.

Una procedura riutilizzabile non sa in quale transazione verrà invocata né cosa il chiamante abbia già fatto prima di chiamarla. Se al primo errore esegue un `rollback` completo, distrugge silenziosamente il lavoro del chiamante e rende il proprio comportamento imprevedibile a seconda del contesto di invocazione. Un `rollback` (come un `commit`) sepolto in un handler `when others` di una procedura condivisa è quasi sempre un difetto grave.

Quando una procedura ha davvero bisogno di garantire la *propria* atomicità — lasciare il database nello stato in cui l'ha trovato se il suo lavoro fallisce a metà — lo strumento corretto non è il `rollback` completo, ma il savepoint: si pone un savepoint all'ingresso, e nell'handler si esegue `rollback to savepoint` seguito da `raise`. In questo modo la procedura annulla soltanto ciò che ha fatto lei, non tocca il lavoro del chiamante, e ripropaga l'eccezione lasciando che sia il chiamante a decidere se annullare l'intera transazione o gestire l'errore in altro modo. La ripropagazione con `raise` è essenziale: annullare il proprio lavoro e poi ingoiare l'eccezione nasconderebbe il fallimento, un anti-pattern trattato nel capitolo sulla gestione delle eccezioni.

Va infine ricordata una garanzia che Oracle fornisce automaticamente e che rende superfluo gran parte del rollback difensivo: il *rollback a livello di istruzione*. Se una singola istruzione SQL solleva un errore, Oracle annulla gli effetti di quella sola istruzione, non dell'intera transazione — il resto del lavoro non committato resta valido e disponibile per l'handler. Confondere questo meccanismo implicito con un `rollback` di transazione porta a scrivere annullamenti manuali che fanno più danno di quanto risolvano.

```sql
-- Errato: la procedura riutilizzabile esegue un rollback completo in caso di errore,
-- annullando anche il lavoro non ancora committato del chiamante, e poi ingoia l'errore
create or replace
package body pkg_contacts
is
    procedure import_contact (  i_contact_id  in  ext_crm_contacts.contact_id%type  )
    is
        k_CONTACT_ID    constant    ext_crm_contacts.contact_id%type    := i_contact_id;
    begin
        insert into contacts (  contact_id
                              , email
                             )
        select ctc.contact_id
             , ctc.email
          from ext_crm_contacts  ctc
         where ctc.contact_id = k_CONTACT_ID;

        update ext_crm_contacts  ctc
           set ctc.status = 'IMPORTED'
         where ctc.contact_id = k_CONTACT_ID;
    exception
        when others then
            rollback;   -- annulla l'intera transazione del chiamante e nasconde l'errore
            lib_logging.log_error(i_text => sqlerrm);
    end import_contact;
end pkg_contacts;
/
```

```sql
-- Corretto: la procedura garantisce solo la propria atomicità locale con un savepoint
-- e ripropaga l'eccezione; la decisione sul commit o rollback resta al chiamante
create or replace
package body pkg_contacts
is
    procedure import_contact (  i_contact_id  in  ext_crm_contacts.contact_id%type  )
    is
        k_CONTACT_ID    constant    ext_crm_contacts.contact_id%type    := i_contact_id;
    begin
        savepoint sp_import_contact;

        insert into contacts (  contact_id
                              , email
                             )
        select ctc.contact_id
             , ctc.email
          from ext_crm_contacts  ctc
         where ctc.contact_id = k_CONTACT_ID;

        update ext_crm_contacts  ctc
           set ctc.status = 'IMPORTED'
         where ctc.contact_id = k_CONTACT_ID;
    exception
        when others then
            rollback to savepoint sp_import_contact;
            lib_logging.log_error(i_text => sqlerrm);
            raise;
    end import_contact;
end pkg_contacts;
/
```

---

## Locking esplicito

Nella maggior parte dei casi il locking in Oracle è implicito e automatico: ogni istruzione DML acquisisce un lock di riga sulle righe che modifica, i lettori non bloccano mai gli scrittori e gli scrittori non bloccano mai i lettori, e i lock vengono rilasciati alla fine della transazione. Questo modello, granulare e non bloccante in lettura, è uno dei punti di forza del database e va lasciato lavorare da solo finché possibile.

Il locking esplicito — `select ... for update` e, in casi estremi, `lock table` — è uno strumento deliberato per coordinare sessioni concorrenti quando la logica applicativa legge un dato, lo elabora e lo riscrive nella stessa transazione. È potente ma costoso: ogni lock esplicito serializza l'accesso alle righe coinvolte e le tiene bloccate fino al `commit` o al `rollback`. Da qui due principi che attraversano tutte le regole di questa sezione. Il primo è che il locking esplicito va usato solo quando serve davvero, e con l'ambito più ristretto possibile: si bloccano le righe che si intende modificare, non una riga in più. Il secondo è che una transazione che detiene lock deve essere la più breve possibile, il che si collega direttamente alla regola per cui il `commit` appartiene al chiamante e chiude l'unità di lavoro: tenere un lock aperto oltre il necessario — a maggior ragione attraverso l'attesa di un utente, come avviene nelle architetture stateless — è un errore di concorrenza, non una strategia. In quegli scenari, dove non si può mantenere una transazione aperta tra due interazioni, la protezione dal lost update si ottiene con il locking ottimistico basato su una colonna di versione — trattato nella sezione successiva — non con un lock esplicito.

Il locking a livello di tabella con `lock table ... in exclusive mode` è quasi sempre da evitare: serializza ogni accesso alla tabella, annullando il vantaggio del locking di riga di Oracle, ed è giustificato solo in rare operazioni massive di manutenzione. In tutti gli altri casi la granularità corretta è quella di riga.

### Proteggere le letture-prima-di-scrittura con `select ... for update`

*Aspetti: Affidabilità — Livello: Critical*

Il classico problema del *lost update* si verifica quando due sessioni leggono la stessa riga, ciascuna calcola un nuovo valore a partire da quello letto, e poi entrambe lo riscrivono: la seconda scrittura sovrascrive la prima, e l'aggiornamento di una delle due sessioni va perso senza alcun errore. È una condizione di corsa che in sviluppo non si manifesta quasi mai e in produzione, sotto concorrenza, produce dati silenziosamente errati.

Quando la logica prevede di leggere una riga e riscriverla nella stessa transazione, la lettura deve acquisire subito il lock con `select ... for update`. In questo modo la riga viene bloccata al momento della lettura e nessun'altra sessione può modificarla fino al `commit`, eliminando la finestra in cui il lost update può avvenire. Il lock va acquisito solo se si intende effettivamente aggiornare la riga: usare `for update` per una semplice lettura blocca le altre sessioni senza motivo.

La clausola che vincola il comportamento in caso di riga già occupata — mostrata qui come `wait 5` — è trattata nella regola successiva; il rilascio del lock, come per ogni transazione, spetta al `commit` del chiamante.

```sql
-- Errato: tra la lettura di balance e la sua riscrittura un'altra sessione può aggiornare
-- la stessa riga; il suo aggiornamento viene perso senza errore (lost update)
create or replace
package body pkg_accounts
is
    procedure withdraw (  i_account_id  in  accounts.account_id%type
                        , i_amount      in  accounts.balance%type
                       )
    is
        k_ACCOUNT_ID    constant    accounts.account_id%type    := i_account_id;
        k_AMOUNT        constant    accounts.balance%type       := i_amount;
        l_balance                   accounts.balance%type;
    begin
        select acc.balance
          into l_balance
          from accounts  acc
         where acc.account_id = k_ACCOUNT_ID;

        -- un'altra sessione può aggiornare balance proprio in questo istante

        update accounts  acc
           set acc.balance = l_balance - k_AMOUNT
         where acc.account_id = k_ACCOUNT_ID;
    end withdraw;
end pkg_accounts;
/
```

```sql
-- Corretto: 'for update' blocca la riga al momento della lettura; nessun'altra sessione
-- può modificarla fino al commit, eliminando la finestra di lost update
create or replace
package body pkg_accounts
is
    procedure withdraw (  i_account_id  in  accounts.account_id%type
                        , i_amount      in  accounts.balance%type
                       )
    is
        k_ACCOUNT_ID    constant    accounts.account_id%type    := i_account_id;
        k_AMOUNT        constant    accounts.balance%type       := i_amount;
        l_balance                   accounts.balance%type;
    begin
        select acc.balance
          into l_balance
          from accounts  acc
         where acc.account_id = k_ACCOUNT_ID
           for update of acc.balance wait 5;

        update accounts  acc
           set acc.balance = l_balance - k_AMOUNT
         where acc.account_id = k_ACCOUNT_ID;
        -- il commit, e con esso il rilascio del lock, spetta al chiamante
    end withdraw;
end pkg_accounts;
/
```

---

### Non attendere indefinitamente: usare `wait` o `nowait`

*Aspetti: Affidabilità, Efficienza — Livello: Critical*

Un `for update` senza qualificatori attende indefinitamente se la riga è già bloccata da un'altra sessione. La sessione che ha richiesto il lock resta appesa senza limite di tempo, e sotto carico questo comportamento si propaga: una catena di sessioni in attesa l'una dell'altra può esaurire i processi disponibili e degradare l'intero database. Un'attesa illimitata non è mai una strategia accettabile in codice di produzione.

Oracle offre due modi per vincolare l'attesa. `for update nowait` fallisce immediatamente con `ORA-00054` se la riga è occupata, lasciando all'applicazione la decisione su cosa fare. `for update wait <secondi>` attende al massimo il numero di secondi indicato e, allo scadere, solleva la stessa `ORA-00054`. In entrambi i casi l'errore va intercettato dichiarando un'eccezione con nome associata al codice `-54` tramite `pragma exception_init`, così da gestirlo in modo controllato — segnalando all'utente che la risorsa è temporaneamente occupata, oppure riprovando secondo una politica definita — invece di restare bloccati. La scelta tra `nowait` e `wait` dipende dal caso: `nowait` per operazioni interattive che devono rispondere subito, `wait` con una soglia breve per elaborazioni che possono tollerare una piccola attesa prima di rinunciare.

Il valore dei secondi nella clausola `wait` deve essere un intero letterale: non accetta variabili né costanti.

```sql
-- Errato: 'for update' senza qualificatori attende senza limite se la riga è bloccata;
-- la sessione resta appesa e, sotto carico, gli stalli si propagano
declare
    k_ORDER_ID  constant    orders.order_id%type        := 100;
    l_status                orders.order_status%type;
begin
    select ord.order_status
      into l_status
      from orders  ord
     where ord.order_id = k_ORDER_ID
       for update;
    -- elaborazione
end;
/
```

```sql
-- Corretto: 'wait 5' limita l'attesa a 5 secondi; allo scadere ORA-00054 viene
-- intercettata da un'eccezione con nome e gestita senza lasciare la sessione appesa
declare
    e_resource_busy exception;
    pragma          exception_init(e_resource_busy, -54);
    k_ORDER_ID      constant    orders.order_id%type        := 100;
    l_status                    orders.order_status%type;
begin
    select ord.order_status
      into l_status
      from orders  ord
     where ord.order_id = k_ORDER_ID
       for update wait 5;
    -- elaborazione
exception
    when e_resource_busy then
        lib_logging.log_error(i_text => 'Ordine temporaneamente bloccato: ' || sqlerrm);
        raise;
end;
/
```

---

### Restringere l'ambito del lock con `for update of`

*Aspetti: Efficienza, Manutenibilità — Livello: Major*

In una query che coinvolge più tabelle, un `for update` senza clausola `of` blocca le righe di *tutte* le tabelle referenziate, comprese quelle di sola lettura — tipicamente le tabelle di lookup o le tabelle padre lette solo per filtrare. Bloccare righe che non si intende modificare riduce inutilmente la concorrenza: altre sessioni che avrebbero legittimamente aggiornato quelle righe restano in attesa senza ragione.

Specificando `for update of <colonne>` si istruisce Oracle a bloccare soltanto le righe delle tabelle a cui appartengono le colonne elencate. Oltre a limitare l'ambito del lock alle sole righe che verranno effettivamente modificate, la clausola documenta l'intenzione: chi legge il codice capisce immediatamente quale tabella della join è il bersaglio dell'aggiornamento.

```sql
-- Errato: 'for update' senza 'of' blocca anche le righe di 'customers', letta solo
-- per filtrare e mai modificata: concorrenza ridotta senza motivo
declare
    k_COUNTRY   constant    customers.country_code%type := 'IT';
    cursor c_orders is
        select ord.order_id
             , ord.order_status
          from orders     ord
          join customers  cus  on  cus.customer_id = ord.customer_id
         where cus.country_code = k_COUNTRY
           for update;
begin
    null;
end;
/
```

```sql
-- Corretto: 'for update of ord.order_status' blocca soltanto le righe di 'orders';
-- le righe di 'customers' restano disponibili alle altre sessioni
declare
    k_COUNTRY   constant    customers.country_code%type := 'IT';
    cursor c_orders is
        select ord.order_id
             , ord.order_status
          from orders     ord
          join customers  cus  on  cus.customer_id = ord.customer_id
         where cus.country_code = k_COUNTRY
           for update of ord.order_status;
begin
    null;
end;
/
```

---

### Elaborazione concorrente a coda con `skip locked`

*Aspetti: Efficienza — Livello: Major*

Quando più processi worker leggono in parallelo da una tabella-coda per prendere in carico unità di lavoro — un pattern comune nelle tabelle `wrk_` di dispatch dei job — il `for update` ordinario li serializza: ogni worker attende il rilascio delle righe già bloccate dagli altri, e il parallelismo che si voleva ottenere svanisce.

La clausola `skip locked` risolve esattamente questo caso: invece di attendere una riga già bloccata, Oracle la salta e passa alla successiva libera. Ogni worker prende così in carico solo righe non contese, e i processi procedono davvero in parallelo senza bloccarsi a vicenda. È uno strumento pensato specificamente per la semantica a coda e va usato solo lì: fuori da quel contesto, saltare silenziosamente le righe bloccate significa ignorare dati che avrebbero dovuto essere elaborati.

```sql
-- Errato: più worker che leggono la coda con 'for update' si bloccano a vicenda,
-- perché ognuno attende le righe già prese in carico da un altro
declare
    k_STATUS_READY  constant    wrk_import_jobs.status%type := 'READY';
    k_BATCH_SIZE    constant    simple_integer              := 50;
    cursor c_jobs is
        select job.job_id
          from wrk_import_jobs  job
         where job.status = k_STATUS_READY
           and rownum <= k_BATCH_SIZE
           for update;
begin
    null;
end;
/
```

```sql
-- Corretto: 'skip locked' fa sì che ogni worker ignori le righe già bloccate da altri
-- e prenda in carico solo quelle libere, procedendo in parallelo
declare
    k_STATUS_READY  constant    wrk_import_jobs.status%type := 'READY';
    k_BATCH_SIZE    constant    simple_integer              := 50;
    cursor c_jobs is
        select job.job_id
          from wrk_import_jobs  job
         where job.status = k_STATUS_READY
           and rownum <= k_BATCH_SIZE
           for update skip locked;
begin
    null;
end;
/
```

---

### Acquisire i lock in un ordine coerente per evitare i deadlock

*Aspetti: Affidabilità — Livello: Critical*

Un deadlock (`ORA-00060`) si verifica quando due sessioni bloccano le stesse risorse in ordine opposto: la prima detiene il lock su A e attende B, la seconda detiene il lock su B e attende A, e nessuna delle due può proseguire. Oracle rileva la situazione e interrompe una delle due istruzioni con un errore, ma il deadlock resta un difetto applicativo da prevenire, non un evento da subire.

La causa quasi sempre è l'acquisizione dei lock in un ordine che dipende dai dati in ingresso anziché da un criterio fisso. Il caso tipico è un trasferimento tra due entità che blocca prima l'origine e poi la destinazione: due trasferimenti concorrenti in direzioni opposte si bloccano a vicenda. La soluzione è imporre un ordine di acquisizione deterministico, identico per tutte le sessioni — tipicamente l'ordine crescente della chiave primaria. Se ogni sessione blocca sempre prima la riga con l'identificativo più basso, la condizione ciclica che genera il deadlock non può formarsi.

```sql
-- Errato: i due conti vengono bloccati nell'ordine in cui arrivano (origine, poi destinazione);
-- un trasferimento A->B e uno concorrente B->A si bloccano a vicenda → ORA-00060
create or replace
package body pkg_transfers
is
    procedure transfer (  i_from_id  in  accounts.account_id%type
                        , i_to_id    in  accounts.account_id%type
                        , i_amount   in  accounts.balance%type
                       )
    is
        k_FROM_ID   constant    accounts.account_id%type    := i_from_id;
        k_TO_ID     constant    accounts.account_id%type    := i_to_id;
        l_balance               accounts.balance%type;
    begin
        select acc.balance into l_balance
          from accounts  acc
         where acc.account_id = k_FROM_ID
           for update;

        select acc.balance into l_balance
          from accounts  acc
         where acc.account_id = k_TO_ID
           for update;

        -- ... registrazione dei movimenti ...
    end transfer;
end pkg_transfers;
/
```

```sql
-- Corretto: si bloccano sempre prima l'id più basso e poi il più alto, con least/greatest;
-- tutte le sessioni acquisiscono i lock nello stesso ordine e il deadlock non può formarsi
create or replace
package body pkg_transfers
is
    procedure transfer (  i_from_id  in  accounts.account_id%type
                        , i_to_id    in  accounts.account_id%type
                        , i_amount   in  accounts.balance%type
                       )
    is
        k_FIRST_ID  constant    accounts.account_id%type    := least(i_from_id, i_to_id);
        k_SECOND_ID constant    accounts.account_id%type    := greatest(i_from_id, i_to_id);
        l_balance               accounts.balance%type;
    begin
        select acc.balance into l_balance
          from accounts  acc
         where acc.account_id = k_FIRST_ID
           for update;

        select acc.balance into l_balance
          from accounts  acc
         where acc.account_id = k_SECOND_ID
           for update;

        -- ... registrazione dei movimenti ...
    end transfer;
end pkg_transfers;
/
```

---

## Locking ottimistico

Il locking pessimistico della sezione precedente presuppone di poter tenere aperta una transazione — e quindi un lock — per tutta la durata dell'operazione di lettura, elaborazione e riscrittura. In un'architettura stateless questo presupposto cade: tra il momento in cui l'applicazione legge un dato e lo mostra all'utente e il momento in cui l'utente conferma la modifica passa un tempo indefinito, durante il quale nessuna transazione può restare aperta e nessun lock può essere mantenuto. Tenere un `for update` in attesa dell'interazione umana è escluso, perché bloccherebbe la riga per secondi o minuti, con effetti devastanti sulla concorrenza.

Il locking ottimistico risolve il problema ribaltando l'approccio: non si blocca nulla durante la lettura, ma al momento della scrittura si verifica se la riga è cambiata da quando è stata letta. Se non è cambiata, l'aggiornamento procede; se è cambiata, significa che un'altra sessione l'ha modificata nel frattempo e l'aggiornamento viene rifiutato, lasciando all'applicazione la scelta di ricaricare il dato aggiornato e riproporre la modifica. Il nome "ottimistico" riflette l'assunzione di fondo: i conflitti sono rari, quindi conviene pagarne il costo solo quando accadono davvero, invece di serializzare ogni accesso per prevenirli.

### Rilevare i conflitti con una colonna di versione

*Aspetti: Affidabilità, Portabilità — Livello: Critical*

Il meccanismo si appoggia a una colonna dedicata — un contatore di versione — presente nella tabella e letta insieme al resto dei dati. Quando l'applicazione rilegge la riga per aggiornarla, lo fa in una nuova transazione che confronta la versione letta in precedenza con quella attuale. Il confronto e l'incremento devono avvenire nella stessa istruzione `update`: la clausola `where` include la versione originale, e la `set` incrementa la colonna. Se nel frattempo un'altra sessione ha aggiornato la riga — incrementando a sua volta la versione — la condizione sulla versione non è più soddisfatta, nessuna riga viene aggiornata, e `sql%rowcount` vale zero. Quel valore è il segnale del conflitto: l'applicazione lo rileva e solleva un errore controllato invece di sovrascrivere silenziosamente la modifica altrui.

È essenziale che il controllo e l'incremento siano atomici, cioè parte della stessa `update`. Verificare la versione con una `select` separata e poi aggiornare in un secondo momento reintroduce esattamente la finestra di corsa che si voleva chiudere: tra la `select` di verifica e l'`update` un'altra sessione potrebbe ancora inserirsi.

L'eccezione che segnala il conflitto va dichiarata nella specifica del package, così da far parte dell'API pubblica: i chiamanti possono intercettarla per nome e reagire in modo appropriato — tipicamente ricaricando il dato e riproponendo la modifica all'utente, non ritentando alla cieca, perché il dato sottostante è cambiato e la decisione va rivalutata.

```sql
-- Errato: in un'architettura stateless la transazione di lettura è già chiusa quando arriva
-- l'aggiornamento; senza controllo di versione due modifiche concorrenti si sovrascrivono,
-- e 'for update' non è applicabile perché non si può tenere un lock durante l'attesa dell'utente
create or replace
package body pkg_orders
is
    procedure update_notes (  i_order_id  in  orders.order_id%type
                            , i_notes     in  orders.notes%type
                           )
    is
        k_ORDER_ID  constant    orders.order_id%type    := i_order_id;
        k_NOTES     constant    orders.notes%type       := i_notes;
    begin
        update orders  ord
           set ord.notes = k_NOTES
         where ord.order_id = k_ORDER_ID;
    end update_notes;
end pkg_orders;
/
```

```sql
-- Corretto: l'update confronta la versione letta con quella corrente e la incrementa nella
-- stessa istruzione; se nessuna riga viene aggiornata, un'altra sessione ha modificato la riga
-- nel frattempo e si segnala il conflitto invece di sovrascrivere
create or replace
package body pkg_orders
is
    procedure update_notes (  i_order_id      in  orders.order_id%type
                            , i_notes         in  orders.notes%type
                            , i_row_version   in  orders.row_version%type
                           )
    is
        k_ORDER_ID      constant    orders.order_id%type        := i_order_id;
        k_NOTES         constant    orders.notes%type           := i_notes;
        k_ROW_VERSION   constant    orders.row_version%type     := i_row_version;
        k_NONE          constant    simple_integer              := 0;
    begin
        update orders  ord
           set ord.notes       = k_NOTES
             , ord.row_version = ord.row_version + 1
         where ord.order_id    = k_ORDER_ID
           and ord.row_version = k_ROW_VERSION;

        if sql%rowcount = k_NONE
        then
            -- nessuna riga aggiornata: la versione non coincide più, la riga è stale
            lib_err.raise(i_error => lib_err.k_STALE_DATA);
        end if;
    end update_notes;
end pkg_orders;
/
```

In alternativa al contatore intero si può usare una colonna `timestamp` aggiornata a ogni modifica, applicando la stessa logica di confronto. Il contatore intero resta però preferibile: è immune alle ambiguità di precisione e di fuso orario che i timestamp possono introdurre, e rende il confronto banale e inequivocabile.

#### Perché una colonna esplicita e non `ora_rowscn`

Oracle espone la pseudo-colonna `ora_rowscn`, che restituisce lo SCN — System Change Number — dell'ultima modifica alla riga, e a prima vista sembra offrire un rilevamento dei conflitti gratuito, senza bisogno di aggiungere una colonna. In pratica è una scelta fragile, ed è la ragione per cui è da evitare.

Il problema principale è la granularità. Per impostazione predefinita `ora_rowscn` è tracciato a livello di blocco, non di riga: la modifica di una qualsiasi altra riga che risiede nello stesso blocco fisico cambia l'`ora_rowscn` anche della riga che ci interessa, pur non essendo stata toccata. Il risultato sono conflitti falsi — l'applicazione rileva una modifica che non è mai avvenuta e rifiuta un aggiornamento del tutto legittimo. Ottenere la precisione a livello di riga richiede di creare la tabella con la clausola `rowdependencies`, che può essere impostata solo alla creazione della tabella — non è aggiungibile in seguito — costa sei byte per riga, e se dimenticata fa ricadere silenziosamente il comportamento sulla granularità di blocco.

A questo si aggiungono due difetti ulteriori. Dopo un `commit`, il meccanismo di *delayed block cleanout* può lasciare temporaneamente l'`ora_rowscn` non valorizzato o impreciso finché il blocco non viene rivisitato, rendendo il valore instabile proprio nell'istante successivo alla scrittura. E `ora_rowscn` è un costrutto specifico di Oracle: legare la logica di controllo della concorrenza a una sua pseudo-colonna riduce la portabilità del codice, una delle caratteristiche di qualità che queste linee guida mirano a preservare.

Una colonna di versione esplicita non ha nessuno di questi difetti. È precisa per riga per costruzione, è stabile subito dopo il commit, è portabile, ed è auto-documentante: chi legge la struttura della tabella vede immediatamente che quella colonna serve al controllo ottimistico della concorrenza.
