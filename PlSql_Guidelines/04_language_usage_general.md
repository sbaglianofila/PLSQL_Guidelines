# Uso del linguaggio — Regole generali

Le sezioni precedenti hanno definito come nominare gli oggetti e come formattare il codice. Questo capitolo affronta un livello diverso: non la forma del codice, ma la sua sostanza. Le regole qui raccolte riguardano abitudini di scrittura che, indipendentemente dalla formattazione, determinano la correttezza, la leggibilità e la manutenibilità del risultato. Alcune sembrano ovvie; il fatto che debbano essere scritte esplicitamente è la prova che vengono violate con sufficiente frequenza da causare problemi reali.

---

## Etichettare blocchi anonimi e loop

*Aspetti: Manutenibilità — Livello: Minor*

I blocchi anonimi annidati e i loop possono ricevere un'etichetta — un nome racchiuso tra `<<` e `>>` — posizionata sulla riga che li precede. Quando un'etichetta è presente, deve essere ripetuta dopo il `end` o il `end loop` corrispondente.

L'etichetta assolve a due funzioni distinte. La prima è documentativa: rende immediatamente leggibile cosa fa quel blocco o quel loop, senza dover leggere il codice interno. La seconda è strutturale: ripetere il nome dopo `end` chiarisce visivamente a quale blocco appartiene la chiusura, in modo analogo a quanto già avviene con le funzioni e le procedure. Nei file che contengono blocchi annidati profondi, questo dettaglio evita ambiguità sulla struttura.

```sql
-- Senza etichette: la struttura è meno leggibile, soprattutto con blocchi annidati
begin
    begin
        null;
    end;
    begin
        null;
    end;
end;
/
```

```sql
-- Con etichette: ogni blocco ha un nome esplicito e il end ne rispecchia l'identità
begin
    <<prepara_dati>>
    begin
        null;
    end prepara_dati;
    --
    <<elabora_dati>>
    begin
        null;
    end elabora_dati;
end;
/
```

Lo stesso vale per i loop. Se un loop è etichettato — il che è utile quando si vuole eseguire un `exit` su un loop esterno da dentro un loop interno — il nome dell'etichetta va ripetuto dopo `end loop`:

```sql
declare
    i               pls_integer;
    k_MIN_VALUE     constant    pls_integer := 1;
    k_MAX_VALUE     constant    pls_integer := 10;
    k_INCREMENT     constant    pls_integer := 1;
begin
    i := k_MIN_VALUE;

    <<loop_while>>
    while ( i <= k_MAX_VALUE )
    loop
        i := i + k_INCREMENT;
    end loop loop_while;

    <<loop_for>>
    for i in k_MIN_VALUE..k_MAX_VALUE
    loop
        dbms_output.put_line(i);
    end loop loop_for;
end;
/
```

L'assenza dell'etichetta dopo `end loop` in un loop che ne ha una è un errore comune di trascinamento: ci si ricorda di metterla all'inizio e ci si dimentica di chiuderla. Un loop che ha un'etichetta ma non la chiude mette in dubbio se la chiusura sia quella giusta.

---

## Variabili non utilizzate

*Aspetti: Efficienza, Manutenibilità — Livello: Major*

Ogni variabile dichiarata nella sezione `is ... begin` che non viene mai letta o scritta nel corpo del blocco è un problema. Non causa un errore a runtime, ma introduce rumore: chi legge il codice non sa se la variabile sia lì perché prevista per un uso futuro, perché è rimasta da una versione precedente, o per errore. Il dubbio ha un costo in attenzione e in tempo.

La regola è semplice: se una variabile non serve, non va dichiarata. Se era utile in passato e non lo è più, va rimossa insieme al codice che la usava.

```sql
-- Errato: l_first_name è dichiarata ma non viene mai usata
create or replace
procedure my_proc
is
    l_last_name     employees.last_name%type;
    l_first_name    employees.first_name%type;  -- dichiarata, mai usata
begin
    select emp.last_name
      into l_last_name
      from employees  emp
     where emp.department_id = 10;
exception
    when no_data_found
    then
        null;
end my_proc;
/
```

```sql
-- Corretto: solo le variabili effettivamente usate compaiono nella sezione dichiarativa
create or replace
procedure my_proc
is
    l_last_name     employees.last_name%type;
begin
    select emp.last_name
      into l_last_name
      from employees  emp
     where emp.department_id = 10;
exception
    when no_data_found
    then
        null;
end my_proc;
/
```

