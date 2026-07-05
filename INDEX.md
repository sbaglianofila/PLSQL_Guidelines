# INDEX — Mappa dei documenti del framework

Questo indice elenca tutti i documenti del framework con una breve descrizione, per permettere una navigazione orientata. È organizzato per strato e per pilastro. Le voci contrassegnate come *pianificato* non sono ancora state prodotte: il loro stato è tracciato in `STATUS.md`.

## Governance

- [CLAUDE.md](CLAUDE.md) — Istruzioni operative per gli assistenti: cosa è il repository, come è organizzato, quali regole applicare quando si produce codice o documentazione.
- [README.md](README.md) — Porta d'ingresso per un lettore umano: scopo, destinatari e come muoversi nel repository.
- [CHANGELOG.md](CHANGELOG.md) — Cronologia delle modifiche al framework, con versionamento semantico.
- [STATUS.md](STATUS.md) — Stato di avanzamento pilastro per pilastro, decisioni prese e decisioni ancora aperte.
- [WRITING_STYLE.md](WRITING_STYLE.md) — Regole di stile per la scrittura dei documenti tecnici del framework.

## Pilastro — Standard di codice (`PlSql_Guidelines/`)

- [01_introduction.md](PlSql_Guidelines/01_introduction.md) — Scopo delle linee guida, caratteristiche di qualità del software, livelli di gravità e parole chiave delle regole.
- [02_naming_conventions.md](PlSql_Guidelines/02_naming_conventions.md) — Convenzioni di denominazione per oggetti del database e identificatori PL/SQL.
- [03_coding_style.md](PlSql_Guidelines/03_coding_style.md) — Stile di codifica: formattazione, indentazione, layout del codice.
- [04_language_usage_general.md](PlSql_Guidelines/04_language_usage_general.md) — Uso del linguaggio: regole generali.
- [05_language_usage_variables_types.md](PlSql_Guidelines/05_language_usage_variables_types.md) — Uso del linguaggio: variabili e tipi.
- [06_language_usage_dml_sql.md](PlSql_Guidelines/06_language_usage_dml_sql.md) — Uso del linguaggio: DML e SQL.
- [07_language_usage_control_structures.md](PlSql_Guidelines/07_language_usage_control_structures.md) — Uso del linguaggio: strutture di controllo.
- [08_language_usage_exception_handling.md](PlSql_Guidelines/08_language_usage_exception_handling.md) — Uso del linguaggio: gestione delle eccezioni.
- [09_language_usage_dynamic_sql.md](PlSql_Guidelines/09_language_usage_dynamic_sql.md) — Uso del linguaggio: SQL dinamico.
- [10_language_usage_stored_objects.md](PlSql_Guidelines/10_language_usage_stored_objects.md) — Uso del linguaggio: oggetti memorizzati.
- [12_language_usage_function_usage.md](PlSql_Guidelines/12_language_usage_function_usage.md) — Uso del linguaggio: uso delle funzioni.
- [11_patterns.md](PlSql_Guidelines/11_patterns.md) — Pattern applicativi ricorrenti.

## Contenuti di progetto (Catalogo)

Documenti vivi, specifici del progetto ed evolutivi nel tempo, tenuti distinti dalle regole stabili delle guidelines.

- [Catalogo/domini.md](Catalogo/domini.md) — Catalogo dei domini dei tipi di progetto.
- [Catalogo/glossario.md](Catalogo/glossario.md) — Glossario delle abbreviazioni e terminologia comune, incluse le rese inglesi approvate dei termini di dominio.

## Pilastro — Architettura DB

