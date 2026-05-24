# Uso del linguaggio — Variabili e tipi

Le decisioni prese nella sezione dichiarativa di un blocco PL/SQL hanno conseguenze che si estendono per tutta la vita del codice. Il tipo scelto per una variabile determina quali valori può contenere, come si comporta nei confronti e in aritmetica, e quanto il codice resisterà alle modifiche dello schema del database. Una dichiarazione sbagliata non produce necessariamente un errore immediato: spesso si manifesta come un bug sottile mesi o anni dopo, quando una colonna viene allargata, un database viene migrato o una variabile viene riutilizzata in modo non previsto.

Questo capitolo raccoglie le regole che governano la dichiarazione e l'uso delle variabili e dei tipi in PL/SQL, organizzate per categoria di dato.

---

## Regole generali

### Dichiarazioni ancorate alle colonne del database

*Aspetti: Manutenibilità, Affidabilità — Livello: Major*

Quando una variabile locale è destinata a contenere il valore di una colonna di una tabella, il suo tipo deve essere ancorato alla colonna con `%type`. Quando un record è destinato a contenere un'intera riga, il suo tipo deve essere ancorato alla tabella con `%rowtype`. Questo principio, già introdotto nel capitolo sullo stile del codice, è qui ribadito come regola esplicita perché la sua violazione non è mai innocua.

Se una colonna `last_name` viene allargata da `varchar2(50 char)` a `varchar2(100 char)`, una variabile dichiarata come `varchar2(50 char)` andrà in errore quando tenterà di ricevere un valore più lungo. Una variabile dichiarata con `%type` si aggiorna automaticamente alla ricompilazione. Non c'è ragione per preferire il tipo esplicito.

```sql
-- Errato: il tipo hardcoded si desincronizzerà dalla colonna prima o poi
create or replace
package body my_package
is
    procedure my_proc
    is
        l_last_name     varchar2(20 char);
    begin
        select emp.last_name
          into l_last_name
          from employees  emp
         where rownum = 1;
    exception
        when no_data_found
        then
            null;
    end my_proc;
end my_package;
/
```

```sql
-- Corretto: il tipo segue la colonna, qualunque modifica venga apportata allo schema
create or replace
package body my_package
is
    procedure my_proc
    is
        l_last_name     employees.last_name%type;
    begin
        select emp.last_name
          into l_last_name
          from employees  emp
         where rownum = 1;
    exception
        when no_data_found
        then
            null;
    end my_proc;
end my_package;
/
```

---

### Posizione unica per tipi e sottotipi

*Aspetti: Modificabilità — Livello: Minor*

I tipi definiti dall'utente — subtypes, tipi record, tipi collection — vanno dichiarati in un unico package dedicato, non ridefiniti localmente in ogni procedura o funzione che ne ha bisogno. Avere la definizione in un solo posto garantisce che qualsiasi modifica al tipo si propaghi automaticamente a tutto il codice che lo usa, senza dover cercare e aggiornare dichiarazioni sparse.

Lo stesso principio vale per i sottotipi di uso comune: se in più punti del codice si usa un campo testuale da mille caratteri, è meglio definire un subtype `big_string_type` nel package dei tipi e usarlo ovunque, piuttosto che scrivere `varchar2(1000 char)` ogni volta.

```sql
-- Errato: il subtype è definito localmente e non può essere condiviso
create or replace
package body my_package
is
    procedure my_proc
    is
        subtype big_string_type is varchar2(1000 char);
        l_note  big_string_type;
    begin
        l_note := some_function();
        do_something(l_note);
    end my_proc;
end my_package;
/
```

```sql
-- Corretto: il subtype vive nel package dei tipi ed è usabile ovunque
create or replace
package types_up
is
    subtype big_string_type is varchar2(1000 char);
end types_up;
/

create or replace
package body my_package
is
    procedure my_proc
    is
        l_note  types_up.big_string_type;
    begin
        l_note := some_function();
        do_something(l_note);
    end my_proc;
end my_package;
/
```

