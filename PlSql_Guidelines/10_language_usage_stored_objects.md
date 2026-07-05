# Uso del linguaggio — Stored Objects

Questo capitolo raccoglie le regole applicabili agli oggetti PL/SQL compilati e memorizzati nel database: procedure, funzioni, package, trigger e sequenze. Le regole sono organizzate per tipo di oggetto, con una sezione iniziale di regole generali valide per qualsiasi sottoprogramma.

---

## Regole generali

### Usare la notazione nominale nelle chiamate ai sottoprogrammi

*Aspetti: Modificabilità, Manutenibilità — Livello: Major*

Chiamare un sottoprogramma passando i parametri in ordine posizionale crea una dipendenza implicita sulla firma: se un parametro viene aggiunto, rimosso o riordinato, tutte le chiamate posizionali devono essere aggiornate manualmente, spesso senza errore di compilazione. La notazione nominale — `i_param => valore` — rende ogni chiamata indipendente dall'ordine dei parametri e immediatamente leggibile.

La regola si applica a qualsiasi stored object con più di un parametro. Non è necessaria per le funzioni di sistema standard (`to_char`, `to_date`, `nvl`, `round` e simili).

```sql
-- Errato: ordine posizionale — fragile rispetto a modifiche della firma
declare
    r_employee  employees%rowtype;
    k_ID        constant    employees.employee_id%type  := 107;
begin
    pkg_employee.employee_by_id(r_employee, k_ID);
end;
/
```

```sql
-- Corretto: notazione nominale — esplicita e indipendente dall'ordine
declare
    r_employee  employees%rowtype;
    k_ID        constant    employees.employee_id%type  := 107;
begin
    pkg_employee.employee_by_id(
          o_row         => r_employee
        , i_employee_id  => k_ID
    );
end;
/
```

---

### Aggiungere il nome dell'unità alla parola chiave `end`

*Aspetti: Manutenibilità — Livello: Minor*

Ripetere il nome del sottoprogramma o del package dopo la parola chiave `end` — `end my_procedure;`, `end my_package;` — rende immediatamente chiaro quale blocco si sta chiudendo, senza dover risalire alla dichiarazione. È particolarmente utile nelle body di package con molti sottoprogrammi, dove la distanza tra l'intestazione e la chiusura può essere considerevole.

```sql
-- Errato: end anonimo — non è chiaro a quale unità si riferisce
create or replace
package body pkg_employee
is
    function employee_by_id
        ( i_employee_id    in  employees.employee_id%type )
        return employees%rowtype
    is
        k_ID        constant    employees.employee_id%type  := i_employee_id;
        r_employee              employees%rowtype;
    begin
        select  *
          into  r_employee
          from  employees  emp
         where  emp.employee_id = k_ID;

        return r_employee;
    exception
        when no_data_found then null;
        when too_many_rows then raise;
    end;      -- di quale funzione?
end;          -- di quale package?
/
```

```sql
-- Corretto: ogni end riporta il nome dell'unità
create or replace
package body pkg_employee
is
    function employee_by_id
        ( i_employee_id    in  employees.employee_id%type )
        return employees%rowtype
    is
        k_ID        constant    employees.employee_id%type  := i_employee_id;
        r_employee              employees%rowtype;
    begin
        select  *
          into  r_employee
          from  employees  emp
         where  emp.employee_id = k_ID;

        return r_employee;
    exception
        when no_data_found then null;
        when too_many_rows then raise;
    end employee_by_id;
end pkg_employee;
/
```

---

### Usare sempre `create or replace` al posto di `create`

*Aspetti: Manutenibilità — Livello: Major*

Usare `create` senza `or replace` causa un errore se l'oggetto esiste già, rendendo lo script non rieseguibile senza un `drop` preventivo. La forma `create or replace` sovrascrive l'oggetto esistente senza errori, mantiene i grant assegnati in precedenza e rende gli script di deploy idempotenti.

```sql
-- Errato: fallisce se il package esiste già
create package body pkg_employee
is
    -- ...
end pkg_employee;
/
```

```sql
-- Corretto: sostituisce l'oggetto se esiste, crea se non esiste
create or replace
package body pkg_employee
is
    -- ...
end pkg_employee;
/
```

