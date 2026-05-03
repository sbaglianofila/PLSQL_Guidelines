# Stile del Codice

La qualità di un sistema software non si misura solo dalla sua correttezza funzionale, ma anche dalla leggibilità e dalla coerenza del codice che lo compone. Codice scritto in modo uniforme — con le stesse convenzioni di indentazione, la stessa logica di formattazione, la stessa disciplina nei commenti — si legge più velocemente, si modifica con meno rischio di errore e si revisiona in modo molto più efficace. In PL/SQL e SQL questa considerazione è particolarmente rilevante: le query e le procedure vengono lette e modificate da persone diverse nel corso di anni, spesso senza il contesto di chi le ha scritte originariamente.

Questo capitolo definisce le convenzioni di stile da applicare a tutto il codice PL/SQL e SQL del progetto. Alcune di queste regole possono sembrare arbitrarie viste singolarmente, ma il loro valore emerge nell'insieme: un codice che le rispetta tutte è un codice che sembra scritto da una sola mano, e questo è uno degli obiettivi più importanti di uno standard di stile.

---

## Regole generali

Il primo principio è che tutto il codice è scritto in minuscolo. Questo vale per le parole chiave del linguaggio (`select`, `from`, `where`, `begin`, `end`), per i nomi degli oggetti del database e per i nomi degli identificatori PL/SQL. L'unica eccezione sono le costanti, i cui nomi — ma non il prefisso — sono scritti in maiuscolo, come descritto nel capitolo sulle convenzioni di denominazione.

La scelta del minuscolo non è arbitraria. Oracle tratta i nomi in modo case-insensitive, ma molti strumenti di sviluppo e di gestione del database mostrano il codice in un casing diverso da quello in cui è stato scritto. Usare il minuscolo ovunque rende il codice visivamente uniforme indipendentemente dallo strumento con cui viene letto. Scrivere le keyword in maiuscolo — come era prassi comune nel SQL classico — non aggiunge leggibilità in un editor moderno che evidenzia la sintassi, e anzi introduce una fonte di disomogeneità quando le keyword si mescolano a nomi di oggetti e variabili.

L'indentazione usa esclusivamente spazi, mai caratteri di tabulazione. Ogni livello di indentazione corrisponde a quattro spazi. Il motivo per cui si evitano i tab è pratico: la larghezza visiva di un tab varia da strumento a strumento — alcuni lo rendono come quattro spazi, altri come otto — il che rende impossibile garantire che il codice appaia allineato allo stesso modo in ambienti diversi. Gli spazi sono assoluti e portabili.

All'interno di un blocco SQL, le parole chiave principali — `select`, `into`, `from`, `where`, `and`, `order by`, e le loro equivalenti nelle istruzioni DML — sono allineate a destra rispetto alla keyword più lunga del blocco. Questo allineamento crea una colonna visiva che separa il "cosa" (le keyword) dal "con cosa" (le espressioni e i nomi), rendendo la struttura della query immediatamente leggibile. Le sezioni successive mostrano come questo principio si applica concretamente ai vari costrutti.

Nelle liste di elementi — colonne di una `select`, parametri di una funzione, valori di una `insert` — la virgola si mette all'inizio della riga successiva al primo elemento, non alla fine della riga corrente. Le parentesi di chiusura di una lista vanno su una riga propria, allineate sotto la parentesi di apertura. Questa convenzione, detta *leading comma*, facilita l'aggiunta e la rimozione di elementi dalla lista: ogni riga è autonoma e può essere commentata, spostata o eliminata senza dover toccare la riga precedente.

---

## Firma di funzioni e procedure

La dichiarazione di una funzione o di una procedura segue una struttura verticale precisa. `create or replace` va su una riga propria, separato dalla keyword `function` o `procedure` che segue sulla riga successiva. Il primo parametro va sulla stessa riga della parentesi di apertura, preceduto da due spazi dopo la parentesi; i parametri successivi iniziano con `, ` a inizio riga, allineati sotto il primo. La parentesi di chiusura `)` va su una riga propria, allineata sotto la parentesi di apertura. Per le funzioni, `return` segue su una riga propria con quattro spazi di indentazione.

