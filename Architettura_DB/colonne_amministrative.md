# Le colonne amministrative

Ogni tabella di business del framework porta, oltre alle proprie colonne di dominio, un insieme fisso di colonne che non descrivono *cosa* contiene la riga ma *come è nata e come è cambiata*: chi l'ha creata, quando e con quale programma; chi l'ha modificata l'ultima volta, quando e con quale programma; e un token che permette di rilevare le modifiche concorrenti. Sono sette colonne, sempre le stesse, con lo stesso nome e lo stesso tipo su tutte le tabelle. Questo documento spiega quali sono, come vengono valorizzate, perché sono progettate così e come si usano.

La ragione per cui vale la pena standardizzarle una volta sola, invece di lasciarle alla discrezione di chi crea la tabella, è la stessa che giustifica l'esistenza del framework. Un insieme di colonne amministrative identico ovunque **accelera lo sviluppo**, perché chi crea una tabella non deve reinventare né la struttura né il trigger che le popola: parte da un template già pronto. **Semplifica la manutenzione**, perché l'Application Maintenance sa che su qualsiasi tabella troverà sempre le stesse colonne, con lo stesso significato, interrogabili nello stesso modo per ricostruire chi ha toccato un dato e quando. E **facilita l'onboarding**, perché è una convenzione che si impara una volta e vale per tutto il progetto. Colonne di audit scritte a mano, con nomi diversi da una tabella all'altra, sono esattamente il tipo di entropia che il framework esiste per prevenire.

## Le sette colonne

Le colonne si dividono in due gruppi simmetrici — creazione e ultima modifica — più una colonna dedicata al controllo della concorrenza.

| Colonna | Gruppo | Significato | Tipo | Visibilità | NULL |
|---|---|---|---|---|---|
| `created_by` | Creazione | Utente applicativo che ha inserito la riga | `varchar2(64 char)` | Invisibile | No |
| `created_at` | Creazione | Istante dell'inserimento | `timestamp(6)` | Invisibile | No |
| `created_program` | Creazione | Programma/modulo che ha inserito la riga | `varchar2(64 char)` | Invisibile | No |
| `modified_by` | Ultima modifica | Utente applicativo dell'ultimo update | `varchar2(64 char)` | Invisibile | Sì |
| `modified_at` | Ultima modifica | Istante dell'ultimo update | `timestamp(6)` | Invisibile | Sì |
| `modified_program` | Ultima modifica | Programma/modulo dell'ultimo update | `varchar2(64 char)` | Invisibile | Sì |
| `row_version` | Locking | Contatore di versione della riga, per il locking ottimistico | `number` | **Visibile** | No |

I nomi sono in inglese e per esteso, coerentemente con le convenzioni di denominazione: si è preferita la leggibilità (`created_by`, `modified_at`) a forme contratte, perché queste colonne compaiono in ogni query di controllo e in ogni vista di sola lettura, e la chiarezza a colpo d'occhio vale più della compattezza. Le colonne che registrano lo stesso concetto semantico — l'istante di un evento, l'identità di un attore — hanno lo stesso nome su tutte le tabelle, come richiede la regola generale sull'uniformità dei nomi.

## Perché l'audit è invisibile e il version no

La scelta più significativa di questo disegno è che le sei colonne di audit sono **invisibili** mentre `row_version` è **visibile**. Non è un'asimmetria casuale: discende direttamente da chi deve leggere ciascuna colonna.

Le colonne invisibili — una funzionalità disponibile da Oracle 12c, quindi pienamente utilizzabile sulla baseline 19c del framework — sono escluse da tre contesti impliciti: non compaiono in `select *`, non entrano in un `%rowtype`, e non partecipano a un `insert into t values (...)` senza lista esplicita delle colonne. Restano a tutti gli effetti colonne normali — indicizzabili, interrogabili, vincolabili — ma solo quando le si nomina esplicitamente. Questa è esattamente la semantica che vogliamo per l'audit: sono impiantistica di servizio, popolata dal database, che il codice applicativo non deve né leggere né scrivere nella sua logica ordinaria. Tenerle fuori da `select *` e da `%rowtype` significa che una Table API che manipola `orders%rowtype` non se le trascina dietro, non rischia di sovrascriverle per errore, e non le espone a chi legge la riga senza averne bisogno. Chi *deve* leggerle — l'AM che indaga, una vista di sola lettura che le espone, una query di controllo — le nomina esplicitamente e le ottiene senza problemi.

