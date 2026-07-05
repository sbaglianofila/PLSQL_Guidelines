# utPLSQL — Guida al testing del codice PL/SQL

Questo documento è la guida condivisa a utPLSQL, il framework con cui scriviamo ed eseguiamo i test automatici del codice PL/SQL. È pensato per essere letto da chiunque entri nel progetto: spiega cos'è utPLSQL, come si struttura un test, come lo si esegue e quali buone pratiche seguire perché i test siano davvero utili e non un peso morto. Il presupposto è che il testing non sia un adempimento burocratico ma lo strumento che ci permette di modificare il codice senza paura: una suite di test solida è ciò che rende sicuro un refactoring e trasforma una regressione da incidente di produzione a errore intercettato prima del merge.

## Cos'è utPLSQL

utPLSQL è un framework di unit testing per PL/SQL, open source e ampiamente adottato, che rappresenta di fatto lo standard per testare il codice Oracle. La sua caratteristica distintiva è di essere *basato su annotazioni*: i test si scrivono come normali package PL/SQL, e sono commenti speciali — le annotazioni, che iniziano con `--%` — a dire al framework quali procedure sono test, come raggrupparli e quando eseguire eventuali passi di preparazione. Questo significa che non serve imparare un linguaggio nuovo: si scrive PL/SQL, e utPLSQL si occupa di scoprire i test, eseguirli, confrontare i risultati attesi con quelli effettivi e produrre un report.

Il valore di un framework rispetto a script di verifica scritti a mano sta in tre cose. La prima è la *scoperta automatica*: utPLSQL trova da solo tutti i test presenti nel database e li esegue, senza che si debba mantenere una lista. La seconda è l'*isolamento*: ogni test viene eseguito in modo indipendente e, per impostazione predefinita, le modifiche ai dati vengono annullate al termine, così che un test non influenzi il successivo. La terza è il *reporting strutturato*: l'esito è un report leggibile — a video, in formato JUnit per l'integrazione con altri strumenti, o in altri formati — che dice esattamente quali test sono passati, quali sono falliti e perché.

## Dove vive utPLSQL: solo sviluppo e test

utPLSQL è uno strumento di sviluppo e va installato **solo negli ambienti di sviluppo e test, mai in produzione**. Si installa in uno schema dedicato — per convenzione `UT3` — che ospita il motore del framework, e viene reso disponibile agli schemi che eseguono i test tramite grant e sinonimi. L'installazione avviene una volta per ambiente, a partire dalla release ufficiale del progetto utPLSQL, e non fa parte dei pacchetti di rilascio destinati alla produzione: il codice applicativo che spediamo non dipende da utPLSQL a runtime.

Anche i package di test seguono lo stesso vincolo d'ambiente: sono codice che esercita l'applicazione, non parte dell'applicazione, e stanno negli ambienti dove si sviluppa e si verifica. Coerentemente con l'architettura degli schemi descritta in `schemi.md`, i test trovano il loro posto naturale accanto agli oggetti che verificano nei database di lavoro, senza mai raggiungere la produzione.

## Concetti fondamentali: suite, test e annotazioni

L'unità organizzativa di utPLSQL è la **suite**: un package i cui sottoprogrammi sono i singoli test. Si dichiara una suite annotando il package con `--%suite`, e si dichiara ciascun test annotando la relativa procedura con `--%test`. Le annotazioni sono commenti PL/SQL a tutti gli effetti — se si rimuovesse utPLSQL, il package resterebbe sintatticamente valido — ma il framework le interpreta per costruire la gerarchia dei test.

Le annotazioni più importanti sono le seguenti. `--%suite(descrizione)` marca il package come suite e ne fornisce un titolo leggibile. `--%suitepath(a.b.c)` colloca la suite in una gerarchia logica, permettendo di raggruppare le suite per modulo applicativo e di eseguirle selettivamente. `--%test(descrizione)` marca una procedura come test e ne descrive il comportamento atteso. Le annotazioni di ciclo di vita — `--%beforeall`, `--%afterall`, `--%beforeeach`, `--%aftereach` — designano procedure da eseguire, rispettivamente, una volta prima di tutti i test della suite, una volta dopo tutti, prima di ciascun test e dopo ciascun test. Altre annotazioni utili sono `--%context` / `--%endcontext` per raggruppare test correlati all'interno di una suite, `--%disabled(motivo)` per escludere temporaneamente un test documentandone la ragione, `--%throws(-20001)` per dichiarare che un test si aspetta il sollevamento di una specifica eccezione, e `--%rollback(manual)` per gestire manualmente le transazioni quando il rollback automatico non è adatto.

