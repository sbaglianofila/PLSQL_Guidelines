# MIGLIORIE — Secondo parere indipendente sul framework

Questo documento raccoglie l'esito di una revisione critica e indipendente dell'intero framework, condotta leggendo tutti i documenti di governance, le guidelines PL/SQL, l'architettura degli schemi, la gestione dei sorgenti, il pilastro di testing, il processo, il catalogo, i template con i relativi esempi e la guida Git. Non è un documento del framework: è un parere esterno, da usare come serbatoio di interventi futuri. La struttura è quella richiesta: una sintesi complessiva, le migliorie raggruppate per area, e una priorizzazione finale.

---

## Sintesi complessiva

Il giudizio d'insieme è positivo, e va detto senza reticenze: questo è un impianto sopra la media per un framework PL/SQL aziendale. I punti di forza sono reali e non di facciata. Le decisioni tecniche fondanti sono giuste e — cosa più rara — sono *motivate* per iscritto: la tripartizione dei sorgenti (ripetibili, baseline, migrazioni) è esattamente la distinzione che Flyway e Liquibase formalizzano, e adottarla oggi con script manuali rende la migrazione futura un'operazione di impacchettamento, non di ripensamento. Il modello degli schemi è disegnato attorno a un vincolo di contesto concreto (database gestito dal cliente) e ne trae conseguenze coerenti: sinonimi privati, autenticazione proxy, quota scoped, privilegio minimo sul dizionario. La strategia di test a due livelli — utPLSQL per la logica, query di controllo per lo stato reale — con la convenzione "zero righe = tutto a posto" è pragmatica e adatta al destinatario AM. La Definition of Done a tre gambe lega tutto in un criterio verificabile. Il rifiuto esplicito della sovra-ingegnerizzazione (niente `develop`, niente multi-versione finché non serve) è una qualità, non una mancanza. Infine, la disciplina di governance (INDEX/STATUS/CHANGELOG aggiornati insieme) funziona: lo stato dichiarato in `STATUS.md` corrisponde davvero a ciò che c'è nel repository.

Le criticità principali sono tre, e sono di natura diversa.

La prima è di **completezza sostanziale**: le guidelines danno per esistente un'infrastruttura che il framework non fornisce. I capitoli 6, 8, 9 e 11 usano sistematicamente `logging_up`, `err_up.raise`, `err.k_*`, e le query di controllo interrogano `log_errors` e `log_process_runs` — ma da nessuna parte esistono la specifica, il DDL o anche solo il contratto minimo di questo framework di errori e logging. È il pezzo mancante più importante: la gestione centralizzata degli errori è dichiarata regola *Critical* e poi lasciata interamente all'immaginazione di chi implementa. Nella stessa famiglia rientra l'assenza di un registro delle migrazioni applicate sul database: con deploy a script manuali, non c'è alcun modo strutturato di sapere quali migrazioni un ambiente ha già ricevuto.

La seconda è di **coerenza editoriale delle guidelines**: il corpus dei capitoli 04–12 (chiaramente derivato da materiale preesistente) non è stato riconciliato con le convenzioni normative del capitolo 02. Gli esempi usano `in_`/`out_` dove la norma dice `i_`/`o_`, `co_` dove la norma dice `k_`, `_type` dove la norma dice `_sbt`, costanti minuscole dove la norma le vuole maiuscole. Nessuna di queste divergenze è grave da sola, ma insieme minano proprio l'autorevolezza che un documento di standard deve avere: chi impara copiando gli esempi imparerà la convenzione sbagliata.

La terza è di **precisione tecnica su un punto architetturale centrale**: la giustificazione del meccanismo guscio per i package è in parte sovradimensionata, perché Oracle già nasconde nativamente il body di un package a chi ha solo `EXECUTE`. Il pattern resta valido — e per viste e oggetti standalone è davvero necessario — ma la motivazione va corretta, altrimenti prima o poi qualcuno la verificherà e metterà in dubbio tutto il resto.

A queste si aggiungono lacune minori ma reali (colonne di audit standard, backout dei rilasci, tooling per far rispettare uno stile di formattazione molto rigido) e alcune opportunità 23ai non ancora registrate. Il dettaglio segue.

---

## Area 1 — Coerenza interna delle guidelines

### 1.1 Riconciliare gli esempi dei capitoli 04–12 con le convenzioni del capitolo 02

**Problema.** Il capitolo `02_naming_conventions.md` fissa convenzioni precise che i capitoli successivi violano sistematicamente nei propri esempi:

- **Prefissi dei parametri**: la norma è `i_` / `o_` / `io_`, e i template in `Gestione_Sorgenti/Templates/` la rispettano (`i_customer_id`). Ma decine di esempi nei capitoli 05–12 usano `in_` / `out_` (`in_dept_id`, `out_new_salary`, `in_employee_id`), che è la convenzione Trivadis originale, non quella adottata.
- **Costanti**: la norma è prefisso `k_` con nome in maiuscolo (`k_STATUS_PENDING`, ribadito in `03_coding_style.md`). Il capitolo 12 usa il prefisso `co_` in minuscolo (`co_dob_str`, `co_salary`); l'esempio ufficiale `Esempi/orders_impl.pkb.sql` usa `k_status_open` in minuscolo.
- **Sottotipi**: la norma è suffisso `_sbt` (`big_string_sbt`); il capitolo 05 definisce e usa ovunque `big_string_type`, `description_type`, `salary_type`.
- **Package dei tipi**: compare come `types_up` in quasi tutti gli esempi ma come `type_up` (senza s) nel capitolo 11.
- **Alias di tabella**: la regola dei tre caratteri esatti convive male con il glossario, che approva `dept` (4) ed `empl` (4); e gli esempi oscillano fra `cus` e `cli` per `customers`, fra `dpt` e `dep` per `departments` — mentre il glossario è categorico ("non sono ammesse varianti").
- **Esempi di constraint**: `empl_fk_dept` e `sct_uk_contracts` non rispettano gli schemi dichiarati nella stessa tabella che li ospita (`<tabella>_fk[n]_<tabella_riferita>` con nome tabella completo, `<tabella>_uk[n]_<colonna>`).

**Perché conta.** In un documento di standard, gli esempi *sono* la norma percepita: vengono copiati molto più spesso di quanto venga letta la tabella delle convenzioni. Ogni divergenza fra norma ed esempio produce codice incoerente in buona fede e discussioni in code review che lo standard esisteva apposta per evitare. È inoltre il tipo di difetto che erode la fiducia nel documento: se il framework non rispetta sé stesso, il singolo sviluppatore si sentirà autorizzato a fare altrettanto.

**Proposta.** Un passaggio editoriale unico e sistematico su tutti i capitoli 04–12 e sugli esempi in `Templates/Esempi/`, con una decisione esplicita per ogni coppia in conflitto (registrata in `STATUS.md`): `i_`/`in_`, `k_MAIUSCOLO`/`k_minuscolo`/`co_`, `_sbt`/`_type`, lunghezza degli alias e loro rapporto col glossario (una soluzione pulita: gli alias di query sono un asse separato dalle abbreviazioni dei nomi, e il glossario ospita una colonna "alias" a tre caratteri per i termini che ne hanno bisogno). Il lavoro è meccanico ma lungo; si presta bene a essere fatto capitolo per capitolo con un assistente, verificando ogni esempio contro la tabella del capitolo 02.

### 1.2 Correggere gli esempi che non compilano sotto il modello di privilegi del framework

**Problema.** Alcuni esempi delle guidelines presuppongono privilegi che l'architettura degli schemi nega deliberatamente all'owner. Il pattern `dbms_application_info` nel capitolo 11 ancora le costanti a `v$session.action%type`: per compilare serve `SELECT` su `v_$session`, che l'owner non ha (e non deve avere). L'esempio del `goto` nel capitolo 07 usa `dba_users.password%type`: stesso problema con le viste `DBA_*`, aggravato dal fatto che quella colonna è deprecata. Il pattern dei lock applicativi usa `sys.dbms_lock`, il cui `EXECUTE` non è concesso di default agli utenti normali in 19c — e i template SYS di provisioning non lo prevedono fra i grant.

**Perché conta.** Sono esempi che falliscono alla prima applicazione reale, nel momento peggiore: quando uno sviluppatore junior sta seguendo le istruzioni alla lettera. Il caso `dbms_lock` è il più insidioso perché il difetto non è nell'esempio ma nel provisioning: il pattern è raccomandato a livello *Blocker* e l'infrastruttura per usarlo non viene mai creata.

**Proposta.** Sostituire gli ancoraggi a viste privilegiate con subtype propri (`types_up`) o tipi espliciti; aggiornare l'esempio `dba_users`. Per `dbms_lock`, aggiungere il grant al template `template_system_grant.grt.sql` (con nota sul perché) oppure — meglio, se il progetto può assumere 19c come minimo reale — valutare `dbms_lock` solo per i lock e documentare che la richiesta del grant fa parte delle richieste ai DBA in `Sources/SYS/Grants/`.

### 1.3 Allineare la baseline dichiarata (11gR2 vs 19c) e le note di stato

