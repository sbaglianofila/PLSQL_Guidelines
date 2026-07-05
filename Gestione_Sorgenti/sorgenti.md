# Gestione dei sorgenti

Le convenzioni di denominazione stabiliscono come chiamare gli oggetti; questo documento stabilisce come organizzare, versionare e distribuire gli script che li creano e li modificano. I due aspetti sono complementari: un nome corretto in uno script mal collocato è difficile da trovare al momento del deploy, e uno script ben posizionato con nomi incoerenti è difficile da mantenere. Qui si definiscono l'alberatura del repository, la nomenclatura dei file, l'ordine di installazione, la strategia di gestione del codice sotto version control e il modo in cui si costruisce un pacchetto di rilascio.

Il documento descrive la struttura del **repository di un progetto** costruito a partire da questa base. La struttura degli schemi a cui l'alberatura si appoggia è definita in `schemi.md`; il primo insieme di script che questa struttura ospita è proprio il provisioning degli schemi descritto in quel documento.

## Premessa: un progetto, non un prodotto

Questa base serve a far partire un singolo progetto PL/SQL senza doverne reinventare l'impianto. Una volta avviato, il progetto diverge: evolve il proprio glossario, i propri domini, le proprie eccezioni. Non stiamo costruendo un prodotto comune manutenuto trasversalmente su più clienti con retrofit delle modifiche — quella è un'altra cosa, e non è l'obiettivo attuale. Questa premessa ha una conseguenza concreta sulle scelte di version control: c'è **una sola linea di produzione**, non più versioni da mantenere in parallelo per clienti diversi. È per questo che il modello di branching descritto più avanti è deliberatamente leggero, e non adotta le strutture di lunga vita che servirebbero solo in uno scenario multi-versione. Se un domani il progetto diventasse un prodotto, il modello andrà rivisto; per ora sovra-ingegnerizzarlo sarebbe un costo senza beneficio.

## Alberatura del repository

Il repository separa nettamente tre aree: i **sorgenti di lavoro** organizzati per schema e per tipo di oggetto, i **rilasci** come artefatti immutabili, e i **template** di partenza. Questa separazione tiene distinti tre piani che hanno cicli di vita diversi: i sorgenti cambiano di continuo, i rilasci sono fotografie che non si toccano più, i template sono scheletri stabili.

```
<repo-di-progetto>/
├── Sources/
│   ├── SYS/                     # richieste ai DBA, da eseguire con utenza privilegiata
│   │   ├── Tablespaces/
│   │   ├── Users/               # create user, utenze proxy
│   │   ├── Roles/               # create role
│   │   ├── Grants/              # grant di sistema e assegnazione ruoli
│   │   └── Install/
│   ├── #APP#/                   # schema owner: possiede tutto l'applicativo
│   │   ├── Sequences/
│   │   ├── Types/               # .typ / .tyb
│   │   ├── Tables/              # .tab, .alt, .idx
│   │   ├── FKs/                 # .fky
│   │   ├── Views/               # .vue
│   │   ├── MaterializedViews/   # .mvw
│   │   ├── MVLogs/              # .mvl
│   │   ├── Packages/            # .pks / .pkb
│   │   ├── Procedures/          # .prc
│   │   ├── Functions/           # .fnc
│   │   ├── Triggers/            # .trg
│   │   ├── Grants/              # .grt
│   │   ├── Synonyms/            # .syn
│   │   ├── Data/                # .dat (seed, configurazione, costanti)
│   │   ├── Scripts/             # .scr (bonifiche puntuali, DML complesse)
│   │   └── Install/             # .ins (orchestratori dello schema)
│   └── #APP#_AM/                # oggetti di lavoro dell'AM (stesse sottocartelle pertinenti)
├── Releases/
│   ├── 1.0.0/
│   │   ├── install.sql          # orchestratore della release
│   │   └── ...                  # snapshot di oggetti e migrazioni rilasciati
│   └── 1.1.0/
└── Templates/                   # istanza di progetto dei template della base
```

### L'area dei sorgenti