---

### Non accedere a variabili esterne nelle funzioni e procedure locali

*Aspetti: Manutenibilità, Affidabilità, Verificabilità — Livello: Major*

Una funzione o procedura locale (dichiarata nella sezione `is ... begin` di un altro sottoprogramma) che legge variabili del blocco esterno le usa di fatto come variabili globali. Questa dipendenza è nascosta: la firma del sottoprogramma locale non la dichiara, e chi la legge non può sapere da dove provengono i dati. Aggiungere il valore come parametro esplicito rende la dipendenza visibile, il codice più testabile e il sottoprogramma locale riutilizzabile in altri contesti.

```sql
-- Errato: commission legge r_emp dal blocco esterno senza dichiararlo come parametro
create or replace
package body pkg_employee
as
    procedure calc_salary
        ( i_employee_id    in  employees.employee_id%type )
    is
        k_EMPLOYEE_ID   constant    employees.employee_id%type  := i_employee_id;
        r_emp                       employees%rowtype;

        function commission
            return employees.salary%type
        is
            l_commission    employees.salary%type := 0;
        begin
            if r_emp.commission_pct is not null then       -- variabile esterna
                l_commission := r_emp.salary * r_emp.commission_pct;
            end if;
            return l_commission;
        end commission;
    begin
        select  *
          into  r_emp
          from  employees  emp
         where  emp.employee_id = k_EMPLOYEE_ID;

        dbms_output.put_line(r_emp.salary + commission());
    end calc_salary;
end pkg_employee;
/
```

```sql
-- Corretto: i dati necessari sono passati come parametri espliciti
create or replace
package body pkg_employee
as
    procedure calc_salary
        ( i_employee_id    in  employees.employee_id%type )
    is
        k_EMPLOYEE_ID   constant    employees.employee_id%type  := i_employee_id;
        r_emp                       employees%rowtype;

        function commission
            (   i_salary       in  employees.salary%type
              , i_comm_pct     in  employees.commission_pct%type
            )
            return employees.salary%type
            deterministic
        is
            k_SALARY    constant    employees.salary%type           := i_salary;
            k_COMM_PCT  constant    employees.commission_pct%type   := i_comm_pct;
        begin
            if k_COMM_PCT is not null then
                return k_SALARY * k_COMM_PCT;
            end if;
            return 0;
        end commission;
    begin
        select  *
          into  r_emp
          from  employees  emp
         where  emp.employee_id = k_EMPLOYEE_ID;

        dbms_output.put_line(
            r_emp.salary + commission(
                  i_salary   => r_emp.salary
                , i_comm_pct => r_emp.commission_pct
            )
        );
    end calc_salary;
end pkg_employee;
/
```

---

### Rimuovere i sottoprogrammi locali non referenziati e i parametri non usati

*Aspetti: Manutenibilità, Efficienza — Livello: Major*

Le stesse regole che valgono per le variabili non utilizzate (capitolo Regole generali) si applicano ai sottoprogrammi locali e ai parametri: se una procedura o funzione locale non viene mai chiamata, è rumore che genera confusione su cosa il codice faccia. Se un parametro nella firma di un sottoprogramma non viene mai letto o scritto nel corpo, va rimosso — la sua presenza è fuorviante e può indurre il chiamante a passare un valore che non ha alcun effetto.

---

### Dichiarare sempre esplicitamente la modalità dei parametri

*Aspetti: Manutenibilità — Livello: Major*

La modalità predefinita di un parametro non dichiarato esplicitamente è `in`. Scrivere `in` (o `out`, o `in out`) rende la firma auto-documentante: chi la legge non deve ricordare il comportamento di default e non rischia di fraintendere la direzione del flusso dati.

```sql
-- Errato: la modalità dei parametri non è esplicita
create or replace
package pkg_employee
is
    procedure store
        (   io_id           in out  employees.employee_id%type
          , i_first_name           employees.first_name%type
          , i_last_name            employees.last_name%type
        );
end pkg_employee;
/
```

```sql
-- Corretto: ogni parametro ha la modalità dichiarata esplicitamente
create or replace
package pkg_employee
is
    procedure store
        (   io_id           in out  employees.employee_id%type
          , i_first_name   in      employees.first_name%type
          , i_last_name    in      employees.last_name%type
        );
end pkg_employee;
/
```