Definire sottotipi semanticamente significativi è particolarmente utile per tipi trasversali al progetto: un tipo per gli identificatori numerici (`id_type`), uno per i nomi degli oggetti Oracle (`ora_name_type`), uno per le stringhe a lunghezza massima (`max_vc2_type`). Il subtype documenta l'intenzione d'uso e aggiunge un livello di significato che il tipo grezzo non trasmette.

---

### Assegnazioni senza effetto sul flusso successivo

*Aspetti: Efficienza, Manutenibilità, Verificabilità — Livello: Major*

Assegnare un valore a una variabile locale e poi non usarlo mai prima che la variabile venga riassegnata o il blocco termini è uno spreco di risorse e una fonte di confusione. Il lettore del codice si aspetta che ogni assegnazione abbia uno scopo; se la variabile viene riscritta subito dopo senza che il valore precedente sia stato letto, quell'assegnazione non ha senso e probabilmente indica un bug: il valore che si voleva usare era diverso.

```sql
-- Errato: l_message viene costruita ma non viene mai inviata (assegnazione senza effetto)
create or replace
package body my_package
is
    procedure my_proc
    is
        k_EMPLOYEE_ID   constant    employees.employee_id%type  := 1042;
        k_HELLO         constant    types_up.big_string_type    := 'Hello, ';
        l_last_name                 employees.last_name%type;
        l_message                   types_up.big_string_type;
    begin
        select emp.last_name
          into l_last_name
          from employees  emp
         where emp.employee_id = k_EMPLOYEE_ID;

        l_message := k_HELLO || l_last_name;
        -- l_message costruita ma mai usata: message_api.send_message non viene chiamata
    exception
        when no_data_found
        then
            null;
    end my_proc;
end my_package;
/
```

```sql
-- Corretto: ogni assegnazione è seguita dall'uso del valore
create or replace
package body my_package
is
    procedure my_proc
    is
        k_EMPLOYEE_ID   constant    employees.employee_id%type  := 1042;
        k_HELLO         constant    types_up.big_string_type    := 'Hello, ';
        l_last_name                 employees.last_name%type;
        l_message                   types_up.big_string_type;
    begin
        select emp.last_name
          into l_last_name
          from employees  emp
         where emp.employee_id = k_EMPLOYEE_ID;

        l_message := k_HELLO || l_last_name;
        message_api.send_message(l_message);
    exception
        when no_data_found
        then
            null;
    end my_proc;
end my_package;
/
```

---

### Non inizializzare variabili con NULL

*Aspetti: Manutenibilità — Livello: Minor*

In PL/SQL ogni variabile è inizializzata implicitamente a `null` alla sua dichiarazione, a meno che non venga specificato un valore diverso. Scrivere `:= null` esplicitamente è ridondante e induce il lettore a chiedersi se ci sia una ragione particolare per quell'inizializzazione — ragione che non esiste.

```sql
-- Errato: l'inizializzazione a null è implicita, scriverla crea rumore senza aggiungere informazione
declare
    l_note  types_up.big_string_type := null;
begin
    dbms_output.put_line(l_note);
end;
/
```

```sql
-- Corretto: la dichiarazione senza valore lascia la variabile null come previsto
declare
    l_note  types_up.big_string_type;
begin
    dbms_output.put_line(l_note);
end;
/
```

La regola vale tanto per le variabili scalari quanto per i record e le collection. L'unica inizializzazione da scrivere esplicitamente è quella che assegna un valore diverso da `null`.

---

### Auto-assegnazione di variabili

*Aspetti: Manutenibilità — Livello: Blocker*

Assegnare una variabile a se stessa — `l_valore := l_valore` — è un'istruzione senza effetto che segnala invariabilmente un errore: o è un residuo di un copia/incolla in cui ci si è dimenticati di modificare il lato destro, o è semplicemente codice superfluo che non dovrebbe essere lì.

