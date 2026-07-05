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
    k_SQL       constant    lib_types.big_string_sbt :=
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
package body pkg_employee
as
    procedure upd_salary
        (   i_employee_id   in      employees.employee_id%type
          , i_increase_pct  in      lib_types.percentage_sbt
          , o_new_salary    out     employees.salary%type
        )
    is
        k_EMPLOYEE_ID   constant    employees.employee_id%type  := i_employee_id;
        k_INCREASE_PCT  constant    lib_types.percentage_sbt     := i_increase_pct;
        k_SQL           constant    lib_types.big_string_sbt    :=
            'update employees
                set salary = salary + (salary / 100 * :1)
              where employee_id = :2
          returning salary into :3';
    begin
        execute immediate k_SQL
            using k_INCREASE_PCT, k_EMPLOYEE_ID, out o_new_salary;
    end upd_salary;
end pkg_employee;
/
```

```sql
-- Corretto: il valore restituito dalla DML va in returning into
create or replace
package body pkg_employee
as
    procedure upd_salary
        (   i_employee_id   in      employees.employee_id%type
          , i_increase_pct  in      lib_types.percentage_sbt
          , o_new_salary    out     employees.salary%type
        )
    is
        k_EMPLOYEE_ID   constant    employees.employee_id%type  := i_employee_id;
        k_INCREASE_PCT  constant    lib_types.percentage_sbt     := i_increase_pct;
        k_SQL           constant    lib_types.big_string_sbt    :=
            'update employees
                set salary = salary + (salary / 100 * :1)
              where employee_id = :2
          returning salary into :3';
    begin
        execute immediate k_SQL
            using k_INCREASE_PCT, k_EMPLOYEE_ID
            returning into o_new_salary;
    end upd_salary;
