# Uso del linguaggio — Exception Handling

La gestione delle eccezioni è uno degli aspetti più critici del codice PL/SQL e, paradossalmente, uno dei più trascurati. Un'eccezione non gestita interrompe l'esecuzione senza lasciare traccia utile; un handler scritto male può nascondere il problema, propagare informazioni errate o ingoiare silenziosamente errori che andrebbero segnalati. Le regole di questo capitolo mirano a rendere la gestione degli errori esplicita, coerente e diagnosticabile.

---

## Usare un framework centralizzato per la gestione degli errori

*Aspetti: Affidabilità, Riusabilità, Verificabilità — Livello: Critical*

Distribuire la logica di logging e di sollevamento degli errori direttamente nel codice applicativo produce duplicazioni, numeri di errore in conflitto e messaggi inconsistenti. Un framework centralizzato risolve questi problemi in un unico punto: definisce come gli errori vengono registrati (su tabella, via mail, su file), come vengono sollevati, e come i messaggi Oracle vengono tradotti in testo comprensibile.

Il framework deve almeno gestire:
- il logging su uno o più canali;
- il sollevamento degli errori in modo controllato;
- un repository dei codici e dei messaggi di errore dell'applicazione.

```sql
-- Errato: logging con dbms_output, non persistente e non strutturato
declare
    k_START     constant    logger_logs.text%type   := 'start';
    k_END       constant    logger_logs.text%type   := 'end';
begin
    dbms_output.put_line(k_START);
    -- elaborazione
    dbms_output.put_line(k_END);
end;
/
```

```sql
-- Corretto: uso di un framework di logging strutturato
declare
    k_START     constant    logger_logs.text%type   := 'start';
    k_END       constant    logger_logs.text%type   := 'end';
    k_SCOPE     constant    logger_logs.scope%type  := 'my_proc';
begin
    logging_up.log(in_text => k_START, in_scope => k_SCOPE);
    -- elaborazione
    logging_up.log(in_text => k_END,   in_scope => k_SCOPE);
end;
/
```

---

## Non gestire eccezioni non nominate tramite il numero di errore

*Aspetti: Manutenibilità — Livello: Critical*

Confrontare `sqlcode` con un numero letterale all'interno di un handler `when others` richiede di conoscere a memoria la tabella degli errori Oracle. Il codice diventa incomprensibile senza un manuale di riferimento, e il rischio di errori di trascrizione è elevato.

La soluzione è dichiarare un'eccezione con nome, associarla al codice Oracle tramite `pragma exception_init`, e usarla direttamente come handler nella sezione `exception`.

```sql
-- Errato: il numero -1 richiede un lookup manuale per capire di che errore si tratta
begin
    my_package.some_processing();
exception
    when too_many_rows then
        my_package.some_further_processing();
    when others then
        if sqlcode = -1 then
            null;
        end if;
end;
/
```

```sql
-- Corretto: l'eccezione ha un nome leggibile e il suo handler è esplicito
declare
    e_dup_val   exception;
    pragma      exception_init(e_dup_val, -1);
begin
    my_package.some_processing();
exception
    when too_many_rows then
        my_package.some_further_processing();
    when e_dup_val then
        null;
end;
/
```

---

## Non usare nomi di eccezioni predefinite per eccezioni utente

*Aspetti: Affidabilità, Verificabilità — Livello: Blocker*

Oracle definisce nel package `standard` un insieme di eccezioni predefinite — `no_data_found`, `too_many_rows`, `dup_val_on_index` e molte altre. Dichiarare un'eccezione utente con lo stesso nome in un blocco locale sovrascrive silenziosamente quella predefinita all'interno di quel blocco: qualsiasi riferimento a quel nome risolverà alla dichiarazione locale, non a quella di Oracle.

Il risultato è che le eccezioni Oracle con quel nome non possono più essere intercettate normalmente, e il codice produce comportamenti difficili da diagnosticare.

```sql
-- Errato: no_data_found locale oscura quella predefinita da Oracle;
-- la select that raises no_data_found non può essere intercettata correttamente
declare
    l_dummy         dual.dummy%type;
    no_data_found   exception;          -- sovrascrive standard.no_data_found
    k_ROWNUM        constant    simple_integer  := 0;
begin
    select  dummy
      into  l_dummy
      from  dual
     where  rownum = k_ROWNUM;

    if l_dummy is null then
        raise no_data_found;
    end if;
exception
    when no_data_found then             -- intercetta la locale, non quella Oracle
        dbms_output.put_line('no_data_found');
end;
/
```