Sotto `Sources/` gli script sono raggruppati prima per **schema** e poi per **tipo di oggetto**. Il raggruppamento per schema riflette i confini di ownership definiti in `schemi.md` e rende immediato capire dove vive e chi possiede ciò che si sta guardando. Lo schema `SYS` non è uno schema applicativo: è la cartella che raccoglie le richieste da sottoporre ai DBA, ossia tutto ciò che va eseguito con un'utenza privilegiata — creazione di tablespace, utenze, ruoli e grant di sistema. In un database gestito dal cliente questi script sono ciò che consegniamo a chi ha i privilegi che noi non abbiamo, e tenerli separati dagli oggetti applicativi ne chiarisce la natura e il destinatario.

All'interno di ogni schema, la suddivisione per tipo di oggetto mette ogni cosa in un posto prevedibile e, non secondariamente, l'ordine delle cartelle richiama grosso modo l'ordine di installazione: le sequence e i type vengono prima delle tabelle, le tabelle prima delle foreign key e delle viste, e così via. Le foreign key hanno una cartella propria, separata dalle tabelle, perché vanno create dopo che *tutte* le tabelle esistono: isolarle evita l'errore ricorrente di dichiarare un vincolo verso una tabella non ancora creata. La cartella `Data` contiene i dati che popolano le tabelle in modo strutturale — configurazioni, costanti, profili — distinti dalle bonifiche una tantum, che stanno in `Scripts`. La cartella `Install` di ogni schema contiene gli orchestratori, ossia gli script che invocano i singoli file nell'ordine corretto.

### L'area dei rilasci

`Releases/` sta al primo livello, sorella di `Sources/`, perché è un'area di consegna ortogonale all'organizzazione per schema. Ogni release ha una sottocartella nominata con la versione, che contiene lo **snapshot immutabile** di ciò che è stato rilasciato: gli oggetti nella versione spedita, le migrazioni di quella release e un `install.sql` che un DBA può eseguire in autonomia. È questo l'artefatto che si consegna, ed è anche il registro storico di cosa è andato in produzione e quando. Una volta creata, la cartella di una release non si modifica: se qualcosa va corretto, si fa una nuova release. Il rapporto con la strategia dei file ripetibili — spiegato più avanti — è che git dice *cosa* è cambiato tra due release, mentre `Releases/` lo *materializza* in file consegnabili.

### L'area dei template

`Templates/` sta anch'essa al primo livello perché è trasversale a schemi e tipi di oggetto. Contiene gli scheletri di partenza — di install, di creazione tabelle, di package, di viste, di script di migrazione, di test — che garantiscono che ogni nuovo file nasca già conforme alle convenzioni. Nel repository di progetto questa cartella è l'istanza dei template forniti dalla base; il progetto può adattarli alle proprie esigenze, purché resti coerente con le regole di questo documento.

## Le tre famiglie di oggetti

Il concetto più importante di questo documento è che gli oggetti non sono tutti uguali rispetto al deploy, e capire a quale famiglia appartiene un oggetto determina come si nomina il suo file, se il file porta una data e come lo si esegue. Le famiglie sono tre.

Gli **oggetti ripetibili** sono quelli che si creano con `CREATE OR REPLACE`: package (spec e body), procedure, funzioni, viste, type, trigger, sinonimi. Sono idempotenti — li si può rieseguire un numero qualsiasi di volte e il risultato è sempre lo stato finale descritto dal file. Per questi oggetti esiste **un solo file per oggetto**, che si sovrascrive in place a ogni modifica; la storia delle modifiche la tiene git, non il nome del file.

Gli **oggetti di baseline** sono la creazione iniziale di tabelle, sequence, e degli indici e delle foreign key di primo impianto. Si creano una volta sola come fondamenta dello schema, e il loro file non si tocca più: le modifiche successive alla struttura non riscrivono questi file, ma arrivano come migrazioni. Anche questi file non portano una data, perché rappresentano lo stato di partenza, non un evento nel tempo.

