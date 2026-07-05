# Pacchetti base — catalogo e linee di contenuto

Questo documento è il catalogo ragionato dei package PL/SQL di base che accompagnano la partenza di un progetto costruito su questa base. Per ciascun package indica lo scopo, il contenuto atteso in forma di sottoprogrammi rappresentativi, le tabelle di appoggio e i prerequisiti di provisioning. Non è ancora la specifica esecutiva: è la mappa da cui attingere quando si realizzano i package, pensata per essere generosa — meglio depennare un'idea che scoprirne la mancanza a progetto avviato. Le priorità di realizzazione sono in fondo.

Il documento va letto insieme alle guidelines: i package qui elencati sono esattamente quelli che gli esempi dei capitoli 04–12 danno già per esistenti (`lib_types`, `lib_constants`, `lib_err`, `lib_logging`, `lib_lock`), più i servizi che completano una base di progetto. Realizzarli significa rendere effettivamente applicabili le regole che oggi li citano.

## Il principio: complemento, non copia

La trappola classica dei package di utilità è la brutta copia di Oracle: il `lib_date.to_date` che fa una `to_date`, il `lib_number.is_number` che riscrive ciò che `validate_conversion` fa nativamente dal 12c, il wrapper uno-a-uno su `dbms_scheduler` che aggiunge un livello di indirezione senza aggiungere valore. Questi package sembrano produttività e sono debito: vanno mantenuti, documentati e imparati, e l'unica cosa che offrono è una firma diversa per una funzione che esisteva già.

