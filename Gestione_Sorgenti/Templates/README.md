# Template dei sorgenti

Questa cartella raccoglie gli scheletri generici di partenza per i file sorgente di un progetto costruito sulla base. Ogni template nasce già conforme alle convenzioni di denominazione, di stile e di gestione dei sorgenti definite nelle guidelines e in `sorgenti.md`: si copia il template, si sostituiscono i segnaposto e si riempie il contenuto, partendo così da una struttura corretta nella forma.

I file `template_*` sono generici. Esempi concreti d'uso — con un oggetto reale al posto dei segnaposto — sono raccolti nella cartella `Esempi/`.

## Legenda dei segnaposto

I template usano segnaposto testuali da sostituire alla creazione del file reale. Il nome del file stesso va rinominato di conseguenza (ad esempio `template_table.tab.sql` diventa `orders.tab.sql`), e il marcatore `File:` all'interno va aggiornato al nome reale.

| Segnaposto | Significato |
|---|---|
| `#APP#` | Schema owner; sostituito col nome del prodotto all'istanziazione del progetto |
| `<table_name>`, `<view_name>`, `<object_name>`, ... | Nome dell'oggetto, in minuscolo |
| `<column_name>`, `<attribute_name>`, `<param_name>` | Nome di colonna, attributo o parametro |
| `<datatype>` | Tipo Oracle (es. `number`, `varchar2(30 char)`, `date`) |
| `<purpose>` | Descrizione in una riga dello scopo dell'oggetto |
| `<AA>` | Iniziali dell'autore, nel changelog di intestazione |
| `<YYYYMMDD_NN>` | Token di datazione delle migrazioni (data + progressivo), nel nome file |

## Convenzioni comuni a tutti i template

Ogni file è pensato per essere eseguito con **SQL\*Plus** o **SQLcl** e produce un log leggibile, così che in caso di errore sia immediato capire cosa si è rotto e dove.

Ogni file si apre con `prompt File: <nomefile> <start>` e si chiude con `prompt File: <nomefile> <end>`. Questi marcatori delimitano il contributo di ciascun file nel log complessivo, rendendo evidente dove inizia e finisce l'esecuzione di ogni sorgente anche quando molti file vengono concatenati da un orchestratore.

Subito dopo il marcatore di apertura c'è un'**intestazione** che identifica il file e l'oggetto, ne dichiara lo scopo e contiene un **changelog manuale** in forma tabellare — data, iniziali dell'autore, descrizione concisa della modifica. Il changelog nel file è un ausilio alla consegna e alla lettura veloce; la storia autorevole e completa resta il version control.

All'interno del file, ogni fase significativa è annunciata da un `prompt` in **inglese** che descrive cosa si sta facendo (`Creating table`, `Adding comments`, `Creating indexes`, `Creating package body`…). A differenza dei commenti `--`, i `prompt` compaiono sempre nel log indipendentemente dalle impostazioni di echo, ed è per questo che sono lo strumento con cui si traccia l'avanzamento.

Al termine di ogni oggetto **compilabile** — package spec e body, procedure, funzioni, trigger, type spec e body, viste — si inserisce `show errors <tipo> <nome>`. È essenziale: un oggetto PL/SQL può essere creato *con errori di compilazione* senza che SQL\*Plus lo segnali come errore SQL, quindi `whenever sqlerror` da solo non basta a intercettarlo; `show errors` riversa gli errori di compilazione nel log, dove diventano diagnosticabili. Tabelle, sequence, indici e foreign key non prevedono `show errors`, perché o l'istruzione riesce, o fallisce come errore SQL.

## Esecuzione e gestione degli errori

Le impostazioni di sessione e la gestione degli errori (`whenever sqlerror exit failure rollback`, `set`, `spool`) sono definite negli **orchestratori** (`template_install.ins.sql`), non nei singoli file oggetto. Un file oggetto è pensato per essere invocato da un orchestratore, oppure eseguito manualmente mentre si è connessi allo schema corretto; per questo non altera impostazioni globali di sessione, che sarebbero un effetto collaterale indesiderato in concatenazione. Le migrazioni DML (`.scr`) e i seed (`.dat`) fanno eccezione: gestiscono in proprio `whenever sqlerror` e il `commit`, perché possono essere eseguiti anche isolatamente.

## Template generici disponibili

| File | Oggetto |
|---|---|
| `template_install.ins.sql` | Orchestratore di install (vale anche da riferimento dell'ordine di dipendenza) |
| `template_sequence.seq.sql` | Sequence |
| `template_type.typ.sql` / `template_type_body.tyb.sql` | Object type: spec e body |
| `template_table.tab.sql` | Tabella (baseline): creazione, colonne amministrative, commenti, indici |
| `template_alter.alt.sql` | Migrazione: alter table (file datato) |
| `template_index.idx.sql` | Indice standalone |
| `template_foreign_key.fky.sql` | Foreign key |
| `template_mv_log.mvl.sql` | Materialized view log |
| `template_view.vue.sql` / `template_view_shell.vue.sql` | Vista di logica (nome pulito `<name>_v`, mai grantata) e vista guscio (`<name>_shell_v`, delega, grantata) |
| `template_materialized_view.mvw.sql` | Materialized view |
| `template_package.pks.sql` / `template_package_body.pkb.sql` | Package di logica `pkg_<name>` (nome pulito, logica, mai grantato) |
| `template_package_shell.pks.sql` / `.pkb.sql` | Package guscio `pkg_<name>_shell` (delega, grantato) |
| `template_procedure.prc.sql` | Procedura standalone |
| `template_function.fnc.sql` | Funzione standalone |
| `template_trigger.trg.sql` | Trigger generico |
| `template_trigger_audit.trg.sql` | Trigger di audit `<table>_audit_trg`: popola le colonne amministrative (audit + `row_version`); vedi `Architettura_DB/colonne_amministrative.md` |
| `template_grant.grt.sql` | Grant a ruoli |
| `template_synonym.syn.sql` | Sinonimo privato |
| `template_data.dat.sql` | Dati seed/configurazione (idempotenti via merge) |
| `template_script.scr.sql` | Migrazione DML una tantum |
| `template_test_suite.pks.sql` / `.pkb.sql` | Suite utPLSQL |

### Template di provisioning privilegiato (cartella `SYS`)

Questi template producono gli script da eseguire con un'utenza privilegiata (o da consegnare ai DBA del cliente). Non contengono mai password reali: le utenze si creano con un segnaposto, e il segreto viene impostato nell'ambiente di destinazione.

| File | Oggetto |
|---|---|
| `template_install_sys.ins.sql` | Orchestratore del provisioning (tablespace → utenze → ruoli → grant) |
| `template_tablespace.tbs.sql` | Tablespace dedicato |
| `template_user.usr.sql` | Creazione utenza, con le varianti per owner/AM, consumatori e tooling |
| `template_role.rol.sql` | Ruolo di profilo |
| `template_system_grant.grt.sql` | Privilegi di sistema, appartenenza ai ruoli e proxy, per profilo |