```sql
-- Corretto: nome distinto per l'eccezione utente; quella Oracle rimane accessibile
declare
    l_dummy         dual.dummy%type;
    e_empty_value   exception;
    k_ROWNUM        constant    simple_integer              := 0;
    k_EMPTY_MSG     constant    types_up.short_text_type    := 'empty_value';
    k_NDF_MSG       constant    types_up.short_text_type    := 'no_data_found';
begin
    select  dummy
      into  l_dummy
      from  dual
     where  rownum = k_ROWNUM;

    if l_dummy is null then
        raise e_empty_value;
    end if;
exception
    when e_empty_value then
        dbms_output.put_line(k_EMPTY_MSG);
    when no_data_found then
        dbms_output.put_line(k_NDF_MSG);
end;
/
```

---

## Non usare `when others` senza altri handler specifici

*Aspetti: Affidabilità — Livello: Critical*

Un handler `when others` che è l'unico handler nella sezione `exception` cattura qualsiasi eccezione, comprese quelle che non erano previste. Questo può far sì che errori gravi vengano ignorati o gestiti in modo inappropriato, rendendo il debugging estremamente difficile.

La regola è: se si usa `when others`, devono essere presenti anche handler per le eccezioni specifiche che si prevede possano essere sollevate. L'unica eccezione ammessa è un handler `when others` che registra l'errore e poi esegue `raise` per ripropagare l'eccezione al chiamante — in questo caso il suo scopo è esclusivamente diagnostico, non di silenziamento.

```sql
-- Errato: when others cattura tutto silenziosamente, incluse eccezioni impreviste
begin
    my_package.some_processing();
exception
    when others then
        my_package.some_further_processing();
end;
/
```

```sql
-- Corretto: handler specifico per l'eccezione attesa
begin
    my_package.some_processing();
exception
    when dup_val_on_index then
        my_package.some_further_processing();
end;
/
```

```sql
-- Ammesso: when others per logging + raise (scopo puramente diagnostico)
begin
    my_package.some_processing();
exception
    when others then
        logging_up.log_error(in_text => 'Eccezione non gestita');
        raise;
end;
/
```

---

## Non usare `raise_application_error` con numeri e messaggi hardcoded

*Aspetti: Modificabilità, Manutenibilità — Livello: Major*

Oracle riserva i numeri da `-20000` a `-20999` per gli errori applicativi. Scrivere questi numeri direttamente nel codice crea risorse condivise non gestite: due sviluppatori possono usare lo stesso numero per errori diversi, e modificare un messaggio richiede di trovare tutte le occorrenze nel codice.

La soluzione è centralizzare i codici di errore in un package dedicato e usare una procedura di sollevamento che accetti solo costanti da quel package. Il messaggio di errore deve provenire da una tabella di configurazione o da una costante con nome, mai da un letterale inline.

```sql
-- Errato: numero e messaggio hardcoded, impossibile garantire unicità e coerenza
begin
    raise_application_error(-20501, 'Dipendente non valido');
end;
/
```

```sql
-- Corretto: il codice di errore è una costante in un package dedicato;
-- la procedura err_up.raise gestisce internamente raise_application_error
begin
    err_up.raise(in_error => err.k_INVALID_EMPLOYEE_ID);
end;
/
```

---

## Gestire le eccezioni prevedibili

*Aspetti: Affidabilità — Livello: Major*

Un blocco che non gestisce le eccezioni che può sollevare trasferisce al chiamante la responsabilità di capire cosa è andato storto e come reagire. Se il codice di una funzione o procedura può sollevare eccezioni prevedibili — `no_data_found`, `too_many_rows`, errori di conversione — la sezione `exception` deve gestirle in modo appropriato.

Per le funzioni, gestire `no_data_found` con un `return null` è spesso la scelta corretta: il chiamante riceve un valore che può testare invece di dover intercettare un'eccezione. Per `too_many_rows` è invece opportuno propagare l'eccezione con `raise`, perché indica una condizione anomala che il chiamante deve conoscere.

```sql
-- Errato: la funzione non gestisce no_data_found né too_many_rows;
-- il chiamante deve sapere quali eccezioni questa funzione può sollevare
create or replace
package body department_api
as
    function name_by_id
        ( in_id     in  departments.department_id%type )
        return departments.department_name%type
    is
        k_ID                constant    departments.department_id%type      := in_id;
        l_department_name               departments.department_name%type;
    begin
        select  dep.department_name
          into  l_department_name
          from  departments  dep
         where  dep.department_id = k_ID;

        return l_department_name;
    end name_by_id;
end department_api;
/
```