`row_version`, al contrario, è **visibile** perché è l'unica delle sette che entra nella logica applicativa. Il locking ottimistico funziona solo se il client legge il valore della versione insieme al resto della riga e lo rimanda indietro al momento dell'update: se la colonna fosse invisibile, non uscirebbe da un `select *` né da un `%rowtype` e il meccanismo non avrebbe modo di funzionare senza che ogni query la nominasse a mano. Essendo visibile, entra naturalmente nel `%rowtype` che la Table API usa per ricevere e restituire le righe, ed è quindi disponibile dove serve senza alcuno sforzo aggiuntivo.

Questa interazione tra visibilità e `%rowtype` è la parte elegante del disegno, e conviene renderla esplicita: rendendo invisibili le colonne di audit e visibile la sola `row_version`, il tipo riga che la Table API passa avanti e indietro contiene *esattamente* ciò che l'applicazione deve vedere — le colonne di dominio più la versione — e nient'altro. La distinzione tra "plumbing gestito dal DB" e "dato che serve alla logica" è codificata nella struttura stessa della tabella, non affidata alla disciplina di chi scrive le query.

## Tipi, domini e politica dei NULL

I tipi si riconducono ai domini già definiti nel catalogo (`Catalogo/domini.md`). Le due colonne temporali usano il dominio `datetime_val` (`timestamp(6)`): la precisione al microsecondo è più che sufficiente per l'audit e si è deliberatamente rinunciato al fuso orario esplicito, perché il framework nasce per un contesto a fuso unico; un progetto multi-regione può promuoverle a `datetime_tz` documentando l'eccezione. Le tre colonne testuali (`created_by`, `created_program` e i loro omologhi di modifica) usano `varchar2(64 char)`, dimensione scelta per allinearsi ai limiti delle sorgenti da cui i valori provengono — il `CLIENT_IDENTIFIER` di sessione arriva a 64 byte, il `MODULE` a 48 — così che nessun valore legittimo venga troncato. `row_version` è un semplice `number` intero: non serve altro che un contatore che cresca a ogni modifica.

La politica dei NULL riflette la decisione presa in fase di disegno: le colonne di creazione sono **NOT NULL**, quelle di modifica sono **nullable**. Una riga ha sempre un creatore, quindi `created_by`, `created_at` e `created_program` non possono mai essere nulle — e non avendo un `DEFAULT`, se per qualsiasi motivo il trigger di audit non fosse presente o attivo, l'inserimento fallirebbe con un errore immediato invece di lasciare silenziosamente una riga senza tracciabilità. È una rete di sicurezza voluta: meglio un insert che si rompe rumorosamente di un audit che manca in sordina. Le colonne di modifica restano invece **NULL fino al primo update**: questo permette di distinguere a colpo d'occhio una riga mai modificata dopo la creazione da una che è stata toccata almeno una volta, informazione che andrebbe persa se le si valorizzasse fin dall'inserimento come copia delle colonne di creazione.

## La meccanica: il trigger di audit

Le sette colonne sono popolate da un unico trigger di riga per tabella, `<table>_audit_trg`, che scatta `before insert or update`. Concentrare in un solo trigger la gestione di tutte e sette le colonne — audit *e* versione — non è un dettaglio: è ciò che rende la meccanica uniforme, generabile automaticamente e facile da spiegare. Non ci sono `DEFAULT` di colonna, colonne virtuali o logiche sparse tra più oggetti; c'è un solo posto dove guardare.

Il trigger distingue i due rami. In **inserimento** valorizza le sole colonne di creazione, lascia esplicitamente a NULL quelle di modifica e inizializza `row_version` a 1. In **aggiornamento** fa tre cose: ricopia le colonne di creazione da `:old` a `:new` — così che restino immutabili anche se un update malaccorto o malevolo provasse a cambiarle — valorizza le colonne di modifica con l'attore e il momento correnti, e incrementa `row_version`. Questo riporta a `:new.row_version := nvl(:old.row_version, 0) + 1`: il valore che il client aveva letto e rimandato viene ignorato e sovrascritto dal database, perché la versione deve essere autorità del server, non un dato che il chiamante possa falsificare.

