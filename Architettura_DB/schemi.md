# Architettura degli schemi

Un'applicazione PL/SQL non vive quasi mai in un unico schema. Distribuirla su più schemi con responsabilità distinte non è un vezzo architetturale: è il modo con cui si stabiliscono i confini di ownership degli oggetti, si applica il principio del privilegio minimo a ogni categoria di utente, si protegge il codice sorgente e si mantiene l'applicazione portabile su infrastrutture che spesso non controlliamo direttamente. Questo documento definisce il modello di riferimento degli schemi del framework, i privilegi di ciascuno, il meccanismo con cui si espongono le funzionalità senza esporre il codice, e la procedura per istanziare il modello in un nuovo progetto.

Il contesto operativo tipico è quello in cui il database è gestito dal cliente, non dal nostro gruppo. Questo vincolo permea l'intero modello: non possiamo dare per scontato di conoscere le password, di avere privilegi di DBA, né di essere gli unici a occupare l'istanza. Molte delle scelte descritte qui — l'uso di sinonimi privati anziché pubblici, l'autenticazione proxy, il privilegio minimo sul dizionario — discendono direttamente da questa realtà.

## Convenzione di nomenclatura degli schemi

Ogni schema del modello prende il nome dallo schema owner, che coincide con il nome del prodotto applicativo. Poiché questo nome cambia da progetto a progetto, in questo documento lo indichiamo con il segnaposto `#APP#`. In un progetto reale per un prodotto chiamato "SIA", `#APP#` diventa `SIA`, `#APP#_APP` diventa `SIA_APP`, e così via.

È importante non confondere il **nome dello schema** con il **prefisso degli oggetti** descritto nelle convenzioni di denominazione (lo `sct_` che compare in alcuni esempi). Sono due assi distinti: il nome dello schema identifica *dove* vive un oggetto e chi lo possiede, mentre il prefisso di progetto sugli oggetti identifica l'ownership logica dell'oggetto all'interno di uno schema che potrebbe ospitarne di più provenienze. Di norma entrambi derivano dallo stesso nome-prodotto, ma restano concettualmente separati e vanno mantenuti coerenti in modo indipendente.

## Il modello di riferimento

Il modello prevede una serie di schemi, alcuni obbligatori e altri opzionali. La distinzione conta: un progetto piccolo, senza elaborazioni batch e senza integrazioni con applicazioni esterne, non deve creare schemi che resterebbero vuoti. Il framework definisce il modello completo, ma ogni progetto ne istanzia solo le parti che gli servono.

| Schema | Ruolo | Obbligatorio |
|---|---|---|
| `#APP#` | Owner: possiede tutti gli oggetti (tabelle, viste, codice, sequenze, tipi) | Sì |
| `#APP#_PROXY` | Utenza proxy per operare sull'owner senza conoscerne la password | Opzionale |
| `#APP#_APP` | Schema applicativo usato dal front end; accede solo all'API | Sì |
| `#APP#_BATCH` | Schema per le elaborazioni batch; accede solo all'API | Opzionale |
| `#APP#_RO` | Sola lettura per operatori e AM sui dati, tramite viste | Sì |
| `#APP#_AM` | Application Maintenance: DML e diagnosi sui dati, oggetti di lavoro propri | Sì |
| `#APP#_EXT_<nome>` | Un'utenza per ciascuna applicazione esterna che si collega al DB | Opzionale (zero o più) |
| `#APP#_GEN` | Tooling di generazione di codice e documentazione via introspezione del dizionario | Opzionale, **solo sviluppo/test** |