**Problema.** `01_introduction.md` dichiara come target "Oracle Database, versione 11g Release 2 o successive", mentre la decisione vincolante del framework è 19c come baseline. Il `README.md` afferma che i pilastri diversi dalle guidelines "sono in via di costruzione", ma `STATUS.md` li dà (correttamente) tutti completati tranne l'onboarding. Nella tabella delle famiglie in `sorgenti.md`, i file `.dat` sono classificati come *Migrazione*, ma il template `template_data.dat.sql` è deliberatamente idempotente via `MERGE` e il file non porta data: di fatto è un ripetibile.

**Perché conta.** Sono piccolezze, ma tutte e tre stanno in documenti d'ingresso o in tabelle normative, cioè nei punti che un nuovo arrivato legge per primi. La classificazione dei `.dat` in particolare ha una conseguenza operativa: se sono "migrazioni" non andrebbero mai modificati dopo il merge, ma un seed idempotente per sua natura *si aggiorna* nel tempo (nuove righe di configurazione) — le due regole sono incompatibili.

**Proposta.** Aggiornare l'introduzione a "19c come baseline, con note sulle funzionalità 12c+ dove rilevanti e improvement 23ai segnalati come opzionali"; correggere il paragrafo del README; riclassificare `.dat` come famiglia ripetibile (o famiglia propria "seed idempotente"), coerente con il template.

### 1.4 Risolvere il conflitto fra la regola del return unico e il pattern `no_data_found → return null`

**Problema.** Il capitolo 10 impone "al massimo un `return` per funzione" e "il `return` come ultima istruzione", ma il pattern codificato nei capitoli 07, 08 e 11 per le funzioni di lookup è `exception when no_data_found then return null; when too_many_rows then raise;` — che produce inevitabilmente due o tre `return` per funzione, incluso uno nell'handler. L'esempio `dept_by_name` del capitolo 11 ha `return` dentro un sotto-blocco e nei suoi handler.

**Perché conta.** Un revisore che applica la checklist alla lettera dovrebbe bocciare il pattern ufficiale del framework. Le regole in contraddizione fra loro non vengono applicate: vengono ignorate entrambe.

**Proposta.** Ammorbidire la regola del return unico con l'eccezione esplicita già praticata: un `return` nel corpo più eventuali `return` nei gestori di eccezioni prevedibili sono conformi. In alternativa, riscrivere il pattern di lookup con variabile di risultato — ma la prima via è più realistica e più leggibile.

---

## Area 2 — Il meccanismo guscio: precisare la motivazione tecnica

**Problema.** `schemi.md` giustifica il pattern guscio/`_impl` così: "Concedere `EXECUTE` su un package rende quel package accessibile, e quindi il chiamante può leggerne il sorgente". Per i package questa affermazione è vera solo a metà, ed è la metà che non conta: chi ha `EXECUTE` su un package vede in `ALL_SOURCE` la **specifica**, ma **non il body**, che Oracle espone solo all'owner e a chi possiede privilegi di dizionario ampi. Poiché la logica di un package vive nel body, per i package la protezione che il guscio promette esiste già nativamente. Il discorso è diverso — e lì il pattern è davvero necessario — per le **viste** (chi ha `SELECT` legge il testo in `ALL_VIEWS`) e per **procedure e funzioni standalone** (il cui sorgente è integralmente visibile all'esecutore).

**Perché conta.** Il guscio ha un costo permanente non banale: ogni funzionalità esiste in due oggetti, ogni modifica di firma tocca quattro file (spec e body di api e impl), ogni grant e sinonimo va tenuto allineato. Un costo del genere si sostiene solo se la motivazione regge; se la motivazione dichiarata è confutabile con una prova di cinque minuti su `ALL_SOURCE`, il giorno che qualcuno la confuta il team smetterà di rispettare il pattern anche dove serve davvero (le viste). Peggio: la spec del guscio, che è leggibile, spesso ancora i parametri con `%type` alle tabelle, rivelando comunque nomi di tabelle e colonne — un dettaglio che il documento non affronta.

**Proposta.** Non abbandonare il pattern, ma rifondarne la motivazione su basi corrette e più solide, distinguendo i casi. Per le viste e gli oggetti standalone: protezione del sorgente, come oggi. Per i package: i benefici reali sono l'API stabile e minimale verso i consumatori (la spec del guscio non espone tipi, costanti ed eccezioni interne), la libertà di rifattorizzare l'implementazione senza toccare l'oggetto grantato, e un bersaglio pulito per i test (`_impl`). Aggiungere due regole pratiche oggi assenti: la spec del guscio non usa `%type` verso le tabelle (usa i subtype di `types_up` o tipi espliciti), per non rivelare struttura; e va detto esplicitamente che chi ha `SELECT ANY DICTIONARY` (l'AM, per scelta) legge tutto — il guscio protegge dai consumatori applicativi ed esterni, non dall'AM, ed è intenzionale. Se dopo questa analisi il team ritenesse il doppio package troppo costoso per gli oggetti a bassa esposizione, si può graduare: guscio obbligatorio per ciò che è grantato a `EXT_*`, opzionale all'interno.

