# Pull Request su GitHub

La *Pull Request* (spesso abbreviata in PR) è lo strumento con cui, su GitHub, si propone di integrare il lavoro di un ramo in un altro — nel nostro flusso, di un ramo `feature/*` o `hotfix/*` in `main`. Non è una funzionalità di Git in sé, ma di GitHub, ed è il luogo dove avviene la collaborazione vera: la revisione del codice, la discussione, e il controllo di qualità prima che una modifica entri nella linea principale. Nel progetto ogni modifica a `main` passa da una Pull Request revisionata: non è una formalità, è il momento in cui una seconda persona guarda il codice prima che diventi ufficiale.

## Aprire una Pull Request

Il presupposto è aver già inviato il proprio ramo al remote con `git push`. Fatto questo, su GitHub — nella pagina del repository — comparirà la proposta di aprire una Pull Request dal ramo appena inviato; in alternativa la si crea dalla scheda "Pull requests" scegliendo il ramo di partenza e `main` come destinazione.

Una buona Pull Request si spiega da sé. Il titolo riassume la modifica in modo chiaro; la descrizione racconta *cosa* è stato fatto e soprattutto *perché*, quali scelte sono state prese e come verificare che funzioni. Se esiste un ticket o una issue collegata, la si richiama nella descrizione: scrivendo ad esempio "Closes #317", GitHub chiuderà automaticamente la issue quando la PR verrà integrata. Il progetto adotta un template di Pull Request che guida la compilazione di questi elementi, così che ogni PR contenga le informazioni necessarie alla revisione.

## La revisione

Una volta aperta, la Pull Request viene assegnata a un revisore. La revisione avviene sulla piattaforma: il revisore vede le differenze introdotte, può commentare righe specifiche, porre domande, chiedere modifiche o approvare. È un dialogo, non un esame: l'obiettivo condiviso è che il codice che entra in `main` sia corretto, conforme alle convenzioni e comprensibile.

Se il revisore chiede modifiche, si interviene semplicemente aggiungendo nuovi commit sullo stesso ramo e inviandoli: la Pull Request si aggiorna da sola, perché è collegata al ramo. Non serve aprire una nuova PR. Quando il revisore è soddisfatto, approva.

## L'integrazione

Approvata la Pull Request, la si integra in `main`. GitHub offre diverse modalità di integrazione, che vale la pena conoscere. Il *merge commit* crea un commit di fusione che conserva la traccia della PR e di tutti i suoi commit. Lo *squash and merge* condensa tutti i commit della PR in un unico commit su `main`, utile quando il ramo conteneva molti commit di lavoro intermedi che non ha senso conservare singolarmente. Il *rebase and merge* riappoggia i commit della PR su `main` senza creare un commit di fusione. La scelta dipende dalle convenzioni del progetto; lo squash è spesso preferito per mantenere la storia di `main` pulita e leggibile, con un commit per funzionalità.

Dopo l'integrazione, il ramo della Pull Request ha esaurito il suo scopo e va cancellato: GitHub offre un pulsante per farlo direttamente, ed è buona abitudine usarlo.

## La protezione del ramo principale

Per garantire che la regola "ogni modifica passa da una PR revisionata" sia davvero rispettata e non solo raccomandata, il ramo `main` è protetto tramite le *branch protection rules* di GitHub. Tipicamente questo significa che non si può inviare codice direttamente su `main`, ma solo attraverso una Pull Request, e che la PR richiede almeno un'approvazione prima di poter essere integrata. Questa protezione è ciò che trasforma una buona pratica in una garanzia strutturale.

## Documentazione di riferimento

- Informazioni sulle Pull Request (GitHub): https://docs.github.com/it/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests
- Creare una Pull Request (GitHub): https://docs.github.com/it/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request
- Informazioni sulle branch protection rules (GitHub): https://docs.github.com/it/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