La stessa regola si applica alle eccezioni dichiarate ma mai sollevate, ai tipi definiti ma mai istanziati, e alle costanti definite ma mai referenziate. La sezione dichiarativa deve contenere solo ciò che il corpo usa.

---

## Codice morto

*Aspetti: Manutenibilità — Livello: Major*

Il codice morto è codice che non può essere raggiunto durante l'esecuzione: istruzioni posizionate dopo un `return`, rami di `if` con condizioni impossibili, porzioni di loop che non vengono mai eseguite per via di una `exit` incondizionata. La sua presenza non causa errori — il compilatore PL/SQL non lo segnala come tale — ma crea confusione: un lettore non può sapere se il codice è lì per essere attivato in futuro, se è stato dimenticato, o se c'è un bug nella logica circostante.

Qualsiasi parte di codice che non può essere raggiunta va rimossa. Se era funzionante in una versione precedente, la sua storia vive nel version control, non nel sorgente attuale.

```sql
-- Errato: il null dopo return non verrà mai eseguito
declare
    k_DEPT_ADMIN    constant    departments.department_id%type := 10;
begin
    <<loop_dipendenti>>
    for r_emp in (
        select emp.last_name
          from employees  emp
         where emp.department_id = k_DEPT_ADMIN
            or emp.commission_pct is not null
               and 5 = 6              -- questa condizione è sempre falsa: codice morto
    )
    loop
        dbms_output.put_line(r_emp.last_name);
    end loop loop_dipendenti;

    return;
    null;  -- codice irraggiungibile
end;
/
```

```sql
-- Corretto: la logica è lineare e ogni istruzione è raggiungibile
declare
    k_DEPT_ADMIN    constant    departments.department_id%type := 10;
begin
    <<loop_dipendenti>>
    for r_emp in (
        select emp.last_name
          from employees  emp
         where emp.department_id  = k_DEPT_ADMIN
            or emp.commission_pct is not null
    )
    loop
        dbms_output.put_line(r_emp.last_name);
    end loop loop_dipendenti;
end;
/
```

Un caso frequente di codice morto è la condizione di un `if` che valuta un'espressione letteralmente impossibile — `if (2 = 3)`, `if (1 = 1 and 'x' = 'y')` — spesso residuo di un debug che non è stato rimosso.

---

## Letterali nel codice

*Aspetti: Modificabilità — Livello: Minor*

Un valore letterale — un numero, una stringa, una data scritta direttamente nel codice senza essere assegnata a una costante — è un problema appena compare più di una volta nello stesso file. La prima ripetizione crea una dipendenza implicita: se quel valore deve cambiare, bisogna trovare tutte le occorrenze e aggiornarle in modo coerente. Un'occorrenza mancata è un bug.

La soluzione è definire ogni valore usato più volte come costante. Tutte le costanti del progetto sono centralizzate in un unico package dedicato, in modo che ci sia un solo punto di modifica e un solo posto dove cercarle.

```sql
-- Errato: il valore 10 appare tre volte; una modifica richiede tre aggiornamenti
begin
    pkg_some.setup   (i_department_id => 10);
    pkg_some.process (i_department_id => 10);
    pkg_some.teardown(i_department_id => 10);
end;
/
```

```sql
-- Corretto: la costante è definita in un package dedicato e referenziata ovunque
create or replace
package lib_constants
is
    k_DEPT_ADMIN    constant    departments.department_id%type  := 10;
end lib_constants;
/

begin
    pkg_some.setup   (i_department_id => lib_constants.k_DEPT_ADMIN);
    pkg_some.process (i_department_id => lib_constants.k_DEPT_ADMIN);
    pkg_some.teardown(i_department_id => lib_constants.k_DEPT_ADMIN);
end;
/
```

Quando una costante deve essere usata anche nelle query SQL — non solo nel codice PL/SQL — non è possibile referenziare direttamente una variabile di package in una `select`. In questo caso si definisce una funzione `deterministic` che la espone:

```sql
create or replace
package lib_constants
is
    k_DEPT_ADMIN    constant    departments.department_id%type  := 10;

    function dept_admin
        return departments.department_id%type
        deterministic;
end lib_constants;
/

create or replace
package body lib_constants
is
    function dept_admin
        return departments.department_id%type
        deterministic
    is
    begin
        return (k_DEPT_ADMIN);
    end dept_admin;
end lib_constants;
/
```