---

## Area 3 — Gestione errori, logging e strumentazione: il pilastro mancante

**Problema.** È la lacuna più importante del framework. Le guidelines *impongono* un framework centralizzato di gestione errori e logging (capitolo 08, livello *Critical*) e lo usano in tutti gli esempi (`logging_up.log`, `logging_up.log_error`, `err_up.raise(in_error => err.k_INVALID_EMPLOYEE_ID)`, `err.e_lock_request_failed`); le query di controllo interrogano tabelle `log_errors`, `log_process_runs`, `err_import_rows`; le convenzioni di denominazione prevedono i prefissi `log_` ed `err_`; la Definition of Done pretende query di lettura dei log. Ma il framework non contiene né la specifica dei package `logging_up`/`err_up`, né il DDL di riferimento delle tabelle di log, né i criteri (cosa si logga, a che livello, con quale retention, come si usa la transazione autonoma che il capitolo 06 ammette proprio e soltanto per questo scopo).

**Perché conta.** Ogni progetto che adotta la base dovrà inventarsi questa infrastruttura da zero, e la inventerà in modo diverso dagli altri — esattamente ciò che un framework esiste per impedire. È anche un'incoerenza formale: la Definition of Done non è soddisfacibile così com'è, perché la "lettura dei log in produzione" presuppone tabelle di log che nessun documento definisce. Infine, la strumentazione è il singolo fattore che più distingue un'applicazione PL/SQL diagnosticabile in esercizio da una che si indaga alla cieca: lasciarla implicita è in contrasto con la vocazione AM del framework.

**Proposta.** Aggiungere un documento (e i relativi template) per un pilastro "Gestione errori e logging" con: il DDL di riferimento delle tabelle `log_process_runs`, `log_errors` (e `err_*` per gli scarti batch) con colonne standard; la specifica minima di `logging_up` (livelli, scope, uso della transazione autonoma, cosa registrare: `sqlerrm` + `format_error_backtrace` + contesto) e di `err_up`/`err` (registro dei codici `-20xxx` con range assegnati, per garantire l'unicità che il capitolo 08 chiede); le regole d'uso (ogni processo batch apre e chiude un run in `log_process_runs`; ogni `when others` logga e rilancia). In alternativa alla scrittura ex novo, valutare l'adozione dell'open source **Logger** (oracle/logger) come motore, incapsulato dietro `logging_up` per non accoppiarsi: la scelta va comunque documentata. Questo pilastro chiuderebbe il cerchio con `dbms_application_info` (già trattato) e darebbe alle query di controllo il loro bersaglio concreto.

---

## Area 4 — Deploy e migrazioni: tracciamento, ripresa, backout

### 4.1 Registro delle migrazioni applicate sul database

**Problema.** Con script ordinati eseguiti a mano non esiste alcuna registrazione, *nel database*, di quali migrazioni siano state applicate e quando. L'unica verifica proposta è indiretta (query di controllo che accerta l'esistenza di una colonna). Se un ambiente salta una release, o un DBA applica un pacchetto a metà, la ricostruzione dello stato è archeologia.

**Perché conta.** È il problema che Flyway e Liquibase risolvono con la loro tabella di storia, ed è la ragione per cui esistono. Il framework è dichiaratamente *migration-ready*, ma la prontezza riguarda solo l'alberatura dei file: manca la metà runtime. Una tabella di registro, oltre a dare visibilità immediata (una query di controllo naturale: "migrazioni attese dalla release X non registrate: atteso 0 righe"), rende la futura adozione di Liquibase una sostituzione, non un'introduzione.

**Proposta.** Definire una tabella owner (ad esempio `cfg_schema_migrations` o `log_migrations`: identificativo migrazione = nome file, release, data applicazione, esito, checksum facoltativo) e una riga di registrazione in coda a ogni template di migrazione (`.alt`, `.scr`) e nell'`install.sql` di release. Costo minimo, beneficio operativo alto, coerente con lo scenario "database del cliente" dove la tracciabilità di ciò che è stato applicato non è negoziabile.

### 4.2 Comportamento su errore a metà install e strategia di backout

