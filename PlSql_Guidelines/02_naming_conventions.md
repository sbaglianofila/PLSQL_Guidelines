# Convenzioni di Denominazione

La scelta dei nomi è una delle decisioni più importanti nello sviluppo di software. Un nome ben scelto comunica intenzioni, riduce la necessità di commenti e rende il codice leggibile a chiunque debba lavorarci in futuro. In PL/SQL e SQL questa responsabilità è amplificata dal fatto che i nomi degli oggetti del database sono condivisi tra applicazioni, team e strumenti diversi: un nome ambiguo o incoerente può generare confusione molto al di là del file in cui compare.

## Linee guida generali

Prima di entrare nelle convenzioni specifiche per ogni tipo di oggetto, è utile stabilire alcune regole di base che si applicano a qualsiasi identificatore, sia nel codice PL/SQL che negli oggetti del database.

Non si deve mai iniziare un nome con un carattere numerico. I nomi devono essere significativi e specifici: un nome come `data` o `valore` non comunica nulla, mentre `hire_date` o `salary_amount` sono immediatamente comprensibili. Le abbreviazioni vanno usate con parsimonia — solo quando il nome completo sarebbe eccessivamente lungo — e comunque devono essere riconoscibili, di uso comune e non superare i 5 caratteri. È buona norma mantenere un glossario delle abbreviazioni accettate nel progetto, in modo che tutti i membri del team usino le stesse forme contratte per gli stessi concetti.

Non si devono mai usare parole riservate di Oracle come nomi di oggetti. L'elenco completo delle parole riservate è consultabile nella vista di sistema `v$reserved_words`. Evita anche prefissi o suffissi ridondanti che non aggiungono informazione: chiamare una tabella `emp_table`, ad esempio, è inutile perché il suffisso `_table` non dice nulla che il contesto non già comunichi.

Tutto il codice deve usare una sola lingua naturale in modo coerente per tutti gli oggetti dell'applicazione. Mescolare lingue diverse produce ambiguità e rende il codice difficile da mantenere. La lingua standard di questo framework è l'**inglese**: i nomi degli oggetti si scrivono in inglese (`orders`, non `ordini`; `employees`, non `dipendenti`), coerentemente con la terminologia tecnica di Oracle e con l'obiettivo di rendere il codice comprensibile anche a chi non parla la lingua del cliente. Un progetto può decidere internamente di adottare una lingua diversa, purché la scelta sia applicata in modo uniforme a tutti i nomi; ma la scelta va fatta consapevolmente una volta, all'inizio, non lasciata all'improvvisazione del singolo autore.

Quando si traduce in inglese un termine di dominio — un concetto di business che nasce nella lingua del cliente — la traduzione deve essere corretta e non approssimativa: una traduzione sbagliata di un termine ricorrente si propaga in decine di nomi e diventa costosa da correggere. È buona norma appoggiarsi a uno strumento di traduzione definito e condiviso dal team (un assistente AI o un dizionario tecnico specializzato) anziché tradurre a orecchio, così che lo stesso concetto riceva sempre la stessa resa inglese. Il termine tradotto, una volta approvato, va registrato nel glossario di progetto, che diventa la fonte di verità per la resa inglese di ogni concetto di dominio.

Infine, elementi con lo stesso significato semantico devono sempre avere lo stesso nome: se la colonna che identifica un dipendente si chiama `employee_id` in una tabella, deve chiamarsi allo stesso modo in tutte le altre tabelle dove compare.

---

## Sezione I — Oggetti del Database

Gli oggetti del database sono entità persistenti nello schema Oracle: tabelle, viste, constraint, indici, sequenze, sinonimi, trigger di sistema, tipi e collezioni. Per questi oggetti vale una regola fondamentale: i nomi non devono mai essere racchiusi tra virgolette doppie. L'uso dei doppi apici forza Oracle a trattare i nomi come case-sensitive, obbligando ogni riferimento successivo a usare le stesse maiuscole. Questo crea una dipendenza fragile e difficile da gestire nel tempo, specialmente in presenza di strumenti di generazione del codice o di query scritte manualmente.

### Tabelle

Il nome di una tabella è il plurale di ciò che contiene. Una tabella che raccoglie dipendenti si chiama `employees`, non `employee` né `tbl_employees`. Fanno eccezione le tabelle progettate per contenere sempre e soltanto una riga (ad esempio tabelle di configurazione globale), per le quali si usa il singolare.