```sql
-- Corretto: le eccezioni prevedibili sono gestite esplicitamente
create or replace
package body department_api
as
    function name_by_id
        ( in_id     in  departments.department_id%type )
        return departments.department_name%type
    is
        k_ID                constant    departments.department_id%type      := in_id;
        l_department_name               departments.department_name%type;
    begin
        select  dep.department_name
          into  l_department_name
          from  departments  dep
         where  dep.department_id = k_ID;

        return l_department_name;
    exception
        when no_data_found then
            return null;
        when too_many_rows then
            raise;
    end name_by_id;
end department_api;
/
```

---

## Non sollevare eccezioni predefinite di Oracle come eccezioni applicative

*Aspetti: Affidabilità — Livello: Blocker*

Le eccezioni predefinite di Oracle — `no_data_found`, `too_many_rows`, `dup_val_on_index` e simili — hanno un significato specifico legato al comportamento del motore database. Usarle come eccezioni applicative, sollevandole con `raise` per segnalare condizioni di business, rende il codice ambiguo: il chiamante non può distinguere se l'eccezione è stata sollevata dall'applicazione o dal database.

Per segnalare condizioni applicative specifiche si dichiara un'eccezione propria con nome significativo e, se necessario, la si associa a un codice con `pragma exception_init`.

```sql
-- Errato: no_data_found viene sollevata come eccezione applicativa,
-- rendendo impossibile distinguerla da quella sollevata da Oracle
begin
    raise no_data_found;
end;
/
```

```sql
-- Corretto: eccezione applicativa con nome proprio
declare
    e_my_exception  exception;
begin
    raise e_my_exception;
end;
/
```

---

## Usare `format_error_backtrace` insieme a `sqlerrm` o `format_error_stack`

*Aspetti: Manutenibilità, Verificabilità — Livello: Critical*

Nell'handler di un'eccezione, `sqlerrm` e `format_error_stack` restituiscono il testo del messaggio di errore, ma non indicano in quale riga del codice l'eccezione è stata sollevata. `dbms_utility.format_error_backtrace` restituisce invece lo stack delle chiamate al momento in cui l'eccezione è stata generata, anche se la funzione viene chiamata da un handler in un blocco esterno.

Registrare solo `sqlerrm` senza il backtrace rende quasi impossibile localizzare l'origine dell'errore in programmi strutturati con molti livelli di chiamate.

```sql
-- Errato: il log contiene solo il messaggio di errore, senza indicazione della riga
create or replace
package body order_api
as
    procedure discount_and_recalculate
        (   in_customer_id  in  customers.customer_id%type
          , in_discount     in  customers.discount_pct%type
        )
    is
        k_CUSTOMER_ID   constant    customers.customer_id%type      := in_customer_id;
        k_DISCOUNT      constant    customers.discount_pct%type     := in_discount;
        k_ERR_PREFIX    constant    types_up.text                   := 'Errore: ';
    begin
        customer_api.apply_discount(
              in_customer_id  => k_CUSTOMER_ID
            , in_discount     => k_DISCOUNT
        );
        customer_api.recalculate(in_customer_id => k_CUSTOMER_ID);
    exception
        when zero_divide then
            null;
        when others then
            logging_up.log_error(in_text => k_ERR_PREFIX || sqlerrm);
            raise;
    end discount_and_recalculate;
end order_api;
/
```

```sql
-- Corretto: il log include sia il messaggio sia il backtrace per localizzare l'origine
create or replace
package body order_api
as
    procedure discount_and_recalculate
        (   in_customer_id  in  customers.customer_id%type
          , in_discount     in  customers.discount_pct%type
        )
    is
        k_CUSTOMER_ID   constant    customers.customer_id%type      := in_customer_id;
        k_DISCOUNT      constant    customers.discount_pct%type     := in_discount;
        k_ERR_PREFIX    constant    types_up.text                   := 'Errore: ';
        k_BT_PREFIX     constant    types_up.text                   := ' - Backtrace: ';
    begin
        customer_api.apply_discount(
              in_customer_id  => k_CUSTOMER_ID
            , in_discount     => k_DISCOUNT
        );
        customer_api.recalculate(in_customer_id => k_CUSTOMER_ID);
    exception
        when zero_divide then
            null;
        when others then
            logging_up.log_error(
                in_text =>    k_ERR_PREFIX
                           || sqlerrm
                           || k_BT_PREFIX
                           || dbms_utility.format_error_backtrace
            );
            raise;
    end discount_and_recalculate;
end order_api;
/
```
