# STATUS — Stato di avanzamento del framework

Questo documento è la fotografia sempre aggiornata di dove siamo arrivati nella costruzione del framework. Serve a riprendere il lavoro tra una sessione e l'altra senza perdere il filo: elenca cosa è fatto, cosa manca, quali decisioni sono state prese e quali sono ancora aperte. Va aggiornato a ogni intervento significativo, insieme a `INDEX.md` e `CHANGELOG.md`.

## Decisioni prese

Le seguenti scelte sono consolidate e vincolano la produzione dei contenuti. Sono ripetute anche in `CLAUDE.md` perché costituiscono il contratto tecnico del framework.

| Ambito | Decisione |
|---|---|
| Database target | Oracle 19c come baseline; improvement 23ai segnalati come opzionali |
| Deploy / versioning | Script SQL ordinati in fase iniziale, alberatura migration-ready verso Liquibase |
| Testing | utPLSQL per la logica + query di controllo per la verifica dati lato AM |
| Hosting | GitHub (PR template, branching, eventuale CI con GitHub Actions) |
| Lingua | Documentazione del framework in italiano; nomi degli oggetti e identificatori in inglese; commenti (inline e di documentazione) sempre in inglese nel framework, con flessibilità per-progetto purché coerente. Termini di dominio tradotti con strumento definito e registrati nel glossario |
| Sinonimi | Privati per schema; nessun `PUBLIC SYNONYM` |
| Assegnazione privilegi | Tramite ruoli di profilo, non oggetto per oggetto |
| Dizionario owner | Privilegi minimi (no `SELECT ANY DICTIONARY` / `SELECT_CATALOG_ROLE`) |
| Package di sistema | `EXECUTE` esplicito per singolo package (`dbms_lock`, `utl_file`, `dbms_crypto`, ...) richiesto nel provisioning SYS; la necessità di un package non giustifica mai privilegi di dizionario sull'owner |
| Naming dei package | Prefissi: `lib_` (nome esteso) per i package generici di libreria, `pkg_` per i package operativi — la **logica** tiene il nome pulito `pkg_<entità>`, il **guscio** esposto prende il suffisso `_shell` (`pkg_<entità>_shell`, viste `<n>_shell_v`); tooling in `#APP#_GEN` con prefisso `gen_`. Superati i suffissi `_api`, `_up` e la precedente collocazione `_impl` sulla logica |
| Protezione codice | Meccanismo guscio (guscio `_shell` grantato, logica col nome pulito no); nessun `wrap`, per preservare il diff codice-a-DB / sorgenti da parte dell'AM. Il suffisso sta sul guscio (non sulla logica) così che promuovere un package a esposto non richieda rinomine e i sinonimi dei consumer portino il nome pulito |
| Natura della base | Base per un singolo progetto, non prodotto multi-cliente; una sola linea di produzione |
| Colonne amministrative | Sette colonne standard su ogni tabella: audit di creazione e modifica (chi/quando/con che programma) **invisibili**, `row_version` **visibile** per il locking ottimistico. Creazione `NOT NULL`, modifica `NULL` fino al primo update; versione come `number` incrementale. Popolate da un unico trigger `<table>_audit_trg` (`before insert or update`); identità e programma dalla sessione (`CLIENT_IDENTIFIER`/`MODULE`) impostati dalla Table API. Nome trigger col suffisso `_trg` per coerenza con `02_naming_conventions.md`. Scartate colonna virtuale, `DEFAULT`-only e `ORA_ROWSCN` |
| Lookup | Tabelle generiche testata/dettaglio `ref_lookups`/`ref_lookup_values` per le liste piatte; PK naturale `lookup_code` sulla testata. Dettaglio: `value_code`, `label`, `description`, `sort_order`, `is_valid`, `is_default`, slot tipizzati `num_value`/`char_value`/`date_value` (no `attr1..N`, no EAV, no JSON per ora), unique `(lookup_code, value_code)` + 7 colonne amministrative. Regola di promozione: liste con attributi/relazioni proprie o molto referenziate restano `ref_` dedicate. Integrità via FK composita con costante (colonna virtuale) dove serve, altrimenti validazione in Table API. Configurazione **fuori** (resta in `cfg_parameters`). API di lettura `lib_lookup` da aggiungere ai pacchetti base |
| Stati / workflow | Pillar dedicato `wfl_` (prefisso a tre lettere, coerente con gli altri; gli stati **non** sono lookup): `wfl_statuses` (con `is_initial`/`is_final`), `wfl_transitions` (transizioni ammesse come dato, guardia via `allowed_role`), audit dei cambi con tabelle **dedicate per entità** `wfl_<entità>_status_log` (FK tipizzata), package `lib_workflow` di validazione. Motore di regole per transizioni rimandato (bassa priorità). **Documento in bozza**; resta aperta solo la FK dalle colonne di stato verso `wfl_statuses` |
| Strategia file sorgenti | Ripetibili (un file per oggetto, storia su git) / baseline (senza data) / migrazioni (`YYYYMMDD_NN`, immutabili); rilasci in `Releases/<versione>` |
| Version control | GitHub Flow + tag; `feature/*` con PR e review; hotfix on-demand dal tag di produzione con forward-port obbligatorio su `main`; SemVer |
| Testing | utPLSQL per la logica (target: package di logica col nome pulito, es. `pkg_orders`); esecuzione **manuale** per ora (CI in futuro); test solo in dev/test |
| Query di controllo | `query_di_controllo.md` definisce categorie ed esempi (verifica oggetti, consistenza dati, lettura log in produzione); le query concrete le produce chi implementa, a fine sviluppo |
| Documento di test | Obiettivo: **test book in JSON** generabile automaticamente, da cui produrre documento ed Excel; include lo script di lancio del test |

