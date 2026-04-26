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

Se il progetto ha più schemi o moduli che condividono lo stesso database, è opportuno prefissare i nomi degli oggetti con un'abbreviazione del progetto o del modulo, per evitare conflitti e chiarire l'appartenenza.

| Situazione | Esempio |
|---|---|
| Tabella standard | `employees` |
| Tabella con una sola riga | `configuration` |
| Tabella con editioning view | `countries_eb` |
| Tabella con prefisso di progetto | `sct_contracts` |

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
| Foreign Key | `<tabella>_<tabella_riferita>_fk[n]` | `empl_dept_fk`, `sct_icmd_ic_fk1` |
| Unique Key | `<tabella>_<ruolo>_uk[n]` | `employees_name_uk`, `sct_contracts_uk` |
| Check Constraint | `<tabella>_<colonna/ruolo>_ck[n]` | `employees_salary_min_ck`, `orders_mode_ck` |

Il numero opzionale in fondo al nome (es. `_fk1`, `_uk2`) si usa quando esistono più constraint dello stesso tipo sulla stessa tabella, per disambiguarli.

### Indici

Gli indici che servono un constraint — primary key, unique key o foreign key — prendono lo stesso nome del constraint corrispondente. Per tutti gli altri indici, il nome deve riflettere la tabella e le colonne indicizzate (o lo scopo dell'indice), con il suffisso `_idx`.

Esempi: `employees_last_name_idx`, `orders_status_created_at_idx`.

### Sequenze

Il nome di una sequenza identifica la tabella per cui genera i valori della chiave primaria, seguito dal suffisso `_seq`. Se la sequenza ha uno scopo più generale, si usa il nome dello scopo al posto della tabella.

| Situazione | Esempio |
|---|---|
| Generatore di PK per una tabella | `employees_seq` |
| Sequenza con scopo generale | `order_number_seq` |

### Sinonimi

I sinonimi servono a referenziare oggetti di schemi esterni senza dover qualificare ogni riferimento con il nome dello schema. La regola è che il sinonimo deve avere lo stesso nome dell'oggetto referenziato: non si usano i sinonimi per rinominare gli oggetti, ma solo per renderli accessibili dallo schema corrente senza prefisso.

### Trigger DML e Instead-of

Per i trigger DML esistono due convenzioni accettate, tra cui è possibile scegliere in modo coerente all'interno del progetto.

La prima usa un nome composto dal nome dell'oggetto su cui agisce il trigger e da un codice che identifica il momento e gli eventi che lo scatenano:

| Codice | Significato |
|---|---|
| `_br_iud` | Before Row su Insert, Update e Delete |
| `_ar_iud` | After Row su Insert, Update e Delete |
| `_io_id` | Instead of su Insert e Delete |

La seconda usa il nome dell'oggetto, una descrizione dell'attività svolta dal trigger e il suffisso `_trg`.

| Convenzione | Esempio |
|---|---|
| Prima (evento) | `employees_br_iud` |
| Seconda (attività) | `orders_audit_trg`, `orders_journal_trg` |

### Trigger di sistema

I trigger di sistema — quelli legati a eventi DDL o di sessione — sono nominati con il nome dell'evento, una descrizione dell'attività e il suffisso `_trg`.

Esempi: `ddl_audit_trg`, `logon_trg`.

### Tipi oggetto e tipi collezione

I tipi oggetto Oracle (`OBJECT`) usano il nome del concetto che rappresentano al singolare, seguito dal suffisso `_ot`. I tipi collezione (`TABLE OF`, `VARRAY`) usano il nome degli oggetti che contengono al plurale, seguito dal suffisso `_ct`. Entrambi possono essere prefissati dall'abbreviazione del progetto.

| Tipo | Schema | Esempio |
|---|---|---|
| Object type | `<contenuto>_ot` | `employee_ot` |
| Collection type | `<contenuti>_ct` | `employees_ct`, `orders_ct` |

### Tabelle temporanee globali

Le Global Temporary Table seguono le stesse regole delle tabelle normali. Possono essere suffissate con `_tmp` per distinguerle visivamente dalle tabelle permanenti, ma il suffisso non è obbligatorio se il contesto è chiaro.

Esempi: `employees_tmp`, `contracts_tmp`.

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