**Problema.** Gli orchestratori usano `whenever sqlerror exit failure rollback`, che è corretto, ma il DDL Oracle committa implicitamente: un install che fallisce a metà lascia l'ambiente in uno stato intermedio non transazionale. Il framework non dice nulla su come si riprende (rieseguire l'install? da dove?) né su come si torna indietro se una release si rivela difettosa dopo l'applicazione: non esiste il concetto di script di backout, né una raccomandazione su backup/flashback/restore point prima dell'applicazione in produzione.

**Perché conta.** È lo scenario di emergenza più probabile nella vita reale di un rilascio consegnato a un DBA terzo, cioè esattamente il contesto operativo dichiarato del framework. L'assenza di istruzioni si tradurrà in decisioni improvvisate sotto pressione.

**Proposta.** Aggiungere a `sorgenti.md` (o a un breve documento di rilascio) tre cose: la regola che i ripetibili sono rieseguibili per costruzione e le migrazioni no, quindi la ripresa di un install fallito consiste nel correggere e ripartire dalla migrazione fallita (il registro del punto 4.1 dice quale); la raccomandazione di chiedere al DBA un *guaranteed restore point* prima dell'apply in produzione, come prerequisito standard nel pacchetto di release; la politica di backout dichiarata (roll-forward con nuova migrazione come via ordinaria, restore point come extrema ratio), così che non debba essere negoziata a incidente in corso.

### 4.3 Manifest del pacchetto di release

**Problema.** La cartella `Releases/<versione>/` è uno snapshot manuale: nulla garantisce che corrisponda davvero al tag git da cui dichiara di derivare.

**Perché conta.** Il pacchetto è l'artefatto consegnato a terzi; una divergenza silenziosa fra tag e snapshot vanifica il diff codice-a-DB su cui l'AM fa affidamento.

**Proposta.** Prescrivere un file `MANIFEST` nella cartella di release (generabile con uno script: hash del commit taggato, elenco file con checksum). In prospettiva, quando arriverà la CI, la costruzione dello snapshot diventa un job automatico dal tag — il manifest è il primo passo verso quel punto.

---

## Area 5 — Testing: contratto formale, copertura, percorso verso la CI

### 5.1 JSON Schema formale per il test book

**Problema.** `test_book.md` descrive la struttura in prosa e con un esempio, e definisce il JSON "il contratto" per il generatore. Ma un contratto descritto a parole non è validabile: nulla impedisce a un test book scritto a mano di divergere dallo schema atteso, e il generatore (futuro) lo scoprirà nel modo peggiore.

**Perché conta.** L'intera idea della sorgente unica si regge sull'affidabilità del formato. Un JSON Schema costa poche ore, rende il contratto verificabile meccanicamente (anche in code review, anche senza generatore) e diventa la specifica esecutiva su cui scrivere il generatore.

**Proposta.** Aggiungere `Testing/test_book.schema.json` con i vincoli descritti (enum per `status`, `category`, `outcome`; campi obbligatori; formati) e citarlo da `test_book.md` come definizione autorevole. Validare `test_book.example.json` contro lo schema.

### 5.2 Copertura del codice e dati di test

**Problema.** La guida utPLSQL è buona ma tace su due temi: la misurazione della copertura (utPLSQL la offre nativamente con i reporter di coverage) e la gestione dei dati di test oltre il singolo fixture (dati condivisi fra suite, dimensioni realistiche, dati sensibili negli ambienti di test quando si copiano da produzione).

**Perché conta.** Senza un indicatore di copertura, il criterio "la logica è coperta da test" della Definition of Done resta interamente soggettivo; senza una riga sulla provenienza dei dati di test, ogni progetto deciderà da sé come (e se) mascherare i dati reali — che nel contesto "database del cliente" è anche un tema contrattuale.

**Proposta.** Un paragrafo in `utplsql.md` sui reporter di coverage e su un uso *indicativo* (non un obiettivo percentuale rigido, che produce test rituali); una sezione o un documento breve sulla policy dei dati negli ambienti non di produzione (dati sintetici via fixture come via preferita; se si copia da produzione, mascheramento dei dati personali come requisito).

### 5.3 Percorso minimo verso la CI

**Problema.** La scelta di rimandare la CI è legittima e documentata, quindi non è un difetto. Ma il framework non descrive nemmeno il percorso, e alcune scelte già fatte (esecuzione manuale "abituale" prima della PR) si reggono solo sulla disciplina individuale.

**Perché conta.** La distanza fra "test manuali di prassi" e "test eseguiti davvero" cresce col team e con la fretta. Il costo di ingresso oggi è basso: utPLSQL-cli è citato come "ponte naturale", GitHub Actions è già nella riga di hosting delle decisioni prese.