## Avanzamento per pilastro

Lo stato di ciascun componente è classificato come **Da fare**, **In corso** o **Completato**. "Completato" significa che il documento esiste, è coerente con lo stile e con le decisioni prese, ed è collegato in `INDEX.md`.

| Pilastro | Componente | Stato |
|---|---|---|
| Governance | `CLAUDE.md`, `README.md`, `CHANGELOG.md`, `STATUS.md`, `INDEX.md` | Completato |
| Standard di codice | `PlSql_Guidelines/` (introduzione, naming, stile, uso linguaggio, pattern) | Completato (preesistente) |
| Contenuti di progetto | `Catalogo/domini.md`, `Catalogo/glossario.md` | Completato (spostati da `PlSql_Guidelines/` a `Catalogo/`) |
| Architettura DB | `schemi.md` (owner, applicativo, batch, sola lettura, AM, esterni) | Completato |
| Architettura DB | `colonne_amministrative.md` (sette colonne standard + trigger `<table>_audit_trg`) | Completato |
| Architettura DB | `lookups.md` (tabelle generiche `ref_lookups`/`ref_lookup_values`) | Documento completato; oggetti (tabelle, template, `lib_lookup`) da fare |
| Architettura DB | `stati_workflow.md` (pillar `wfl_` degli stati) | In corso (bozza da raffinare) |
| Architettura DB | `utenti_profili.md` (RBAC applicativo `adm_*`) | Documento consolidato (decisioni prese); oggetti (tabelle, template, `lib_authz`) da fare |
| Gestione sorgenti | `sorgenti.md` (alberatura, naming file, famiglie oggetti, install, git) | Completato |
| Gestione sorgenti | Template generici `template_*` (uno per tipo di oggetto) + esempi | Completato |
| Pacchetti base | `Pacchetti_Base/pacchetti_base.md` (catalogo, contenuti attesi, priorità) | Completato |
| Pacchetti base | Implementazione dei package (spec, body, tabelle di appoggio, test) — per ondate secondo il catalogo | In corso. **1ª ondata** completata (`lib_types`, `lib_constants`, `lib_err`, `lib_logging`, `lib_session`, `lib_config`, `lib_lock`, `lib_batch`). **2ª ondata — tier Servizi** completato (`lib_assert`, `lib_text`, `lib_calendar` + tabella `ref_holidays`). **Tier Integrazione** completato: `lib_mail` (interfaccia unica + `lib_mail_engine` con due body alternativi `utl_smtp`/`apex`, tabelle `cfg_email_templates`/`wrk_mail_queue`), `lib_file` (I/O CLOB su `utl_file` con validazione e errori parlanti), `lib_report` (render CSV/HTML via `dbms_sql` + `run_report` con tabella `cfg_reports`). Tutto in `Sources/#APP#/` con suite utPLSQL. Resta solo il tooling `gen_*` in `#APP#_GEN` |
| Testing | `strategia_test.md`, `utplsql.md`, `query_di_controllo.md`, `test_book.md` (+ esempio JSON) | Completato |
| Testing | Generatore del test book (JSON → documento + Excel) | Da fare |
| Guida a Git | `Guida_Git/` — 17 pagine + indice (fondamenti, uso quotidiano, strategia, TortoiseGit, glossario) | Completato |
| Processo | Definition of Done, checklist code review, template Pull Request | Completato |
| Onboarding | Guida di ingresso | Da fare |

## Ordine di costruzione proposto

L'ordine tiene conto delle dipendenze tra documenti. Si parte dall'**architettura degli schemi**, perché definisce i confini di ownership e i nomi degli schemi che tutti gli altri documenti danno per scontati. Segue la **gestione dei sorgenti**, che appoggia la propria alberatura sulla struttura a schemi appena definita e introduce i primi template. Si prosegue con il **testing**, che ha bisogno dei template per definire i propri, e con il **processo** (Definition of Done, code review, Pull Request), che mette in relazione codice, test e query di controllo. Si chiude con l'**onboarding**, che è per natura un documento riepilogativo e presuppone che tutto il resto esista già.

## Decisioni ancora aperte