## Anatomia di una suite

Una suite è composta, come ogni package, da una specifica e da un corpo. La specifica contiene le annotazioni e le dichiarazioni delle procedure di test; il corpo ne contiene l'implementazione. Il nome del package di test, per convenzione, è `test_` seguito dal nome dell'oggetto sotto test.

La specifica dichiara la struttura della suite:

```sql
create or replace package test_pkg_orders is

   --%suite(Orders API)
   --%suitepath(#APP#.orders)

   --%beforeall
   procedure setup_fixture;

   --%aftereach
   procedure cleanup;

   --%test(Returns only OPEN orders for the given customer)
   procedure returns_open_only;

   --%test(Excludes logically deleted orders)
   procedure excludes_deleted;

   --%test(Raises when the customer id is null)
   --%throws(-20010)
   procedure raises_on_null_customer;

end test_pkg_orders;
/
```

Il corpo implementa le procedure. Ogni test segue la struttura *Arrange-Act-Assert*: si predispone lo scenario, si invoca l'oggetto sotto test, si verifica il risultato con un'aspettativa.

```sql
create or replace package body test_pkg_orders is

   procedure setup_fixture is
   begin
      -- Arrange condiviso: dati validi per l'intera suite
      insert into customers (customer_id, customer_name) values (1, 'ACME');
      insert into orders (order_id, customer_id, status)  values (10, 1, 'OPEN');
      insert into orders (order_id, customer_id, status)  values (11, 1, 'CANCELLED');
   end setup_fixture;

   procedure cleanup is
   begin
      -- Con rollback automatico questo è spesso superfluo, ma è utile
      -- quando si gestisce la transazione manualmente.
      null;
   end cleanup;

   procedure returns_open_only is
      l_actual sys_refcursor;
   begin
      -- Act
      l_actual := pkg_orders.open_orders_by_customer(i_customer_id => 1);
      -- Assert
      ut.expect(l_actual).to_have_count(1);
   end returns_open_only;

   procedure excludes_deleted is
      l_actual sys_refcursor;
   begin
      l_actual := pkg_orders.open_orders_by_customer(i_customer_id => 1);
      ut.expect(l_actual).not_to_be_empty;
   end excludes_deleted;

   procedure raises_on_null_customer is
      l_actual sys_refcursor;
   begin
      l_actual := pkg_orders.open_orders_by_customer(i_customer_id => null);
   end raises_on_null_customer;

end test_pkg_orders;
/
```

Nel terzo test non c'è un blocco di assert esplicito: l'aspettativa è codificata nell'annotazione `--%throws(-20010)`, che fa passare il test se e solo se la procedura solleva l'eccezione con quel codice. Questo è il modo idiomatico di testare la gestione degli errori.

## Le aspettative: come si asserisce

Il cuore di un test è l'aspettativa, espressa con la sintassi `ut.expect(valore_effettivo).matcher(valore_atteso)`. Il framework confronta il valore effettivo con quello atteso secondo il *matcher* scelto e registra il successo o il fallimento. La forma è deliberatamente leggibile, quasi una frase: `ut.expect(l_total).to_equal(100)` si legge "mi aspetto che il totale sia uguale a 100".

I matcher più usati coprono i casi ricorrenti. `to_equal` verifica l'uguaglianza di valori scalari. `to_be_null` e `to_be_not_null` verificano la presenza o assenza di valore. `to_be_true` e `to_be_false` lavorano sui booleani. `to_be_greater_than`, `to_be_less_or_equal_than`, `to_be_between` verificano relazioni d'ordine. `to_be_like` e `to_match` verificano corrispondenze testuali, la prima con i pattern SQL, la seconda con espressioni regolari. Per le collezioni e i cursori, `to_have_count` verifica il numero di righe, `to_be_empty` e `not_to_be_empty` la presenza di dati. Ogni matcher ha la sua forma negata, ottenibile con `not_to_...` oppure con la forma `ut.expect(x).not_to( equal(y) )`.