Immediatamente prima della keyword `is`, si inserisce un commento che descrive lo scopo del sottoprogramma e documenta i parametri. Questo commento è posizionato lì per una ragione pratica: Oracle lo rende accessibile tramite le viste del Data Dictionary, permettendo di estrarre la documentazione inline direttamente dal database senza mantenere un documento separato.

```sql
create or replace
function process_customer_orders (  i_customer_id   in  number
                                  , i_process_date  in  date        default sysdate
                                 )
    return number
-- Elabora gli ordini in stato PENDING per il cliente specificato,
-- aggiorna i saldi e produce un record di audit per ogni ordine processato.
-- i_customer_id  : identificativo del cliente
-- i_process_date : data di riferimento per il filtraggio degli ordini
is
```

I tipi dei parametri non includono mai una dimensione esplicita — si scrive `varchar2`, non `varchar2(200)`. La dimensione è una proprietà della colonna del database, non del parametro: vincolarla nel parametro creerebbe una dipendenza che potrebbe rompere il codice quando la colonna viene allargata. Per evitare questo problema in modo definitivo, si preferisce usare `%type` per ancorare il tipo del parametro alla colonna corrispondente: `i_customer_name in customers.customer_name%type`.

---

## Sezione dichiarativa

Le dichiarazioni nel blocco `is ... begin` sono raggruppate per tipo, ognuna preceduta da un commento di intestazione che identifica la categoria. All'interno di ciascun gruppo, i datatype e le assegnazioni sono allineati verticalmente in colonna, il che rende immediatamente visibili le analogie e le differenze tra le variabili dello stesso gruppo.

```sql
is
    -- Costanti
    k_STATUS_PENDING    constant    varchar2(10)    := 'PENDING';
    k_VALORE_ZERO       constant    number          := 0;

    -- Variabili scalari
    l_customer_name                 varchar2(200);
    l_total_amount                  number(15,2)    := 0;
    l_processed_count               number          := 0;
    l_status_code                   varchar2(10);

    -- Tipi e record
    type t_order_type           is table of number;

    r_order_rec                     orders%rowtype;
    t_order                         t_order_type;
```

L'ordine dei gruppi segue una gerarchia logica: prima le costanti, poi i tipi definiti dall'utente, poi le variabili scalari, poi i record e le collection, infine i cursori e le eccezioni. Questo ordine riflette le dipendenze: non è possibile dichiarare una variabile di un tipo definito localmente prima di aver dichiarato il tipo stesso.

---

## Formattazione SQL

Le query SQL embedded nel codice PL/SQL seguono la regola dell'allineamento a destra delle keyword. In una `select`, la parola più lunga tra le keyword di sezione è tipicamente `order by`; tutte le altre si allineano di conseguenza. Le colonne nella lista `select` e le condizioni nel `where` usano la virgola e `and` a inizio riga.

Tra le sezioni logiche della query si inserisce una riga di separazione composta da un commento vuoto `--`. Questo separatore visivo — posto dopo il blocco `from`, dopo il blocco `where`, e in altri punti di transizione — rende la struttura della query leggibile a colpo d'occhio, senza dover seguire le keyword con lo sguardo.

```sql
select cus.customer_name
     , cus.customer_email
     , ord.order_date
  into l_customer_name
     , l_customer_email
     , l_order_date
  from customers    cus
     , orders       ord
    --
 where cus.customer_id  = i_customer_id
   and ord.customer_id  = cus.customer_id
   and ord.status       = k_STATUS_PENDING
    --
 order by ord.order_date
        , ord.order_id;
```

Ogni tabella referenziata nella clausola `from` deve avere un alias di esattamente tre caratteri, sempre presente, anche quando la query coinvolge una sola tabella. L'alias si usa sistematicamente per qualificare ogni colonna, in ogni punto della query. Questo elimina ogni ambiguità su quale tabella provenga un dato campo, e rende le query resistenti alle modifiche strutturali — se si aggiunge una tabella con una colonna omonima, il codice esistente non si rompe.