```sql
create or replace trigger orders_audit_trg
   before insert or update on orders
   for each row
begin
   if inserting then
      :new.created_by       := nvl( sys_context('userenv', 'client_identifier')
                                  , sys_context('userenv', 'session_user') );
      :new.created_at       := systimestamp;
      :new.created_program  := sys_context('userenv', 'module');
      :new.modified_by      := null;
      :new.modified_at      := null;
      :new.modified_program := null;
      :new.row_version      := 1;
   elsif updating then
      -- creation columns are immutable: carry them over untouched
      :new.created_by       := :old.created_by;
      :new.created_at       := :old.created_at;
      :new.created_program  := :old.created_program;
      --
      :new.modified_by      := nvl( sys_context('userenv', 'client_identifier')
                                  , sys_context('userenv', 'session_user') );
      :new.modified_at      := systimestamp;
      :new.modified_program := sys_context('userenv', 'module');
      :new.row_version      := nvl(:old.row_version, 0) + 1;
   end if;
end orders_audit_trg;
/
```

Il trigger tocca soltanto `:new` della riga corrente, quindi non incontra il *mutating table error* e non ha bisogno di essere un compound trigger: un semplice trigger di riga è la forma corretta e più economica. Non gestisce il `delete`, perché la cancellazione di una riga fa sparire la riga stessa e con essa le sue colonne di audit; tracciare le cancellazioni è un problema diverso, che si risolve con una tabella di storico (`his_*`) o di log (`log_*`), non con queste colonne.

## Da dove vengono "chi" e "con che programma"

Le colonne temporali e la versione il trigger le ricava da sé — `systimestamp` e un contatore non dipendono da nulla di esterno. L'identità dell'attore e il nome del programma, invece, devono arrivare al database dalla sessione, e qui c'è un punto architetturale che va comprensione esplicita.

In un'applicazione che si connette tramite un **connection pool**, tutte le sessioni condividono lo stesso utente di database — tipicamente lo schema applicativo `#APP#_APP`. Se il trigger leggesse `sys_context('userenv', 'session_user')` otterrebbe sempre quel nome tecnico, identico per tutti, inutile ai fini dell'audit. L'identità dell'utente *reale* deve quindi essere propagata al database per un canale diverso: il `CLIENT_IDENTIFIER` della sessione, impostato dall'applicazione con `dbms_session.set_identifier` all'inizio di ogni operazione, e leggibile dal trigger via `sys_context('userenv', 'client_identifier')`. Analogamente, il nome del programma si ricava dal `MODULE` della sessione, che l'applicazione valorizza con `dbms_application_info.set_module` — lo stesso meccanismo che il framework usa per il monitoraggio del progresso (si veda il pattern in `PlSql_Guidelines/11_patterns.md`).

Questo definisce una divisione di responsabilità netta e conveniente: **è la Table API a impostare il contesto di sessione** (chi e con quale programma) all'ingresso di ogni operazione, e **è il trigger a leggerlo e a stamparlo** sulle colonne. Il pacchetto di base `lib_session` esiste proprio per gestire l'identità effettiva in modo consapevole del proxy, ed è il punto naturale in cui centralizzare l'impostazione del `CLIENT_IDENTIFIER`; il trigger mostrato sopra usa direttamente `sys_context` per non dipendere da un pacchetto in fase di compilazione, ma un progetto che adotta `lib_session` può sostituire la lettura grezza con l'accessore dell'identità effettiva che quel pacchetto espone, mantenendo un'unica fonte di verità sull'attore.

Il `nvl` di fallback verso `session_user` non è cosmetico: garantisce che anche una DML eseguita fuori dal percorso applicativo — una correzione manuale dell'AM, un caricamento di servizio — lasci comunque una traccia sensata (l'utente di database effettivo) invece di un NULL. È esattamente lo scenario in cui l'audit conta di più, ed è la ragione per cui la stampa è affidata a un trigger e non alla sola Table API: il trigger copre *ogni* percorso di modifica, mentre l'API copre solo ciò che passa da lei.

## Il locking ottimistico