Questa tecnica — una funzione deterministica per ogni costante da usare in SQL — è preferibile all'alternativa di riscrivere il valore letterale nelle query, perché mantiene il principio del punto unico di modifica anche per il codice SQL.

La soglia pratica: un letterale che compare una sola volta in un file e che non ha motivo di comparire altrove può restare tale. Un letterale che compare due o più volte, o che ha un significato semantico preciso (un codice di stato, un valore di riferimento, una soglia di business), va promosso a costante.

---

## ROWID e UROWID

*Aspetti: Affidabilità — Livello: Blocker*

Il `rowid` è l'indirizzo fisico di una riga all'interno dei file di dati Oracle. Può essere letto da una query, passato come valore e usato per identificare una riga in modo estremamente efficiente — ma è un riferimento volatile: qualsiasi riorganizzazione della tabella, anche implicita, ricalcola i `rowid`. Un `rowid` salvato in una tabella e riutilizzato dopo un'operazione di questo tipo punta a una riga diversa, o a nessuna riga, senza alcun segnale di errore.

Per questa ragione non va mai salvato un `rowid` in una tabella del database, né usato come riferimento persistente a una riga. L'identificatore stabile di una riga è la sua chiave primaria, e quella va usata ogni volta che è necessario conservare un riferimento.

```sql
-- Errato: il rowid viene salvato in tabella e potrebbe diventare invalido
begin
    insert
      into employees_log (  employee_id
                          , last_name
                          , rid
                         )
    select emp.employee_id
         , emp.last_name
         , emp.rowid
      from employees  emp;
end;
/
```

```sql
-- Corretto: si conserva la chiave primaria, che è un riferimento stabile
begin
    insert
      into employees_log (  employee_id
                          , last_name
                         )
    select emp.employee_id
         , emp.last_name
      from employees  emp;
end;
/
```

L'uso del `rowid` per identificare la riga da aggiornare all'interno della stessa transazione — ad esempio in un pattern `select ... for update` seguito da `update ... where rowid = l_rowid` — è tecnicamente sicuro perché il `rowid` non cambia nel corso della stessa sessione. Rimane però una pratica da evitare: introduce una dipendenza su un dettaglio implementativo di Oracle che non è garantito restare stabile tra versioni future, e rende il codice meno portabile e meno leggibile per chi non conosce questa garanzia.

---

## Espressioni identiche nei confronti

*Aspetti: Manutenibilità, Efficienza, Verificabilità — Livello: Blocker*

Un operatore binario — `=`, `<>`, `>`, `<`, `and`, `or` — con la stessa espressione su entrambi i lati è quasi sempre un errore. Nelle condizioni logiche, scrivere `a > 0 or a > 0` è equivalente a scrivere `a > 0` e il ramo duplicato va rimosso. Nella maggioranza dei casi reali si tratta di un copia/incolla in cui si è dimenticato di modificare uno dei due lati.

Il problema non è solo la ridondanza: un'espressione duplicata può mascherare un bug. Chi legge `salary > k_MAX_SALARY or salary > k_MAX_SALARY` deve fermarsi e verificare se la ripetizione sia intenzionale — e quasi sempre non lo è.

```sql
-- Errato: la condizione salary > k_MAX_SALARY è ripetuta due volte con or (copia/incolla)
declare
    k_MAX_SALARY    constant    employees.salary%type   := 3000;
begin
    select emp.first_name
         , emp.last_name
         , emp.salary
      from employees  emp
     where emp.salary > k_MAX_SALARY
        or emp.salary > k_MAX_SALARY;
end;
/
```

```sql
-- Corretto: una sola condizione, chiara e non ambigua
declare
    k_MAX_SALARY    constant    employees.salary%type   := 3000;
begin
    select emp.first_name
         , emp.last_name
         , emp.salary
      from employees  emp
     where emp.salary > k_MAX_SALARY;
end;
/
```

Sono escluse da questa regola le espressioni usate intenzionalmente con operatori commutativi come `+`, `*` e `||` — dove `x + x` è un modo valido di scrivere `x * 2` — e le condizioni tautologiche convenzionali come `1 = 1`, usate per semplificare la generazione dinamica di SQL.