---

## Cursori

Un cursore esplicito si dichiara nella sezione dichiarativa con i suoi parametri, seguiti da un commento descrittivo prima dell'`is`, e dalla query interna che segue le stesse regole di formattazione del paragrafo precedente. I parametri del cursore usano il prefisso `p_` per distinguerli dai parametri del sottoprogramma.

```sql
cursor c_pending_orders (  p_customer_id    in number
                         , p_date           in date
                        )
-- Restituisce gli ordini in stato PENDING per il cliente,
-- con data uguale o precedente alla data di riferimento.
is
    select ord.order_id
         , ord.order_date
         , ord.amount
         , ord.status
        --
      from orders      ord
        --
     where ord.customer_id    = p_customer_id
       and ord.order_date    <= p_date
       and ord.status         = k_STATUS_PENDING
        --
     order by ord.order_date
            , ord.order_id;
```

Nel `for loop` che itera sul cursore, il record di iterazione prende il nome del cursore con il prefisso `r_` al posto di `c_`: se il cursore si chiama `c_pending_orders`, il record si chiama `r_pending_orders`. Le keyword `loop` e `end loop;` vanno su righe proprie. I parametri vengono sempre passati con notazione named, allineati verticalmente:

```sql
for r_pending_orders in c_pending_orders (  p_customer_id  => i_customer_id
                                          , p_date         => i_process_date
                                         )
loop

    l_total_amount    := l_total_amount + r_pending_orders.amount;
    l_processed_count := l_processed_count + 1;

end loop;
```

---

## DML — INSERT, UPDATE, DELETE

### INSERT

La `insert` si struttura con `insert` su una riga propria e `into` sulla riga successiva con indentazione. La lista delle colonne e la lista dei valori seguono entrambe la convenzione della virgola a inizio riga, con le parentesi di chiusura su righe proprie:

```sql
insert
  into order_audit (  audit_id
                    , order_id
                    , customer_id
                    , action
                    , action_date
                    , amount
                   )
values (  order_audit_seq.nextval
        , r_pending_orders.order_id
        , i_customer_id
        , 'PROCESSED'
        , sysdate
        , r_pending_orders.amount
       );
```

### UPDATE

In una `update`, le keyword `update`, `set` e `where` sono allineate a destra. I campi aggiornati usano la virgola a inizio riga, e i valori sono allineati in colonna:

```sql
update orders
   set status      = 'PROCESSED'
     , updated_at  = sysdate
 where order_id    = r_pending_orders.order_id;
```

### DELETE

La `delete` usa `delete` su riga propria e `from` sulla riga successiva, seguendo le stesse regole di allineamento della `where`:

```sql
delete
  from order_logs
 where order_id    = r_pending_orders.order_id
   and log_date    < add_months(sysdate, -12);
```

---

## MERGE

L'istruzione `merge` è strutturata con `merge` su riga propria e `into` sulla riga successiva. Per convenzione, la tabella di destinazione usa sempre l'alias `dst` e la sorgente usa sempre `src`. La condizione di `on` va tra parentesi. Le clausole `when matched then` e `when not matched then` vanno su righe proprie, e le sezioni sono separate dai consueti separatori `--`.

```sql
merge
 into customer_balance  dst
   --
using ( select i_customer_id    customer_id
             , l_total_amount   amount
          from dual
      ) src
   on ( dst.customer_id = src.customer_id )
   --
 when matched
 then
     update
        set dst.balance      = dst.balance + src.amount
          , dst.last_update  = sysdate
   --
 when not matched
 then
     insert (  dst.customer_id
             , dst.balance
             , dst.last_update
            )
     values (  src.customer_id
             , src.amount
             , sysdate
            );
```

L'uso di alias fissi `dst` e `src` non è una preferenza estetica: elimina la necessità di decidere ogni volta come chiamare le due parti del merge, e rende le istruzioni `merge` immediatamente riconoscibili come tali anche a una lettura rapida.

---

## Control flow — IF, LOOP e assegnazioni

### IF