La regola di ammissione al set di base è quindi questa: **un sottoprogramma entra in un package base solo se fa qualcosa che Oracle non fa, o se combina più primitive Oracle in un comportamento di progetto** (convenzioni, logging, configurazione, guardie d'ambiente). Prima di scrivere una utility si verifica cosa offre già il dizionario delle funzioni SQL e dei package `DBMS_*`/`UTL_*`; se esiste l'equivalente nativo, si usa quello e il wrapper non si scrive.

Per fissare il confine, alcuni esempi concreti di ciò che **non** va scritto:

- niente wrapper di conversione: `to_date`/`to_char`/`to_number` con formato esplicito e `default ... on conversion error` (capitolo 12 delle guidelines) coprono già tutto, inclusa la validazione (`validate_conversion`);
- niente doppioni di funzioni stringa o data native (`initcap`, `trim`, `add_months`, `last_day`, `months_between`, `next_day`);
- niente reimplementazioni JSON: dalla 19c le API native (`json_object_t`, `json_array_t`, funzioni SQL/JSON) sono complete;
- niente wrapper passacarte su `dbms_scheduler`, `dbms_output`, `dbms_utility`: si chiamano direttamente, qualificati con `sys.`;
- niente "librerie matematiche": `round`, `trunc`, `mod`, `floor` esistono già; una funzione di arrotondamento entra solo se incorpora una *regola di business* (es. arrotondamento fiscale).

Il valore dei package base sta altrove: nel dare al progetto un modo **unico e osservabile** di trattare errori, log, configurazione, lock, batch, file e mail — le cose che ogni progetto reinventa in modo diverso se nessuno le standardizza.

## Regole trasversali

Alcune regole valgono per tutti i package del set, e conviene fissarle prima del catalogo.

I package base vivono nello **schema owner** `#APP#` e, salvo eccezioni dichiarate, **non vengono grantati** ai consumer: sono infrastruttura interna usata dalle API applicative, non superficie esposta. Per questo non richiedono lo sdoppiamento logica/guscio, che è riservato a ciò che si granta; se un giorno un package base dovesse essere esposto (ad esempio una funzione di `lib_report` invocabile dal batch), per quella sola parte si applica il meccanismo guscio come per qualsiasi API (la logica tiene il nome pulito, il guscio grantato prende il suffisso `_shell`).

Ogni package rispetta le guidelines senza sconti: prefisso `lib_` con nome esteso per i package di libreria (i package operativi usano invece `pkg_`, con la logica dal nome pulito e il guscio esposto `_shell`), parametri `i_`/`o_`/`io_`, costanti `k_MAIUSCOLE`, sottotipi `_sbt`, nessuna variabile pubblica nella spec (stato nel body con getter/setter), commento di documentazione prima dell'`is` di ogni sottoprogramma. Ogni package nasce con la sua **suite utPLSQL** (`test_<nome>`) e, dove ha tabelle di appoggio, con i relativi file baseline, seed e query di controllo: un package base senza test è un controsenso, dato che è il codice più riusato del progetto.

Le **dipendenze sono a strati e vanno in una sola direzione**: le fondamenta (tipi, costanti, errori, log) non dipendono da nulla; i servizi dipendono dalle fondamenta; le integrazioni dipendono dai servizi. Un package di fondamenta che chiama `lib_mail` è un errore di architettura — se il logging deve notificare via mail, è un processo schedulato a leggere i log e a spedirli, non il logger a conoscere la posta.

---

## Livello 0 — Fondamenta

Sono i package senza i quali gli altri non si scrivono. Non hanno dipendenze reciproche se non, al più, verso `lib_types` e `lib_constants`.

### `lib_types` — sottotipi condivisi

Sola specifica, senza body: raccoglie i sottotipi `_sbt` trasversali al progetto, allineati ai domini di `Catalogo/domini.md`. È il package più citato dalle guidelines ed è deliberatamente piccolo: un sottotipo entra solo se rappresenta un concetto ricorrente, non "per completezza".

- Sottotipi testuali per taglia: `code_sbt`, `name_sbt`, `short_text_sbt`, `text_sbt`, `big_string_sbt` (dimensioni coerenti con i domini `code`, `name`, `description`, `note`);
- sottotipi tecnici usati dai package base: `lock_name_sbt`, `lock_handle_sbt`, `scope_sbt` (per il logging), `percentage_sbt`, `flag_sbt` (`Y`/`N` pre-23ai);
- eventuali sottotipi numerici di dominio (`amount_sbt`, `quantity_sbt`) quando il progetto li adotta.

### `lib_constants` — costanti di progetto

Il punto unico per i valori letterali trasversali, secondo la regola del capitolo 04 delle guidelines, con le funzioni `deterministic` che espongono al SQL le costanti che servono anche nelle query. Contiene solo costanti davvero trasversali: i valori di stato di una singola entità di business stanno nel package API di quell'entità, non qui.

- Valori dei flag (`k_YES`/`k_NO`), formati data canonici del progetto (`k_DATE_FMT`, `k_TIMESTAMP_FMT`, sempre con `FX` dove usati in conversione);
- soglie e limiti condivisi (dimensione dei batch bulk, durata di default dei lock, giorni di retention dei log);
- per ogni costante necessaria in SQL, la corrispondente funzione deterministica (`function yes return varchar2 deterministic`).

### `lib_err` — catalogo e motore degli errori

Il package che le guidelines usano in tutti gli esempi (`lib_err.raise(i_error => lib_err.k_...)`, `when lib_err.e_lock_request_failed`). Tiene insieme in un solo oggetto il **catalogo** — codici, messaggi ed eccezioni con nome, dichiarati nella specifica — e il **motore** — le procedure che sollevano, arricchiscono e rilanciano, implementate nel body. La specifica resta leggibile come un registro: aggiungere un errore significa aggiungere una costante (e, se serve intercettarlo per nome, un'eccezione), senza toccare la logica.

Contenuto della specifica (il catalogo):

- una costante per ogni errore applicativo, con codice nel range riservato `-20000..-20999` **assegnato per fasce** (es. `-20000..-20099` infrastruttura, `-20100..-20199` primo dominio funzionale, e così via): la fascia è ciò che garantisce l'unicità che il capitolo 08 pretende;
- il messaggio associato a ogni codice, con segnaposto per i parametri (`Order %1 not found for customer %2`);
- le **eccezioni con nome** agganciate ai codici via `pragma exception_init` (`e_stale_data`, `e_lock_request_failed`, `e_invalid_parameter`...), dichiarate nella spec così che i chiamanti le intercettino per nome.

Contenuto del body (il motore):

- `raise(i_error, i_p1, i_p2, ...)` — solleva l'errore del catalogo sostituendo i segnaposto nel messaggio; è l'unico punto del progetto che chiama `raise_application_error`;
- `reraise` — rilancia l'eccezione corrente preservando lo stack, dopo il log;
- `message_of(i_error)` — restituisce il messaggio composto, per chi deve mostrarlo senza sollevare;
- integrazione fissa con `lib_logging`: ogni `raise` registra l'errore con backtrace prima di sollevarlo, così il log è completo anche se il chiamante ingoia l'eccezione.

### `lib_logging` — logging strutturato

Il motore di tracciamento su cui poggiano diagnosi e query di controllo: scrive su tabelle `log_*` in **transazione autonoma** (l'unico uso legittimo del pragma, capitolo 06), così che il log sopravviva al rollback della transazione applicativa. È il pezzo che rende leggibile "cosa è successo" in esercizio, ed è il presupposto della categoria di query di controllo "lettura dei log in produzione".

- `log_error(i_text, i_scope)` — registra messaggio, `sqlerrm`, `dbms_utility.format_error_backtrace`, call stack, utente effettivo (proxy-aware, via `lib_session`) e timestamp;
- `log_warn` / `log_info` / `log_debug(i_text, i_scope)` — livelli inferiori, filtrati a runtime;
- abilitazione **configurabile senza ricompilare**: livello minimo globale e override per scope, letti da `lib_config` e tenuti in cache nel body; il debug si accende su un modulo in produzione senza toccare il codice;
- `purge(i_retention_days)` — pulizia con retention da configurazione, pensata per un job schedulato;
- tabelle di appoggio: `log_entries` (il flusso), `log_errors` (gli errori con backtrace — o un'unica tabella con livello, da decidere in fase di disegno). Le colonne devono includere ciò che le query di controllo di `query_di_controllo.md` già interrogano.

---

## Livello 1 — Sessione e configurazione

### `lib_session` — identità, contesto e strumentazione di sessione

Il package dei "contesti": risponde a *chi sta operando* e *cosa sta facendo la sessione*, e centralizza l'uso dei contesti applicativi. È il complemento di progetto a `sys_context`, non un suo wrapper: il valore sta nel fissare **quale** identità conta in un modello con proxy e utenze tecniche, e nel dare un solo posto agli attributi di sessione che le viste e le API leggono.

- `current_actor` — l'identità effettiva secondo la convenzione del progetto: `proxy_user` quando ci si connette via proxy, altrimenti `session_user`, con l'eventuale `client_identifier` impostato dal front end per l'utente finale; è la funzione che popola i futuri `created_by`/`updated_by`;
- `set_client(i_identifier, i_info)` — imposta `client_identifier`/`client_info` per le connessioni applicative (il front end dichiara l'utente di business che sta servendo);
- `set_step(i_module, i_action)` — strumentazione via `dbms_application_info` con troncamento sicuro a 64 byte e integrazione con il run corrente di `lib_batch`; il pattern del capitolo 11 diventa una chiamata sola;
- gestione di un **contesto applicativo** (`create context #APP#_ctx using lib_session`): setter e getter tipizzati per gli attributi di sessione del progetto (es. unità organizzativa corrente, data contabile di lavoro), leggibili in SQL con `sys_context` e pronti per un eventuale futuro VPD. Richiede il privilegio `CREATE ANY CONTEXT` in provisioning — da aggiungere alle richieste SYS quando lo si adotta.

### `lib_config` — parametri applicativi

L'accesso disciplinato alla tabella `cfg_parameters`: getter tipizzati, default espliciti, cache. Evita le due derive classiche — parametri letti con `select` sparse nel codice, e valori "temporaneamente" hardcoded in attesa della tabella che non arriva mai.

- `get_string(i_name)`, `get_number(i_name)`, `get_date(i_name)`, `get_flag(i_name)` — con conversione controllata (formati espliciti) ed errore parlante dal catalogo di `lib_err` se il parametro manca o non converte; varianti con `i_default` per i parametri facoltativi;
- `set_value(i_name, i_value)` — l'unico punto di scrittura, che registra la modifica nel log (chi, quando, valore precedente);
- **identità d'ambiente**: `environment` (`DEV`/`TEST`/`PROD`, da una riga di configurazione valorizzata al provisioning) e `is_production` — la guardia che `lib_mail`, i job e gli strumenti usano per comportarsi diversamente fuori dalla produzione;
- cache nel body con `refresh` esplicito, per non pagare una query a ogni lettura;
- tabelle di appoggio: `cfg_parameters` (nome, valore, tipo dichiarato, descrizione, modificabilità).

---

## Livello 2 — Servizi

### `lib_lock` — lock applicativi

Il pattern del capitolo 11 promosso a package: serializzare processi che non devono girare in parallelo, appoggiandosi a `sys.dbms_lock` così che il rilascio sia garantito da Oracle anche in caso di crash della sessione.

- `request(i_lock_name, i_timeout_seconds)` — alloca l'handle con `allocate_unique`, richiede il lock esclusivo, solleva `lib_err.e_lock_request_failed` (o un più specifico `e_already_running`) se il lock non si ottiene nel tempo dato;
- `release(i_lock_handle)`;
- `run_exclusive` (facoltativo, seconda battuta): esegue una procedura passata per nome dentro la coppia request/release, per non duplicare il boilerplate try/finally nei batch;
- prerequisito: `grant execute on sys.dbms_lock` (già previsto in `template_system_grant.grt.sql`).

### `lib_batch` — ciclo di vita dei processi batch

Dà a ogni elaborazione un **run tracciato**: inizio, fine, esito, contatori. È ciò che permette all'AM di rispondere a "il batch di stanotte com'è andato?" con una query invece che con un'indagine, ed è il bersaglio della query di controllo "esito e durata degli ultimi run" già prevista in `query_di_controllo.md`.

- `start_run(i_process_name) return run_id` — apre il run su `log_process_runs`, imposta module/action via `lib_session`, opzionalmente acquisisce il lock di esecuzione singola via `lib_lock`;
- `end_run(i_run_id, i_status, i_rows_processed, i_rows_rejected)` — chiude il run con esito e statistiche; una variante `fail_run` registra l'errore corrente e chiude come fallito;
- `checkpoint(i_run_id, i_step, i_counter)` — avanzamento intermedio per i processi lunghi (aggiorna il run e l'action di sessione);
- tabelle di appoggio: `log_process_runs` (processo, inizio, fine, stato, contatori, run precedente) — la stessa che le query di controllo interrogano.

### `lib_assert` — validazione degli argomenti

Il complemento applicativo di `dbms_assert` (che valida identificatori SQL, non argomenti di business): rende la validazione dei parametri all'ingresso delle API una riga leggibile invece di un `if` con `raise` artigianale. Piccolo per costruzione.

- `not_null(i_value, i_param_name)` — solleva `lib_err.e_invalid_parameter` con il nome del parametro nel messaggio;
- `is_true(i_condition, i_error)` — asserzione generica con errore del catalogo;
- `in_range(i_value, i_min, i_max, i_param_name)`, `max_length(i_value, i_max, i_param_name)`;
- da tenere d'occhio: non deve crescere fino a duplicare i vincoli del database — l'integrità dei dati resta ai constraint; qui si validano gli *argomenti* delle chiamate.

### `lib_text` — testo: solo ciò che manca a Oracle

Il package più a rischio brutta copia, quindi con la lista chiusa più severa. Dentro solo ciò che Oracle non offre o offre in modo scomodo:

- `split(i_text, i_separator) return t_strings_type` — da stringa a collection (l'inverso di `listagg`, che nativamente non esiste senza APEX);
- `join(i_strings, i_separator)` — da collection a stringa, per i casi in cui i dati non sono già in una query;
- `format(i_template, i_p1, i_p2, ...)` — sostituzione di segnaposto `%1`, `%2` nei messaggi; è la primitiva usata da `lib_err` e `lib_mail` per i template;
- `normalize_code(i_text)` — normalizzazione per codici: maiuscole, accenti rimossi, spazi e caratteri non ammessi sostituiti; utile per generare codici mnemonici coerenti;
- eventuali helper CLOB *mirati* (costruzione efficiente di un CLOB da molti frammenti varchar2), solo se il profiling ne dimostra il bisogno;
- esplicitamente fuori: wrapper di `upper`/`trim`/`lpad`, `is_number`/`is_date` (esiste `validate_conversion`), replace multipli banali.

### `lib_calendar` — calendario di business

Un complemento vero: Oracle non sa nulla di giorni lavorativi e festività. Serve a qualsiasi progetto con scadenze, SLA o elaborazioni "il primo giorno lavorativo del mese".

- `is_working_day(i_date)`, `next_working_day(i_date)`, `previous_working_day(i_date)`;
- `add_working_days(i_date, i_days)`, `working_days_between(i_from, i_to)`;
- definizione del weekend e calendario festività su tabella `ref_holidays` (data, descrizione, eventuale calendario multiplo se il progetto opera su più piazze);
- da valutare in seconda battuta: periodi fiscali/contabili (`fiscal_period_of(i_date)`), se il dominio li usa.

---

## Livello 3 — Integrazione e output

### `lib_file` — I/O su file

Sopra `utl_file`, ma solo dove `utl_file` è scomodo o pericoloso da usare a mano crudo: lettura e scrittura intere, errori parlanti, directory da configurazione.

- `read_clob(i_directory, i_filename)` / `write_clob(i_directory, i_filename, i_content)` — file interi da/verso CLOB, con gestione dei chunk e chiusura garantita anche su eccezione;
- `exists(i_directory, i_filename)`, `remove`, `rename` — con mappatura degli errori `utl_file` (ORA-29283 e famiglia) su errori del catalogo comprensibili;
- validazione del nome file (niente path traversal: il nome non contiene separatori di percorso);
- directory logiche risolte via `lib_config` (`k_DIR_IMPORT`, `k_DIR_EXPORT`), non hardcoded nei chiamanti;
- prerequisiti: `grant execute on sys.utl_file` (ambienti hardened) e oggetti `DIRECTORY` con `read`/`write` grantati all'owner — richieste già previste nel provisioning SYS.

### `lib_mail` — invio mail

Il package generico di posta, il cui valore non è "chiamare `utl_smtp`" ma tutto ciò che ci sta intorno: costruzione corretta del messaggio, template, coda, e la guardia d'ambiente che evita di spedire mail vere dal collaudo.

- `send(i_to, i_subject, i_body, ...)` — invio con supporto multiparte: corpo testo/HTML, allegati da CLOB/BLOB con mime type, destinatari multipli, cc/bcc;
- `send_template(i_template_code, i_to, i_p1, ...)` — corpo e oggetto da `cfg_email_templates` con segnaposto risolti via `lib_text.format`: i testi si cambiano a configurazione, non a codice;
- **guardia d'ambiente**: fuori produzione (`lib_config.is_production = false`) i destinatari reali vengono riscritti verso una casella di test e il messaggio marcato — regola non aggirabile dal chiamante;
- modalità **accodata** come default consigliato: `send` scrive su `wrk_mail_queue` e un job schedulato spedisce con retry e backoff, così l'invio non allunga né fa fallire la transazione applicativa; l'invio sincrono resta disponibile per i casi che lo richiedono;
- ogni invio (o fallimento) tracciato via `lib_logging`;
- prerequisiti: `grant execute on sys.utl_smtp` + ACL di rete verso il mail server (previsti nel provisioning); da registrare come decisione: se l'infrastruttura ha APEX, `apex_mail` può fare da motore dietro la stessa interfaccia.

### `lib_report` — report automatici

Il tassello che lega insieme query di controllo, scheduler e posta: produce e recapita report tabellari senza che ogni esigenza di reportistica diventi un sviluppo ad hoc. Il caso d'uso principe è il **monitoraggio AM**: eseguire periodicamente le query di controllo e farsi vivo solo quando c'è qualcosa da guardare.

- `render_csv(i_cursor) return clob` / `render_html(i_cursor) return clob` — trasformano un `sys_refcursor` in CSV o tabella HTML usando `dbms_sql` per descrivere le colonne: funziona con qualsiasi query senza codice dedicato;
- `run_report(i_report_code)` — esegue un report registrato: legge la definizione, esegue la query, formatta e recapita via `lib_mail` o `lib_file`;
- registro dei report su `cfg_reports` (codice, descrizione, testo SQL o funzione che restituisce il cursore, formato, destinatari, pianificazione);
- modalità **"solo anomalie"**: per i report costruiti su query di controllo (convenzione "zero righe = tutto a posto") il recapito avviene solo se la query restituisce righe — il silenzio è la buona notizia;
- ogni esecuzione è un run di `lib_batch`, quindi tracciata e interrogabile.

### `lib_http` — chiamate HTTP in uscita *(opzionale, quando serve un'integrazione)*

Solo per progetti che chiamano servizi esterni dal database. Sopra `utl_http`, con il valore nelle cose che a mano si sbagliano: timeout espliciti, log di richiesta e risposta, mappatura degli errori, gestione degli header ripetitivi (autenticazione, content type). Da ricordare nei prerequisiti che HTTPS richiede il wallet configurato dal DBA oltre alla ACL. Se il progetto non ha integrazioni in uscita, questo package semplicemente non si crea.

### `lib_queue` — code di lavoro su tabella *(opzionale)*

La standardizzazione del pattern `wrk_` + `for update skip locked` del capitolo 06, per i progetti con elaborazioni a worker paralleli: `enqueue` di unità di lavoro, `dequeue` a lotti con skip delle righe contese, marcatura di esito con spostamento degli scarti verso la tabella `err_` corrispondente. Vale la pena solo se il pattern ricorre su più code; per una coda singola il pattern documentato basta.

### Sullo scheduling: convenzioni, non package

`dbms_scheduler` è deliberatamente **senza wrapper**: è già un'API completa e un `lib_scheduler` passacarte sarebbe l'esempio da manuale di brutta copia. Ciò che serve è una pagina di convenzioni (nomenclatura dei job `#APP#_<processo>_job`, job che invocano procedure le quali aprono un run con `lib_batch`, log degli esiti, abilitazione per ambiente) da aggiungere alle guidelines o a questo documento quando i primi job nascono. Se col tempo emergesse boilerplate ricorrente — creazione di job standard con le convenzioni applicate — si potrà valutare un singolo helper, non prima.

---

## Tooling di generazione (schema `#APP#_GEN`, solo sviluppo/test)

Questi package vivono nello schema di tooling, hanno i privilegi di introspezione che l'owner non ha, ed **emettono sorgenti** che entrano nel progetto dal normale percorso di install e review (mai installati direttamente). Sono la parte del set con il miglior rapporto tra sforzo e fatica risparmiata.

### `gen_shell` — generazione dei gusci

Legge dal dizionario la spec di un package di logica (nome pulito) e genera spec e body del guscio `_shell` corrispondente: firme identiche, corpo di pura delega, header conforme ai template. Elimina il costo di doppia manutenzione del meccanismo guscio — la modifica si fa sulla logica e il guscio si rigenera — che è oggi il prezzo più alto del pattern. Analogamente può generare la vista guscio `_shell_v` dalla vista di logica `_v` (elenco colonne esplicito).

### `gen_testbook` — precompilazione del test book

Interroga i metadati di utPLSQL (le annotazioni delle suite presenti) e genera lo scheletro del test book JSON con i casi `utplsql` già elencati e riferiti a suite e procedure. Chi implementa completa precondizioni, query di controllo e sign-off invece di partire dal foglio bianco. È il primo pezzo del generatore pianificato in `STATUS.md`.

### `gen_doc` — documentazione dal dizionario

Estrae commenti di tabelle e colonne, firme dei package esposti e commenti di documentazione, e produce markdown: il catalogo dati e la referenza API del progetto restano generabili e quindi sempre allineabili. È la ragione per cui le guidelines insistono sui commenti a dizionario.

### `gen_qc` — scheletri di query di controllo

Genera dal dizionario le query di controllo standard di un rilascio: oggetti invalidi dello schema, riepilogo delle migrazioni attese, e — per le tabelle indicate — gli scheletri delle verifiche di consistenza (orfani sulle FK dichiarate, duplicati sulle chiavi univoche). Chi implementa parte da una base meccanica e aggiunge le verifiche funzionali che solo lui conosce.

---

## Riepilogo e priorità

La tabella riassume il catalogo; la colonna delle priorità propone le ondate di realizzazione. La prima ondata è ciò che serve per scrivere il primo package applicativo *bene* (errori, log, configurazione, run); la seconda completa i servizi; la terza si attiva a domanda.

| Package | Livello | Tabelle di appoggio | Prerequisiti SYS | Priorità |
|---|---|---|---|---|
| `lib_types` | Fondamenta | — | — | 1ª ondata |
| `lib_constants` | Fondamenta | — | — | 1ª ondata |
| `lib_err` | Fondamenta | — (catalogo nella spec) | — | 1ª ondata |
| `lib_logging` | Fondamenta | `log_entries`, `log_errors` | — | 1ª ondata |
| `lib_session` | Sessione | — | `create any context` (se si adotta il contesto) | 1ª ondata (minimo: identità e `set_step`) |
| `lib_config` | Sessione | `cfg_parameters` | — | 1ª ondata |
| `lib_lock` | Servizi | — | `execute on sys.dbms_lock` | 1ª ondata |
| `lib_batch` | Servizi | `log_process_runs` | — | 1ª ondata |
| `lib_assert` | Servizi | — | — | 2ª ondata |
| `lib_text` | Servizi | — | — | 2ª ondata |
| `lib_calendar` | Servizi | `ref_holidays` | — | 2ª ondata |
| `lib_file` | Integrazione | — | `utl_file` + `DIRECTORY` | 2ª ondata |
| `lib_mail` | Integrazione | `cfg_email_templates`, `wrk_mail_queue` | `utl_smtp` + ACL | 2ª ondata |
| `lib_report` | Integrazione | `cfg_reports` | — (usa mail/file) | 2ª ondata |
| `lib_http` | Integrazione | — | `utl_http` + ACL + wallet | A domanda |
| `lib_queue` | Integrazione | tabelle `wrk_` dedicate | — | A domanda |
| `gen_shell` | Tooling GEN | — | dizionario (già previsto per `#APP#_GEN`) | 2ª ondata |
| `gen_testbook` | Tooling GEN | — | dizionario | 3ª ondata |
| `gen_doc` | Tooling GEN | — | dizionario | 3ª ondata |
| `gen_qc` | Tooling GEN | — | dizionario | 3ª ondata |

Due note per la fase di realizzazione. La prima: ogni package della prima ondata va disegnato **spec-first** — si scrive e si rivede la specifica con i commenti di documentazione, la si valida contro gli usi già presenti nelle guidelines (le firme citate negli esempi sono il contratto minimo), e solo dopo si implementa il body con la sua suite di test. La seconda: le tabelle di appoggio (`log_*`, `cfg_*`, `ref_holidays`, `wrk_mail_queue`) seguono il percorso normale dei sorgenti — baseline, commenti a dizionario, seed idempotenti per i dati di configurazione — e ognuna porta con sé le query di controllo che la riguardano.
