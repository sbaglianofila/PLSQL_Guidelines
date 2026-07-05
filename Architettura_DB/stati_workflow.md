# Stati e workflow

> **Bozza.** Questo documento è una stesura in raffinamento. Fissa l'impianto e le scelte di fondo — la maggior parte delle decisioni è ormai presa (vedi "Decisioni prese in questa passata") e resta un solo nodo aperto, segnalato in fondo. Non è ancora un contratto stabile del framework.

## Perché gli stati non sono lookup

Lo stato di un ordine, di una pratica, di un documento sembra a prima vista una lista di valori come un'altra — `OPEN`, `PROCESSED`, `CANCELLED` — e verrebbe la tentazione di metterlo tra le lookup generiche descritte in `lookups.md`. È una tentazione da respingere, perché uno stato non è un valore piatto: è un nodo di una **macchina a stati**. Di uno stato non interessa solo il codice e l'etichetta, ma da quali altri stati ci si può arrivare e verso quali si può proseguire — le *transizioni ammesse* — e, altrettanto importante, la storia di come ogni singola entità ha attraversato quegli stati nel tempo: chi ha portato l'ordine da `OPEN` a `PROCESSED`, quando e perché.

Nessuna di queste tre cose — le transizioni, le regole che le governano, l'audit dei cambiamenti per entità — entra nelle tabelle di lookup, che sanno soltanto elencare valori. È l'esempio più netto della "regola di promozione" enunciata in `lookups.md`: gli stati graduano a un pillar dedicato, con un prefisso proprio, `wfl_` (workflow). Questo documento ne definisce l'impianto.

Vale la pena distinguere subito questo pillar dal lavoro sulle colonne amministrative (`colonne_amministrative.md`), perché i due si completano ma operano a livelli diversi. Le sette colonne amministrative dicono, per ogni riga, chi l'ha modificata l'ultima volta e quando — un'informazione a grana di riga, indifferenziata rispetto a *cosa* è cambiato. L'audit dei cambi di stato dice qualcosa di più specifico e più ricco: che la dimensione *stato* è passata da un valore a un altro, per opera di chi, quando e per quale motivo. La prima è impiantistica generale; la seconda è tracciamento di dominio sulla transizione di stato.

## L'impianto: tre livelli