La logica di fondo è che **un solo schema possiede e crea** (l'owner), mentre **tutti gli altri consumano** attraverso un'interfaccia controllata. Nessuno schema diverso dall'owner e dall'AM ha la facoltà di creare oggetti applicativi; nessuno schema esterno all'owner ha accesso diretto alle tabelle. Questa asimmetria è ciò che rende il modello difendibile.

## Lo schema owner `#APP#`

L'owner è il proprietario di tutto l'applicativo: tabelle, viste, package, procedure, funzioni, sequenze, tipi, trigger. È l'unico schema in cui si esegue DDL applicativa, ed è il punto da cui si dipanano tutti i grant verso gli altri schemi.

### Privilegi di sistema

L'owner ha bisogno di poter creare i tipi di oggetto che compongono l'applicazione, e nient'altro. Il principio guida è il privilegio minimo: si concedono i singoli privilegi `CREATE ...` necessari, non ruoli onnicomprensivi come `RESOURCE` (che storicamente trascinava con sé `UNLIMITED TABLESPACE`) né tantomeno `DBA`.

```sql
grant create session           to #APP#;
grant create table             to #APP#;
grant create view              to #APP#;
grant create sequence          to #APP#;
grant create procedure         to #APP#;
grant create trigger           to #APP#;
grant create type              to #APP#;
grant create synonym           to #APP#;   -- sinonimi privati, non pubblici
grant create materialized view to #APP#;   -- solo se il progetto ne fa uso
grant create job               to #APP#;   -- solo se usa lo Scheduler
```

Due assenze in questo elenco sono deliberate e vanno spiegate, perché contraddicono una prima intuizione comune.

Non è presente `CREATE PUBLIC SYNONYM`. I sinonimi pubblici sono globali all'intero database: in un'istanza gestita dal cliente e potenzialmente condivisa con altre applicazioni, creano rischio di collisione di nomi e inquinano un namespace che non è nostro. Il framework usa esclusivamente **sinonimi privati** creati nello schema che ne ha bisogno, come descritto più avanti. L'owner quindi non crea sinonimi pubblici e non ne ha il privilegio.

Non sono presenti `SELECT ANY DICTIONARY` né `SELECT_CATALOG_ROLE`. Sono privilegi ampi, che darebbero all'owner visibilità sui metadati di tutti gli schemi dell'istanza e sulle viste `DBA_*` e `V$`. Un owner applicativo non ne ha bisogno: per i propri oggetti gli bastano le viste `USER_*`, che non richiedono alcun privilegio, e le `ALL_*` per ciò a cui ha accesso. Questi privilegi si concedono all'owner **solo** se il framework contiene codice che fa introspezione del dizionario dati oltre il proprio schema — cosa che al momento non è prevista. Se un progetto introducesse tale necessità, la si documenterebbe come eccezione motivata.

### Package di sistema: grant espliciti, per package

Oltre ai privilegi di creazione, l'owner ha bisogno di eseguire alcuni package forniti da Oracle. Anche qui vale il privilegio minimo, declinato però in modo diverso: non ruoli o privilegi di dizionario, ma un `grant execute` **esplicito e per singolo package**, limitato a ciò che l'applicazione usa davvero. Questa forma ha due vantaggi: la lista dei grant documenta esattamente quali capacità di sistema l'applicazione richiede — cosa preziosa quando la richiesta va motivata ai DBA del cliente — e ogni capacità può essere revocata singolarmente senza toccare le altre.

Una parte dei package di uso comune è già eseguibile da chiunque, perché Oracle ne concede l'`EXECUTE` a `PUBLIC`: è il caso di `dbms_output`, `dbms_utility`, `dbms_application_info`, `dbms_scheduler` e `dbms_sql`, per i quali non serve alcuna richiesta. Altri invece richiedono il grant esplicito. `dbms_lock`, usato per i lock applicativi (pattern in `11_patterns.md`), non è concesso di default alle utenze normali. `utl_file` è storicamente concesso a `PUBLIC`, ma gli ambienti irrigiditi lo revocano ed è quindi prudente chiederlo esplicitamente quando l'applicazione fa I/O su file; va inoltre ricordato che l'accesso ai file passa comunque da oggetti `DIRECTORY` creati dal DBA, con `READ`/`WRITE` grantati all'owner. `dbms_crypto` (hashing e cifratura) richiede sempre il grant esplicito. `utl_http` e `utl_smtp`, se il progetto li usa, richiedono oltre al grant anche una ACL di rete configurata dal DBA.

```sql
grant execute on sys.dbms_lock   to #APP#;   -- lock applicativi
grant execute on sys.utl_file    to #APP#;   -- I/O su file (più directory dedicate)
grant execute on sys.dbms_crypto to #APP#;   -- solo se il progetto ne fa uso
```

Il punto fermo resta quello già stabilito: la necessità di un package di sistema **non** giustifica mai la concessione di `SELECT_CATALOG_ROLE` o `SELECT ANY DICTIONARY` all'owner. I due assi sono indipendenti — eseguire `dbms_lock` non implica leggere il dizionario — e la potenza di introspezione resta confinata all'AM e allo schema di tooling. I grant sui package di sistema fanno parte del provisioning e sono previsti nel template `template_system_grant.grt.sql`.

### Password e accesso: la questione del DB gestito dal cliente

Poiché non sempre è il nostro gruppo a gestire il database, l'accesso all'owner ammette due modelli. Nel primo, la password dell'owner è gestita dal cliente e a noi ignota: riceviamo accesso solo quando serve, e il cliente esegue o supervisiona i rilasci. È semplice ma perde tracciabilità e agilità.

Nel secondo modello, preferibile, si usa l'**autenticazione proxy**. Si crea un'utenza `#APP#_PROXY` con i soli privilegi di sessione, e si abilita quell'utenza a connettersi "attraverso" l'owner senza conoscerne la password.

```sql
create user #APP#_proxy identified by <password_del_proxy>;
grant create session to #APP#_proxy;
alter user #APP# grant connect through #APP#_proxy;
```

Ci si connette poi come proxy specificando l'owner tra parentesi quadre — ad esempio `#APP#_proxy[#APP#]/<password_del_proxy>@<db>` — e si opera con i privilegi dell'owner senza mai digitarne la password. Il vantaggio, oltre a non dover conoscere il segreto dell'owner, è l'auditabilità: ogni azione resta tracciata come proveniente dal proxy, e il permesso di proxy può essere revocato con un singolo comando senza toccare l'owner.

### Tablespace e quota

L'owner ha un tablespace dati dedicato, `#APP#_DATA`, che isola i dati dell'applicazione da quelli di altri schemi e semplifica backup, monitoraggio e gestione dello spazio. La quota si concede **su quel tablespace specifico**, non tramite il privilegio di sistema globale `UNLIMITED TABLESPACE`: la differenza è sostanziale, perché una quota scoped non permette all'owner di occupare tablespace che non gli competono.

```sql
create user #APP# identified by <password>
   default tablespace   #APP#_data
   temporary tablespace temp
   quota unlimited on   #APP#_data;
```

Per il tablespace temporaneo, il default dell'istanza (`TEMP`) è di norma sufficiente. Un `TEMP` dedicato si giustifica solo se l'applicazione è particolarmente pesante su ordinamenti e hash join di grandi dimensioni; introdurlo senza questa necessità è complessità che non ripaga.

## Lo schema applicativo `#APP#_APP`

È lo schema con cui si connette il front end. Il suo tratto distintivo è che **non vede l'applicativo**: non ha grant sulle tabelle, non può leggerne il contenuto direttamente, non conosce la struttura interna. Interagisce esclusivamente con l'**API** — un insieme di package esposti dall'owner — tramite grant di `EXECUTE` mirati. Se ha bisogno di leggere dati, lo fa attraverso viste guscio, mai attraverso le tabelle.

I privilegi si assegnano tramite un ruolo, `#APP#_app_role`, e non oggetto per oggetto (il razionale è nella sezione sui ruoli). Lo schema riceve i soli `CREATE SESSION` e il ruolo, e nessuna quota su alcun tablespace: non creando nulla, non deve poter materializzare segmenti nemmeno per errore.

```sql
create role #APP#_app_role;
grant execute on #APP#.pkg_orders to #APP#_app_role;   -- ripetuto per ogni package dell'API

create user #APP#_app identified by <password>;   -- nessuna clausola quota
grant create session to #APP#_app;
grant #APP#_app_role to #APP#_app;
alter user #APP#_app default role all;
```

## Lo schema batch `#APP#_BATCH`

Le elaborazioni batch — job schedulati, import, riconciliazioni, chiusure — hanno le stesse necessità di isolamento del front end e seguono lo stesso principio: accesso alla sola API tramite un ruolo dedicato `#APP#_batch_role`, nessun accesso diretto alle tabelle, nessuna quota. La ragione per tenerlo separato dallo schema applicativo, invece di riusare `#APP#_APP`, è che i due profili hanno tipicamente API diverse: il batch invoca procedure di elaborazione massiva che non ha senso esporre al front end, e viceversa. Separarli permette di dare a ciascuno esattamente ciò che gli serve. Nei progetti senza batch, questo schema semplicemente non si crea.

## Lo schema di sola lettura `#APP#_RO`

Serve agli operatori — utenti del cliente o del gruppo di progetto — che devono consultare i dati senza poterli modificare. L'accesso avviene sempre attraverso **viste**, mai attraverso le tabelle: questo permette di controllare esattamente quali colonne sono esposte, di nascondere quelle sensibili e di applicare filtri di riga senza che il consumatore ne sia consapevole. I privilegi sono soli `SELECT`, concessi tramite il ruolo `#APP#_ro_role`. Come per gli schemi applicativi, nessuna quota e nessun privilegio di creazione.

## Lo schema di Application Maintenance `#APP#_AM`

L'AM è il profilo più potente dopo l'owner, ma la sua potenza è deliberatamente asimmetrica: **può lavorare sui dati ma non può alterare gli oggetti**. In concreto, l'AM ha grant di `SELECT`, `INSERT`, `UPDATE` e `DELETE` su tutte le tabelle dell'owner e `EXECUTE` su tutti i package, così da poter correggere dati, rieseguire elaborazioni e diagnosticare problemi in produzione. Ciò che non ha è il privilegio di fare DDL sugli oggetti dell'owner: non possiede `ALTER ANY TABLE` né alcun grant che gli permetta di modificare la struttura dell'applicativo. La struttura resta di competenza esclusiva dell'owner e dei rilasci controllati.

Questa distinzione tra "può toccare i dati" e "non può toccare gli oggetti" è il cuore del ruolo AM e va tenuta ferma: è ciò che permette all'AM di intervenire in emergenza senza poter introdurre derive strutturali non tracciate.

L'AM ha però la facoltà di creare i **propri** oggetti di lavoro — tabelle di appoggio, viste di analisi, procedure di diagnosi — nel proprio schema, in un tablespace dedicato `#APP#_AM_DATA` con quota scoped. Questi oggetti sono strumenti dell'AM, distinti dall'applicativo, e il tablespace separato ne impedisce la commistione con i dati di produzione. All'AM si concedono inoltre `SELECT_CATALOG_ROLE` e `SELECT ANY DICTIONARY`: a differenza dell'owner, l'AM ha davvero bisogno di introspezionare il dizionario per il proprio lavoro diagnostico.

```sql
create user #APP#_am identified by <password>
   default tablespace   #APP#_am_data
   temporary tablespace temp
   quota unlimited on   #APP#_am_data;

grant create session to #APP#_am;

-- oggetti di lavoro propri
grant create table, create view, create procedure, create sequence, create synonym to #APP#_am;

-- lavoro sui dati applicativi, tramite ruolo
create role #APP#_am_role;
grant select, insert, update, delete on #APP#.<tabella> to #APP#_am_role;   -- per ogni tabella
grant execute on #APP#.<package> to #APP#_am_role;                          -- per ogni package
grant #APP#_am_role to #APP#_am;

-- introspezione del dizionario per la diagnosi
grant select_catalog_role   to #APP#_am;
grant select any dictionary to #APP#_am;
```

## Lo schema di tooling `#APP#_GEN` (solo sviluppo/test)

Questo schema ospita gli strumenti di sviluppo che generano automaticamente codice e documentazione a partire dai metadati del database: package che leggono il dizionario dati e ne derivano, ad esempio, la documentazione delle interfacce o lo scheletro di oggetti ripetitivi. È un'utenza di comodità per chi sviluppa, non un componente dell'applicazione.

Il suo tratto definente è il **vincolo d'ambiente**: `#APP#_GEN` si crea unicamente negli ambienti di sviluppo e test, e non deve mai esistere in produzione. La ragione è che per introspezionare il dizionario ha bisogno di `SELECT_CATALOG_ROLE` e `SELECT ANY DICTIONARY`, privilegi ampi che sono accettabili su un ambiente di lavoro ma che non hanno ragione di stare in produzione. Confinare questa capacità qui è ciò che ci ha permesso di tenere l'owner `#APP#` con privilegi minimi sul dizionario: la potenza di introspezione vive in uno schema isolato e usa-e-getta, non nell'owner. Coerentemente, gli script di provisioning di questo schema restano fuori dai pacchetti di release destinati alla produzione.

Anche per uno strumento di sviluppo vale il privilegio minimo. `#APP#_GEN` **legge** i metadati ed **emette** artefatti — script, file di documentazione — ma non scrive sull'owner: non ha `CREATE ANY` né alcun privilegio di DDL su `#APP#`. Il codice che genera non viene installato da lui, ma entra nell'applicazione attraverso il normale percorso di install descritto in `sorgenti.md`, passando quindi da version control e revisione come qualsiasi altro sorgente. Crea soltanto i propri package di generazione, in un tablespace di default con quota, dato che i suoi oggetti sono transitori e non critici.

```sql
create user #APP#_gen identified by <password>
   default tablespace   users
   temporary tablespace temp
   quota unlimited on   users;

grant create session to #APP#_gen;
grant create procedure, create table, create view to #APP#_gen;   -- propri oggetti di generazione

grant select_catalog_role   to #APP#_gen;
grant select any dictionary to #APP#_gen;
```

## Gli schemi delle applicazioni esterne `#APP#_EXT_<nome>`

Per ogni applicazione esterna al nostro progetto che deve collegarsi al database si crea un'utenza dedicata, con nome che ne identifica l'origine (`#APP#_EXT_CRM`, `#APP#_EXT_ERP`). Il principio è il privilegio minimo assoluto: **sola lettura, e solo attraverso viste guscio dedicate**. Un'applicazione esterna non ha mai grant su tabelle, non vede il codice, non ha privilegi di creazione, e riceve unicamente `CREATE SESSION` più un ruolo `#APP#_ext_<nome>_role` che contiene i soli `SELECT` sulle viste che quella specifica integrazione è autorizzata a leggere. Viste diverse per integrazioni diverse permettono di esporre a ciascuna esattamente il sottoinsieme di dati che le compete, senza sovra-esposizione.

È verso queste utenze che la protezione del codice conta di più, ed è per loro che il meccanismo guscio descritto nella prossima sezione è progettato.

## Il layer di incapsulamento: esporre le funzionalità senza esporre il codice

Il requisito è che i consumatori — soprattutto le applicazioni esterne — possano usare le funzionalità del database senza poter leggere la logica che le implementa: le join, i filtri, gli algoritmi. Oracle non offre un permesso "esegui ma non leggere", quindi la protezione si ottiene per costruzione, separando ogni funzionalità esposta in due oggetti: un oggetto di **logica**, col nome pulito, che contiene l'implementazione reale e non viene mai grantato, e un **guscio** suffissato `_shell`, privo di logica, che è l'unico grantato.

### Perché funziona

Le viste `ALL_SOURCE`, `ALL_VIEWS` e affini mostrano il sorgente solo degli oggetti *accessibili* all'utente. Concedere `EXECUTE` su un package rende quel package accessibile, e quindi il chiamante **può leggerne il sorgente**. Questo è il punto controintuitivo che rende necessario il pattern: non basta concedere `EXECUTE` per nascondere il codice.

La soluzione è che l'oggetto grantato non contenga logica. Un package guscio la cui unica istruzione è delegare alla logica — nella forma `begin logica.procedura; end;` — è leggibile dal chiamante, ma ciò che il chiamante legge è soltanto la delega: l'implementazione reale sta nel package di logica dal nome pulito, sul quale non c'è alcun grant, che quindi non è accessibile e il cui sorgente resta invisibile. Perché il meccanismo regga servono due condizioni. La prima è che il guscio giri a **definer's rights** (il comportamento predefinito): se fosse dichiarato `AUTHID CURRENT_USER`, verrebbe eseguito con i privilegi del chiamante, che non ha accesso alla logica, e fallirebbe. La seconda è che il guscio sia **davvero privo di logica**: niente letterali significativi, niente SQL, nessun ramo condizionale che riveli le regole di business, altrimenti sono proprio quelle righe visibili a trapelare.

### Package guscio

```sql
-- package di logica (nome pulito): contiene la logica, NON viene grantato
create or replace package body pkg_orders is
   function open_orders_by_customer(i_customer_id in number) return sys_refcursor is
      l_result sys_refcursor;
   begin
      open l_result for
         select o.order_id, o.order_date, o.total_amount
           from orders o
          where o.customer_id = i_customer_id
            and o.status      = 'OPEN'
            and o.deleted_flag = 'N';
      return l_result;
   end;
end pkg_orders;
/

-- package guscio: delega pura, viene grantato all'API
create or replace package body pkg_orders_shell is
   function open_orders_by_customer(i_customer_id in number) return sys_refcursor is
   begin
      return pkg_orders.open_orders_by_customer(i_customer_id);
   end;
end pkg_orders_shell;
/

grant execute on pkg_orders_shell to #APP#_app_role;
```

Chi ha il grant su `pkg_orders_shell` può leggere che esso delega a `pkg_orders`, ma non può leggere `pkg_orders`: la query con le sue join, i suoi filtri di stato e di cancellazione logica resta protetta.

### Viste guscio

Lo stesso principio si applica alle viste. La vista di logica, col nome pulito, contiene le join e i filtri; la vista guscio suffissata `_shell`, che è quella grantata, si limita a selezionare dalla vista di logica elencando le colonne in modo esplicito.

```sql
-- vista di logica (nome pulito): join e filtri, NON grantata
create or replace view orders_v as
   select o.order_id, o.customer_id, c.customer_name, o.status, o.total_amount
     from orders o
     join customers c on c.customer_id = o.customer_id
    where o.deleted_flag = 'N';

-- vista guscio: colonne esplicite, nessuna logica, grantata
create or replace view orders_shell_v as
   select order_id, customer_id, customer_name, status, total_amount
     from orders_v;

grant select on orders_shell_v to #APP#_ext_crm_role;
```

Le colonne si elencano esplicitamente, senza `select *`: oltre a essere coerente con le best practice generali, questo rende il contratto della vista guscio stabile, perché una colonna aggiunta alla vista di logica non altera silenziosamente ciò che il consumatore vede.

### Convenzione di denominazione del layer

Questo pattern introduce una coppia di oggetti dove le convenzioni di denominazione ne prevedevano uno solo, e serve quindi una regola per distinguerli. La **logica** — quella che non va mai grantata — mantiene il nome pulito secondo le convenzioni già stabilite (prefisso `pkg_` per i package operativi, `_v` per le viste dove serve distinguerle); il **guscio** esposto aggiunge il suffisso `_shell` (`pkg_orders_shell`, `orders_shell_v`). Il nome pulito resta così sulla logica, l'oggetto che si edita e a cui puntano i sinonimi privati dei consumatori, mentre `_shell` marca l'adattatore grantato. Questa regola è riportata anche nel documento delle convenzioni di denominazione perché è parte dello standard e non resti confinata qui.

### Perché non si usa `wrap`

Oracle offre la utility `wrap` (e `DBMS_DDL.WRAP`) per offuscare il sorgente in modo che sia illeggibile anche quando l'oggetto è accessibile. Il framework **sceglie deliberatamente di non usarla**. La ragione è operativa: l'AM deve poter confrontare il codice effettivamente presente sul database con i sorgenti in repository, ed è proprio questo diff lo strumento con cui si individuano i disallineamenti tra ambiente e versione attesa. Offuscare il codice a DB renderebbe impossibile questo confronto e costringerebbe a indagini alla cieca ogni volta che si sospetta una discrepanza. La protezione del codice è quindi affidata interamente al meccanismo guscio — si granta il guscio, mai l'implementazione — che protegge dagli occhi esterni senza sacrificare la diagnosticabilità interna.

## Il modello dei privilegi tramite ruoli

I privilegi verso gli schemi consumer non si concedono oggetto per oggetto a ciascuna utenza, ma si raccolgono in **ruoli** che vengono poi assegnati. A ogni profilo corrisponde un ruolo: `#APP#_app_role`, `#APP#_batch_role`, `#APP#_ro_role`, `#APP#_am_role`, e un ruolo per ciascuna integrazione esterna. Il vantaggio è di manutenzione: quando si aggiunge un oggetto all'API, si esegue un solo grant verso il ruolo, e tutte le utenze che lo possiedono ne beneficiano immediatamente, senza dover ripetere il grant per ognuna.

Esiste un caveat noto da conoscere: i privilegi ottenuti tramite ruolo **non sono attivi all'interno di unità PL/SQL a definer's rights**. Se un'unità di codice compilata a definer's rights avesse bisogno di un privilegio, quel privilegio dovrebbe esserle grantato direttamente, non tramite ruolo. Nel nostro modello questo non è un problema, perché l'unico schema che contiene codice a definer's rights è l'owner, che possiede già i propri oggetti e non dipende da ruoli. Gli schemi consumer non contengono codice proprio: invocano l'API dell'owner da sessioni SQL o PL/SQL dirette, contesto in cui i privilegi da ruolo sono pienamente attivi. L'AM, che esegue DML ad-hoc nelle proprie sessioni, è nella stessa condizione.

## I sinonimi privati

Perché il codice degli schemi consumer non debba qualificare ogni riferimento con il nome dell'owner — accoppiandosi così a un nome che cambia da progetto a progetto — si creano **sinonimi privati** nello schema consumer, che puntano agli oggetti dell'API dell'owner. Un sinonimo privato è visibile solo nello schema in cui è definito, e quindi non genera le collisioni globali dei sinonimi pubblici.

C'è un dettaglio di provisioning da tenere presente. Creare un sinonimo privato dentro lo schema di un consumer richiede o che il consumer abbia il privilegio `CREATE SYNONYM` — che gli abbiamo negato per mantenerlo privo di capacità di creazione — o che sia un'utenza di installazione dotata di `CREATE ANY SYNONYM` a crearli per suo conto. Si adotta la seconda via: i sinonimi privati degli schemi consumer vengono creati durante il provisioning dall'utenza di installazione, così che a runtime i consumer restino con i soli `CREATE SESSION` e il proprio ruolo.

```sql
-- eseguito in fase di provisioning da un'utenza con CREATE ANY SYNONYM
create synonym #APP#_app.pkg_orders for #APP#.pkg_orders;
```

## Matrice riepilogativa

La tabella seguente sintetizza per ciascuno schema i privilegi di creazione, l'accesso ai dati, il tablespace e la quota. Va letta come promemoria operativo dopo aver compreso le sezioni precedenti, non come sostituto della loro spiegazione.

| Schema | Creazione oggetti | Accesso ai dati | Tablespace / quota |
|---|---|---|---|
| `#APP#` | Tutti i tipi applicativi (no public synonym, no dizionario) | Possiede tutto | `#APP#_DATA` dedicato, quota scoped; `TEMP` default |
| `#APP#_PROXY` | Nessuna | Nessuno (solo proxy verso owner) | Nessuna quota |
| `#APP#_APP` | Nessuna | `EXECUTE` su API via ruolo | Nessuna quota |
| `#APP#_BATCH` | Nessuna | `EXECUTE` su API batch via ruolo | Nessuna quota |
| `#APP#_RO` | Nessuna | `SELECT` su viste guscio via ruolo | Nessuna quota |
| `#APP#_AM` | Solo oggetti di lavoro propri | DML su tabelle + `EXECUTE` su package via ruolo; `SELECT_CATALOG_ROLE` + `SELECT ANY DICTIONARY` | `#APP#_AM_DATA` dedicato, quota scoped; `TEMP` default |
| `#APP#_EXT_<nome>` | Nessuna | `SELECT` su viste guscio dedicate via ruolo | Nessuna quota |
| `#APP#_GEN` (dev/test) | Solo propri package di generazione | `SELECT_CATALOG_ROLE` + `SELECT ANY DICTIONARY`; nessuna scrittura sull'owner | Tablespace di default con quota; assente in produzione |

## Provisioning di un nuovo progetto

Istanziare il modello in un nuovo progetto significa sostituire il segnaposto `#APP#` con il nome del prodotto e creare gli schemi obbligatori, aggiungendo quelli opzionali solo se il progetto li richiede. L'ordine dei passi rispetta le dipendenze: prima i tablespace, poi l'owner, poi i ruoli, poi gli schemi consumer, e infine i sinonimi privati che presuppongono l'esistenza sia dell'API sull'owner sia degli schemi che la consumano.

1. Creare i tablespace dedicati `#APP#_DATA` e `#APP#_AM_DATA`.
2. Creare l'owner `#APP#` con i privilegi di creazione e la quota sul proprio tablespace, e — se si adotta il modello proxy — l'utenza `#APP#_PROXY`.
3. Creare i ruoli di profilo (`#APP#_app_role`, `#APP#_ro_role`, `#APP#_am_role`, e i ruoli batch ed esterni se previsti).
4. Creare gli schemi consumer obbligatori (`#APP#_APP`, `#APP#_RO`, `#APP#_AM`) e quelli opzionali necessari, assegnando a ciascuno `CREATE SESSION` e il proprio ruolo.
5. Man mano che l'API viene sviluppata sull'owner, concedere i relativi `EXECUTE` e `SELECT` ai ruoli, e creare i sinonimi privati negli schemi consumer tramite l'utenza di installazione.

Poiché in fase iniziale il deploy avviene tramite script SQL ordinati, questi passi si concretizzano in una sequenza di script numerati nella struttura dei sorgenti descritta in `sorgenti.md`. La medesima sequenza è pensata per essere in seguito impacchettata in changelog Liquibase senza modifiche alla logica di provisioning.

## Improvement disponibili con Oracle 23ai

Il modello descritto è pensato per Oracle 19c. Alcune funzionalità introdotte con la 23ai permetterebbero di semplificarlo, e vengono segnalate qui come opzioni per i progetti che girano su quella release, senza che nulla di ciò sia obbligatorio.

La più rilevante sono i **privilegi a livello di schema**: la 23ai consente di concedere un privilegio sull'intero schema di un altro utente con un solo comando — ad esempio `grant select any table on schema #APP# to #APP#_am_role` — evitando di iterare il grant tabella per tabella come richiesto in 19c. Questo semplifica sensibilmente la configurazione del ruolo AM e la manutenzione dei ruoli di sola lettura. Vanno comunque valutati con attenzione, perché per gli schemi consumer applicativi ed esterni il modello richiede deliberatamente un accesso *selettivo* alla sola API e non all'intero schema: il privilegio a livello di schema è quindi appropriato per l'AM, meno per i profili a esposizione minima.