---

### Non usare `in out` per parametri che sono solo input o solo output

*Aspetti: Efficienza, Manutenibilità — Livello: Major*

Un parametro `in out` implica che il sottoprogramma legge il valore fornito dal chiamante e poi lo sovrascrive con un risultato. Se il corpo legge solo il parametro senza mai assegnargli un nuovo valore, la modalità corretta è `in`; se assegna senza mai leggere il valore iniziale, la modalità corretta è `out`. Usare `in out` quando non è necessario induce il chiamante a credere che il valore iniziale venga usato, quando invece non è così.

---

## Package

### Mantenere i package di dimensioni ridotte

*Aspetti: Efficienza, Manutenibilità — Livello: Major*

Oracle carica l'intero package in memoria la prima volta che viene invocato. Un package molto grande con decine di procedure e funzioni eterogenee occupa più SGA del necessario e aumenta il tempo di caricamento iniziale. La pratica corretta è raggruppare in un package solo i sottoprogrammi che operano sullo stesso contesto funzionale (ad esempio, tutto ciò che riguarda gli ordini, oppure tutto ciò che riguarda i dipendenti), e separare in package distinti le funzionalità non correlate.

---

### Usare la forward declaration per le funzioni e procedure private

*Aspetti: Modificabilità — Livello: Minor*

All'interno di un package body, un sottoprogramma privato può essere chiamato solo da sottoprogrammi dichiarati dopo di esso, a meno che non si usi una forward declaration — ovvero la sola firma, senza il corpo, posizionata in cima al package body. Le forward declaration permettono di ordinare i sottoprogrammi in modo logico (ad esempio, dalle operazioni pubbliche verso le private), indipendentemente dall'ordine in cui si chiamano a vicenda.

```sql
-- Errato: does_exist deve precedere del per poter essere chiamata da essa
create or replace
package body pkg_department
is
    function does_exist
        ( i_department_id  in  departments.department_id%type )
        return boolean
    is
        -- ...
    end does_exist;

    procedure del
        ( i_department_id  in  departments.department_id%type )
    is
        k_ID    constant    departments.department_id%type := i_department_id;
    begin
        if does_exist(i_department_id => k_ID) then
            delete from departments  dep
                  where dep.department_id = k_ID;
        end if;
    end del;
end pkg_department;
/
```

```sql
-- Corretto: la forward declaration permette di mettere del prima di does_exist
create or replace
package body pkg_department
is
    -- forward declaration
    function does_exist
        ( i_department_id  in  departments.department_id%type )
        return boolean;

    procedure del
        ( i_department_id  in  departments.department_id%type )
    is
        k_ID    constant    departments.department_id%type := i_department_id;
    begin
        if does_exist(i_department_id => k_ID) then
            delete from departments  dep
                  where dep.department_id = k_ID;
        end if;
    end del;

    function does_exist
        ( i_department_id  in  departments.department_id%type )
        return boolean
    is
        -- ...
    end does_exist;
end pkg_department;
/
```

---

### Non dichiarare variabili globali pubbliche nella specifica del package

*Aspetti: Affidabilità — Livello: Major*

