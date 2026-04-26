# Introduzione

## Scopo

Questo documento descrive regole e raccomandazioni per lo sviluppo di applicazioni che utilizzano il linguaggio PL/SQL e SQL nell'ambito di Oracle Database, versione 11g Release 2 o successive, e degli strumenti che accedono a tali database.

## Caratteristiche di qualità del software

Le linee guida contenute in questo documento sono organizzate attorno a un insieme di caratteristiche che definiscono la qualità del codice sorgente. Capire queste caratteristiche aiuta a comprendere il ragionamento alla base di ciascuna regola: ogni indicazione ha lo scopo di proteggere o migliorare almeno una di esse.

La **modificabilità** riguarda la facilità con cui il software può essere adattato a nuove esigenze. Include aspetti legati all'architettura, alla logica applicativa e alla gestione dei dati. Un codice difficile da modificare è costoso da mantenere ed è fonte di errori difficili da isolare quando si rende necessario un intervento.

L'**efficienza** descrive la capacità del software di fornire prestazioni adeguate rispetto alle risorse utilizzate — memoria, processore, rete. Scrivere codice efficiente non significa ottimizzare prematuramente ogni istruzione, ma evitare sprechi prevedibili e colli di bottiglia che emergono a scala.

La **manutenibilità** è forse la caratteristica più rilevante per chi lavora in ambienti di produzione su lungo periodo. Un software manutenibile può essere corretto, migliorato e adattato senza sforzo eccessivo. Si esprime nella comprensibilità del codice, nella sua leggibilità e nella chiarezza delle intenzioni dell'autore: il codice viene letto molto più spesso di quanto venga scritto, e ogni scorciatoia presa durante la scrittura si paga con interessi durante la manutenzione.

La **portabilità** misura quanto il software sia trasferibile tra ambienti diversi: compilatori, hardware, sistemi operativi, fusi orari. In ambito Oracle questo si traduce nel rispettare gli standard linguistici e nell'evitare di affidarsi a comportamenti non documentati o specifici di una versione particolare.

L'**affidabilità** è la capacità del software di mantenere il livello di prestazioni atteso nelle condizioni di utilizzo previste. Comprende la gestione corretta delle eccezioni, la tolleranza ai guasti, la correttezza della logica e la gestione sicura delle risorse di sistema.

La **riusabilità** riguarda la possibilità di impiegare i componenti sviluppati in contesti diversi da quello originale. Si ottiene principalmente attraverso la modularità del codice e la chiarezza delle interfacce esposte verso l'esterno.

La **sicurezza** descrive la protezione delle informazioni da accessi non autorizzati o da modifiche non consentite. In SQL e PL/SQL include la gestione corretta degli input provenienti dall'esterno, l'uso appropriato delle API di sistema e il non lasciare il database in uno stato vulnerabile a seguito di errori o eccezioni non gestite.

La **verificabilità** è la capacità del software di essere validato dopo una modifica. Un codice verificabile è strutturato in modo da permettere test sia a livello di unità che di integrazione, facilitando il rilevamento precoce degli errori prima che raggiungano la produzione.

## Gravità delle regole

Ogni regola di questo documento è associata a un livello di gravità, che esprime l'impatto potenziale della sua violazione sul sistema. Conoscere questo livello aiuta a stabilire le priorità durante la revisione del codice e nella pianificazione degli interventi correttivi.

Le regole di livello **Blocker** identificano problemi che possono causare direttamente un bug, un risultato errato o un'eccezione a runtime. Ignorarle equivale ad accettare consapevolmente il rischio di un malfunzionamento in produzione. Le regole di livello **Critical** hanno una natura simile: possono tradursi in bug o avere un impatto diretto e significativo sui costi di manutenzione.

Le regole di livello **Major** segnalano situazioni che influenzano in modo rilevante la manutenibilità e che possono avere ripercussioni sul comportamento a runtime — ad esempio la produzione di dati di audit incompleti o un degrado delle prestazioni sotto carico.