```sql
-- Errato: l_parallel_degree viene assegnata a se stessa invece di ricevere l_function_result
declare
    k_PARALLEL_DEGREE   constant    types_up.name%type  := 'parallel_degree';
    l_function_result               pls_integer;
    l_parallel_degree               pls_integer;
begin
    l_function_result := maintenance.get_config(k_PARALLEL_DEGREE);

    if ( l_function_result is not null )
    then
        l_parallel_degree := l_parallel_degree;  -- bug: copia/incolla non corretto
        do_something(l_parallel_degree);
    end if;
end;
/
```

```sql
-- Corretto: l_parallel_degree riceve il valore calcolato
declare
    k_PARALLEL_DEGREE   constant    types_up.name%type  := 'parallel_degree';
    l_function_result               pls_integer;
    l_parallel_degree               pls_integer;
begin
    l_function_result := maintenance.get_config(k_PARALLEL_DEGREE);

    if ( l_function_result is not null )
    then
        l_parallel_degree := l_function_result;
        do_something(l_parallel_degree);
    end if;
end;
/
```

---

### Confronti con NULL

*Aspetti: Portabilità, Affidabilità — Livello: Blocker*

In SQL e PL/SQL, `null` non è un valore: è l'assenza di valore. Qualsiasi confronto che coinvolge `null` con un operatore relazionale (`=`, `<>`, `>`, ecc.) restituisce sempre `null`, non `true` né `false`. Un `if (l_valore = null)` non sarà mai vero, nemmeno quando `l_valore` è effettivamente `null`. Per verificare se un valore è o non è `null` si usano esclusivamente `is null` e `is not null`.

```sql
-- Errato: il confronto con = null è sempre falso; l_valore non viene mai considerato null
declare
    l_valore    integer;
begin
    if ( l_valore = null )
    then
        null;
    end if;
end;
/
```

```sql
-- Corretto: is null verifica correttamente l'assenza di valore
declare
    l_valore    integer;
begin
    if ( l_valore is null )
    then
        null;
    end if;
end;
/
```

Questa non è una questione di stile: è un comportamento definito dallo standard SQL (logica a tre valori — true, false, unknown) e non cambia tra versioni di Oracle. Il codice che usa `= null` nei confronti produce risultati errati in modo silenzioso.

---

### Funzioni nella sezione dichiarativa

*Aspetti: Affidabilità — Livello: Critical*

Inizializzare una variabile locale chiamando una funzione direttamente nella sezione dichiarativa — `l_nome departments.department_name%type := department_api.name_by_id(in_id => 10)` — è un errore strutturale. Se la funzione solleva un'eccezione, questa non può essere catturata dal blocco `exception` del blocco corrente, perché la sezione dichiarativa viene eseguita prima che il blocco entri nella sua fase eseguibile. L'eccezione si propaga al blocco chiamante senza possibilità di gestione locale.

La soluzione è spostare la chiamata alla funzione nel corpo del blocco, racchiudendola in un sotto-blocco anonimo etichettato se si vuole isolare la gestione dell'errore.

```sql
-- Errato: se name_by_id solleva un'eccezione durante la dichiarazione,
-- il blocco exception sottostante non la vede mai
declare
    k_DEPT_ID           constant    integer                         := 100;
    l_department_name               departments.department_name%type
                                    := department_api.name_by_id(in_id => k_DEPT_ID);
begin
    dbms_output.put_line(l_department_name);
end;
/
```

```sql
-- Corretto: la chiamata avviene nel corpo del blocco, dove le eccezioni possono essere gestite
declare
    k_DEPT_ID           constant    integer                             := 100;
    k_UNKNOWN_NAME      constant    departments.department_name%type    := 'unknown';
    l_department_name               departments.department_name%type;
begin
    <<init>>
    begin
        l_department_name := department_api.name_by_id(in_id => k_DEPT_ID);
    exception
        when value_error
        then
            l_department_name := k_UNKNOWN_NAME;
    end init;

    dbms_output.put_line(l_department_name);
end;
/
```