Le **migrazioni incrementali** sono gli interventi una tantum che modificano uno stato esistente: le `alter table`, gli indici e le foreign key aggiunti dopo il primo impianto, le bonifiche DML, le correzioni di dati. Si eseguono una volta sola e in ordine; rieseguirle è un errore. Ogni migrazione è un file nuovo che, una volta creato e integrato, **non si modifica mai più**: è un pezzo di storia immutabile. Qui la proliferazione di file non è un difetto, è la forma stessa del registro delle modifiche.

Questa tripartizione non è un'invenzione locale: è la stessa distinzione che gli strumenti di migrazione formalizzano — le *repeatable migrations* contro le *versioned migrations* di Flyway, il `runOnChange` di Liquibase. Adottarla adesso, con script ordinati a mano, significa essere già pronti a migrare a uno di questi strumenti senza ripensare l'organizzazione: i ripetibili diventeranno migrazioni a esecuzione condizionata dal checksum, baseline e incrementali diventeranno migrazioni ordinate.

## Nomenclatura dei file

Ogni file ha estensione `.sql`, preceduta da una **sotto-estensione di tre lettere** che ne dichiara il tipo. La sotto-estensione rende il tipo di oggetto leggibile dal nome del file e permette a strumenti e script di trattare i file per categoria. La tabella seguente elenca le sotto-estensioni per ogni tipo, con l'indicazione della famiglia di appartenenza.

| Tipo di oggetto | Sotto-estensione | Famiglia |
|---|---|---|
| Tabella (creazione) | `.tab` | Baseline |
| Alter table | `.alt` | Migrazione |
| Indice standalone | `.idx` | Baseline o migrazione |
| Foreign key | `.fky` | Baseline o migrazione |
| Sequence | `.seq` | Baseline |
| Type spec / body | `.typ` / `.tyb` | Ripetibile |
| Package spec / body | `.pks` / `.pkb` | Ripetibile |
| Procedure | `.prc` | Ripetibile |
| Function | `.fnc` | Ripetibile |
| Trigger | `.trg` | Ripetibile |
| View | `.vue` | Ripetibile |
| Materialized view | `.mvw` | Speciale |
| Materialized view log | `.mvl` | Speciale |
| Grant | `.grt` | Ripetibile |
| Synonym | `.syn` | Ripetibile |
| Dati seed / configurazione | `.dat` | Migrazione |
| Script / bonifica | `.scr` | Migrazione |
| Tablespace (SYS) | `.tbs` | Baseline |
| Utenza / schema (SYS) | `.usr` | Baseline |
| Ruolo (SYS) | `.rol` | Baseline |
| Install / orchestratore | `.ins` | — |

### La data nel nome del file

La regola che lega il nome alla famiglia è la seguente: **portano una data i file delle migrazioni; non la portano i ripetibili né la baseline iniziale**. La ragione è coerente con la natura delle famiglie: un file ripetibile o di baseline rappresenta uno *stato* — l'oggetto così com'è o com'è nato — e uno stato non ha una data; una migrazione rappresenta un *evento* nel tempo, e un evento la data ce l'ha.

Il formato della data è `YYYYMMDD_NN`, dove `NN` è un progressivo a due cifre che ordina più migrazioni dello stesso giorno. La data dà l'ordine di massima, il progressivo risolve l'ambiguità quando nello stesso giorno nascono più script; insieme forniscono un ordinamento deterministico senza bisogno di coordinare un contatore globale tra chi sviluppa in parallelo. Va detto con onestà che in un ambiente complesso questo ordinamento non garantisce l'ordine "vero" con cui gli interventi andrebbero applicati — due sviluppatori possono lavorare in giorni diversi su migrazioni interdipendenti — ma è un'approssimazione utile e molto migliore dell'assenza di ordine. Quando l'interdipendenza è reale e critica, la si gestisce nell'orchestratore di install, che è la fonte di verità dell'ordine di esecuzione.

La creazione di un oggetto non porta data, la sua alterazione sì:

```
orders.tab.sql                  -- creazione della tabella (baseline)
orders.20260630_01.alt.sql      -- prima alter del 30/06/2026
orders.20260630_02.alt.sql      -- seconda alter dello stesso giorno
pkg_orders.pks.sql              -- spec del package (ripetibile, un solo file)
pkg_orders.pkb.sql              -- body del package (ripetibile, un solo file)
cleanup_duplicates.20260701_01.scr.sql   -- bonifica una tantum
```

