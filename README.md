# Framework PL/SQL

Questo repository raccoglie l'insieme di regole, documenti, template e procedure che standardizzano la creazione di applicazioni PL/SQL su Oracle Database. Non contiene un'applicazione: contiene il modo in cui le applicazioni vanno costruite, testate, versionate e mantenute.

Va inteso come una **base di partenza per un singolo progetto**, non come un prodotto comune manutenuto su più clienti: un progetto adotta questa base e poi evolve in autonomia il proprio glossario, i propri domini e le proprie eccezioni. Questa natura si riflette in scelte deliberatamente leggere, a partire dal modello di version control, pensato per una sola linea di produzione.

## A cosa serve

Il framework nasce per rispondere a tre esigenze concrete che si presentano in qualsiasi team che sviluppa e mantiene software PL/SQL nel tempo. La prima è **accelerare lo sviluppo**: partire da template già conformi alle convenzioni e da pattern collaudati evita di reinventare ogni volta le stesse scelte. La seconda è **semplificare la manutenzione**: un codice scritto in modo uniforme, con schemi di denominazione prevedibili e una Definition of Done chiara, è più economico da correggere e da far evolvere. La terza è **facilitare l'onboarding**: una persona che entra nel progetto trova in un unico posto le regole da seguire e il razionale che le motiva, riducendo il tempo necessario a diventare produttiva.

## A chi si rivolge

Il framework parla a due tipi di lettori. Chi **sviluppa** trova qui le convenzioni di denominazione, lo stile di codifica, i pattern, i template e le regole di gestione dei sorgenti. Chi **mantiene le applicazioni in esercizio** — in particolare il gruppo di Application Maintenance — trova la Definition of Done, le query di controllo per verificare lo stato dei dati e i criteri per validare una modifica prima e dopo il rilascio.

## Come muoversi nel repository

Il punto di ingresso per una lettura orientata è `INDEX.md`, che elenca tutti i documenti con una breve descrizione e li collega. Per capire a che punto è la costruzione del framework e quali decisioni sono state prese, si consulta `STATUS.md`. Le regole di scrittura dei documenti sono in `WRITING_STYLE.md`, mentre le istruzioni operative per gli assistenti automatici sono in `CLAUDE.md`.

Il cuore delle regole di codice è nella cartella `PlSql_Guidelines/`, organizzata in capitoli numerati che vanno dall'introduzione ai pattern applicativi. Gli altri pilastri — architettura degli schemi, gestione dei sorgenti, testing, processo e onboarding — sono in via di costruzione secondo il piano descritto in `STATUS.md`.

## Stato del progetto

Il framework è in costruzione incrementale. La versione corrente e la cronologia delle modifiche sono tracciate in `CHANGELOG.md`; l'avanzamento pilastro per pilastro è in `STATUS.md`. Le fondamenta tecniche già decise sono: Oracle 19c come baseline (con note sugli improvement disponibili in 23ai), deploy iniziale tramite script SQL ordinati con struttura pronta per una futura migrazione a Liquibase, testing con utPLSQL affiancato da query di controllo, e hosting su GitHub.