La stessa regola vale per le costanti: assegnare a una costante il valore restituito da una funzione nella sezione dichiarativa è ugualmente pericoloso.

---

### Riuso di nomi tra scope annidati

*Aspetti: Affidabilità — Livello: Major*

Dichiarare in un blocco annidato una variabile con lo stesso nome di una variabile del blocco esterno nasconde la variabile esterna. Il compilatore non segnala l'ambiguità — la referenziazione funziona — ma il lettore del codice è costretto a tenere traccia di quale variabile sia attiva in quale scope, aumentando il rischio di errori e rendendo il codice molto più difficile da capire e da debuggare.

```sql
-- Errato: l_variable nel blocco interno nasconde l_variable del blocco esterno
begin
    <<main>>
    declare
        k_MAIN      constant    user_objects.object_name%type   := 'test_main';
        k_SUB       constant    user_objects.object_name%type   := 'test_sub';
        k_SEP       constant    user_objects.object_name%type   := ' - ';
        l_variable              user_objects.object_name%type   := k_MAIN;
    begin
        <<sub>>
        declare
            l_variable  user_objects.object_name%type := k_SUB;  -- nasconde main.l_variable
        begin
            dbms_output.put_line(l_variable || k_SEP || main.l_variable);
        end sub;
    end main;
end;
/
```

```sql
-- Corretto: ogni variabile ha un nome univoco che riflette il suo scope
begin
    <<main>>
    declare
        k_MAIN          constant    user_objects.object_name%type   := 'test_main';
        k_SUB           constant    user_objects.object_name%type   := 'test_sub';
        k_SEP           constant    user_objects.object_name%type   := ' - ';
        l_main_variable             user_objects.object_name%type   := k_MAIN;
    begin
        <<sub>>
        declare
            l_sub_variable  user_objects.object_name%type := k_SUB;
        begin
            dbms_output.put_line(l_sub_variable || k_SEP || l_main_variable);
        end sub;
    end main;
end;
/
```

---

### Identificatori tra virgolette

*Aspetti: Manutenibilità — Livello: Major*

Oracle permette di definire identificatori racchiudendoli tra virgolette doppie: `"my variable"`, `"My Constant"`. Questa sintassi rende l'identificatore case-sensitive e consente di usare caratteri altrimenti non ammessi nei nomi — spazi, caratteri speciali, parole chiave riservate. Non va usata.

Gli identificatori tra virgolette rendono il codice difficile da leggere, obbligano a ricordare il casing esatto ad ogni riferimento e violano le convenzioni di denominazione del progetto. Ogni identificatore che richiederebbe le virgolette per essere valido è un identificatore mal scelto: la soluzione è rinominarlo con un nome conforme alle convenzioni, non aggirare il problema con le virgolette.

```sql
-- Errato: identificatori tra virgolette, case-sensitive e incompatibili con le convenzioni
declare
    "sal+comm"      integer;
    "my constant"   constant    integer := 1;
    "my exception"  exception;
begin
    "sal+comm" := "my constant";
    do_something("sal+comm");
exception
    when "my exception"
    then
        null;
end;
/
```

```sql
-- Corretto: nomi conformi alle convenzioni, senza virgolette
declare
    l_sal_comm      integer;
    k_MY_CONSTANT   constant    integer := 1;
    e_my_exception  exception;
begin
    l_sal_comm := k_MY_CONSTANT;
    do_something(l_sal_comm);
exception
    when e_my_exception
    then
        null;
end;
/
```

---

## Tipi numerici

### NUMBER senza precisione

*Aspetti: Efficienza — Livello: Critical*

Il tipo `number` senza argomenti di precisione e scala occupa fino a 38 cifre significative, il massimo supportato da Oracle. Nella maggioranza dei casi questa precisione è eccessiva e comporta un consumo di memoria e di risorse di calcolo superiore al necessario. Quando si conosce l'intervallo di valori atteso — il che è quasi sempre vero per variabili locali significative — va usato un tipo più specifico.