Il pillar si articola su tre livelli, due di *definizione* del workflow (gli stati e le transizioni ammesse) e uno di *storia* (l'audit dei cambiamenti effettivamente avvenuti).

### Gli stati di un workflow: `wfl_statuses`

Ogni workflow ha il proprio insieme di stati. A differenza di un valore di lookup, uno stato porta attributi che descrivono il suo ruolo nella macchina: se è lo stato *iniziale* in cui un'entità nasce, se è uno degli stati *finali* oltre i quali non si prosegue, oltre all'etichetta e all'ordinamento di presentazione.

| Colonna | Tipo | Scopo |
|---|---|---|
| `workflow_code` | `varchar2(32 char)` | Il workflow di appartenenza (`'ORDER'`) |
| `status_code` | `varchar2(32 char)` | Il codice dello stato (`'OPEN'`) |
| `label` | `varchar2(128 char)` | Testo mostrato a video |
| `sort_order` | `number` | Ordine di presentazione |
| `is_initial` | `flag` | Stato in cui l'entità nasce (uno per workflow) |
| `is_final` | `flag` | Stato terminale (zero o più per workflow) |
| `is_valid` | `flag` | Stato ancora in uso o dismesso |

con chiave `(workflow_code, status_code)` e le sette colonne amministrative.

### Le transizioni ammesse: `wfl_transitions`

È qui che vive la macchina a stati vera e propria: l'elenco degli archi ammessi tra uno stato e l'altro. Una riga per ogni transizione permessa, con opzionalmente il ruolo autorizzato a compierla o una condizione da soddisfare.

| Colonna | Tipo | Scopo |
|---|---|---|
| `workflow_code` | `varchar2(32 char)` | Il workflow di appartenenza |
| `from_status` | `varchar2(32 char)` | Stato di partenza |
| `to_status` | `varchar2(32 char)` | Stato di arrivo |
| `allowed_role` | `varchar2(32 char)` | Ruolo autorizzato alla transizione (opzionale) |
| `is_valid` | `flag` | Transizione attiva o disattivata |

con chiave `(workflow_code, from_status, to_status)`, foreign key di `from_status` e `to_status` verso `wfl_statuses`, e le colonne amministrative. La regola "da `OPEN` si può solo andare a `PROCESSED` o `CANCELLED`" diventa così un dato, non codice: aggiungere o togliere una transizione ammessa non richiede di ricompilare nulla.

### L'audit dei cambiamenti

Il terzo livello registra ciò che è realmente accaduto: una riga per ogni transizione avvenuta su una specifica entità. È un log append-only che risponde alla domanda "come è arrivato quest'ordine allo stato in cui è?".

Questo audit è realizzato con una **tabella dedicata per entità**, non con un contenitore generico unico. La scelta applica la stessa regola di promozione usata altrove nel framework: una tabella per entità porta una foreign key tipizzata e pulita verso la riga di business (`orders`, `contracts`, …), mentre un contenitore generico con colonne `entity_table`/`entity_id` avrebbe perso quell'integrità dichiarativa, come accade alle lookup generiche. La tabella si colloca nel pillar sotto il prefisso `wfl_`, con un nome che identifica l'entità e la sua natura di storia degli stati — per esempio `wfl_orders_status_log`.

| Colonna | Tipo | Scopo |
|---|---|---|
| *(FK all'entità)* | `number` | La riga di business che ha cambiato stato (FK tipizzata, es. `order_id` → `orders`) |
| `from_status` | `varchar2(32 char)` | Stato di partenza (nullo alla creazione) |
| `to_status` | `varchar2(32 char)` | Stato di arrivo |
| `changed_at` | `timestamp(6)` | Istante del cambiamento |
| `changed_by` | `varchar2(64 char)` | Utente che ha effettuato il cambiamento |
| `reason` | `varchar2(512 char)` | Motivo del cambiamento (opzionale) |

Ogni entità con un workflow ha quindi la propria tabella `wfl_<entità>_status_log`. Il costo — una tabella in più per entità con workflow — è basso e ripaga in chiarezza e integrità; le entità senza workflow semplicemente non ne hanno.

## La validazione: `lib_workflow`

Le tabelle di definizione descrivono la macchina a stati; qualcuno deve farla rispettare. Il posto è la Table API dell'entità, appoggiata a un package di base — chiamiamolo `lib_workflow` — che espone le operazioni ricorrenti: verificare se una transizione è ammessa (`can_transition(workflow, from, to, role)`), ed effettuare un cambiamento di stato validandolo e registrandolo nell'audit in un colpo solo (`change_status`). Concentrare qui la logica evita che ogni entità reimplementi il controllo delle transizioni, e garantisce che nessun cambiamento di stato sfugga all'audit: si cambia stato solo passando da `lib_workflow`, che valida contro `wfl_transitions` e scrive la storia. Questo package andrebbe aggiunto al catalogo dei pacchetti base.

## Rapporto con le colonne amministrative

Vale la pena chiarire un potenziale doppione. La tabella di audit dei cambiamenti è, a sua volta, una tabella che porterebbe le sette colonne amministrative standard; e le sue colonne `created_by`/`created_at` conterrebbero di fatto la stessa informazione di `changed_by`/`changed_at`, dato che ogni riga di audit nasce nel momento del cambiamento e non viene più modificata. Qui la scelta è tra due strade: appoggiarsi alle colonne amministrative (l'evento è "chi ha creato la riga di audit") oppure tenere colonne esplicite `changed_by`/`changed_at` di dominio. Si adottano le **colonne esplicite**, perché `reason`, `from_status` e `to_status` sono già dati di dominio e avere accanto `changed_by`/`changed_at` esplicite rende la tabella auto-descrittiva senza dover ricordare che qui, eccezionalmente, l'audit di riga coinciderebbe con il dato di business. Le sette colonne amministrative restano comunque presenti (sono lo standard di ogni tabella), ma il significato funzionale del cambiamento si legge nelle colonne esplicite.

## Decisioni prese in questa passata

Tre nodi che nella prima stesura erano aperti sono stati sciolti.

L'**audit dei cambiamenti** è realizzato con tabelle **dedicate per entità** (`wfl_<entità>_status_log`), con foreign key tipizzata verso la riga di business, e non con un contenitore generico: si applica la regola di promozione, privilegiando l'integrità dichiarativa dove conta, come descritto nella sezione dell'audit.

Il **prefisso del pillar** è `wfl_`, per tutti i suoi oggetti — definizioni (`wfl_statuses`, `wfl_transitions`) e audit (`wfl_<entità>_status_log`). Si è scelto `wfl_` e non `wf_` per coerenza con gli altri prefissi funzionali del framework, tutti di tre lettere; e si è preferito tenere anche l'audit sotto `wfl_`, per coesione del pillar, invece di classificarlo sotto `log_`: pur essendo un log di eventi, appartiene concettualmente al workflow ed è comodo trovarlo accanto alle sue definizioni.

Le **transizioni** portano un `allowed_role` opzionale come unica forma di guardia in questa fase. È sufficiente per esprimere "questa transizione la può compiere solo questo ruolo", che copre il bisogno immediato.

## Sviluppi futuri

Un **motore di regole** più espressivo per le transizioni — capace di guardie condizionali sui dati dell'entità, e di azioni o hook richiamati al passaggio di stato (per esempio l'invio di una notifica) — è riconosciuto come evoluzione desiderabile, ma **rimandato e a bassa priorità**. Va sviluppato solo quando un bisogno concreto lo giustifichi: il rischio, altrimenti, è costruire un motore di regole generico che il framework non ha chiesto e che complica senza ripagare. Fino ad allora, la logica specifica di una transizione che ecceda il semplice controllo del ruolo vive nella Table API dell'entità, non nelle tabelle di definizione.

## Decisioni ancora aperte

Resta un solo nodo da sciogliere nella prossima passata: il **rapporto con le lookup dal lato delle tabelle di business**. Gli stati sono definiti in `wfl_statuses` e non nelle lookup generiche; va però deciso se le tabelle di business che portano una colonna di stato debbano referenziare `wfl_statuses` con una foreign key composita — sullo stile di quella descritta in `lookups.md`, ma verso gli stati del workflow — così da vincolare dichiarativamente la colonna di stato ai soli stati di quel workflow, oppure se lasciare quel controllo alla sola Table API.
