# Convenzioni di Denominazione

La scelta dei nomi è una delle decisioni più importanti nello sviluppo di software. Un nome ben scelto comunica intenzioni, riduce la necessità di commenti e rende il codice leggibile a chiunque debba lavorarci in futuro. In PL/SQL e SQL questa responsabilità è amplificata dal fatto che i nomi degli oggetti del database sono condivisi tra applicazioni, team e strumenti diversi: un nome ambiguo o incoerente può generare confusione molto al di là del file in cui compare.

## Linee guida generali

Prima di entrare nelle convenzioni specifiche per ogni tipo di oggetto, è utile stabilire alcune regole di base che si applicano a qualsiasi identificatore, sia nel codice PL/SQL che negli oggetti del database.

Non si deve mai iniziare un nome con un carattere numerico. I nomi devono essere significativi e specifici: un nome come `data` o `valore` non comunica nulla, mentre `hire_date` o `salary_amount` sono immediatamente comprensibili. Le abbreviazioni vanno usate con parsimonia — solo quando il nome completo sarebbe eccessivamente lungo — e comunque devono essere riconoscibili, di uso comune e non superare i 5 caratteri. È buona norma mantenere un glossario delle abbreviazioni accettate nel progetto, in modo che tutti i membri del team usino le stesse forme contratte per gli stessi concetti.

Non si devono mai usare parole riservate di Oracle come nomi di oggetti. L'elenco completo delle parole riservate è consultabile nella vista di sistema `v$reserved_words`. Evita anche prefissi o suffissi ridondanti che non aggiungono informazione: chiamare una tabella `emp_table`, ad esempio, è inutile perché il suffisso `_table` non dice nulla che il contesto non già comunichi.

Tutto il codice deve usare una sola lingua naturale — italiano, inglese, tedesco, ecc. — in modo coerente per tutti gli oggetti dell'applicazione. Mescolare lingue diverse produce ambiguità e rende il codice difficile da mantenere. Infine, elementi con lo stesso significato semantico devono sempre avere lo stesso nome: se la colonna che identifica un dipendente si chiama `employee_id` in una tabella, deve chiamarsi allo stesso modo in tutte le altre tabelle dove compare.

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

Gli indici che servono un constraint — primary key, unique key o foreign key — prendono lo stesso nome del constraint corrispondente. Per tutti gli altri indici, il nome deve riflettere la tabella e le colonne indicizzate (o lo scopo dell'indice), con òa dicitura `idx`.

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
         in_table_name  => 'EMPLOYEES',
         in_operation   => case
                              when inserting then 'I'
                              when updating  then 'U'
                              when deleting  then 'D'
                           end,
         in_changed_by  => sys_context('userenv', 'session_user'),
         in_changed_at  => systimestamp
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
| Parametro IN | `in_` | | `in_empno` |
| Parametro OUT | `out_` | | `out_ename` |
| Parametro IN OUT | `io_` | | `io_employee` |
| Tipo record | `r_` | `_type` | `r_employee_type` |
| Tipo array/table | `t_` | `_type` | `t_employees_type` |
| Eccezione | `e_` | | `e_employee_exists` |
| Costante | `co_` | | `co_empno` |
| Sottotipo | | `_type` | `big_string_type` |

### Variabili

Le variabili locali usano il prefisso `l_`, quelle globali (dichiarate a livello di package body o spec) usano `g_`. La distinzione è importante perché rende immediatamente visibile lo scope di una variabile durante la lettura del codice: se vedi `l_salary` sai che quella variabile è locale alla procedura corrente, mentre `g_session_user` è condivisa tra le unità del package.

Le costanti usano il prefisso `co_` e devono sempre essere dichiarate come tali con la keyword `CONSTANT`. Raccogliere le costanti in un package dedicato — tipicamente chiamato `constants_up` o simile — è una buona pratica che evita la duplicazione dei valori letterali nel codice.

### Parametri

I parametri dei sottoprogrammi usano prefissi che comunicano la modalità di passaggio: `in_` per i parametri di sola lettura, `out_` per quelli di sola scrittura e `io_` per quelli in lettura e scrittura. I parametri dei cursori usano il prefisso `p_`, che li distingue dai parametri di sottoprogramma.

Questa distinzione non è solo stilistica: scrivere `in_employee_id` comunica immediatamente che quel parametro non viene modificato dalla procedura, senza dover leggere la dichiarazione completa o la firma del sottoprogramma. Allo stesso modo, `out_result` o `io_balance` comunicano intenzioni che altrimenti richiederebbero un commento.

### Cursori, record e collection

I cursori usano il prefisso `c_`, i record il prefisso `r_` e le collection (array o nested table) il prefisso `t_`. I tipi definiti per questi costrutti aggiungono il suffisso `_type`, che li distingue dalle variabili istanziate: `r_employee_type` è il tipo, `r_employee` è la variabile di quel tipo.

### Eccezioni

Le eccezioni usano il prefisso `e_`. Il nome deve descrivere la condizione di errore, non il codice numerico: `e_employee_not_found` è molto più leggibile di `e_1403` o `e_no_data`. Le eccezioni definite a livello di package spec sono accessibili agli utilizzatori del package e dovrebbero avere nomi che abbiano senso nel contesto dell'API pubblica.

### Package, procedure e funzioni

I package prendono il nome dal contesto funzionale che racchiudono. Un package che gestisce le operazioni CRUD sulla tabella `employees` si chiamerà `employees_api`; un package di utilità che include funzionalità di logging si chiamerà `logging_up`. Il suffisso non è imposto dalla convenzione, ma usare suffissi coerenti — come `_api` per le API applicative e `_up` per le utility — aiuta a orientarsi nell'insieme degli oggetti del progetto.

Le procedure prendono il nome da un verbo seguito da un sostantivo, e il nome deve rispondere alla domanda "cosa fa questa procedura?". Esempi chiari sono `calculate_salary`, `set_hiredate`, `check_order_state`. I nomi in minuscolo con underscore sono preferiti perché molti strumenti mostrano i nomi in maiuscolo nell'albero degli oggetti, rendendo difficile leggere nomi in camelCase.

Le funzioni seguono la stessa struttura verbo + sostantivo, ma il nome deve rispondere alla domanda "qual è il risultato di questa funzione?". Non è utile usare il prefisso `get_` per tutte le funzioni — una funzione per definizione restituisce sempre qualcosa. Un nome come `employee_by_id` comunica direttamente il risultato. Se più funzioni restituiscono lo stesso tipo di risultato con logiche diverse, il nome deve essere più specifico: `active_employee_by_id`, `employee_by_email`, ecc.

### Sottotipi

I sottotipi usano il suffisso `_type` senza prefisso. Sono tipicamente definiti in un package centralizzato e riflettono il concetto che il tipo rappresenta: `big_string_type` per una stringa di grandi dimensioni, `percentage_type` per un valore percentuale. Raccogliere i sottotipi in un'unica location semplifica la manutenzione quando il dominio dei dati cambia.