Per valori interi si preferisce `pls_integer` o `simple_integer` (trattati nella sezione successiva). Per valori decimali si specifica la precisione: `number(15,2)` per importi monetari, `number(5,1)` per percentuali, e così via.

```sql
-- Errato: number senza precisione occupa risorse senza motivo
create or replace
package types_up
is
    subtype salary_type is number;
end types_up;
/
```

```sql
-- Corretto: la precisione riflette il dominio del dato
create or replace
package types_up
is
    subtype salary_type is number(8, 2);
end types_up;
/
```

---

### Aritmetica intera: PLS_INTEGER e SIMPLE_INTEGER

*Aspetti: Efficienza — Livello: Critical*

Per le operazioni aritmetiche su valori interi si usa `pls_integer` invece di `number`. `pls_integer` copre il range da -2.147.483.648 a 2.147.483.647 e usa l'aritmetica nativa del processore, che è significativamente più veloce dell'aritmetica in libreria usata da `number`. Usa inoltre meno memoria.

`simple_integer` è un sottotipo di `pls_integer` con due differenze rilevanti: è dichiarato `not null` per definizione, e in caso di overflow numerico non solleva un'eccezione ma va in wraparound silenzioso. Quando il valore di una variabile non sarà mai `null` e si è sicuri che il range non verrà superato — ad esempio un contatore in un loop limitato — `simple_integer` offre prestazioni ancora superiori, specialmente quando il codice è compilato in modalità nativa.

```sql
-- Errato: number(9,0) per un contatore intero è eccessivo in termini di risorse
declare
    l_result        number(9, 0)    := 0;
    k_UPPER_BOUND   constant        pls_integer := 1e8;
begin
    <<loop_calcolo>>
    for i in 1..k_UPPER_BOUND
    loop
        if ( i > 0 )
        then
            l_result := l_result + 1;
        end if;
    end loop loop_calcolo;

    dbms_output.put_line(l_result);
end;
/
```

```sql
-- Corretto: pls_integer per l_result, che è sempre intero e non null
declare
    l_result        pls_integer := 0;
    k_UPPER_BOUND   constant    pls_integer := 1e8;
begin
    <<loop_calcolo>>
    for i in 1..k_UPPER_BOUND
    loop
        if ( i > 0 )
        then
            l_result := l_result + 1;
        end if;
    end loop loop_calcolo;

    dbms_output.put_line(l_result);
end;
/
```

La scelta tra `pls_integer` e `simple_integer` si basa su due fattori: se il valore potrebbe essere `null` (in quel caso solo `pls_integer` è applicabile) e se il rischio di overflow deve essere rilevato come errore (in quel caso `simple_integer` non è adatto, perché il wraparound è silenzioso).

---

## Tipi di testo

### Evitare CHAR

*Aspetti: Affidabilità — Livello: Blocker*

`char` è un tipo a lunghezza fissa: una variabile o colonna `char(10)` contiene sempre esattamente 10 caratteri, riempiti con spazi a destra se il valore è più corto. Questo comportamento è fonte di errori sottili nei confronti: `'ABC'` e `'ABC       '` sono stringhe diverse per `varchar2`, ma confrontare una variabile `char` con una `varchar2` può produrre risultati inattesi perché Oracle applica regole di comparazione diverse a seconda dei tipi coinvolti.

In tutti i casi in cui si potrebbe essere tentati di usare `char`, `varchar2` è la scelta corretta. L'unica eccezione accettabile è quando si lavora con colonne di tipo `char` già esistenti nel database e non modificabili, nel qual caso si usa `%type` per allinearsi al tipo della colonna.

```sql
-- Errato: char(200) riempie sempre con spazi, causa confronti errati con varchar2
create or replace
package types_up
is
    subtype description_type is char(200);
end types_up;
/
```