La condizione di un `if` è sempre racchiusa tra parentesi, anche quando è una condizione semplice. Questa regola rende visibile il confine della condizione e facilita l'aggiunta di condizioni composte in fase di modifica. La keyword `then` va su riga propria. Il ramo `else` — quando non fa nulla — si scrive esplicitamente come `else null;`, per comunicare che l'assenza di logica è intenzionale e non una dimenticanza.

```sql
if ( l_customer_name = 'TEST' )
then
    dbms_output.put_line('Test');
else
    null;
end if;
```

Quando la condizione è composta da più predicati, ogni predicato va su una riga propria, con `and` o `or` a inizio riga allineati. La parentesi di chiusura della condizione va su riga propria:

```sql
if (    l_status_code  = 'ACTIVE'
    and l_total_amount > k_VALORE_ZERO
   )
then
    -- logica
end if;
```

### Assegnazioni multiple

Quando compaiono più assegnazioni consecutive, gli operatori `:=` vengono allineati verticalmente. Questa regola vale per le assegnazioni scalari, ma anche per i parametri di chiamata a funzioni e cursori. L'allineamento verticale permette di leggere la lista come una tabella e di individuare immediatamente valori incongruenti o errori di tipo.

```sql
l_status_code   := 'ACTIVE';
l_total_amount  := 0;
l_dummy         := 1;
```

---

## Chiamate a procedure e funzioni

Le chiamate a sottoprogrammi usano sempre la notazione named per i parametri, mai la notazione posizionale. La notazione posizionale — in cui i valori si passano nell'ordine in cui compaiono nella firma — è fragile: se la firma del sottoprogramma viene modificata (un parametro aggiunto, uno spostato, uno rimosso), le chiamate esistenti compilano ancora ma producono risultati errati. La notazione named è immune a questi problemi perché ogni valore è esplicitamente associato al parametro per nome.

I parametri si allineano verticalmente come nelle dichiarazioni di firma, con la parentesi di chiusura su riga propria:

```sql
calcola_sconto (  i_codice_ordine  => r_pending_orders.order_id
               , i_customer        => i_customer_id
              );
```

---

## Commenti

Un commento nel codice è una scelta deliberata che ha un costo: va scritto, mantenuto e aggiornato ogni volta che il codice che descrive cambia. Un commento non aggiornato è peggio di nessun commento, perché crea una contraddizione tra ciò che il codice fa e ciò che il testo dice. Per questo, la prima domanda da porsi prima di scrivere un commento è: *è davvero necessario?* Se il codice è scritto in modo chiaro — con nomi significativi, struttura leggibile e logica lineare — spesso la risposta è no.

### Cosa commentare

Un commento è giustificato quando aggiunge informazione che il codice da solo non può trasmettere. Ci sono quattro situazioni in cui questo accade.

La prima è quando il codice implementa una logica non ovvia: una formula, un algoritmo, una regola di business che non è deducibile dalla struttura del codice. In questi casi il commento spiega il *perché* della scelta, non il *cosa* — il cosa è già nel codice. Per esempio, un aggiornamento di stato con una condizione particolare dovrebbe essere spiegato in termini della regola di business che lo motiva, non descritto come "update dello stato":

```sql
-- Gli ordini in stato PENDING da più di 30 giorni vengono forzati a EXPIRED
-- per liberare i lock sulle righe di magazzino associate (vedi regola R-42).
update orders
   set status      = 'EXPIRED'
     , updated_at  = sysdate
 where status      = k_STATUS_PENDING
   and order_date  < sysdate - 30;
```

La seconda situazione è quando esiste un vincolo esterno che non è visibile nel codice: una dipendenza da un comportamento specifico di Oracle, una limitazione imposta da un sistema chiamante, un workaround per un bug noto. Questi commenti sono particolarmente preziosi perché documentano perché il codice *non* è scritto nel modo più semplice possibile.

La terza situazione riguarda la struttura delle query. Quando una `select into` recupera dati il cui scopo non è immediatamente deducibile dal nome delle variabili di destinazione, un commento che ne descriva il ruolo nel flusso della procedura è utile. Non si tratta di descrivere la query tecnicamente, ma di spiegare perché quel dato viene recuperato in quel punto:

```sql
-- Recupero dei dati di fatturazione del cliente: necessari per popolare l'intestazione del documento.
select cus.billing_address
     , cus.vat_number
     , cus.payment_terms
  into l_billing_address
     , l_vat_number
     , l_payment_terms
  from customers    cus
 where cus.customer_id = i_customer_id;
```

La quarta situazione sono i punti di confine tra blocchi logici distinti all'interno di una procedura lunga. Un breve titolo di sezione — una riga sola, senza decorazioni — aiuta il lettore a orientarsi nel flusso senza dover leggere tutto il codice:

```sql
-- Validazione dell'input
...

-- Raccolta dei dati dal database
...

-- Elaborazione e aggiornamento
...

-- Audit
...
```

### Cosa non commentare

Il difetto opposto — commentare tutto — è altrettanto dannoso. I commenti ridondanti aggiungono rumore, affaticano la lettura e creano disallineamenti nel tempo. Non vanno mai scritti commenti che si limitano a descrivere l'istruzione che segue, come `-- UPDATE` prima di una `update`, o `-- BEGIN` prima di un `begin`. Non vanno commentati nomi già autoesplicativi, né logiche banali.

```sql
-- Errato: il commento non aggiunge nulla che il codice non dica già
-- Aggiornamento dello stato dell'ordine
update orders
   set status = 'PROCESSED'
 where order_id = r_pending_orders.order_id;

-- Corretto: il commento spiega il contesto, non l'istruzione
-- Lo stato viene aggiornato qui e non alla fine del loop per rendere
-- il lock sulla riga il più breve possibile durante l'elaborazione del cursore.
update orders
   set status = 'PROCESSED'
 where order_id = r_pending_orders.order_id;
```

### Intestazione di funzioni, procedure e cursori

Ogni funzione, procedura e cursore deve avere un commento di intestazione posizionato immediatamente prima della keyword `is`. Questo commento è strutturato in due parti: una descrizione dello scopo del sottoprogramma in forma discorsiva, seguita dall'elenco dei parametri con una breve descrizione per ciascuno.

La descrizione deve rispondere alla domanda "cosa fa questo sottoprogramma e perché esiste?". Non basta descrivere la meccanica dell'implementazione; bisogna chiarire il contesto d'uso, il perché del sottoprogramma nel sistema, e se pertinente, i presupposti (precondizioni) e le garanzie (postcondizioni) che offre al chiamante.

```sql
create or replace
procedure archive_expired_orders (  i_cutoff_date    in  date
                                  , o_archived_count out number
                                 )
-- Sposta nella tabella arc_orders tutti gli ordini con stato EXPIRED
-- e data antecedente a i_cutoff_date. Aggiorna i_cutoff_date come
-- punto di taglio negli audit log. Deve essere invocata esclusivamente
-- dal job notturno di manutenzione, non durante le finestre operative.
-- i_cutoff_date    : data limite per l'archiviazione; gli ordini con
--                    order_date >= i_cutoff_date non vengono toccati.
-- o_archived_count : numero di ordini effettivamente archiviati.
is
```

Lo stesso vale per i cursori: il commento prima dell'`is` descrive quali dati il cursore restituisce, il criterio di filtro e l'ordinamento, e il contesto in cui viene usato se non è ovvio dal nome:

```sql
cursor c_expiring_contracts (  p_reference_date  in date
                             , p_days_ahead       in number
                            )
-- Restituisce i contratti in scadenza entro p_days_ahead giorni
-- dalla data di riferimento, ordinati per data di scadenza crescente.
-- Usato dal processo di notifica per generare le comunicazioni ai clienti.
is
    ...
```

### Forma e stile dei commenti

All'interno del corpo di una procedura, funzione o cursore si usa esclusivamente la sintassi a doppio trattino `--`. I commenti a blocco `/* ... */` sono vietati nel corpo del codice. Le uniche eccezioni ammesse sono due: l'intestazione di un file SQL, e il commento di documentazione posto immediatamente prima dell'`is` di funzioni, procedure e cursori — in quel caso la sintassi `/* ... */` facilita l'estrazione automatica da parte di tool che analizzano i sorgenti per produrre documentazione. In tutti gli altri contesti — logica interna, separatori di sezione, note inline — si usa esclusivamente `--`.