end pkg_employee;
/
```

---

## Usare bind variables per i valori nel SQL dinamico

*Aspetti: Sicurezza, Efficienza — Livello: Blocker*

Quando si costruisce un'istruzione SQL dinamica, ogni valore da passare come parametro — un filtro nel `where`, un dato in `values`, un argomento di `set` — deve essere separato dal testo SQL tramite bind variables: segnaposto nella forma `:nome` nel testo dell'istruzione, associati poi ai valori effettivi nella clausola `using`. Concatenare i valori direttamente nel testo è sbagliato per due ragioni distinte, entrambe con conseguenze gravi.

La prima è la sicurezza. Un valore concatenato viene interpretato da Oracle come parte del codice SQL: se proviene dall'esterno — da un parametro di un'API, da un campo in una tabella di configurazione, da un input fornito dall'utente — un valore costruito con intenzione malevola può alterare la struttura della query. Un filtro `where status = 'ACTIVE'` diventa `where status = '' or '1'='1'` se il valore passato è `' or '1'='1`, restituendo tutte le righe indipendentemente dalla condizione originale. Nella sua forma più aggressiva, il pattern può essere usato per eseguire istruzioni arbitrarie. Questa vulnerabilità è nota come SQL injection, e il suo impatto potenziale va dalla fuga di dati alla corruzione o all'eliminazione completa del contenuto del database.

La seconda ragione è la performance. Ogni variazione nel testo dell'istruzione SQL — anche di un singolo carattere — produce una stringa che Oracle non riconosce come già analizzata e deve compilare da zero: hard parse, con calcolo del piano di esecuzione e allocazione di strutture in shared pool. Con i bind variables il testo è sempre identico indipendentemente dal valore: Oracle analizza la query una sola volta e riutilizza il piano per tutte le esecuzioni successive (soft parse). In sistemi ad alto volume, la differenza si misura in contesa sulla shared pool e in tempi di risposta.

```sql
-- Errato: il valore viene concatenato nel testo SQL;
-- un input come ''' or ''1''=''1' bypassa il filtro e restituisce tutte le righe
create or replace
package body pkg_employee
is
    function search_by_status
        ( i_status in varchar2 )
        return sys_refcursor
    is
        k_SQL   constant    lib_types.big_string_sbt :=
              'select emp.employee_id'
           || '     , emp.last_name'
           || '     , emp.salary'
           || '  from employees  emp'
           || ' where emp.status = ''' || i_status || '''';
        c_result    sys_refcursor;
    begin
        open c_result for k_SQL;
        return c_result;
    end search_by_status;
end pkg_employee;
/
```

```sql
-- Corretto: il valore è passato come bind variable;
-- qualsiasi contenuto di i_status viene trattato come dato, mai come codice
create or replace
package body pkg_employee
is
    function search_by_status
        ( i_status in employees.status%type )
        return sys_refcursor
    is
        k_SQL   constant    lib_types.big_string_sbt :=
              'select emp.employee_id'
           || '     , emp.last_name'
           || '     , emp.salary'
           || '  from employees  emp'
           || ' where emp.status = :status';
        c_result    sys_refcursor;
    begin
        open c_result for k_SQL using i_status;
        return c_result;
    end search_by_status;
end pkg_employee;
/
```

Quando l'istruzione richiede più bind variables, si usano nomi distinti — `:dept_id`, `:status` — invece di indici posizionali come `:1`, `:2`. I nomi espliciti rendono la corrispondenza tra il testo SQL e la clausola `using` immediatamente leggibile e riducono il rischio di errori nell'ordinamento dei parametri. Se lo stesso segnaposto compare più volte nel testo SQL, in `execute immediate` il valore corrispondente va ripetuto nella clausola `using` per ogni occorrenza; con `open ... for` il segnaposto viene invece risolto una sola volta anche se compare in più punti.

---

## Usare `dbms_assert` per gli identificatori dinamici

*Aspetti: Sicurezza — Livello: Blocker*

I bind variables risolvono il problema dell'injection per i valori — stringhe, numeri, date — ma non possono essere usati per le parti strutturali dell'istruzione SQL: nomi di tabella, di colonna, di schema o di altri oggetti del database. Questi elementi devono essere noti al parser prima dell'esecuzione e non possono essere sostituiti da segnaposto. Quando un nome di oggetto viene determinato a runtime, l'unica alternativa è la concatenazione diretta nel testo SQL — ma concatenare un identificatore non validato ha le stesse implicazioni di sicurezza della concatenazione di valori: un input costruito ad arte può alterare la struttura dell'istruzione.

Oracle fornisce il package `sys.dbms_assert` per validare gli identificatori prima che vengano inclusi nel testo SQL. Le funzioni del package verificano il formato e, in alcuni casi, l'esistenza dell'oggetto nel dizionario dati, sollevando un'eccezione specifica (`ORA-44xxx`) se la stringa non supera la verifica. Un identificatore passato attraverso `dbms_assert` è garantito essere un nome sintatticamente valido — o un oggetto realmente esistente — prima di finire nel codice SQL.

| Funzione | Verifica | Ambito d'uso tipico |
|---|---|---|
| `dbms_assert.sql_object_name(str)` | Il nome esiste nel dizionario dati | Nomi di tabella, vista, sequenza che devono esistere |
| `dbms_assert.schema_name(str)` | Lo schema esiste nel database | Nomi di schema con cui qualificare gli oggetti |
| `dbms_assert.simple_sql_name(str)` | Il nome è un identificatore SQL semplice valido (no punti, no spazi) | Nomi di colonna o di oggetti locali |
| `dbms_assert.qualified_sql_name(str)` | Il nome è un identificatore qualificato valido (`schema.oggetto`) | Riferimenti con prefisso di schema |
| `dbms_assert.enquote_name(str, capitalize)` | Racchiude il nome tra doppi apici, opzionalmente maiuscolizzandolo | Identificatori che contengono caratteri non standard |
| `dbms_assert.enquote_literal(str)` | Racchiude la stringa tra apici singoli, raddoppiando quelli interni | Letterali stringa da includere nel testo SQL senza bind variable |
| `dbms_assert.noop(str)` | Nessuna verifica — restituisce la stringa invariata | Quando si documenta esplicitamente la scelta di non validare |

```sql
-- Errato: il nome della tabella viene concatenato senza validazione;
-- un input come 'employees--' potrebbe alterare il comportamento dell'istruzione
create or replace
package body lib_maintenance
is
    procedure count_table_rows
        (   i_table_name in  varchar2
          , o_row_count  out pls_integer
        )
    is
        k_SQL   constant    lib_types.big_string_sbt :=
            'select count(*) from ' || i_table_name;
    begin
        execute immediate k_SQL
            into o_row_count;
    end count_table_rows;
end lib_maintenance;
/
```

```sql
-- Corretto: dbms_assert.sql_object_name è chiamata nel corpo del blocco,
-- non nella sezione dichiarativa: l'eccezione ORA-44002 può così essere
-- intercettata dall'handler locale invece di propagarsi al chiamante
create or replace
package body lib_maintenance
is
    procedure count_table_rows
        (   i_table_name in  varchar2
          , o_row_count  out pls_integer
        )
    is
        l_table             lib_types.big_string_sbt;
        l_sql               lib_types.big_string_sbt;
        e_invalid_object    exception;
        pragma              exception_init(e_invalid_object, -44002);
    begin
        l_table     := sys.dbms_assert.sql_object_name(i_table_name);
        l_sql       := 'select count(*) from ' || l_table;

        execute immediate l_sql
            into o_row_count;
    exception
        when e_invalid_object then
            lib_err.raise(i_error => lib_err.k_INVALID_TABLE_NAME);
    end count_table_rows;
end lib_maintenance;
/
```

`dbms_assert` è una difesa in profondità contro l'injection, non un sostituto del controllo degli accessi. `sql_object_name` verifica che la stringa corrisponda a un oggetto esistente nel dizionario dati, non che il chiamante abbia il diritto di operarvi: un utente che conosce il nome di una tabella su cui ha accesso può comunque passarlo come parametro. Il controllo degli accessi rimane responsabilità dei privilege Oracle e della logica applicativa.

`dbms_assert.noop` non esegue alcuna validazione ma serve come documentazione esplicita dell'intenzione: indica che il programmatore ha valutato il rischio e ha deliberatamente scelto di non validare — ad esempio perché l'identificatore proviene esclusivamente da una costante interna, non da input esterno. Usarlo esplicitamente è preferibile a una concatenazione silenziosa, perché rende visibile il ragionamento e facilita la revisione del codice.