**Proposta.** Registrare in `STATUS.md` (decisioni aperte) il disegno minimo già condiviso: un workflow GitHub Actions che, su PR, tira su un container `gvenzl/oracle-free` (o database di servizio equivalente), esegue install da `Sources/` e lancia `utPLSQL-cli` con reporter JUnit. Non serve realizzarlo oggi; serve che il primo che lo realizzerà non parta da un foglio bianco. Nel frattempo, una misura a costo zero: la checklist PR chiede già "i test passano", si può chiedere di incollare l'output di `ut.run` nella sezione "Come verificare".

---

## Area 6 — Architettura e sicurezza operativa

### 6.1 Auditing degli accessi privilegiati

**Problema.** Il modello dei privilegi è ben disegnato in termini di *cosa può fare chi*, ma non dice nulla su *come si traccia chi ha fatto cosa*. I due profili che lo meritano sono il proxy verso l'owner (il documento cita l'auditabilità come vantaggio del proxy, ma non prescrive alcun audit) e l'AM, che in produzione ha DML libero su tutte le tabelle: un privilegio corretto e necessario, ma che in qualunque contesto con requisiti di compliance deve lasciare traccia.

**Perché conta.** In un database del cliente, prima o poi qualcuno chiederà "chi ha modificato questo dato in produzione?". Se la risposta è "l'utenza AM, e non è tracciato altro", il problema diventa del progetto. L'audit è anche la contropartita naturale che rende difendibile la potenza del profilo AM di fronte al DBA del cliente.

**Proposta.** Aggiungere a `schemi.md` una sezione breve su Unified Auditing: una policy di audit sulle connessioni proxy verso l'owner e una sul DML dell'utenza AM (o quantomeno sulle tabelle critiche), con il relativo template in `Sources/SYS/`. Va presentata come richiesta standard ai DBA, coerente con lo spirito "consegniamo a chi ha i privilegi".

### 6.2 Utenze condivise per operatori umani (`#APP#_RO`, `#APP#_AM`)

**Problema.** `#APP#_RO` e `#APP#_AM` sono descritti come schemi a cui "gli operatori" accedono: così come sono, sono account condivisi fra persone. La responsabilità individuale si perde e la rotazione delle password a ogni uscita dal team diventa un onere.

**Perché conta.** È la versione umana del problema del punto precedente: l'audit senza identità individuale è mezzo audit.

**Proposta.** Documentare l'opzione (già coerente col modello, visto che il proxy è adottato per l'owner) di utenze personali leggere con `grant connect through` verso `#APP#_RO`/`#APP#_AM`, oppure utenze personali con il solo ruolo di profilo. Non serve imporla: serve che il modello la preveda, perché è il tipo di richiesta che i clienti strutturati fanno.

### 6.3 Profili e hardening minimo delle utenze applicative

**Problema.** I template `SYS` creano le utenze senza `PROFILE`: nessuna policy su scadenza/complessità password per le utenze tecniche, nessun lock preventivo delle utenze non interattive.

**Perché conta.** Dettagli piccoli, ma sono esattamente le osservazioni che un security assessment del cliente solleva al primo giro, e costano pochissimo se previste dal template.

**Proposta.** Aggiungere al `template_user.usr.sql` un profilo di riferimento per le utenze tecniche (password che non scade a sorpresa a metà esercizio ma ruotata per procedura, `FAILED_LOGIN_ATTEMPTS` sensato) e la nota di mantenere `#APP#` stessa non direttamente connettibile quando si adotta il proxy (`ACCOUNT LOCK` opzionale, con i rilasci che passano dal proxy).

---

## Area 7 — Modello dati: colonne standard e pattern trasversali

### 7.1 Colonne di audit di riga e colonna di versione

**Problema.** Gli esempi usano qua e là `created_date`, `changed_date`, `updated_at`, `modified_at` — quattro nomi per due concetti — e il capitolo 06 fonda il locking ottimistico su una colonna `row_version` che però non esiste né nei domini né nel template di tabella. Non c'è una regola su quali tabelle debbano avere colonne di audit di riga (chi/quando ha creato e modificato) né su come popolarle (trigger vs API).

**Perché conta.** Le colonne di audit sono la convenzione trasversale per eccellenza: se non le fissa il framework, ogni tabella nascerà diversa, e le query di controllo e lo storico ne pagheranno il prezzo per sempre. La colonna di versione, poi, è *prescritta* da una regola Critical: o entra nello standard delle tabelle, o la regola resta inattuabile.

