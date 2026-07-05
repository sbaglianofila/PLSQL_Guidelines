# CLAUDE.md — Istruzioni operative per l'assistente

Questo file è il punto di partenza per qualsiasi assistente (incluso Claude) che lavori su questo repository. Descrive cosa contiene il progetto, come è organizzato e quali regole rispettare quando si generano codice o documenti. Va letto per intero prima di produrre qualsiasi contenuto.

## Cos'è questo repository

Questo non è un'applicazione: è un **Framework PL/SQL**, ovvero un insieme organico di regole, documenti, template e procedure il cui scopo è standardizzare la creazione di applicazioni PL/SQL su Oracle Database. Gli obiettivi dichiarati sono tre: accelerare lo sviluppo, semplificare la manutenzione e rendere più rapido l'onboarding di nuove persone. Ogni oggetto che viene aggiunto al framework deve servire almeno uno di questi tre obiettivi; se non lo fa, non appartiene qui.

Una precisazione importante sulla natura di questa base, per evitare di sovra-ingegnerizzare: al momento è una **base di partenza per un singolo progetto**, non un prodotto comune manutenuto trasversalmente su più clienti con retrofit delle modifiche. Un progetto adotta questa base, poi diverge — evolve il proprio glossario, i propri domini, le proprie eccezioni. Questo significa una sola linea di produzione, non più versioni da mantenere in parallelo: le scelte (in particolare quelle di version control) vanno mantenute leggere e coerenti con questo scenario. Se un domani la base diventasse un vero prodotto multi-versione, le regole andranno riviste; finché non accade, non vanno anticipate strutture che servirebbero solo in quel caso.

Il framework si rivolge a due categorie di destinatari. La prima è chi sviluppa: trova qui le convenzioni, i template e i pattern da applicare. La seconda è chi mantiene le applicazioni in esercizio — in particolare il gruppo di **Application Maintenance (AM)** — che trova le query di controllo, la Definition of Done e i criteri per verificare che una modifica sia sana prima e dopo il rilascio.

## Decisioni tecniche vincolanti

Queste decisioni sono state prese esplicitamente e condizionano tutto il resto del framework. Non vanno cambiate senza aggiornare `STATUS.md` e `CHANGELOG.md`.

| Ambito | Decisione | Nota |
|---|---|---|
| Database target | Oracle **19c** come baseline | Dove una feature di **23ai** semplifica la soluzione, la si segnala come *improvement* opzionale, senza renderla obbligatoria. |
| Deploy / versioning DB | **Script SQL ordinati** in fase iniziale | L'alberatura è progettata *migration-ready* per passare a **Liquibase** in seguito senza riscrivere la struttura. |
| Strategia file sorgenti | Tre famiglie: **ripetibili** (un file per oggetto, storia su git), **baseline** (creazione iniziale, senza data), **migrazioni** (file datati `YYYYMMDD_NN`, immutabili) | Le migrazioni non si modificano dopo il merge; i rilasci si materializzano in `Releases/<versione>`. Dettagli in `Gestione_Sorgenti/sorgenti.md`. |
| Testing | **utPLSQL** per la logica + **query di controllo** per la verifica dati lato AM | I due livelli sono complementari e concorrono entrambi alla Definition of Done. |
| Hosting repository | **GitHub** | Modello **GitHub Flow + tag**, con hotfix on-demand dal tag di produzione e forward-port obbligatorio su `main`. |

## Come è organizzato il framework

Il repository è strutturato in uno strato di governance (i file meta in radice) e in una serie di pilastri di contenuto. La mappa completa e sempre aggiornata dei documenti è in `INDEX.md`; lo stato di avanzamento è in `STATUS.md`. La struttura a pilastri è la seguente:

- **Standard di codice** — la cartella `PlSql_Guidelines/`, che contiene le convenzioni di denominazione, lo stile di codifica, l'uso del linguaggio, i pattern e la gestione delle eccezioni.
- **Architettura DB** — la definizione degli schemi (owner, applicativo, sola lettura, AM) e delle loro relazioni.
- **Gestione sorgenti** — l'alberatura del repository, la nomenclatura degli script, le regole di version control e i template operativi.
- **Testing** — la strategia di test, i template dei documenti di test e le query di controllo.
- **Processo** — la Definition of Done, la checklist di code review e il template di Pull Request.
- **Onboarding** — la guida di ingresso per chi entra nel progetto.

I contenuti di progetto che evolvono nel tempo — il **glossario** delle abbreviazioni e i **domini** dei tipi — sono documenti vivi tenuti distinti dalle regole stabili.

## Regole di ingaggio quando produci contenuti

Quando scrivi un **documento**, segui `WRITING_STYLE.md` senza eccezioni: prosa discorsiva come forma principale, elenchi e tabelle solo a supporto, spiegazione del *perché* e non solo del *cosa*, lingua italiana. La superficialità è considerata un difetto.

Quando scrivi o generi **codice PL/SQL**, applichi le regole della cartella `PlSql_Guidelines/`: convenzioni di denominazione (`02_naming_conventions.md`), stile di codifica (`03_coding_style.md`), uso del linguaggio (documenti `04`–`12`) e pattern (`11_patterns.md`). Prima di nominare un oggetto, verifica sempre il glossario delle abbreviazioni; prima di scegliere il tipo di una colonna, verifica i domini.

La lingua degli identificatori nel codice è l'**inglese** (`orders` non `ordini`, `employees` non `dipendenti`, `hire_date`, `l_salary`), coerentemente con gli esempi delle guidelines. Anche i **commenti** — inline e di documentazione degli oggetti — nel codice che produci come parte di questo framework sono sempre in inglese, senza eccezioni; un progetto derivato può scegliere un'altra lingua per i commenti purché la applichi in modo uniforme, ma il framework usa l'inglese. La **documentazione** del framework (i file `.md`) è invece in **italiano**. Nessuna lingua va mai mescolata all'interno dello stesso file o della stessa applicazione. Quando traduci un termine di dominio in inglese, usa una resa corretta e registrala nel glossario di progetto, non tradurre a orecchio.

## Manutenzione del framework stesso

Ogni volta che aggiungi, modifichi o rimuovi un documento o un template, aggiorna di conseguenza tre file: `INDEX.md` (per mantenere la mappa navigabile), `STATUS.md` (per riflettere l'avanzamento e le decisioni) e `CHANGELOG.md` (per lasciare traccia storica della modifica). Questi tre aggiornamenti fanno parte della definizione di "lavoro completato" sul framework, non sono un passaggio opzionale.

Quando una decisione tecnica cambia o quando emerge una decisione ancora aperta, registrala in `STATUS.md` nella sezione dedicata, in modo che il ragionamento resti tracciabile e non vada perso tra una sessione e l'altra.
