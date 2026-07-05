# Buone pratiche

Conoscere i comandi di Git è una cosa; usarli bene, in modo che la storia del progetto resti pulita e la collaborazione scorra senza attriti, è un'altra. Questa pagina raccoglie le abitudini che fanno la differenza tra un uso di Git ordinato e uno caotico. Non sono regole imposte dallo strumento, ma convenzioni che il team adotta perché rendono la vita di tutti più semplice.

## Commit piccoli e a tema

Un commit dovrebbe rappresentare **una sola modifica logica e coerente**. Un commit che risolve un bug è un buon commit; un commit che risolve un bug, aggiunge una funzionalità e riformatta tre file è un cattivo commit, perché è difficile da revisionare, impossibile da annullare selettivamente e confuso da leggere nella storia. Committare spesso, con commit piccoli e mirati, produce una storia che si legge come un racconto ordinato di come il progetto è cresciuto.

## Messaggi di commit che spiegano il perché

Il messaggio di commit è documentazione permanente. La prima riga, breve e all'imperativo, dice *cosa* fa il commit; il corpo, quando serve, spiega il *perché*. Il *cosa* spesso si intuisce dal codice; è il *perché* — la ragione di una scelta, il contesto di una correzione, il vincolo che ha imposto una soluzione non ovvia — a essere prezioso mesi dopo. Un messaggio come "Corregge il calcolo del totale escludendo gli ordini annullati, che gonfiavano il fatturato mensile" vale infinitamente più di "fix".

## Sincronizzarsi spesso

Fare `pull` regolarmente, e integrare di frequente il ramo principale nel proprio lavoro, evita che i rami divergano troppo. Più a lungo due linee di sviluppo restano separate, più aumenta la probabilità e la gravità dei conflitti al momento di riunirle. Integrazioni piccole e frequenti sono molto meno dolorose di una grande integrazione rimandata a lungo. La regola pratica è: aggiorna prima di iniziare a lavorare, e aggiorna prima di inviare.

## Rami di vita breve

Un ramo `feature/*` dovrebbe vivere il tempo necessario a completare la sua attività, e non di più. I rami che restano aperti per settimane accumulano divergenza rispetto a `main` e diventano difficili da integrare. Meglio suddividere un lavoro grande in più attività piccole, ciascuna con il proprio ramo e la propria Pull Request, che portare avanti un unico ramo gigantesco per lungo tempo.

## Mai committare segreti

Password, token, chiavi private, stringhe di connessione con credenziali: nulla di tutto questo deve mai entrare in un repository. Una volta committato, un segreto resta nella storia anche se lo cancelli in un commit successivo, e va considerato compromesso. Si prevengono questi incidenti usando il file `.gitignore` per escludere i file di configurazione locale, e tenendo i segreti in file che non vengono mai versionati. Se un segreto finisce per errore nel repository, va revocato e sostituito, non semplicemente cancellato.

## Non riscrivere la storia condivisa

È la regola d'oro già incontrata parlando di rebase, e merita di stare tra le buone pratiche perché è la più importante in assoluto per la serenità del team. Rebase, `commit --amend` e `reset` sono strumenti eccellenti finché operano su commit **locali, non ancora condivisi**. Nel momento in cui un commit è stato inviato al remote e altri potrebbero averlo, riscriverlo crea divergenze che si pagano care. Per annullare qualcosa di già pubblico si usa `revert`, che aggiunge un commit di annullamento senza toccare la storia esistente.

## Usare bene .gitignore

Un `.gitignore` ben curato tiene il repository pulito da tutto ciò che non deve esserci: artefatti generati, file temporanei, configurazioni locali, cartelle di dipendenze. Un repository che contiene solo ciò che va versionato è più leggero, più chiaro e meno soggetto a conflitti inutili. Il `.gitignore` è condiviso e versionato, così che tutto il team ignori le stesse cose.

## Leggere prima di agire, quando si è in dubbio

Infine, un'abitudine che vale più di molti comandi: quando non si è sicuri di cosa stia succedendo, `git status` e `git log` sono lì per dirlo. E quando si sta per fare qualcosa di potenzialmente distruttivo, vale la pena fermarsi un momento a rileggere cosa il comando farà davvero. Git è molto bravo a non far perdere lavoro a chi procede con consapevolezza; il reflog è la rete di sicurezza, ma la prima difesa è capire cosa si sta facendo.

## Documentazione di riferimento

- Suggerimenti sulla creazione dei commit (Pro Git): https://git-scm.com/book/it/v2/Git-Distribuito-Contribuire-a-un-Progetto
- Rimuovere dati sensibili da un repository (GitHub): https://docs.github.com/it/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository
