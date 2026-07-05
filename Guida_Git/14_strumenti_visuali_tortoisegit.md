# Strumenti visuali: TortoiseGit e altri

Tutto ciò che abbiamo visto finora si fa da riga di comando, ed è importante conoscere la riga di comando perché è universale, precisa e sempre disponibile. Ma non è l'unico modo di usare Git: esistono strumenti con interfaccia grafica che rendono molte operazioni più immediate, specialmente la visualizzazione della storia, la preparazione dei commit e la risoluzione dei conflitti. Non sostituiscono la comprensione dei concetti — un'interfaccia grafica che non si capisce è pericolosa quanto un comando digitato a caso — ma una volta chiari i concetti, possono rendere il lavoro più comodo. Questa pagina si concentra su TortoiseGit, molto diffuso in ambiente Windows, e cita brevemente le alternative.

## TortoiseGit

TortoiseGit è un'interfaccia grafica per Git integrata direttamente in Esplora file di Windows. La sua caratteristica distintiva è di non essere un'applicazione separata: si usa dal menu contestuale (il tasto destro del mouse) sulle cartelle e sui file, e mostra lo stato dei file tramite piccole icone sovrapposte alle loro nell'esplora risorse. Richiede che Git sia già installato sul sistema, di cui costituisce un'interfaccia.

Si installa da https://tortoisegit.org. Dopo l'installazione, facendo clic destro su una cartella comparirà un menu TortoiseGit con le operazioni disponibili.

### Le operazioni principali

Le operazioni che abbiamo visto da riga di comando hanno tutte il loro corrispettivo nel menu contestuale di TortoiseGit, e comprenderne il legame aiuta a orientarsi. **Clone** avvia la copia di un repository remoto, chiedendo l'indirizzo in una finestra. Le **icone sovrapposte** sui file comunicano a colpo d'occhio lo stato: una spunta verde per i file invariati, un punto esclamativo rosso per quelli modificati, e così via. La voce **Git Commit** apre una finestra dove si vedono i file modificati, si scelgono quelli da includere (l'equivalente visuale della staging area), si scrive il messaggio e si conferma. **Push** e **Pull** aprono finestre per inviare e ricevere, con le opzioni presentate come caselle da spuntare anziché come opzioni da ricordare. **Show log** apre una vista grafica della storia, con i rami disegnati, particolarmente utile per capire com'è fatta la storia del progetto.

La creazione e il cambio di ramo, il merge, il rebase e la gestione dei tag sono tutti presenti nel menu, con finestre che espongono le stesse scelte dei comandi corrispondenti. In caso di conflitto, TortoiseGit offre un editor dedicato che mostra le due versioni affiancate e la risultante, facilitando la risoluzione.

### Il valore e il limite

Il valore di TortoiseGit è l'immediatezza, soprattutto per chi lavora prevalentemente in ambiente Windows e preferisce un'interfaccia visuale, e per operazioni come l'ispezione della storia dove il grafico vale più di mille righe di testo. Il limite è che nasconde ciò che sta accadendo dietro le quinte: è per questo che conviene comunque conoscere i comandi sottostanti, così da capire cosa fa ogni pulsante e da non trovarsi spaesati quando qualcosa non va come previsto o quando ci si trova su una macchina senza interfaccia grafica.

## Le alternative

TortoiseGit non è l'unico strumento visuale. **GitHub Desktop** (https://desktop.github.com) è un'applicazione semplice e curata, integrata con GitHub, ottima per chi lavora principalmente con Pull Request e vuole un'esperienza lineare. **Visual Studio Code** (https://code.visualstudio.com), l'editor molto diffuso, ha un supporto Git integrato eccellente e, con estensioni come GitLens, diventa uno strumento di visualizzazione della storia molto potente senza uscire dall'editor in cui si scrive il codice. **Sourcetree** e **GitKraken** sono client grafici completi e multipiattaforma, apprezzati per la loro visualizzazione ricca della storia.

La scelta dello strumento è in larga misura una questione di gusto personale e di flusso di lavoro. L'importante è che, qualunque strumento si usi, i concetti restino chiari: lo strumento è un'interfaccia verso Git, non un Git diverso.

## Documentazione di riferimento

- TortoiseGit, documentazione: https://tortoisegit.org/docs/
- GitHub Desktop, documentazione: https://docs.github.com/it/desktop
- Uso di Git in Visual Studio Code: https://code.visualstudio.com/docs/sourcecontrol/overview
- Interfacce grafiche per Git (elenco ufficiale): https://git-scm.com/downloads/guis