Le variabili dichiarate nella specifica di un package (non all'interno di un sottoprogramma) sono accessibili da qualsiasi sessione con i permessi di esecuzione sul package. Chiunque può leggere o modificare direttamente questi valori, rendendo impossibile garantire la coerenza dello stato interno. La soluzione è dichiarare le variabili di stato nel package body e esporne l'accesso tramite funzioni getter e procedure setter, che possono applicare validazione e controllo degli accessi.

```sql
-- Errato: g_salary_increase è pubblica e modificabile da chiunque
create or replace
package pkg_employee
as
    g_salary_increase   lib_types.sal_increase_sbt;  -- variabile globale pubblica
end pkg_employee;
/
```

```sql
-- Corretto: la variabile è privata nel body; l'accesso avviene tramite getter/setter
create or replace
package pkg_employee
as
    procedure set_salary_increase
        ( i_increase   in  lib_types.sal_increase_sbt );

    function salary_increase
        return lib_types.sal_increase_sbt;
end pkg_employee;
/

create or replace
package body pkg_employee
as
    g_salary_increase   lib_types.sal_increase_sbt;  -- privata nel body

    procedure set_salary_increase
        ( i_increase   in  lib_types.sal_increase_sbt )
    is
        k_MIN   constant    lib_types.sal_increase_sbt := lib_constants.k_MIN_INCREASE;
        k_MAX   constant    lib_types.sal_increase_sbt := lib_constants.k_MAX_INCREASE;
    begin
        if i_increase between k_MIN and k_MAX then
            g_salary_increase := i_increase;
        end if;
    end set_salary_increase;

    function salary_increase
        return lib_types.sal_increase_sbt
    is
    begin
        return g_salary_increase;
    end salary_increase;
end pkg_employee;
/
```

---

### Non usare `return` nel blocco di inizializzazione del package

*Aspetti: Manutenibilità — Livello: Major*

Il blocco di inizializzazione di un package body — il blocco `begin ... end` che segue tutti i sottoprogrammi — serve a inizializzare variabili globali del package. L'istruzione `return` è sintatticamente valida in quel contesto, ma semanticamente non ha senso: se è l'ultima istruzione è superflua, se non lo è rende irraggiungibile tutto il codice successivo.

```sql
-- Errato: return interrompe l'inizializzazione, il codice successivo è morto
create or replace
package body pkg_employee
as
    g_salary_increase   lib_types.sal_increase_sbt;

    -- ... sottoprogrammi ...

begin
    g_salary_increase := lib_constants.k_MIN_INCREASE;
    return;                              -- superfluo o causa codice morto
    g_salary_increase := 0;             -- mai raggiunto
end pkg_employee;
/
```

```sql
-- Corretto: il blocco di inizializzazione non contiene return
create or replace
package body pkg_employee
as
    g_salary_increase   lib_types.sal_increase_sbt;

    -- ... sottoprogrammi ...

begin
    g_salary_increase := lib_constants.k_MIN_INCREASE;
end pkg_employee;
/
```

---

## Procedure

### Evitare procedure e funzioni standalone — usare i package

*Aspetti: Manutenibilità — Livello: Minor*

Le procedure e le funzioni standalone sono oggetti isolati nel database. I package, al contrario, raggruppano sottoprogrammi correlati in un'unica unità compilabile: modificare il body di un package non invalida gli oggetti che lo richiamano, mentre ricompilare una procedura standalone invalida tutti i suoi dipendenti. Per questo motivo ogni sottoprogramma dovrebbe far parte di un package, anche se il package contiene un solo elemento.

---

### Evitare `return` nelle procedure

*Aspetti: Manutenibilità, Verificabilità — Livello: Major*

Il `return` è sintatticamente valido nelle procedure, ma ha lo stesso effetto di un `goto`: interrompe il flusso in un punto intermedio e crea percorsi di uscita multipli. Il principio "un ingresso, un'uscita" rende il codice più semplice da tracciare e da testare. Se la logica richiede di terminare anticipatamente la procedura in certe condizioni, è preferibile strutturare il codice con condizionali espliciti che conducano all'unica uscita naturale alla fine del blocco.

---

### Assegnare sempre un valore ai parametri `out`

*Aspetti: Manutenibilità, Verificabilità — Livello: Blocker*

Un parametro dichiarato `out` comunica al chiamante che riceverà un valore prodotto dalla procedura. Se il codice esce dalla procedura senza aver assegnato il parametro — ad esempio perché un ramo condizionale non lo inizializza — il chiamante riceve `null` senza alcun segnale di errore. Ogni percorso di esecuzione della procedura deve garantire che tutti i parametri `out` ricevano un valore prima dell'uscita.

```sql
-- Errato: se l_message non viene costruito correttamente, o_greeting rimane null
create or replace
package body my_package
is
    procedure greet
        (   i_name         in  employees.first_name%type
          , o_greeting    out varchar2
        )
    is
        k_NAME      constant    employees.first_name%type   := i_name;
        k_HELLO     constant    lib_types.text_sbt           := 'Ciao, ';
        l_message               lib_types.text_sbt;
    begin
        if k_NAME is not null then
            l_message    := k_HELLO || k_NAME || '!';
            o_greeting := l_message;
        end if;
        -- se k_NAME è null, o_greeting non viene mai assegnato
    end greet;
end my_package;
/
```

```sql
-- Corretto: o_greeting viene assegnato in ogni ramo
create or replace
package body my_package
is
    procedure greet
        (   i_name         in  employees.first_name%type
          , o_greeting    out varchar2
        )
    is
        k_NAME      constant    employees.first_name%type   := i_name;
        k_HELLO     constant    lib_types.text_sbt           := 'Ciao, ';
        k_UNKNOWN   constant    lib_types.text_sbt           := 'Ospite';
    begin
        if k_NAME is not null then
            o_greeting := k_HELLO || k_NAME   || '!';
        else
            o_greeting := k_HELLO || k_UNKNOWN || '!';
        end if;
    end greet;
end my_package;
/
```

---

## Funzioni

### Il `return` deve essere l'ultima istruzione della funzione

*Aspetti: Manutenibilità — Livello: Major*

Il `return` in posizione intermedia interrompe il flusso della funzione prima della fine del corpo, lasciando codice irraggiungibile dopo di esso e rendendo il percorso di esecuzione difficile da seguire. La forma corretta è accumulare il risultato in una variabile locale e restituirlo con un unico `return` alla fine.

```sql
-- Errato: return in mezzo al loop; il codice dopo il loop è irraggiungibile
create or replace
package body my_package
is
    function my_function
        (   i_from     in  pls_integer
          , i_to       in  pls_integer
        )
        return pls_integer
        deterministic
    is
        l_result    pls_integer := i_from;
    begin
        <<for_loop>>
        for i in i_from..i_to
        loop
            l_result := l_result + i;
            if i = i_to then
                return l_result;        -- return anticipato nel loop
            end if;
        end loop for_loop;

        return l_result;                -- mai raggiunto
    end my_function;
end my_package;
/
```

```sql
-- Corretto: un solo return alla fine
create or replace
package body my_package
is
    function my_function
        (   i_from     in  pls_integer
          , i_to       in  pls_integer
        )
        return pls_integer
        deterministic
    is
        l_result    pls_integer := i_from;
    begin
        <<for_loop>>
        for i in i_from..i_to
        loop
            l_result := l_result + i;
        end loop for_loop;

        return l_result;
    end my_function;
end my_package;
/
```

---

### Usare al massimo un `return` all'interno di una funzione

*Aspetti: Manutenibilità, Verificabilità — Livello: Major*

Avere più istruzioni `return` in una funzione crea percorsi di uscita multipli che rendono difficile ragionare sul comportamento del codice. La forma preferita è raccogliere il risultato in una variabile locale e restituirlo con un unico `return` alla fine, eventualmente con la gestione delle eccezioni che si limita anch'essa a restituire il valore appropriato.

```sql
-- Errato: due return in rami distinti
create or replace
package body my_package
is
    function my_function
        ( i_value  in  pls_integer )
        return boolean
        deterministic
    is
        k_YES   constant    pls_integer := 1;
    begin
        if i_value = k_YES then
            return true;
        else
            return false;
        end if;
    end my_function;
end my_package;
/
```

```sql
-- Corretto: risultato accumulato in variabile, un solo return
create or replace
package body my_package
is
    function my_function
        ( i_value  in  pls_integer )
        return boolean
        deterministic
    is
        k_YES       constant    pls_integer := 1;
        l_result                boolean;
    begin
        l_result := (i_value = k_YES);
        return l_result;
    end my_function;
end my_package;
/
```

---

### Non usare parametri `out` nelle funzioni

*Aspetti: Riusabilità — Livello: Major*

Una funzione con parametri `out` non può essere usata direttamente nelle istruzioni SQL, perché SQL non supporta la restituzione di valori tramite parametri di output. Se una funzione ha bisogno di restituire più di un valore, le alternative sono: usare una procedura, restituire un record, oppure suddividere la logica in più funzioni indipendenti.

```sql
-- Errato: o_date impedisce l'uso della funzione in SQL
create or replace
package body my_package
is
    function my_function
        ( o_date  out date )
        return boolean
        deterministic
    is
    begin
        o_date := sysdate;
        return true;
    end my_function;
end my_package;
/
```

```sql
-- Corretto: la funzione restituisce solo attraverso la clausola return
create or replace
package body my_package
is
    function current_date_value
        return date
        deterministic
    is
    begin
        return sysdate;
    end current_date_value;
end my_package;
/
```

---

### Non restituire `null` da una funzione booleana

*Aspetti: Affidabilità, Verificabilità — Livello: Blocker*

Una funzione booleana che può restituire `null` obbliga ogni chiamante a gestire tre stati invece di due: `true`, `false` e `null`. Questo rende l'uso della funzione più complesso e soggetto a errori, perché `if my_function() then` non entra nel ramo `then` quando il risultato è `null`, e questo comportamento è spesso inatteso.

Le funzioni booleane devono restituire sempre `true` o `false`, mai `null`.

---

### Dichiarare le funzioni `deterministic` quando appropriato

*Aspetti: Efficienza — Livello: Major*

Una funzione è deterministica se, per gli stessi valori dei parametri di ingresso, restituisce sempre lo stesso risultato. Dichiarare una funzione con la keyword `deterministic` permette a Oracle di ottimizzarne l'esecuzione nelle query SQL: invece di invocare la funzione una volta per ogni riga del risultato, Oracle può eseguirla una sola volta per ogni distinto insieme di parametri e riutilizzare il valore nelle righe successive.

La keyword va usata solo quando la funzione è effettivamente deterministica: non dipende da variabili globali, da tabelle del database, da `sysdate` o da qualsiasi altra fonte di stato mutabile.

```sql
-- Errato: la funzione è deterministica ma non dichiarata tale
create or replace
package pkg_department
is
    function name_by_id
        ( i_department_id  in  departments.department_id%type )
        return departments.department_name%type;
end pkg_department;
/
```

```sql
-- Corretto: la keyword deterministic abilita le ottimizzazioni del query optimizer
create or replace
package pkg_department
is
    function name_by_id
        ( i_department_id  in  departments.department_id%type )
        return departments.department_name%type
        deterministic;
end pkg_department;
/
```

---

## Package di sistema Oracle

### Qualificare sempre i package Oracle con il nome dello schema `sys`

*Aspetti: Sicurezza — Livello: Major*

I nomi dei package forniti da Oracle — `dbms_output`, `dbms_utility`, `utl_file` e simili — sono pubblicamente noti. È tecnicamente possibile creare package utente con gli stessi nomi che eseguono operazioni diverse. Qualificare sempre questi package con il prefisso `sys.` garantisce che venga chiamato il package Oracle originale, indipendentemente da eventuali oggetti omonimi presenti nello schema dell'utente corrente.

```sql
-- Errato: dbms_output potrebbe essere oscurato da un package omonimo nello schema
begin
    dbms_output.put_line('Hello World');
end;
/
```

```sql
-- Corretto: il prefisso sys. garantisce il riferimento al package Oracle
begin
    sys.dbms_output.put_line('Hello World');
end;
/
```

---

## Trigger

### Evitare i trigger a cascata

*Aspetti: Manutenibilità, Verificabilità — Livello: Major*

Un trigger che modifica una tabella sulla quale esistono altri trigger attiva quei trigger in modo implicito. Il comportamento che ne risulta — catene di trigger che si innescano a vicenda — è difficile da prevedere, da testare e da diagnosticare in caso di errore. La logica di aggiornamento delle tabelle correlate deve essere esplicitata nel codice applicativo, non nascosta in catene di trigger.

```sql
-- Errato: dept_br_u modifica departments_hist, che potrebbe avere propri trigger
create or replace
trigger dept_br_u
before update on departments
for each row
begin
    insert into departments_hist
        (   department_id
          , department_name
          , modification_date
        )
    values
        (   :old.department_id
          , :old.department_name
          , sysdate
        );
    -- questo insert può innescare trigger su departments_hist
end;
/
```

```sql
-- Corretto: ogni trigger si limita a operare sulla propria tabella
create or replace
trigger dept_br_u
before update on departments
for each row
begin
    insert into departments_hist
        (   department_id
          , department_name
          , modification_date
        )
    values
        (   :old.department_id
          , :old.department_name
          , sysdate
        );
end;
/
```

---

### Non usare più clausole `update of` separate nella definizione dell'evento

*Aspetti: Manutenibilità, Affidabilità, Verificabilità — Livello: Blocker*

Un trigger può essere attivato da un `update` limitato a specifiche colonne tramite `update of col1, col2`. Se si scrivono più clausole `update of` separate da `or` — `update of col1 or update of col2` — solo l'ultima viene effettivamente considerata da Oracle, senza alcun messaggio di errore o avvertimento. Il trigger non si attiverà per le colonne delle clausole precedenti, generando un bug silenzioso.

La forma corretta è una singola clausola `update of` con le colonne separate da virgole.

```sql
-- Errato: solo update of department_name è effettivo; department_id viene ignorato
create or replace
trigger dept_br_u
before update of department_id
    or update of department_name   -- solo questa viene considerata
on departments
for each row
begin
    null;
end;
/
```

```sql
-- Corretto: una sola clausola update of con tutte le colonne
create or replace
trigger dept_br_u
before update of department_id, department_name
on departments
for each row
begin
    null;
end;
/
```

---

### Usare un trigger separato per ogni evento DML

*Aspetti: Manutenibilità, Verificabilità — Livello: Major*

Un trigger che gestisce `insert`, `update` e `delete` nello stesso corpo — tramite blocchi `if inserting`, `if updating`, `if deleting` — è difficile da testare e da manutenere: modificare la logica per un evento richiede di lavorare su un unico oggetto che contiene anche la logica degli altri. La pratica corretta è un trigger per evento, ciascuno con responsabilità ben definita.

L'eccezione è ammessa quando la maggior parte della logica è comune a tutti gli eventi e solo piccole porzioni sono specifiche: in quel caso si può usare un trigger unico, oppure un trigger per evento che chiama una procedura comune.

Un'ulteriore ragione per separare gli eventi riguarda l'assegnazione alla chiave primaria: se un trigger assegna la chiave primaria in un blocco `if inserting` ma il trigger gestisce anche `update`, Oracle acquisisce un lock sulle tabelle figlie anche per le operazioni di update, dove l'assegnazione non avviene. Un trigger separato per il solo `insert` elimina questo overhead.

```sql
-- Errato: un solo trigger per insert e update, con assegnazione della PK
create or replace
trigger dept_briu
before insert or update on departments
for each row
begin
    if inserting then
        :new.department_id := department_seq.nextval;
        :new.created_date  := sysdate;
    end if;
    if updating then
        :new.changed_date  := sysdate;
    end if;
end;
/
```

```sql
-- Corretto: trigger separati per insert e update
create or replace
trigger dept_br_i
before insert on departments
for each row
begin
    :new.department_id := department_seq.nextval;
    :new.created_date  := sysdate;
end;
/

create or replace
trigger dept_br_u
before update on departments
for each row
begin
    :new.changed_date := sysdate;
end;
/
```

---

## Sequenze

### Non usare SQL per leggere i valori delle sequenze da PL/SQL

*Aspetti: Efficienza, Manutenibilità — Livello: Critical*

Prima di Oracle 11g era necessario usare `select sequence.nextval from dual` per leggere il valore successivo di una sequenza in PL/SQL, con il conseguente context switch tra il motore PL/SQL e quello SQL. Da Oracle 11g è possibile usare la sequenza direttamente nell'assegnazione PL/SQL — `l_var := my_seq.nextval` — eliminando il context switch e rendendo il codice più leggibile. Lo stesso vale per `sysdate` e `systimestamp`.

```sql
-- Errato: context switch inutile tra PL/SQL e SQL
declare
    l_employee_id   employees.employee_id%type;
begin
    select  employees_seq.nextval
      into  l_employee_id
      from  dual;

    my_package.do_something(i_id => l_employee_id);
end;
/
```

```sql
-- Corretto: assegnazione diretta senza context switch (Oracle 11g+)
declare
    l_employee_id   employees.employee_id%type;
begin
    l_employee_id := employees_seq.nextval;
    my_package.do_something(i_id => l_employee_id);
end;
/
```