I motivi tecnici del divieto sono due. Il primo è che i commenti a blocco non possono essere annidati: se si commenta temporaneamente un blocco di codice che contiene già un `/* ... */`, il compilatore segnala un errore sintattico. Il secondo è che un commento a blocco è invisibile senza syntax highlighting: aprendo il file in un editor testuale come `vi` o `less`, un `/* ... */` su più righe è indistinguibile dal codice circostante — non c'è nessun marker visibile a inizio riga che segnali che si tratta di testo commentato. Un `--` in colonna 1, al contrario, è immediatamente riconoscibile a qualsiasi livello di tooling.

### Codice commentato

Quando si disabilita temporaneamente un blocco di codice — ad esempio come esito di una correttiva, in attesa di verifica, o per confronto con la versione precedente — i `--` devono essere posizionati in **colonna 1**, indipendentemente dall'indentazione originale del codice. Questo li rende immediatamente visibili anche senza syntax highlighting e impedisce di confonderli con i commenti esplicativi normali, che seguono l'indentazione del codice circostante.

```sql
-- Versione precedente, disabilitata dopo correttiva del 2024-11-15:
--    update orders
--       set status      = 'PROCESSED'
--         , updated_at  = sysdate
--     where order_id    = r_pending_orders.order_id;

-- Nuova logica: aggiorna solo se lo stato corrente è ancora PENDING,
-- per evitare sovrascritture in caso di elaborazioni concorrenti.
update orders
   set status      = 'PROCESSED'
     , updated_at  = sysdate
 where order_id    = r_pending_orders.order_id
   and status      = k_STATUS_PENDING;
```

Il codice commentato in questo modo non deve restare nel sorgente a tempo indeterminato: va rimosso non appena la correttiva è verificata e consolidata. La sua presenza è accettabile solo come strumento di transizione, non come forma di documentazione storica — per quella esiste il version control.

I commenti si scrivono in forma di frasi complete quando spiegano logica o contesto, e in forma nominale breve quando documentano i parametri. Si usa la stessa lingua naturale usata per i nomi degli oggetti: se il progetto è in italiano, i commenti sono in italiano; se è in inglese, in inglese. Non si mescolano le lingue nello stesso file.

La punteggiatura segue le regole della lingua usata. Un commento che è una frase completa termina con il punto. Un commento che è un'etichetta o un titolo di sezione non lo richiede.

---

## RETURN ed EXCEPTION

### RETURN

Il valore restituito da una funzione va sempre tra parentesi, anche quando si tratta di una singola variabile o espressione. Questa convenzione non è richiesta da Oracle, ma rende immediatamente visibile il confine dell'espressione restituita, specialmente quando il valore è il risultato di un calcolo:

```sql
return (l_processed_count);
```

### EXCEPTION

Il blocco `exception` elenca i gestori degli errori con `when <eccezione>` su riga propria e `then` sulla riga successiva. Il corpo di ogni handler è indentato di quattro spazi rispetto al `when`. Gli handler sono separati da una riga vuota per facilitare la lettura.

```sql
exception
    when no_data_found
    then
        raise_application_error(-20001, 'customer not found: ' || i_customer_id);

    when too_many_rows
    then
        raise_application_error(-20002, 'multiple customers found for id: ' || i_customer_id);

    when others
    then
        raise_application_error(-20099, 'unexpected error in process_customer_orders: ' || sqlerrm);

end process_customer_orders;
/
```

Il nome del sottoprogramma viene ripetuto dopo `end` per chiarire immediatamente a quale blocco appartiene la chiusura, specialmente nei file che contengono più unità o nei package body dove diversi sottoprogrammi si succedono. Lo slash `/` finale è obbligatorio per eseguire il blocco `create or replace` in SQL*Plus e negli strumenti compatibili.