**Proposta.** Aggiungere ai domini (`Catalogo/domini.md`) e al `template_table.tab.sql` il blocco standard: `created_at`/`created_by`/`updated_at`/`updated_by` (con la decisione su come popolarle — la via coerente col framework è nell'API/impl, non nei trigger, visti i capitoli sui trigger) e `row_version number default 0 not null` per le tabelle esposte ad aggiornamenti concorrenti. Registrare i nomi scelti nel glossario e ripulire gli esempi che usano varianti.

### 7.2 Pattern di storicizzazione per le tabelle `his_`

**Problema.** Il prefisso `his_` è definito e ben distinto da `arc_`, ma non esiste il pattern che dice *come* si alimenta uno storico: struttura della tabella `his_` rispetto alla tabella base, momento di scrittura, trigger compound (di cui esiste un ottimo esempio nel capitolo 02, ma orientato all'audit generico) o scrittura via API.

**Perché conta.** La storicizzazione è uno dei punti dove ogni sviluppatore inventa una variante; è anche il caso d'uso naturale del trigger compound già documentato, che oggi resta un esempio orfano.

**Proposta.** Una sezione in `11_patterns.md` con il pattern di journaling raccomandato (colonne della `his_` = colonne della base + metadati di versione/operazione; alimentazione; interazione con `arc_`). In ottica 23ai si può menzionare, come improvement opzionale, che Oracle Flashback Time Travel / le funzionalità native possono coprire parte del requisito.

---

## Area 8 — Tooling: far rispettare le convenzioni senza pagarle a mano

**Problema.** Lo stile di codifica adottato è insolitamente rigido (keyword allineate a destra, virgole a inizio riga, colonne di allineamento nelle dichiarazioni, separatori `--`): tutto verificabile solo a occhio, in code review. Non esiste alcuna indicazione di formatter o linter, né configurazione condivisa; non è nemmeno citato uno strumento di analisi statica, benché l'introduzione ne riconosca il valore.

**Perché conta.** Uno standard di formattazione così dettagliato senza strumento di supporto ha due destini possibili: consumare tempo di review in osservazioni cosmetiche, o decadere. Entrambi sono costi che lo standard doveva evitare. In più, molte regole delle guidelines (variabili non usate, `when others` senza raise, commit nei loop) sono esattamente ciò che un linter PL/SQL rileva gratis.

**Proposta.** Tre livelli, in ordine di costo. Primo: valutare e registrare in `STATUS.md` la posizione del framework sugli strumenti esistenti — il formatter di SQL Developer/SQLcl con profilo condiviso nel repository (le regole Trivadis, da cui le guidelines derivano, hanno profili pronti: l'allineamento non sarà perfetto ma copre l'80%), e un linter come db* CODECOP o Zpa per le regole d'uso. Secondo: dove lo strumento non arriva, decidere consapevolmente se la regola vale il costo manuale (l'allineamento verticale delle dichiarazioni è il candidato più oneroso). Terzo, più avanti: agganciare il linter alla futura CI. Il punto essenziale da mettere a verbale è che *le regole non automatizzabili vanno difese o alleggerite*, non lasciate a metà.

---

## Area 9 — Prontezza per Oracle 23ai

**Problema/opportunità.** Il framework tratta già bene tre improvement 23ai (privilegi a livello di schema, `DOMAIN`, `boolean` su colonna). Mancano però alcune novità 23ai che toccano proprio i punti dove il framework oggi fatica, e la loro segnalazione costa poco:

- **`IF [NOT] EXISTS` nel DDL**: rende idempotenti creazioni e drop. Impatta direttamente la famiglia baseline e la ripresa di un install fallito (Area 4.2): su 23ai gli script baseline possono diventare rieseguibili senza errori. È l'improvement più rilevante per la gestione sorgenti e oggi non è citato.
- **`DB_DEVELOPER_ROLE`**: il ruolo pronto per gli sviluppatori semplifica il provisioning degli ambienti di sviluppo (non della produzione), da valutare per gli schemi di lavoro e `#APP#_GEN`.
- **Annotazioni sugli oggetti** (`ANNOTATIONS`): metadati strutturati su tabelle e colonne, complementari ai commenti obbligatori; utili in prospettiva per il tooling `#APP#_GEN`.
- **Lock-free reservations e `VALIDATE_CONVERSION`/miglioramenti d'errore**: citazioni puntuali nei capitoli su locking e conversioni.

Da rivedere in chiave evolutiva anche due scelte già fatte: il dominio `flag` (`'Y'/'N'`) convive con la nota "su 23c+ preferire boolean" — bene, ma serve la regola di transizione (i progetti nuovi su 23ai partono con boolean; i domini vanno aggiornati di conseguenza); e la pagina dei domini usa "23c" mentre il resto del framework dice "23ai" — uniformare la dicitura.

**Proposta.** Un passaggio unico che aggiunga le note 23ai mancanti nei documenti pertinenti (sorgenti per `IF NOT EXISTS`, schemi per `DB_DEVELOPER_ROLE`, patterns per lock-free reservations), mantenendo lo stile attuale: opzionali, segnalati, mai obbligatori. Nessuna scelta 19c attuale risulta *sbagliata* in ottica 23ai — la struttura regge bene; si tratta solo di completare la mappa.

---

## Area 10 — Onboarding e fruibilità

**Problema.** L'onboarding è l'ultimo pilastro mancante ed è già pianificato: non è una scoperta di questa revisione. Vale però la pena orientarne il taglio: il rischio, con un corpus ormai ampio (12 capitoli di guidelines più sei pilastri), è produrre un indice ragionato che duplichi `INDEX.md` invece di un percorso.

**Perché conta.** L'obiettivo dichiarato numero tre del framework è ridurre il tempo di ingresso; un documento riepilogativo non lo riduce, un percorso guidato sì.

**Proposta.** Impostare l'onboarding come percorso operativo in giornate ("giorno 1: leggi X e Y, installa l'ambiente; giorno 2: crea una tabella e un package dal template, apri la tua prima PR fittizia...") sfruttando il filo conduttore `orders` che già attraversa esempi e template — è un asset: lo stesso oggetto compare in schemi, sorgenti, test e template, e il percorso di onboarding può ripercorrerlo end-to-end. In quel contesto troverà posto naturale anche la "prima installazione completa da zero" (provisioning SYS → owner → consumer → test), che oggi è descritta a pezzi in tre documenti ma mai come sequenza unica eseguita.

---

## Priorizzazione

La priorità riflette il rapporto fra impatto e costo, e la propedeuticità: le prime tre voci sono quelle senza le quali il framework promette cose che non mantiene.

**Priorità alta.**
1. **Pilastro gestione errori e logging** (Area 3): è richiesto dalle guidelines e dalla Definition of Done ma non esiste; blocca la coerenza dell'intero impianto di testing/AM.
2. **Passaggio di riconciliazione delle guidelines** (Aree 1.1, 1.2, 1.4): ripristina l'autorevolezza dello standard prima che il primo progetto reale ne copi gli esempi; include la correzione degli esempi che non compilano sotto privilegio minimo.
3. **Registro delle migrazioni sul database** (Area 4.1): costo minimo, chiude il buco operativo più rischioso del deploy a script e prepara Liquibase.
4. **Correzione della motivazione del meccanismo guscio** (Area 2): il pattern è centrale e la giustificazione attuale è confutabile; da sistemare prima che la confuti qualcun altro.

**Priorità media.**
5. **Colonne standard di audit e `row_version`** (Area 7.1): conviene fissarle prima che nascano le prime tabelle reali.
6. **Ripresa e backout dei rilasci** (Area 4.2) e **manifest di release** (Area 4.3).
7. **JSON Schema del test book** (Area 5.1): piccolo, e dà valore immediato anche senza generatore.
8. **Auditing dei profili privilegiati e utenze personali** (Aree 6.1, 6.2): da avere pronto come proposta standard verso i DBA del cliente.
9. **Decisione sul tooling di stile** (Area 8): non urgente in assoluto, ma va presa *prima* che il volume di codice renda costoso qualsiasi cambio di rotta.
10. **Allineamenti minori dei documenti** (Area 1.3: baseline 11gR2→19c, README, famiglia `.dat`).

**Priorità bassa.**
11. **Note 23ai aggiuntive** (Area 9): utili, non bloccanti; da fare in un passaggio unico.
12. **Pattern di storicizzazione `his_`** (Area 7.2): serve al primo progetto che ne ha bisogno, non prima.
13. **Coverage, policy dati di test, disegno CI** (Aree 5.2, 5.3): coerenti con la scelta dichiarata di rimandare l'automazione; basta registrarne il percorso.
14. **Taglio dell'onboarding come percorso operativo** (Area 10): coincide con il lavoro già pianificato; questa nota ne è solo l'orientamento.

Un'ultima osservazione di metodo, in positivo: la disciplina di governance del repository (decisioni tracciate, stato reale allineato allo stato dichiarato, changelog curato) è il motivo per cui questa revisione ha potuto essere precisa. È la stessa disciplina che renderà economico attuare le migliorie qui elencate — conviene proteggerla come si protegge il codice.