## Ordine di installazione

L'ordine con cui gli script vanno eseguiti rispetta le dipendenze tra oggetti, e non coincide con l'ordine alfabetico né con quello di creazione. Questo ordine è codificato negli orchestratori nella cartella `Install`, che invocano i singoli file nella sequenza corretta; gli orchestratori sono la fonte di verità dell'ordine, mentre l'alberatura ne è solo un promemoria visivo.

All'interno di un singolo schema l'ordine tipico procede dagli oggetti senza dipendenze verso quelli che ne dipendono: prima i type e le sequence, poi le tabelle con i loro vincoli interni e gli indici, poi le viste che leggono dalle tabelle, quindi le spec dei package, i sottoprogrammi standalone e i body dei package, seguiti dai trigger. Le foreign key si applicano dopo che tutte le tabelle esistono. I materialized view log precedono le materialized view che ne fanno uso. I grant e i sinonimi vengono verso la fine, quando gli oggetti a cui si riferiscono sono già presenti. I dati di seed e le eventuali bonifiche chiudono la sequenza.

Tra schemi diversi l'ordine è dettato dalla struttura definita in `schemi.md`: prima gli script `SYS` che creano tablespace, utenze e ruoli; poi lo schema owner `#APP#`, con i suoi oggetti e i grant verso i ruoli; infine gli schemi consumatori, in particolare i loro sinonimi privati, che presuppongono l'esistenza sia dell'API sull'owner sia dei grant che la rendono accessibile. Un orchestratore di livello superiore mette in sequenza gli orchestratori dei singoli schemi.

## Strategia dei ripetibili e costruzione del rilascio

Per gli oggetti ripetibili si tiene un solo file per oggetto, sovrascritto a ogni modifica, e si affida a git la storia: diff, blame e confronto tra due punti qualsiasi sono esattamente ciò che git offre nativamente, e un naming datato sarebbe una reimplementazione manuale e peggiore di quelle funzioni. Un ulteriore vantaggio è operativo: chi apre il repository vede subito qual è la versione viva di un oggetto, senza dover capire quale tra molti file datati sia quello attuale, e il confronto tra il codice presente sul database e il sorgente — lo strumento con cui l'AM diagnostica i disallineamenti, reso possibile dalla scelta di non offuscare il codice descritta in `schemi.md` — resta immediato.

Il problema che questa scelta lascia aperto non è la storia, ma il **rilascio**: sapere esattamente cosa contiene una release e consegnarlo ai DBA. Questo si risolve con la cartella `Releases/`. Quando si taglia una release, si costruisce `Releases/<versione>/` copiandovi lo snapshot di ciò che si rilascia: la versione corrente dei ripetibili che sono cambiati dall'ultima release, le migrazioni introdotte in questa release, e un `install.sql` che ne orchestra l'esecuzione. Sapere *quali* ripetibili sono cambiati è banale: è il `git diff` tra il tag della release precedente e il punto di rilascio. In questo modo git risponde alla domanda "cosa è cambiato" e `Releases/` risponde alla domanda "cosa consegno", senza duplicare informazione nei nomi dei file sorgente.

## Version control con git

Il progetto è ospitato su GitHub e adotta un modello di branching leggero, coerente con l'esistenza di una sola linea di produzione: **GitHub Flow con tag di release**, esteso con un meccanismo di hotfix on-demand per le emergenze di produzione.

### Il flusso ordinario

Il branch `main` rappresenta lo stato integrato e destinato al rilascio. Ogni intervento — una feature, una correzione non urgente, una migrazione — si sviluppa su un branch dedicato `feature/<descrizione>`, di vita breve, che viene integrato in `main` tramite una Pull Request soggetta a revisione. La revisione non è una formalità: è il punto in cui si verifica la conformità alle convenzioni e la correttezza prima che il codice entri nella linea principale. Al momento del rilascio si applica un **tag** con la versione (`v1.2.0`) e si costruisce lo snapshot in `Releases/1.2.0/`. Non esistono branch `develop` o `release` di lunga vita: in uno scenario a linea singola sarebbero cerimonia senza beneficio.