```sql
-- Corretto: varchar2 si comporta come ci si aspetta
create or replace
package types_up
is
    subtype description_type is varchar2(200 char);
end types_up;
/
```

---

### Non usare VARCHAR

*Aspetti: Portabilità, Affidabilità — Livello: Blocker*

`varchar` è attualmente sinonimo di `varchar2` in Oracle, ma è riservato per un uso futuro con semantica di confronto diversa. Usarlo oggi significa esporre il codice a una potenziale incompatibilità con versioni future di Oracle Database. Si usa sempre e solo `varchar2`.

```sql
-- Errato: varchar è un alias deprecato con semantica potenzialmente divergente
create or replace
package types_up
is
    subtype description_type is varchar(200);
end types_up;
/
```

```sql
-- Corretto: varchar2 è il tipo testuale standard di Oracle
create or replace
package types_up
is
    subtype description_type is varchar2(200 char);
end types_up;
/
```

---

### Stringhe vuote e NULL

*Aspetti: Portabilità, Affidabilità — Livello: Blocker*

In Oracle Database una stringa vuota (`''`) e `null` sono attualmente trattate allo stesso modo: una stringa di lunghezza zero è equivalente a `null`. Questo è un comportamento specifico di Oracle, non conforme allo standard SQL, e Oracle stessa non garantisce che resti invariato nelle versioni future. Usare `''` con il significato di `null` crea codice che dipende da una quirk implementativa che potrebbe cambiare.

Quando si intende `null`, si scrive `null`. Quando si intende una stringa vuota in senso stretto, si documenta esplicitamente questa intenzione.

```sql
-- Errato: '' viene usato come null, ma il comportamento futuro non è garantito
create or replace
package body constants_up
is
    k_NULL_STRING   constant    types_up.big_string_type    := '';

    function null_string
        return varchar2
        deterministic
    is
    begin
        return (k_NULL_STRING);
    end null_string;
end constants_up;
/
```

```sql
-- Corretto: null viene usato direttamente, senza ambiguità
create or replace
package body constants_up
is
    function empty_string
        return varchar2
        deterministic
    is
    begin
        return (null);
    end empty_string;
end constants_up;
/
```

---

### Semantica dei caratteri in VARCHAR2

*Aspetti: Affidabilità — Livello: Blocker*

Una dichiarazione `varchar2(200)` senza specificare la semantica usa per default la semantica dei byte: il numero massimo di byte, non di caratteri. In un database con character set multibyte — come AL32UTF8, dove un singolo carattere può occupare fino a 4 byte — una variabile `varchar2(200)` potrebbe non contenere 200 caratteri, ma molti meno.

Ogni dichiarazione `varchar2` non ancorata con `%type` deve usare la semantica dei caratteri aggiungendo `char` dopo la dimensione: `varchar2(200 char)`. Questo garantisce che la variabile possa contenere il numero indicato di caratteri indipendentemente dal character set.

```sql
-- Errato: senza char, il limite è in byte — in multibyte potrebbe non bastare
create or replace
package types_up
is
    subtype description_type is varchar2(200);
end types_up;
/
```

```sql
-- Corretto: la semantica char garantisce 200 caratteri indipendentemente dal character set
create or replace
package types_up
is
    subtype description_type is varchar2(200 char);
end types_up;
/
```

Questa regola non si applica alle dichiarazioni ancorate con `%type`, che ereditano la semantica della colonna di riferimento.

---

## Tipo booleano

*Aspetti: Manutenibilità — Livello: Minor*

Quando una variabile rappresenta una condizione con due soli stati — vero o falso, attivo o inattivo, trovato o non trovato — il tipo corretto è `boolean`, non `pls_integer` o `number` usati come flag numerici. Il tipo `boolean` rende il codice autoesplicativo: `if (l_found)` è più chiaro di `if (l_found = 1)`, e non introduce il problema di doversi ricordare quale valore rappresenta quale stato.