- **Generatore del test book**: lo schema JSON del test book è definito in `test_book.md` con esempio; resta da realizzare il programma che ne genera documento ed Excel (contratto già fissato dallo schema). Collocazione possibile: tooling `#APP#_GEN` o programma esterno. Il catalogo dei pacchetti base prevede `gen_testbook` come primo tassello (precompilazione del JSON dalle suite utPLSQL).
- ~~**Motore di invio mail**~~ **(risolta a livello di impianto)**: `lib_mail` è unico e indipendente dal motore; la trasmissione è isolata in `lib_mail_engine`, di cui esistono **due body alternativi** — `lib_mail_engine.utl_smtp.pkb.sql` e `lib_mail_engine.apex.pkb.sql`. Se ne installa **esattamente uno** (in `install.ins.sql` è cablato l'`utl_smtp`, con l'`apex` commentato come alternativa). La scelta del motore resta quindi una decisione di install per-progetto, non di codice.
- ~~**Struttura delle tabelle di log**~~ **(risolta)**: adottate due tabelle distinte, `log_entries` (flusso DEBUG/INFO/WARN) e `log_errors` (errori con backtrace, call stack, `process_name`), coerenti con le colonne interrogate dalle query di controllo di `query_di_controllo.md`. Decisa al disegno di `lib_logging` nella 1ª ondata.
- **Pillar stati/workflow (`wfl_`)**: bozza in `stati_workflow.md`. Decisioni prese in questa passata: audit dei cambi con tabelle **dedicate per entità** (`wfl_<entità>_status_log`, FK tipizzata); **prefisso `wfl_`** per tutto il pillar, audit incluso (accanto alle definizioni, non sotto `log_`); guardia via **`allowed_role`**; `changed_by`/`changed_at` come colonne esplicite di dominio. **Motore di regole** per le transizioni (guardie condizionali, azioni/hook) riconosciuto come sviluppo futuro a **bassa priorità**. Resta aperto un solo nodo: se le colonne di stato delle tabelle di business debbano referenziare `wfl_statuses` con una FK composita, o affidare il controllo alla sola Table API.
- **Companion API delle nuove strutture**: `lib_lookup` (lettura delle lookup, gemello di `lib_config`, con cache), `lib_workflow` (`can_transition`/`change_status`) e `lib_authz` (`has_access`/`functionalities_of`, con cache dei permessi per sessione) sono da aggiungere al catalogo dei pacchetti base e realizzare dopo la definizione delle rispettive tabelle.
- ~~**RBAC applicativo (`adm_*`)**~~ **(decisioni prese)**: impianto RBAC a strati in `utenti_profili.md`, distinto dai ruoli di database di `schemi.md`, con identità legata al `CLIENT_IDENTIFIER`. Deciso: assegnazione all'utente per **profilo** e grant delle funzionalità ai **profili** (i ruoli compongono il profilo, senza gate diretto); **`adm_masks`** dedicata referenziata dalle funzionalità; **autenticazione esterna** (nessuna credenziale nel framework); modi di accesso a **tre flag** `can_read`/`can_write`/`can_execute`. Estensione futura possibile: gerarchia di funzionalità (auto‑referenza su `adm_functionalities`). Restano da produrre gli oggetti e il package `lib_authz`.

## Prossimo passo

La **1ª ondata** e il **tier Servizi della 2ª ondata** dei pacchetti base sono stati imbastiti in `Sources/#APP#/` (spec + body + suite utPLSQL + tabelle + seed + orchestratori). Restano da fare, in ordine:

- **revisione e compilazione su DB** di quanto prodotto (il codice è scritto ma non ancora compilato/eseguito su un'istanza Oracle; vanno verificati compilazione, esecuzione delle suite utPLSQL e i grant SYS previsti — in particolare `execute on sys.dbms_lock`; da sciogliere il nodo del nome riservato `lib_err.raise`);
- **3ª ondata — tooling `#APP#_GEN`**: `gen_shell` (generazione gusci `_shell` dalla logica), `gen_testbook`, `gen_doc`, `gen_qc`. La 2ª ondata (servizi + integrazione) è completa. Prereq. SYS già noti per l'integrazione: `lib_file` → `grant execute on sys.utl_file` + oggetti `DIRECTORY`; `lib_mail` motore `utl_smtp` → `sys.utl_smtp` + ACL, motore `apex` → APEX + `apex_mail`; `lib_report` → nessun prereq. proprio (usa `dbms_sql` già disponibile, più mail/file);
- il pilastro **Onboarding** (guida d'ingresso) e il **generatore del test book** (vedi decisioni aperte).

Nota di riconciliazione delle firme: dove il catalogo `pacchetti_base.md` e gli esempi delle guidelines divergevano, si sono seguite le guidelines (dichiarate "contratto minimo"): `lib_lock` espone `request_lock`/`release_lock` (non `request`/`release`); i sottotipi testuali di `lib_types` seguono l'elenco del catalogo (`code_sbt`, `name_sbt`, `short_text_sbt`, `text_sbt`, `big_string_sbt`).