Le regole di livello **Minor** hanno un impatto potenziale sulla manutenibilità, con possibili effetti secondari sul comportamento del sistema — come un maggiore consumo di memoria — ma senza conseguenze immediate sulla correttezza del risultato.

Le regole di livello **Info** hanno un impatto minimo e non influenzano il comportamento a runtime. Rappresentano osservazioni di buona pratica il cui valore è prevalentemente stilistico o documentale.

## Parole chiave utilizzate

La formulazione delle regole segue una convenzione precisa, progettata per comunicare con chiarezza il grado di obbligo di ciascuna indicazione. Comprendere queste parole chiave è necessario per interpretare correttamente le regole e per scegliere con consapevolezza quando e come applicarle.

**Always** (Sempre) indica che la regola deve essere applicata senza eccezioni. **Never** (Mai) indica che l'azione descritta non deve in nessun caso avvenire. Queste due parole chiave definiscono regole assolute, non soggette a interpretazione né a valutazione caso per caso.

**Avoid** (Evitare) indica che la situazione descritta dovrebbe essere prevenuta, pur ammettendo l'esistenza di casi eccezionali in cui potrebbe essere giustificata. **Try** (Tentare) indica che la regola dovrebbe essere seguita quando possibile e appropriato, senza essere vincolante in tutte le circostanze: è un'indicazione di buona pratica, non un obbligo.

Alcune regole sono accompagnate da sezioni aggiuntive che ne arricchiscono la comprensione. La sezione **Example** introduce un esempio illustrativo della regola. La sezione **Reason** spiega il ragionamento alla base dell'indicazione, elemento importante per capire se la regola si applica alla situazione specifica in esame. La sezione **Restriction** descrive le condizioni che devono essere soddisfatte affinché la regola sia applicabile.

## Perché gli standard sono importanti

Per una macchina che esegue un programma, la formattazione del codice è irrilevante. Per l'occhio umano, al contrario, un codice ben strutturato e scritto in modo coerente è molto più semplice da leggere, interpretare e modificare. Gli strumenti di analisi statica moderni possono aiutare ad applicare molte di queste regole in modo automatico, ma il loro valore va ben oltre la semplice formattazione sintattica.

Adottare standard di codifica condivisi in PL/SQL offre vantaggi concreti a chi sviluppa e a chi mantiene le applicazioni nel tempo. Il codice scritto in modo coerente è più facile da leggere, analizzare e modificare — non solo per chi lo ha scritto, ma per chiunque debba lavorarci in futuro, spesso in assenza dell'autore originale. Gli sviluppatori non sono costretti a definire le proprie convenzioni di volta in volta, né a decifrare quelle altrui: le regole sono stabilite, condivise e documentate. Una struttura definita rende strutturalmente più difficile commettere certi tipi di errori. Il codice che rispetta questi standard tende inoltre a essere più efficiente e più modulare, agevolando il riuso dei componenti in contesti diversi da quelli per cui erano stati scritti originalmente.

## Adottare, adattare, non ignorare

Questo documento definisce possibili standard, non regole incise nella pietra. Se in un progetto esistono già convenzioni consolidate — anche diverse da quelle qui descritte — non ha senso modificarle soltanto per conformarsi a questo documento. La coerenza interna a un progetto è più importante della conformità a uno standard esterno.

Alcune regole non generano controversie: il loro beneficio è evidente e non c'è ragione valida per non seguirle. Altre, invece, sono per natura discutibili — come la scelta tra 2, 3 o 4 spazi per l'indentazione, o l'uso dei tab. In questi casi, l'importante non è quale opzione si scelga, ma che la scelta sia coerente all'interno del progetto e mantenuta nel tempo. Prolungate discussioni su quale sia l'opzione "migliore" in assoluto sono raramente produttive: è molto più utile concordare su un'opzione e rispettarla. Il valore degli standard deriva in larga misura proprio dalla loro applicazione uniforme, indipendentemente da quale opzione specifica sia stata scelta.

Per chi avesse esigenze particolari che si discostano da quanto qui definito, la natura aperta di questo progetto consente di derivarne una versione personalizzata, adattata al proprio contesto organizzativo o tecnico.