```sql
-- Errato: pls_integer usato come flag booleano richiede una convenzione implicita (1=true, 0=false)
declare
    k_NEWFILE   constant    pls_integer := 1000;
    k_OLDFILE   constant    pls_integer := 500;
    l_bigger                pls_integer;
begin
    if ( k_NEWFILE < k_OLDFILE )
    then
        l_bigger := constants_up.k_NUMERIC_TRUE;
    else
        l_bigger := constants_up.k_NUMERIC_FALSE;
    end if;

    do_something(l_bigger);
end;
/
```

```sql
-- Corretto: boolean esprime direttamente l'intenzione
declare
    k_NEWFILE   constant    pls_integer := 1000;
    k_OLDFILE   constant    pls_integer := 500;
    l_bigger                boolean;
begin
    l_bigger := nvl(k_NEWFILE < k_OLDFILE, false);
    do_something(l_bigger);
end;
/
```
Il tipo `boolean` è pienamente utilizzabile nel codice PL/SQL. In SQL — come tipo di colonna nelle tabelle — non era disponibile fino a Oracle Database 23c (23ai), che ne ha esteso il supporto anche al livello relazionale: dalla versione 23c in poi è possibile definire colonne di tipo `boolean` direttamente nelle tabelle. Su versioni precedenti, per persistere un valore booleano in una colonna si usa tipicamente `varchar(1)` con valori `'Y'`/`'N'` oppure `number(1)` con valori `1`/`0`, convertendo al momento della lettura e della scrittura.

---

## Large Object — CLOB e BLOB

*Aspetti: Portabilità — Livello: Major*

I tipi `long` e `long raw` sono stati deprecati da Oracle dalla versione 8i. Presentano numerose limitazioni rispetto ai tipi LOB moderni — tra cui il vincolo di una sola colonna `long` per tabella, la non supportabilità in alcuni contesti SQL e la mancanza di funzioni di manipolazione — e il supporto potrebbe essere rimosso in versioni future.

Per i dati testuali di grandi dimensioni si usa `clob`; per i dati binari si usa `blob`.

```sql
-- Errato: long e long raw sono deprecati
declare
    l_testo     long;
    l_binario   long raw;
begin
    do_something(l_testo);
    do_something(l_binario);
end;
/
```

```sql
-- Corretto: clob e blob sono i tipi LOB moderni e supportati
declare
    l_testo     clob;
    l_binario   blob;
begin
    do_something(l_testo);
    do_something(l_binario);
end;
/
```

---

## Cursori variabile

*Aspetti: Modificabilità, Manutenibilità, Portabilità, Riusabilità — Livello: Minor*

Un ref cursor debole — un cursore aperto su una query determinata a runtime — non richiede la definizione di un tipo personalizzato. Oracle fornisce `sys_refcursor` come tipo built-in per questo scopo, e non c'è alcuna differenza funzionale tra `sys_refcursor` e un tipo debole definito dall'utente. Definire il proprio tipo equivale a creare manutenzione senza beneficio: il tipo va dichiarato, documentato e tenuto allineato con le aspettative dei chiamanti.

```sql
-- Errato: local_weak_cursor_type è identico a sys_refcursor e non aggiunge nulla
declare
    type local_weak_cursor_type is ref cursor;
    c_data  local_weak_cursor_type;
begin
    if ( configuration.use_employee )
    then
        open c_data for
            select emp.employee_id
                 , emp.first_name
                 , emp.last_name
              from employees  emp;
    else
        open c_data for
            select emp.emp_id
                 , emp.name
              from emp  emp;
    end if;
end;
/
```

```sql
-- Corretto: sys_refcursor è il tipo built-in equivalente, senza ridefinizione
declare
    c_data  sys_refcursor;
begin
    if ( configuration.use_employee )
    then
        open c_data for
            select emp.employee_id
                 , emp.first_name
                 , emp.last_name
              from employees  emp;
    else
        open c_data for
            select emp.emp_id
                 , emp.name
              from emp  emp;
    end if;
end;
/
```