`row_version` implementa il controllo della concorrenza ottimistico, che è l'approccio corretto per un'applicazione OLTP in cui non si vuole tenere una riga bloccata per tutto il tempo in cui un utente la sta guardando o editando. Il principio è semplice: al momento della lettura, il client riceve la riga insieme al valore corrente di `row_version`; quando ripropone la riga in aggiornamento, la Table API esegue l'update vincolandolo alla versione che il client aveva letto.

```sql
update orders
   set ...                                   -- colonne di business
 where order_id    = i_order_id
   and row_version = i_expected_version;     -- la versione letta dal client

if sql%rowcount = 0 then
   lib_err.raise(lib_err.k_STALE_DATA);      -- qualcun altro ha modificato la riga
end if;
```

Se nel frattempo un'altra sessione ha modificato la riga, il trigger ne ha incrementato `row_version`, la clausola `where` non trova corrispondenza, `sql%rowcount` vale zero e la Table API segnala il conflitto invece di sovrascrivere silenziosamente le modifiche altrui. Il codice d'errore per questo caso esiste già nel catalogo del pacchetto di base `lib_err`: `k_STALE_DATA` (con l'eccezione con nome `e_stale_data`, che il chiamante può intercettare), il cui messaggio è *"Data was modified by another session; please retry."*. Il controllo, si noti, non vive nel trigger — il trigger si limita a *mantenere* la versione — ma nella clausola `where` dell'update, cioè nella Table API. La responsabilità è quindi ripartita: il database garantisce che la versione cambi a ogni modifica, l'API garantisce che ogni modifica verifichi la versione attesa e sollevi `k_STALE_DATA` quando non è più quella letta.

Si è preferito un contatore numerico incrementale a un token basato su timestamp per due ragioni. La prima è la compattezza e la chiarezza di intento: un intero che cresce di uno a ogni modifica è inequivocabile e non pone questioni di risoluzione o collisione. La seconda è che l'informazione temporale che un token-timestamp avrebbe portato è già registrata, in modo più esplicito, da `modified_at`: duplicarla nella colonna di versione sarebbe stato ridondante. Chi vuole sapere *quando* è avvenuta l'ultima modifica guarda `modified_at`; `row_version` risponde solo alla domanda "è ancora la stessa versione che avevo letto?".

## Prestazioni: OLTP contro batch

La domanda legittima su un trigger di riga è quanto costi. La risposta onesta è che per il carico **OLTP** — inserimenti e aggiornamenti di poche righe per transazione — il costo è trascurabile: una manciata di assegnazioni e due o tre letture di `sys_context` si misurano in microsecondi, una quantità invisibile accanto al costo della DML stessa, del round-trip di rete e del commit. Non c'è ragione di preoccuparsene, ed è pienamente sostenibile.

Il punto in cui i trigger di riga pesano davvero non è l'OLTP ma il **batch**: un `insert into ... select` di milioni di righe, o un update massivo, paga l'overhead del trigger una volta per riga e perde le ottimizzazioni bulk che Oracle applicherebbe in sua assenza, con un rallentamento che in quel contesto diventa misurabile. La regola pratica che ne discende è quindi: il trigger resta sempre attivo come garanzia di default, ma per i caricamenti massivi si valuta un percorso dedicato — la Table API che imposta i valori in modo esplicito, o tecniche direct-path — quando il profilo di performance lo richiede. È un'avvertenza da tenere presente, non un motivo per rinunciare al trigger nel funzionamento ordinario.

## Alternative considerate e scartate

Vale la pena spiegare perché la versione non è realizzata come colonna calcolata dal database, che a prima vista sembrerebbe la via più naturale. Una colonna dichiarata `generated always as (...)` in Oracle è una **colonna virtuale**, e le colonne virtuali hanno due proprietà che le rendono inadatte. Devono essere deterministiche: un'espressione che contiene `systimestamp` viene rifiutata in fase di DDL con `ORA-54002`, perché non è pura. E anche potendo, una colonna virtuale non è materializzata ma **ricalcolata a ogni lettura**: restituirebbe un valore diverso ogni volta che la si legge, l'esatto contrario di ciò che un token di locking deve fare, cioè restare stabile tra la lettura e l'update successivo. Una colonna virtuale, quindi, non può in alcun modo servire da versione di riga.

Nemmeno un semplice `DEFAULT` di colonna basterebbe: il `DEFAULT` interviene solo in inserimento e mai in aggiornamento, mentre la versione deve cambiare proprio a ogni update. Affidare la creazione a un `DEFAULT` e la modifica a un trigger avrebbe inoltre spezzato la logica tra due meccanismi diversi, contro l'obiettivo di avere un solo posto dove guardare. Per questo tutte e sette le colonne, versione compresa, sono gestite dall'unico trigger di audit.

Un'ultima alternativa è lo pseudo-colonna nativo `ORA_ROWSCN`, che con una tabella creata `rowdependencies` fornisce il numero di sistema (SCN) dell'ultima modifica della riga, permettendo il locking ottimistico senza alcuna colonna aggiuntiva. Il framework non la adotta per tre motivi. È opaca: un numero SCN non dice a un essere umano né chi né quando, mentre le nostre colonne esplicite raccontano la storia della riga. Ha un caso limite noto — il *delayed block cleanout* può far apparire cambiato l'SCN di una riga anche senza una modifica reale, generando falsi conflitti; è un comportamento sicuro (semmai troppo prudente) ma sorprendente da spiegare. E richiede che la tabella nasca `rowdependencies`, clausola non modificabile in seguito con un semplice `alter`. Una colonna di versione esplicita è più trasparente, più facile da testare con utPLSQL e priva di sorprese.

## Denominazione del trigger

Il trigger segue la convenzione già stabilita in `PlSql_Guidelines/02_naming_conventions.md` per i trigger orientati all'attività: nome della tabella, descrizione dell'attività svolta e suffisso `_trg`, cioè `<table>_audit_trg` (`orders_audit_trg`, `customers_audit_trg`). Si è scelta questa forma, e non un ipotetico prefisso `trg_`, proprio perché la convenzione del framework colloca `_trg` come suffisso e riporta `orders_audit_trg` come esempio canonico di trigger d'attività: adottarla mantiene la coerenza con lo standard già pubblicato invece di introdurre una seconda forma concorrente.

## Integrazione con il resto del framework

Queste colonne non vivono isolate: sono parte del contratto di ogni tabella e si riflettono in più punti del framework. Il **template di tabella** (`Gestione_Sorgenti/Templates/template_table.tab.sql`) include già il blocco delle sette colonne con i loro commenti a dizionario, così che ogni nuova tabella parta conforme. Il **template del trigger di audit** (`template_trigger_audit.trg.sql`) fornisce il trigger pronto, da affiancare a ogni tabella: essendo meccanico e identico a meno del nome della tabella, è anche un candidato naturale alla generazione automatica da parte del tooling `#APP#_GEN`. La **Definition of Done** richiede che ogni tabella di business porti le sette colonne e il relativo trigger. Le **viste di sola lettura** destinate all'AM e agli operatori, e le **query di controllo** che verificano chi ha toccato un dato, espongono le colonne di audit nominandole esplicitamente, dato che l'invisibilità le tiene fuori da `select *`.

Un'avvertenza pratica proprio su quest'ultimo punto: poiché le colonne di audit sono invisibili, un `select *` — tipicamente il primo gesto dell'AM che indaga su una riga — non le mostra. Chi ha bisogno di leggerle deve nominarle, e le viste di sola lettura pensate per la diagnosi dovrebbero elencarle in modo esplicito nel proprio corpo, così che l'informazione di audit sia a portata di mano di chi la consulta senza doverla richiedere colonna per colonna ogni volta.

## Improvement disponibili con Oracle 23ai

Lo standard è pensato per la baseline 19c e non richiede nulla oltre a essa. Su Oracle 23ai un paio di funzionalità permetterebbero varianti, segnalate qui come opzioni non obbligatorie. La più pertinente riguarda i valori di default per gli aggiornamenti: la clausola `DEFAULT ON NULL` e, più in generale, l'evoluzione dei default consentirebbero di spostare parte della logica di inizializzazione dalla procedura al DDL, anche se nel nostro caso la scelta di concentrare tutto nel trigger resta preferibile per uniformità. Resta valido il principio generale del framework: dove una feature 23ai semplifica davvero, la si valuta come improvement documentato, senza renderla il default finché la baseline è 19c.