Ogni tabella deve avere un commento nel dizionario dati, così come ogni sua colonna. Questo non è un dettaglio opzionale: la documentazione incorporata nel database è l'unica forma di documentazione che rimane sempre sincronizzata con la struttura effettiva.

Quando una tabella è protetta da una *editioning view* — un meccanismo Oracle per la ridefinizione basata su edizioni — viene suffissata con `_eb`, e la vista che la sovrasta prende il nome originale senza suffisso. In questo modo il codice applicativo che fa riferimento alla vista non deve essere modificato durante la transizione.

#### Prefissi funzionali

I nomi delle tabelle possono essere preceduti da un prefisso che ne identifica il dominio funzionale all'interno dell'applicazione. Questo meccanismo è distinto dal prefisso di progetto (che identifica l'ownership dello schema) e serve invece a classificare le tabelle per scopo, rendendo immediatamente leggibile la natura di un oggetto anche senza consultare documentazione esterna.

I prefissi funzionali definiti per questo progetto sono i seguenti:

| Prefisso | Ambito | Esempi |
|---|---|---|
| `adm_` | Gestione amministrativa di utenti, ruoli e permessi | `adm_users`, `adm_roles`, `adm_role_grants` |
| `cfg_` | Tabelle di configurazione applicativa | `cfg_parameters`, `cfg_feature_flags`, `cfg_email_templates` |
| `wrk_` | Tabelle di appoggio per elaborazioni intermedie, non temporanee | `wrk_import_staging`, `wrk_reconciliation_data` |
| `log_` | Tabelle di audit, tracciamento eventi e log applicativi | `log_user_actions`, `log_api_calls`, `log_errors` |
| `his_` | Storico dei dati di business: versioni precedenti di record modificati o cancellati | `his_employees`, `his_contract_lines` |
| `arc_` | Archivio di dati conclusi o scaduti, spostati dalle tabelle operative per motivi di performance | `arc_orders`, `arc_invoices` |
| `ref_` | Tabelle di decodifica e lookup: domini di valori ammessi, codici, categorie | `ref_countries`, `ref_order_statuses`, `ref_currencies` |
| `ext_` | Dati ricevuti da sistemi esterni, in attesa di validazione o integrazione | `ext_crm_contacts`, `ext_erp_orders` |
| `rpt_` | Tabelle pre-aggregate o denormalizzate a supporto della reportistica | `rpt_monthly_sales`, `rpt_user_activity_summary` |
| `err_` | Tabelle di raccolta degli errori funzionali, usate da processi batch o pipeline ETL | `err_import_rows`, `err_reconciliation` |
| `xrf_` | Tabelle di cross-reference: mappature tra identificativi di sistemi diversi | `xrf_crm_erp_customers`, `xrf_legacy_product_codes` |

Alcuni di questi prefissi richiedono una distinzione che non è sempre immediata. La differenza tra `log_` e `err_` sta nel destinatario: `log_` raccoglie eventi regolari del flusso applicativo (accessi, chiamate API, transizioni di stato), mentre `err_` raccoglie fallimenti funzionali che richiedono analisi o reprocessing — tipicamente righe scartate da un processo batch. La differenza tra `his_` e `arc_` sta invece nel trigger dello spostamento: `his_` registra ogni versione di un record nel corso della sua vita operativa (storico delle modifiche), mentre `arc_` raccoglie record che hanno completato il loro ciclo di vita e vengono rimossi dalle tabelle operative per motivi di performance o data retention.

La differenza tra `cfg_` e le normali tabelle di dominio non è sempre ovvia, ma il criterio è che una tabella `cfg_` contiene dati che modificano il *comportamento* dell'applicazione — parametri, soglie, template, flag — e che vengono letti dalla logica applicativa per prendere decisioni, non elaborati come dati di business. Le tabelle `wrk_` invece contengono dati transitori legati a un processo specifico: a differenza delle Global Temporary Table, persistono tra le sessioni e possono essere partizionate o indicizzate, ma il loro ciclo di vita è subordinato all'elaborazione che le produce. Le tabelle `ext_` sono concettualmente simili alle `wrk_`, ma il dato ha origine esterna e non è stato ancora validato: trattarle separatamente chiarisce la responsabilità sulla qualità del dato.

Quando si usa sia un prefisso funzionale che uno di progetto, il prefisso di progetto viene per primo: `sct_adm_users`, `sct_cfg_parameters`.

| Situazione | Esempio |
|---|---|
| Tabella standard | `employees` |
| Tabella con una sola riga | `configuration` |
| Tabella con editioning view | `countries_eb` |
| Tabella amministrativa | `adm_roles` |
| Tabella di configurazione | `cfg_parameters` |
| Tabella di lavoro/appoggio | `wrk_import_staging` |
| Tabella di log/audit | `log_user_actions` |
| Storico modifiche | `his_employees` |
| Archivio dati conclusi | `arc_orders` |
| Decodifica/lookup | `ref_countries` |
| Dati da sistema esterno | `ext_crm_contacts` |
| Tabella reportistica | `rpt_monthly_sales` |
| Errori batch | `err_import_rows` |
| Cross-reference | `xrf_crm_erp_customers` |
| Prefisso progetto + funzionale | `sct_cfg_parameters` |

### Viste

Le viste seguono le stesse regole delle tabelle in termini di pluralità del nome. Possono opzionalmente essere suffissate con `_v` quando coesistono con una tabella con lo stesso nome base, per distinguerle chiaramente. Le *editioning views* fanno eccezione: prendono il nome della tabella sottostante senza suffisso, proprio perché sostituiscono la tabella nella visione dell'applicazione.

Anche per le viste è obbligatorio inserire commenti nel dizionario dati per la vista stessa e per ogni colonna esposta.

| Situazione | Esempio |
|---|---|
| Vista standard | `active_orders` |
| Vista con suffisso esplicito | `orders_v` |
| Editioning view per `countries_eb` | `countries` |

### Colonne

Il nome di una colonna è il singolare di ciò che contiene. Anche qui si usa il plurale solo quando la colonna contiene un tipo collection. La regola più importante è che il nome deve descrivere il dato, non il tipo: `name` è meglio di `varchar_name`, e `hire_date` è meglio di `date1`.

Ogni colonna deve avere un commento nel dizionario dati.

Oltre alle colonne di dominio, ogni tabella porta un insieme fisso di **colonne amministrative** — `created_by`, `created_at`, `created_program`, `modified_by`, `modified_at`, `modified_program` e `row_version` — con nomi, tipi e semantica standard su tutte le tabelle. La loro definizione completa, insieme al trigger `<table>_audit_trg` che le popola, è in `Architettura_DB/colonne_amministrative.md`; qui basti sapere che questi sette nomi sono riservati a quello scopo e non vanno riusati per colonne di dominio.

### Constraint

I constraint di integrità seguono schemi di nomenclatura precisi, che ne rendono immediatamente identificabili il tipo e la tabella di appartenenza. La tabella seguente riassume le convenzioni per ogni tipo.

| Tipo di constraint | Schema del nome | Esempi |
|---|---|---|
| Primary Key | `<tabella>_pk` | `employees_pk`, `departments_pk` |
| Foreign Key | `<tabella>_fk[n]_<tabella_riferita>` | `empl_fk_dept`, `sct_icmd_fk1_ic` |
| Unique Key | `<tabella>_uk[n]_<colonna>` | `employees_uk_name`, `sct_uk_contracts` |
| Not Null Constraint | `<tabella>_nn_<colonna>` | `employees_nn_id` |
| Check Constraint Colonna| `<tabella>_ck[n]_<colonna>` | `employees_ck_salary`, `orders_ck_mode` |
| Check Constraint Tabella| `<tabella>_ck[n]` | `departments_ck`, `clients_ck1` |

Il numero opzionale in fondo al nome (es. `_fk1`, `_uk2`) si usa quando esistono più constraint dello stesso tipo sulla stessa tabella, per disambiguarli.

### Indici

Gli indici che servono un constraint — primary key, unique key o foreign key — prendono lo stesso nome del constraint corrispondente. Per tutti gli altri indici, il nome deve riflettere la tabella e le colonne indicizzate (o lo scopo dell'indice), con la dicitura `idx`.

Esempi: `employees_idx_last_name`, `orders_status_idx_created_at`.

### Sequenze

Il nome di una sequenza identifica la tabella per cui genera i valori della chiave primaria, seguito dal suffisso `_seq`. Se la sequenza ha uno scopo più generale, si usa il nome dello scopo al posto della tabella.

| Situazione | Esempio |
|---|---|
| Generatore di PK per una tabella | `employees_seq` |
| Sequenza con scopo generale | `order_number_seq` |

### Sinonimi

I sinonimi servono a referenziare oggetti di schemi esterni senza dover qualificare ogni riferimento con il nome dello schema. La regola è che il sinonimo deve avere lo stesso nome dell'oggetto referenziato: non si usano i sinonimi per rinominare gli oggetti, ma solo per renderli accessibili dallo schema corrente senza prefisso.

### Trigger DML, Instead-of e Compound

#### Trigger semplici

Per i trigger DML semplici — quelli che si scatenano in un singolo punto di timing — esistono due convenzioni accettate, tra cui è possibile scegliere in modo coerente all'interno del progetto.

La prima usa un nome composto dal nome della tabella e da un codice che identifica il momento di firing e gli eventi coinvolti:

| Codice | Significato |
|---|---|
| `_br_iud` | Before Row su Insert, Update e Delete |
| `_ar_iud` | After Row su Insert, Update e Delete |
| `_bs_iud` | Before Statement su Insert, Update e Delete |
| `_as_iud` | After Statement su Insert, Update e Delete |
| `_io_id` | Instead of su Insert e Delete |

Il codice può essere adattato agli eventi effettivi del trigger: un trigger che agisce solo su Insert e Update userà `_br_iu` anziché `_br_iud`. Questo rende il nome auto-documentante rispetto al comportamento del trigger.

La seconda convenzione usa il nome della tabella, una descrizione dell'attività svolta e il suffisso `_trg`, ed è preferibile quando il trigger ha uno scopo semanticamente definito che va oltre i semplici eventi che lo scatenano.

| Convenzione | Esempio |
|---|---|
| Prima (evento) | `employees_br_iud` |
| Seconda (attività) | `orders_audit_trg`, `orders_journal_trg` |

#### Trigger compound

I trigger compound — introdotti in Oracle 11g — sono la soluzione preferita ogni volta che la logica richiede di agire in più punti del ciclo di vita di un'istruzione DML. Un trigger compound è un unico oggetto del database che dichiara sezioni distinte per ciascuno dei quattro timing point: `BEFORE STATEMENT`, `BEFORE EACH ROW`, `AFTER EACH ROW` e `AFTER STATEMENT`. Non è obbligatorio implementarle tutte: si dichiarano solo quelle necessarie.

Questa struttura risolve elegantemente due problemi ricorrenti con i trigger tradizionali. Il primo è il cosiddetto *mutating table error* (ORA-04091): un trigger `BEFORE EACH ROW` non può leggere la stessa tabella su cui sta scattando, ma un trigger compound può raccogliere i dati riga per riga nella sezione `AFTER EACH ROW` e poi elaborarli in blocco nella sezione `AFTER STATEMENT`, dopo che Oracle ha terminato le modifiche. Il secondo problema è l'efficienza: invece di eseguire una DML per ogni riga elaborata, il trigger compound può accumulare i dati in una collection definita nella sezione globale — visibile a tutte le sezioni — e poi eseguire una singola operazione bulk nella sezione di statement.

Il nome di un trigger compound usa il suffisso `_cmpd_trg`, preceduto dal nome della tabella. Se il progetto adotta la convenzione basata sugli eventi, è possibile usare il suffisso `_cmpd_iud` per indicare esplicitamente gli eventi coinvolti.

| Convenzione | Esempio |
|---|---|
| Con suffisso descrittivo | `employees_cmpd_trg` |
| Con suffisso evento | `employees_cmpd_iud` |

Un esempio tipico di struttura compound è il seguente:

```sql
create or replace trigger employees_cmpd_trg
   for insert or update or delete on employees
   compound trigger

   -- sezione globale: visibile a tutte le sezioni del trigger
   t_audit_rows adm_audit_log_ct := adm_audit_log_ct();

   before statement is
   begin
      -- logica pre-istruzione, es. controlli di sessione
      null;
   end before statement;

   after each row is
   begin
      -- accumula i dati di audit riga per riga
      t_audit_rows.extend;
      t_audit_rows(t_audit_rows.last) := adm_audit_log_ot(
         i_table_name  => 'EMPLOYEES',
         i_operation   => case
                             when inserting then 'I'
                             when updating  then 'U'
                             when deleting  then 'D'
                          end,
         i_changed_by  => sys_context('userenv', 'session_user'),
         i_changed_at  => systimestamp
      );
   end after each row;

   after statement is
   begin
      -- inserimento bulk dei dati di audit
      forall i in indices of t_audit_rows
         insert into adm_audit_log values t_audit_rows(i);
   end after statement;

end employees_cmpd_trg;
/
```

La sezione globale del trigger è il punto in cui si dichiara la collection usata per l'accumulo e qualsiasi altra variabile condivisa tra le sezioni. È importante che questa collection venga inizializzata nella sezione `BEFORE STATEMENT` se il trigger può essere invocato più volte nella stessa sessione (ad esempio in loop su bulk operations), per evitare di accumulare dati di esecuzioni precedenti.

#### Trigger di sistema

I trigger di sistema — quelli legati a eventi DDL o di sessione — sono nominati con il nome dell'evento, una descrizione dell'attività e il suffisso `_trg`.

Esempi: `ddl_audit_trg`, `logon_trg`.

### Tipi oggetto e tipi collezione

I tipi oggetto Oracle (`OBJECT`) usano il nome del concetto che rappresentano al singolare, seguito dal suffisso `_ot`. I tipi collezione (`TABLE OF`, `VARRAY`) usano il nome degli oggetti che contengono al plurale, seguito dal suffisso `_ct`. Entrambi possono essere prefissati dall'abbreviazione del progetto.

| Tipo | Schema | Esempio |
|---|---|---|
| Object type | `<contenuto>_ot` | `employee_ot` |
| Collection type | `<contenuti>_ct` | `employees_ct`, `orders_ct` |

### Tabelle temporanee globali

Le Global Temporary Table seguono le stesse regole delle tabelle normali. Devono essere prefissate con `tmp_` per distinguerle visivamente dalle tabelle permanenti.

Esempi: `tmp_employees`, `tmp_contracts`.

---

## Sezione II — Identificatori PL/SQL

All'interno del codice PL/SQL — ovvero in package, procedure, funzioni, trigger e blocchi anonimi — si usano convenzioni di denominazione specifiche per le variabili, i parametri, i cursori e gli altri costrutti del linguaggio. Queste convenzioni si basano su un sistema di prefissi e suffissi che comunicano a colpo d'occhio la natura e lo scope di ogni identificatore.

Oracle tratta i nomi in modo case-insensitive: `personname`, `PersonName` e `PERSONNAME` sono lo stesso identificatore. Alcuni strumenti di sviluppo racchiudono automaticamente i nomi tra virgolette doppie, rendendo i nomi case-sensitive e costringendo ogni riferimento futuro a usare le stesse maiuscole. Per evitare questa dipendenza fragile, la raccomandazione è di scrivere tutti i nomi in minuscolo e di non usare mai identificatori tra virgolette doppie.

### Schema generale di nomenclatura

La convenzione segue il pattern `{prefisso}nome_contenuto{suffisso}`. Il prefisso identifica il tipo e lo scope dell'identificatore; il suffisso, dove presente, identifica la natura del tipo definito. La tabella seguente elenca le convenzioni per tutti gli identificatori PL/SQL.

| Identificatore | Prefisso | Suffisso | Esempio |
|---|---|---|---|
| Variabile globale | `g_` | | `g_version` |
| Variabile locale | `l_` | | `l_version` |
| Cursore | `c_` | | `c_employees` |
| Record | `r_` | | `r_employee` |
| Array / Table | `t_` | | `t_employees` |
| Oggetto | `o_` | | `o_employee` |
| Parametro cursore | `p_` | | `p_empno` |
| Parametro IN | `i_` | | `i_empno` |
| Parametro OUT | `o_` | | `o_ename` |
| Parametro IN OUT | `io_` | | `io_employee` |
| Tipo record | `r_` | `_type` | `r_employee_type` |
| Tipo array/table | `t_` | `_type` | `t_employees_type` |
| Eccezione | `e_` | | `e_employee_exists` |
| Costante | `k_` | | `k_EMPNO` |
| Sottotipo | | `_sbt` | `big_string_sbt` |

### Variabili

Le variabili locali usano il prefisso `l_`, quelle globali (dichiarate a livello di package body o spec) usano `g_`. La distinzione è importante perché rende immediatamente visibile lo scope di una variabile durante la lettura del codice: se vedi `l_salary` sai che quella variabile è locale alla procedura corrente, mentre `g_session_user` è condivisa tra le unità del package.

Le costanti usano il prefisso `k_` e devono sempre essere dichiarate come tali con la keyword `constant`. Raccogliere le costanti in un package dedicato è una buona pratica che evita la duplicazione dei valori letterali nel codice.

### Parametri

I parametri dei sottoprogrammi usano prefissi che comunicano la modalità di passaggio: `i_` per i parametri di sola lettura, `o_` per quelli di sola scrittura e `io_` per quelli in lettura e scrittura. I parametri dei cursori usano il prefisso `p_`, che li distingue dai parametri di sottoprogramma.

Questa distinzione non è solo stilistica: scrivere `i_employee_id` comunica immediatamente che quel parametro non viene modificato dalla procedura, senza dover leggere la dichiarazione completa o la firma del sottoprogramma. Allo stesso modo, `o_result` o `io_balance` comunicano intenzioni che altrimenti richiederebbero un commento.

### Cursori, record e collection

I cursori usano il prefisso `c_`, i record il prefisso `r_` e le collection (array o nested table) il prefisso `t_`. I tipi definiti per questi costrutti aggiungono il suffisso `_type`, che li distingue dalle variabili istanziate: `r_employee_type` è il tipo, `r_employee` è la variabile di quel tipo.

### Eccezioni

Le eccezioni usano il prefisso `e_`. Il nome deve descrivere la condizione di errore, non il codice numerico: `e_employee_not_found` è molto più leggibile di `e_1403` o `e_no_data`. Le eccezioni definite a livello di package spec sono accessibili agli utilizzatori del package e dovrebbero avere nomi che abbiano senso nel contesto dell'API pubblica.

### Package, procedure e funzioni

I package prendono il nome dal contesto funzionale che racchiudono, preceduto da un **prefisso che ne dichiara la natura**. I package **operativi** — quelli che espongono le funzionalità applicative sulle entità del dominio — usano il prefisso `pkg_`: il package che gestisce le operazioni sulla tabella `employees` si chiama `pkg_employees`, quello sugli ordini `pkg_orders`. I package **di libreria** — le utility generiche e trasversali, indipendenti dal dominio — usano il prefisso `lib_`: il package di logging si chiama `lib_logging`, quello dei tipi condivisi `lib_types`, quello delle costanti `lib_constants`. Il prefisso rende leggibile a colpo d'occhio, nell'albero degli oggetti, cosa è superficie applicativa e cosa è infrastruttura di base. Quando un package operativo va esposto a un consumatore, il package con il suo nome pulito resta la **logica** (`pkg_orders`) e si aggiunge davanti un **guscio** con il suffisso `_shell` (`pkg_orders` → `pkg_orders_shell`), che è l'oggetto grantato, come descritto nella sezione sul layer di incapsulamento.

Le procedure prendono il nome da un verbo seguito da un sostantivo, e il nome deve rispondere alla domanda "cosa fa questa procedura?". Esempi chiari sono `calculate_salary`, `set_hiredate`, `check_order_state`. I nomi in minuscolo con underscore sono preferiti perché molti strumenti mostrano i nomi in maiuscolo nell'albero degli oggetti, rendendo difficile leggere nomi in camelCase.

Le funzioni seguono la stessa struttura verbo + sostantivo, ma il nome deve rispondere alla domanda "qual è il risultato di questa funzione?". Non è utile usare il prefisso `get_` per tutte le funzioni — una funzione per definizione restituisce sempre qualcosa. Un nome come `employee_by_id` comunica direttamente il risultato. Se più funzioni restituiscono lo stesso tipo di risultato con logiche diverse, il nome deve essere più specifico: `active_employee_by_id`, `employee_by_email`, ecc.

### Sottotipi

I sottotipi usano il suffisso `_sbt` senza prefisso. Sono tipicamente definiti in un package centralizzato e riflettono il concetto che il tipo rappresenta: `big_string_sbt` per una stringa di grandi dimensioni, `percentage_sbt` per un valore percentuale. Raccogliere i sottotipi in un'unica location semplifica la manutenzione quando il dominio dei dati cambia.

---

## Glossario di progetto

Il glossario ha uno scopo più ampio della sola gestione delle abbreviazioni: è il luogo dove il team stabilisce una **lingua comune**. Questo significa due cose distinte.

La prima è la standardizzazione delle abbreviazioni: ogni termine che compare in un nome di oggetto o di identificatore — e che per ragioni di lunghezza deve essere contratto — ha una e una sola forma abbreviata approvata. Usare forme diverse per lo stesso concetto (`cust`, `cus`, `cli` tutti per "cliente") produce incoerenza che si accumula nel tempo e rende il codice difficile da navigare.

La seconda è la standardizzazione della terminologia: anche senza abbreviare, certi concetti del dominio possono essere espressi con parole diverse che in realtà si riferiscono alla stessa cosa. Il glossario stabilisce quale parola è quella ufficiale, eliminando ambiguità nei nomi, nei commenti e nella documentazione.

### Regole d'uso

Prima di assegnare un nome a un nuovo oggetto, si verifica nel glossario se il termine è già presente e si usa quella forma. Se il termine non è presente, si propone l'aggiunta rispettando i criteri già descritti nelle linee guida generali — per le abbreviazioni: riconoscibile, di uso comune, non superiore a 5 caratteri. Qualsiasi aggiunta deve essere condivisa e approvata dal team prima di essere usata nel codice. Un glossario a cui contribuisce una sola persona è peggio di nessun glossario.

Il glossario si applica ovunque compaia un termine rilevante:

- **alias di tabella** nelle query SQL (`cus` per `customers`, `ord` per `orders`)
- **nomi di colonne e tabelle** quando il termine completo supera i limiti pratici
- **nomi di variabili e parametri** PL/SQL quando il termine forma parte di un nome composto
- **commenti e documentazione** inline, dove la coerenza terminologica è altrettanto importante

### Contenuto

Le abbreviazioni approvate e il vocabolario comune sono raccolti nel documento `glossario.md`, separato da questo capitolo per tenere le regole — stabili — distinte dal contenuto — specifico del progetto ed evolutivo nel tempo. Qualsiasi modifica al glossario (nuove voci, revisioni, deprecazioni) avviene in quel documento.

---

## Domini e tipi standard

Una colonna non ha solo un nome: ha un tipo, una dimensione e, spesso, dei vincoli impliciti legati al concetto che rappresenta. Senza uno standard esplicito, lo stesso concetto — un nome, un importo, un codice fiscale — può comparire con tipi e dimensioni diversi in tabelle diverse, generando incoerenze che si scoprono tardi: quando si cerca di spostare dati, di confrontare colonne, o di unificare le definizioni in una migrazione.

Un dominio, in questo senso, è la specifica completa del tipo per un determinato concetto riutilizzabile: "una email è `varchar2(128 char)`", "un identificativo di tabella di lookup è `number(4)`", "una percentuale è `number(5,2)`". Una volta definiti i domini del progetto, ogni nuova colonna viene ricondotta al dominio appropriato invece di scegliere tipo e dimensione caso per caso.

A partire da Oracle Database 23c, questa standardizzazione può essere formalizzata nel database attraverso gli oggetti `DOMAIN`, che permettono di definire un tipo con i suoi vincoli e di usarlo nelle DDL come se fosse un tipo nativo. Su versioni precedenti, i domini rimangono una convenzione documentata, applicata attraverso i subtype del package dei tipi e verificata in fase di code review.

### Regole d'uso

Prima di scegliere il tipo di una nuova colonna, si verifica in `domini.md` se esiste un dominio adatto. Se esiste, lo si usa senza modifiche. Se non esiste, si propone l'aggiunta al team e lo si inserisce nel catalogo prima di usarlo nel codice.

Una colonna che si discosta da un dominio standard deve avere un commento nel dizionario dati che motivi l'eccezione. Un'eccezione non documentata è indistinguibile da un errore.

### Contenuto

I domini approvati per il progetto sono raccolti nel documento `domini.md`, separato da questo capitolo con la stessa logica del glossario. Il documento elenca per ogni dominio il tipo Oracle, la dimensione, gli eventuali vincoli e, per Oracle 23c+, il DDL per la creazione dell'oggetto `DOMAIN` corrispondente.

---

## Definizione degli schemi di progetto

Un'applicazione Oracle è spesso distribuita su più schemi con responsabilità distinte: uno schema applicativo, uno per la configurazione, uno per l'integrazione con sistemi esterni, uno per la reportistica. La struttura degli schemi non è un dettaglio tecnico secondario — determina i confini di ownership degli oggetti, i privilegi necessari tra schemi, e l'impatto che ogni modifica strutturale ha sulle componenti dipendenti. Senza una definizione documentata e condivisa, le dipendenze diventano implicite e difficili da ricostruire, e ogni intervento sullo schema rischia di avere conseguenze non previste su altri componenti.

### Contenuto

La definizione degli schemi del progetto — ownership degli oggetti, relazioni tra schemi, privilegi esposti e dipendenze — è raccolta nel documento `schemi.md`. Ogni nuovo schema, ogni privilege grant tra schemi e ogni modifica alle dipendenze esistenti va documentata in quel documento prima di essere implementata nel database.

---

## Layer di incapsulamento: logica e oggetti guscio

Il framework espone le proprie funzionalità agli schemi consumatori — il front end, i batch, la sola lettura, le applicazioni esterne — senza esporne il codice. Il meccanismo, descritto in dettaglio in `schemi.md`, consiste nello sdoppiare ogni funzionalità esposta in due oggetti: un oggetto di **logica**, che contiene l'implementazione reale — le join, i filtri, gli algoritmi — e che non viene mai grantato, e un oggetto **guscio**, privo di logica, che si limita a delegare e che è l'unico grantato al consumatore. Poiché il consumatore ha privilegi solo sul guscio, e il sorgente di un oggetto è leggibile soltanto da chi vi ha accesso, la logica resta invisibile.

Questo sdoppiamento crea una coppia di oggetti dove le convenzioni viste finora ne prevedevano uno solo, e richiede una regola dedicata per distinguerli. La regola è che **la logica conserva il nome pulito** secondo le convenzioni standard del suo tipo, mentre **il guscio esposto porta il suffisso `_shell`**. Il suffisso va quindi sempre sull'oggetto grantato, mai sulla logica.

Questa scelta ha due ragioni concrete. La prima è che l'oggetto su cui si lavora quotidianamente — la logica — mantiene sempre il nome pulito: promuovere un package da interno a esposto significa **aggiungere** un guscio, non **rinominare** la logica e correggere tutti i suoi riferimenti interni. La seconda è che il suffisso non trapela mai nel codice dei consumatori: come descritto in `schemi.md`, i consumatori accedono tramite **sinonimi privati** che portano il nome pulito (`orders`, `pkg_orders`) e puntano dietro le quinte al guscio `_shell`. Il nome pulito resta quindi il contratto d'uso ovunque conti, e `_shell` marca l'adattatore di confine che vive solo nell'owner. (Da non confondere con il package di tooling `gen_shell` in `#APP#_GEN`, che genera i gusci: è un nome di oggetto, non un suffisso.)

Per i package, la logica è il package operativo con il suo nome pulito e `_shell` fa da suo guscio: `pkg_orders` implementa la logica e non è grantato, `pkg_orders_shell` è l'interfaccia esposta e grantata che vi delega. Per le viste, la logica conserva il nome standard della vista — al plurale, eventualmente con suffisso `_v` dove serve distinguerla da una tabella omonima — e il guscio aggiunge `_shell` prima di tale suffisso.

| Tipo di oggetto | Logica (nome pulito, mai grantata) | Guscio (esposto e grantato) |
|---|---|---|
| Package operativo | `pkg_orders` | `pkg_orders_shell` |
| Vista | `orders_v` | `orders_shell_v` |

La stessa logica si estende a qualsiasi altro oggetto che venga esposto attraverso un guscio: il principio da ricordare è che il nome pulito porta la logica confinata nello schema owner, e `_shell` marca ciò che viene reso accessibile all'esterno. Il codice interno dell'owner chiama sempre la logica col nome pulito; solo i consumatori esterni passano dal guscio.

---

## Template e gestione del codice sorgente

Le convenzioni di denominazione stabiliscono come chiamare gli oggetti; la gestione del codice sorgente stabilisce come organizzare, versionare e distribuire gli script che li creano e modificano. I due aspetti sono complementari: un nome corretto in uno script mal collocato è difficile da trovare al momento del deploy, e uno script correttamente posizionato con nomi inconsistenti è difficile da mantenere nel tempo.

Il progetto adotta template standard per i principali tipi di oggetto — package, procedura, trigger, script DDL, script di migrazione — progettati per essere coerenti con le convenzioni di questo documento fin dalla prima riga. L'adozione dei template garantisce che ogni nuovo file parta da una struttura già conforme: intestazione, sezione dichiarativa, gestione delle eccezioni e chiusura del blocco sono predisposti secondo le regole definite qui. Insieme ai template, sono definite l'alberatura delle directory nel repository e le regole per la nomenclatura degli script, per il loro ordinamento e per la gestione tramite gli strumenti di version control adottati dal progetto.

### Contenuto

I template, la struttura delle directory e le regole di version control sono raccolti nel documento `sorgenti.md`. Qualsiasi nuovo tipo di script, variazione alla struttura del repository o modifica alle convenzioni di version control va concordata con il team e documentata in quel documento prima di essere adottata.