### Gli hotfix di produzione

Il flusso ordinario ha un limite noto: quando `main` è già avanzato con lavoro destinato alla prossima release, non lo si può rilasciare per correggere un bug urgente in produzione, perché spedirebbe funzionalità non ancora pronte. La soluzione è un branch di hotfix creato **a partire dal tag della versione attualmente in produzione**, non dalla testa di `main`. Si parte dunque dal tag (ad esempio `v1.2.0`), si crea `hotfix/1.2.1`, vi si sviluppa la correzione con la consueta revisione, si tagga la patch (`v1.2.1`) e si costruisce `Releases/1.2.1/` da consegnare ai DBA. Il branch di hotfix è effimero: esiste solo finché la correzione è in lavorazione, e non introduce alcuna struttura permanente aggiuntiva.

Il gruppo di Application Maintenance è il naturale titolare di questo flusso, coerentemente con il suo ruolo di intervento sulla produzione. Esiste però una regola che non ammette eccezioni: **la correzione va sempre riportata su `main`** (forward-port, tramite merge o cherry-pick del branch di hotfix). È l'errore più frequente e più insidioso dimenticarsene, perché il bug corretto in produzione ricomparirebbe puntualmente alla release successiva, dato che `main` non conterrebbe il fix. Il forward-port è parte integrante e non negoziabile della chiusura di un hotfix.

### Regole trasversali

Alcune regole valgono indipendentemente dal branch. Le **migrazioni non si modificano dopo essere state integrate**: un file `.alt` o `.scr` già in `main` è storia, e se contiene un errore lo si corregge con una nuova migrazione, non riscrivendo la vecchia — riscriverla significherebbe che ambienti già allineati e ambienti nuovi divergerebbero silenziosamente. Le **password non compaiono mai** negli script, in particolare in quelli sotto `SYS/`: si usano segnaposto, perché in un database gestito dal cliente il segreto lo detiene il cliente, e comunque un segreto non deve entrare nel version control. Ogni modifica alla linea principale passa da una **Pull Request con almeno una revisione**, sfruttando la branch protection di GitHub.

### Versionamento

Le versioni seguono il versionamento semantico applicato allo stato del database. L'incremento *major* segnala un cambiamento strutturale non retro-compatibile, che richiede un intervento coordinato di migrazione; il *minor* segnala nuove funzionalità retro-compatibili; la *patch* è tipicamente il prodotto di un hotfix. Il numero di versione è ciò che collega il tag git, la cartella in `Releases/` e il pacchetto consegnato ai DBA, tenendo allineati i tre piani.

## Dagli ambienti alla consegna

Il codice attraversa gli ambienti di sviluppo, test e produzione. In sviluppo e test si esegue direttamente dagli script sotto `Sources/`, tipicamente tramite gli orchestratori di install, ricostruendo o aggiornando lo schema secondo necessità. Alcuni schemi esistono solo in questi ambienti — è il caso dello schema di tooling `#APP#_GEN` definito in `schemi.md` — e i loro script di provisioning restano deliberatamente fuori dai pacchetti di release destinati alla produzione. La produzione, specie quando il database è gestito dal cliente, riceve il **pacchetto di release** costruito in `Releases/<versione>/`: è quel pacchetto, autoconsistente e orchestrato dal suo `install.sql`, a essere consegnato a chi ha i privilegi per applicarlo. Il passaggio da script di lavoro a pacchetto di release è il momento in cui lo stato fluido dei sorgenti si cristallizza in un artefatto immutabile e tracciabile.

## Template

Gli scheletri concreti per i principali tipi di file — orchestratori di install, creazione di tabelle, package spec e body, viste, script di migrazione, script di test — sono raccolti tra i template della base e istanziati nella cartella `Templates/` del progetto. Ogni template nasce già conforme alle convenzioni di denominazione e di stile: intestazione, sezione dichiarativa, gestione delle eccezioni e chiusura del blocco sono predisposti secondo le regole definite nelle guidelines, così che partire da un template significhi partire da codice già corretto nella forma.