```sql
ut.expect(l_salary).to_be_greater_than(0);
ut.expect(l_name).to_be_like('%SPA');
ut.expect(l_flag).to_be_true;
ut.expect(l_rows).to_have_count(3);
ut.expect(l_email).not_to_be_null;
```

### Confronto di insiemi di dati

La capacità più potente di utPLSQL è il confronto tra *cursori*, che permette di verificare interi risultati di query, non solo singoli valori. Si passa un `sys_refcursor` come valore effettivo e uno come atteso, e il framework confronta i due insiemi riga per riga e colonna per colonna, producendo in caso di differenza un report dettagliato che indica esattamente quali righe e quali colonne divergono.

```sql
procedure returns_expected_dataset is
   l_actual   sys_refcursor;
   l_expected sys_refcursor;
begin
   open l_expected for
      select 10 as order_id, 'OPEN' as status from dual;

   l_actual := pkg_orders.open_orders_by_customer(i_customer_id => 1);

   ut.expect(l_actual).to_equal(l_expected);
end returns_expected_dataset;
```

Il confronto tra cursori si può raffinare: `.exclude('created_at')` ignora una colonna volatile come un timestamp di inserimento, `.join_by('order_id')` confronta le righe appaiandole per chiave anziché per posizione, e la modalità non ordinata ignora l'ordine delle righe. Queste opzioni servono a rendere i test robusti rispetto a dettagli che non fanno parte di ciò che si vuole verificare.

## Preparazione, pulizia e transazioni

I test hanno bisogno di dati su cui lavorare, e questi dati vanno predisposti in modo controllato. Le annotazioni di ciclo di vita servono a questo: `--%beforeall` prepara un contesto condiviso da tutti i test della suite, mentre `--%beforeeach` prepara lo stato per ciascun test individualmente, garantendo che ogni test parta da una situazione nota. La scelta tra i due dipende dal costo della preparazione e dal grado di isolamento desiderato: dati costosi da creare e immutabili stanno bene in `beforeall`; dati che ogni test modifica vanno rigenerati in `beforeeach`.

Per impostazione predefinita utPLSQL avvolge ogni test in un *savepoint* e annulla le modifiche al suo termine, così che i dati creati da un test non permangano né influenzino gli altri. Questo rollback automatico è ciò che rende i test ripetibili senza lasciare residui nel database. In alcuni casi — tipicamente quando il codice sotto test esegue `commit` al proprio interno, o quando si testano operazioni su transazioni autonome — il rollback automatico non è applicabile: in quelle situazioni si usa `--%rollback(manual)` e ci si assume la responsabilità di riportare il database allo stato iniziale nei passi di teardown.

## Organizzazione delle suite

Le suite vanno organizzate in modo che la struttura dei test rispecchi la struttura dell'applicazione. Lo strumento per farlo è `--%suitepath`, che colloca ogni suite in una gerarchia logica a punti — ad esempio `#APP#.orders` per i test del dominio ordini. Questa gerarchia non deve corrispondere a package fisici: è una tassonomia che permette di eseguire selettivamente tutti i test di un modulo, di un sottodominio o dell'intera applicazione con un solo comando. Mantenere i suitepath allineati ai moduli funzionali dell'applicazione rende immediato, davanti a un fallimento, capire quale area è coinvolta.

Sul piano dei sorgenti, i package di test seguono le convenzioni di gestione descritte in `sorgenti.md` — sono oggetti ripetibili come qualsiasi altro package, con il loro file spec e body — ma risiedono negli ambienti di sviluppo e test. Il nome del package di test rispecchia l'oggetto verificato con il prefisso `test_`, così che la relazione tra codice e test sia leggibile dal solo nome.

## Come eseguire i test