- [Architettura_DB/schemi.md](Architettura_DB/schemi.md) — Modello di riferimento degli schemi (owner, applicativo, batch, sola lettura, AM, esterni), privilegi e ruoli, meccanismo guscio per proteggere il codice, sinonimi privati, tablespace e procedura di provisioning.
- [Architettura_DB/colonne_amministrative.md](Architettura_DB/colonne_amministrative.md) — Le sette colonne amministrative standard di ogni tabella (audit di creazione e modifica — chi/quando/con che programma — più `row_version` per il locking ottimistico): tipi, visibilità (audit invisibile, versione visibile), politica dei NULL, il trigger `<table>_audit_trg` che le popola, la propagazione dell'identità via `CLIENT_IDENTIFIER`/`MODULE`, l'uso del locking nella Table API, le prestazioni e le alternative scartate (colonna virtuale, `DEFAULT`, `ORA_ROWSCN`).
- [Architettura_DB/lookups.md](Architettura_DB/lookups.md) — Le tabelle di lookup generiche testata/dettaglio (`ref_lookups` con PK naturale `lookup_code` + `ref_lookup_values` con `value_code`, `is_valid`/`is_default`, slot tipizzati `num_value`/`char_value`/`date_value`): la regola di promozione generica vs dedicata `ref_`, la distinzione da `cfg_parameters` e dagli stati, la foreign key composita con costante via colonna virtuale per l'integrità, l'API di lettura `lib_lookup` e cosa mettere dentro vs cosa tenere dedicato.
- [Architettura_DB/stati_workflow.md](Architettura_DB/stati_workflow.md) — *(bozza)* Pillar `wf_` per gli stati come macchine a stati: `wf_statuses` (stati con `is_initial`/`is_final`), `wf_transitions` (transizioni ammesse), audit dei cambi di stato per entità, e il package `lib_workflow` di validazione. Include le decisioni ancora aperte (collocazione dell'audit, ricchezza delle transizioni, prefisso, FK verso gli stati).

## Pilastro — Gestione sorgenti

- [Gestione_Sorgenti/sorgenti.md](Gestione_Sorgenti/sorgenti.md) — Alberatura del repository, nomenclatura dei file (sotto-estensioni e datazione), le tre famiglie di oggetti, ordine di installazione, strategia dei file ripetibili con snapshot in `Releases/`, e version control con GitHub Flow + tag e hotfix on-demand.
- [Gestione_Sorgenti/Templates/](Gestione_Sorgenti/Templates/README.md) — Set generico di template `template_*` (uno per tipo di oggetto: install, sequence, type/body, table — con le colonne amministrative — alter, index, FK, MV log, vista di logica/guscio (`_v` / `_shell_v`), MV, package di logica/guscio (`pkg_<name>` / `pkg_<name>_shell`), procedure, function, trigger generico, trigger di audit (`<table>_audit_trg`), grant, synonym, data, script, suite utPLSQL), tutti conformi alle convenzioni (segnaposto, `prompt File <start>/<end>`, header con changelog, `prompt` di avanzamento, `show errors`). Include anche i template di provisioning privilegiato per la cartella `SYS` (tablespace, utenze, ruoli, grant di sistema, orchestratore). Gli esempi concreti d'uso vanno in `Gestione_Sorgenti/Templates/Esempi/`.

## Pilastro — Pacchetti base

- [Pacchetti_Base/pacchetti_base.md](Pacchetti_Base/pacchetti_base.md) — Catalogo ragionato dei package PL/SQL di base: principio "complemento a Oracle, non copia" (con la lista di ciò che non va scritto), regole trasversali, i package per livello (fondamenta: `lib_types`, `lib_constants`, `lib_err`, `lib_logging`; sessione: `lib_session`, `lib_config`; servizi: `lib_lock`, `lib_batch`, `lib_assert`, `lib_text`, `lib_calendar`; integrazione: `lib_file`, `lib_mail`, `lib_report`, `lib_http`, `lib_queue`; tooling `#APP#_GEN`: generatori di gusci, test book, documentazione e query di controllo), con contenuti attesi, tabelle di appoggio, prerequisiti SYS e priorità di realizzazione.
- [Sources/#APP#/](Sources/%23APP%23/Install/install.ins.sql) — Implementazione dei pacchetti base (spec + body + suite utPLSQL). **1ª ondata**: `lib_types`, `lib_constants`, `lib_err`, `lib_logging`, `lib_session`, `lib_config`, `lib_lock`, `lib_batch` (tabelle `log_entries`, `log_errors`, `cfg_parameters`, `log_process_runs` + seed di configurazione). **2ª ondata, tier Servizi**: `lib_assert`, `lib_text`, `lib_calendar` (tabella `ref_holidays`). **Tier Integrazione**: `lib_mail` con motore intercambiabile — `lib_mail_engine` in due body alternativi (`utl_smtp` / `apex`), tabelle `cfg_email_templates` e `wrk_mail_queue`; `lib_file` (I/O CLOB su `utl_file`); `lib_report` (render CSV/HTML via `dbms_sql` + `run_report`, tabella `cfg_reports`). Con gli orchestratori di install ([base](Sources/%23APP%23/Install/install.ins.sql) e [test](Sources/%23APP%23/Install/install_tests.ins.sql)). Resta il tooling `gen_*`.

## Pilastro — Testing

- [Testing/strategia_test.md](Testing/strategia_test.md) — Cappello della strategia: i due livelli (utPLSQL + query di controllo), perché servono entrambi, il test book, esecuzione e integrazione nella Definition of Done.
- [Testing/utplsql.md](Testing/utplsql.md) — Guida condivisa a utPLSQL: cos'è, dove si installa (solo dev/test), annotazioni, anatomia di una suite, aspettative e confronto di dataset, setup/teardown, organizzazione, esecuzione manuale, cosa testare e buone pratiche.
- [Testing/query_di_controllo.md](Testing/query_di_controllo.md) — Definizione, principi, categorie ed esempi delle query di controllo per l'AM (verifica oggetti, consistenza dati, verifica funzionale, lettura dei log in produzione). Le query concrete le produce chi implementa.
- [Testing/test_book.md](Testing/test_book.md) — Formato JSON del test book (metadati, script di lancio, casi di test, query di controllo, sign-off) da cui generare documento ed Excel, con [esempio](Testing/test_book.example.json). Il generatore è pianificato.

## Guida a Git

Raccolta di pagine per il gruppo di lavoro, in [Guida_Git/](Guida_Git/README.md): dai fondamenti all'uso quotidiano, fino alla strategia di branching del progetto, agli strumenti visuali e al glossario.

- [README](Guida_Git/README.md) — indice e percorso di lettura
- [01 Introduzione](Guida_Git/01_introduzione.md) · [02 Installazione e configurazione](Guida_Git/02_installazione_e_configurazione.md) · [03 Chiavi SSH e autenticazione](Guida_Git/03_chiavi_ssh_e_autenticazione.md) · [04 Creare o clonare un repository](Guida_Git/04_creare_o_clonare_un_repository.md)
- [05 Ciclo base: add, commit, log](Guida_Git/05_ciclo_base_add_commit_log.md) · [06 Branch e merge](Guida_Git/06_branch_e_merge.md) · [07 Remote: push, pull, fetch](Guida_Git/07_lavorare_con_i_remote.md) · [08 Rebase](Guida_Git/08_rebase.md)
- [09 Annullare e recuperare](Guida_Git/09_annullare_e_recuperare.md) · [10 Tag e release](Guida_Git/10_tag_e_release.md) · [11 Gestione dei conflitti](Guida_Git/11_gestione_dei_conflitti.md) · [12 Strategia di branching del progetto](Guida_Git/12_strategia_di_branching.md)
- [13 Pull Request su GitHub](Guida_Git/13_pull_request_su_github.md) · [14 Strumenti visuali (TortoiseGit)](Guida_Git/14_strumenti_visuali_tortoisegit.md) · [15 Buone pratiche](Guida_Git/15_buone_pratiche.md) · [16 Troubleshooting](Guida_Git/16_troubleshooting.md) · [17 Glossario](Guida_Git/17_glossario.md)

## Pilastro — Processo

- [Processo/definition_of_done.md](Processo/definition_of_done.md) — Criterio di completamento su tre gambe (codice + test utPLSQL + query di controllo) con i criteri di contorno e la lista di controllo sintetica.
- [Processo/code_review_checklist.md](Processo/code_review_checklist.md) — Checklist di revisione per aree (correttezza, conformità, sicurezza, prestazioni, test, sorgenti, leggibilità) e indicazioni su come condurre la revisione.
- [Processo/pull_request_template.md](Processo/pull_request_template.md) — Template di Pull Request pronto per `.github/`, con descrizione, verifica, impatto su sorgenti e checklist autore allineata alla Definition of Done.

## Pilastro — Onboarding *(pianificato)*

- `onboarding.md` — Guida di ingresso per chi entra nel progetto.
