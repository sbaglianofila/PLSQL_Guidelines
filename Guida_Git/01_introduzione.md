# Introduzione: cos'è Git

Git è un sistema di controllo di versione: uno strumento che registra la storia delle modifiche a un insieme di file, permette a più persone di lavorarci contemporaneamente senza pestarsi i piedi, e consente di tornare indietro nel tempo quando qualcosa va storto. Se hai mai salvato file chiamati `documento_v2`, `documento_finale`, `documento_finale_davvero`, hai intuito il problema che Git risolve in modo rigoroso: tenere traccia di come qualcosa evolve, chi ha cambiato cosa e perché, e poter ricostruire qualsiasi stato passato.

## Perché un sistema di controllo di versione

Senza uno strumento del genere, collaborare su del codice diventa presto ingestibile. Non si sa chi ha modificato una riga né quando, unire il lavoro di due persone significa copiare e incollare a mano, e un errore introdotto la settimana scorsa è difficile da isolare perché non c'è memoria di com'era il codice prima. Un sistema di controllo di versione dà tre garanzie: una **storia** completa e navigabile di ogni modifica, la possibilità di **collaborare** unendo il lavoro di più persone in modo controllato, e una rete di sicurezza che permette di **tornare indietro** a uno stato funzionante.

## Git è distribuito

Git appartiene alla famiglia dei sistemi *distribuiti*, e questa è la sua caratteristica più importante da capire subito. In un sistema centralizzato la storia vive su un server, e senza connessione non si può fare quasi nulla. In Git, invece, quando copi un repository (operazione chiamata *clone*) ottieni sul tuo computer l'intera storia del progetto, non solo l'ultima versione. Puoi quindi lavorare, salvare modifiche, consultare la storia e creare rami anche completamente offline; ti sincronizzi con gli altri solo quando vuoi, inviando e ricevendo le modifiche. Ogni clone è un repository completo, e questo rende Git veloce e robusto: non esiste un singolo punto la cui perdita cancelli la storia.

## I concetti fondamentali

Prima di usare Git conviene fissare alcuni termini, perché tornano di continuo. Il **repository** (o *repo*) è il contenitore del progetto e della sua intera storia; sul tuo disco è una normale cartella con dentro una sottocartella nascosta `.git` che custodisce tutto. La **working directory** è lo stato dei file come li vedi e li modifichi in quella cartella. La **staging area** (o *index*) è un'area intermedia dove prepari le modifiche che entreranno nel prossimo salvataggio: è una peculiarità di Git che all'inizio spiazza, ma che dà un controllo prezioso, perché ti permette di decidere con precisione cosa includere in un salvataggio e cosa no.

Un **commit** è un salvataggio: una fotografia dello stato del progetto in un dato momento, corredata di un autore, una data e un messaggio che spiega la modifica. Ogni commit è identificato da un codice esadecimale univoco (un *hash* SHA) e conosce il commit che lo precede, così che l'insieme dei commit formi la storia. **HEAD** è un puntatore che indica dove ti trovi nella storia, di norma sull'ultimo commit del ramo su cui stai lavorando. Un **branch** (ramo) è una linea di sviluppo indipendente: tecnicamente è solo un puntatore mobile a un commit, ed è ciò che permette di portare avanti più lavori in parallelo. Un **remote** è un repository ospitato altrove — tipicamente su GitHub — con cui sincronizzi il tuo; per convenzione il remote principale si chiama `origin`.

## Come Git memorizza la storia

Un dettaglio che aiuta a capire il comportamento di Git è che ogni commit non registra le *differenze* rispetto al precedente, ma una *fotografia* completa dello stato dei file (internamente ottimizzata per non sprecare spazio). Questo rende operazioni come cambiare ramo o consultare una versione passata molto rapide, perché Git non deve ricostruire nulla applicando differenze in sequenza: ha già lo snapshot. Ogni commit punta al proprio predecessore, e un ramo non è altro che un'etichetta che indica l'ultimo commit di una sequenza. Spostarsi tra rami significa spostare HEAD e aggiornare la working directory allo snapshot corrispondente.

## Git non è GitHub

È una confusione frequente e vale la pena chiarirla subito. **Git** è lo strumento di controllo di versione che gira sul tuo computer. **GitHub** è un servizio che ospita repository Git su Internet e vi aggiunge funzionalità di collaborazione: le Pull Request, la gestione dei permessi, la revisione del codice, le automazioni. Si può usare Git senza GitHub, e GitHub è solo uno dei possibili servizi di hosting — ne esistono altri, come GitLab o Bitbucket. Nel nostro progetto usiamo Git come strumento e GitHub come luogo dove i repository vivono e dove collaboriamo.

## Documentazione di riferimento

- Cos'è il controllo di versione (Pro Git, in italiano): https://git-scm.com/book/it/v2/Per-Iniziare-Informazioni-sul-Controllo-di-Versione
- Nozioni di base di Git: https://git-scm.com/book/it/v2/Per-Iniziare-Nozioni-di-Base-di-Git