L'esecuzione dei test, allo stato attuale del progetto, è **manuale**: non c'è ancora una pipeline di integrazione continua che li lanci automaticamente sulle Pull Request, scelta che potremo rivedere in seguito. Eseguire i test manualmente è comunque semplice e va fatto abitualmente prima di aprire una Pull Request.

Il comando fondamentale è `ut.run`, invocabile da qualsiasi client SQL connesso a un ambiente dove utPLSQL è installato. Senza argomenti esegue tutti i test presenti; con un argomento restringe l'esecuzione a uno schema, a un package o a un ramo del suitepath.

```sql
-- Tutti i test dello schema corrente
begin
   ut.run;
end;
/

-- Solo una suite specifica
begin
   ut.run('#APP#.test_pkg_orders');
end;
/

-- Tutti i test di un modulo, via suitepath
begin
   ut.run(a_path => '#APP#:orders');
end;
/
```

L'output può essere formattato da diversi *reporter*. Il reporter di documentazione produce un resoconto leggibile a video, adatto all'uso interattivo durante lo sviluppo; altri reporter producono formati destinati all'elaborazione automatica, come JUnit o formati tabellari, che torneranno utili quando si introdurrà l'esecuzione in CI. Da riga di comando, lo strumento `utPLSQL-cli` permette di lanciare le suite e raccoglierne i report al di fuori di un client SQL interattivo, ed è il ponte naturale verso una futura automazione.

## Cosa testare, e cosa no

Non tutto il codice ha lo stesso valore sotto test, e concentrare lo sforzo dove conta è parte della disciplina. Va testata la **logica di business**: i calcoli, le regole, le trasformazioni, le condizioni al contorno. Nel modello di incapsulamento del framework, questa logica vive nei package col nome pulito (`pkg_orders`), ed è lì che i test trovano il loro bersaglio naturale — verificare la logica significa verificare il comportamento reale, mentre il guscio (`pkg_*_shell`) si limita a delegare e non contiene logica da esercitare. Vanno testati con particolare attenzione i casi limite e la gestione degli errori: il valore nullo, l'insieme vuoto, il confine di un intervallo, l'eccezione che deve essere sollevata. Sono questi i punti in cui il codice si rompe più spesso e in cui un test previene un difetto reale.

Non ha senso, viceversa, testare ciò che è già garantito da Oracle — che un vincolo di integrità referenziale funzioni, che una `select` restituisca ciò che le si chiede — né scrivere test che si limitano a rieseguire l'implementazione duplicandola. Un test che non può fallire per una ragione sensata non aggiunge valore: aggiunge solo codice da mantenere.

## Buone pratiche

Un buon test è *indipendente*: non presuppone che altri test siano stati eseguiti prima, e non lascia residui che condizionino quelli successivi. Il rollback automatico aiuta, ma l'indipendenza va progettata, evitando di appoggiarsi a dati preesistenti nel database e creando invece ogni volta il proprio scenario. Un buon test è *deterministico*: dà sempre lo stesso esito a parità di codice, e non dipende dalla data corrente, dall'ordine delle righe o da dati che cambiano nel tempo — quando questi fattori sono in gioco, si neutralizzano fissandoli nel setup o escludendoli dal confronto.

Un buon test verifica *un solo concetto*: concentrare più aspettative scorrelate in un unico test rende ambiguo il significato di un fallimento e più difficile la diagnosi. Meglio più test piccoli e mirati che uno grande e generico. Infine, il nome e la descrizione di un test devono comunicare il comportamento atteso in modo che, leggendo il report, si capisca cosa non funziona senza aprire il codice: `Returns only OPEN orders for the given customer` è una descrizione utile, `test1` non lo è.

## Relazione con la Definition of Done

Il testing con utPLSQL è uno dei tre pilastri che concorrono a considerare completo un intervento, insieme al codice e alle query di controllo per l'AM. La Definition of Done — definita nel pilastro Processo — stabilisce che una funzionalità non è conclusa finché la sua logica non è coperta da test automatici che passano. Questa guida fornisce gli strumenti per soddisfare quella parte del criterio; le query di controllo, che verificano lo stato dei dati e leggono i log in esercizio, ne completano il quadro e sono trattate nel documento dedicato.
