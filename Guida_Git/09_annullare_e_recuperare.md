# Annullare e recuperare

Prima o poi capita a tutti: un commit sbagliato, una modifica da buttare, un file aggiunto per errore, o la sensazione di aver perso del lavoro. Git offre molti modi per annullare e recuperare, e la buona notizia è che quasi nulla va perso davvero: Git è progettato per non buttare via il lavoro, e con gli strumenti giusti si esce quasi sempre indenni. La cattiva notizia è che i comandi si assomigliano e fanno cose diverse, quindi vale la pena capirli bene.

## Scartare modifiche non ancora committate

Se hai modificato un file e vuoi buttare via le modifiche tornando all'ultima versione committata, usi `git restore`:

```bash
git restore percorso/del/file.sql   # scarta le modifiche a un file
git restore .                       # scarta tutte le modifiche nella cartella
```

Attenzione: questo comando **butta via** le modifiche non committate, che non sono recuperabili perché non erano mai state salvate. Usalo con consapevolezza. Se invece vuoi solo togliere un file dalla staging area lasciando intatte le modifiche, usi `git restore --staged <file>`, come visto nella pagina sul ciclo base.

## Correggere l'ultimo commit

Se hai appena fatto un commit e ti accorgi che il messaggio era sbagliato, o che avevi dimenticato di includere un file, puoi correggere l'ultimo commit con `--amend`. Aggiungi il file mancante alla staging area e poi:

```bash
git commit --amend
```

Git apre l'editor per rivedere il messaggio e sostituisce l'ultimo commit con uno nuovo che include le correzioni. Vale la regola d'oro del rebase: `--amend` riscrive la storia, quindi va usato solo su commit **non ancora inviati** al remote.

## Mettere da parte il lavoro con stash

A volte stai lavorando a qualcosa di incompleto e devi passare urgentemente ad altro — magari a un ramo diverso — senza voler committare un lavoro a metà. Lo *stash* mette da parte le modifiche non committate, riportando la working directory pulita, per poi recuperarle quando vuoi:

```bash
git stash             # mette da parte le modifiche correnti
git stash list        # elenca gli stash salvati
git stash pop         # recupera l'ultimo stash e lo rimuove dall'elenco
```

È lo strumento ideale per l'interruzione improvvisa: metti in pausa, cambi contesto, e poi riprendi esattamente da dove eri.

## Annullare un commit già condiviso: revert

C'è una differenza cruciale tra annullare un commit che è ancora solo tuo e uno che hai già condiviso. Per un commit già inviato al remote, riscrivere la storia è vietato dalla regola d'oro; l'annullamento corretto avviene con `git revert`, che non cancella il commit ma ne crea uno *nuovo* che ne inverte gli effetti:

```bash
git revert <hash-del-commit>
```

Il risultato è che la modifica sbagliata viene neutralizzata, ma la storia resta intatta e coerente per tutti: c'è il commit originale e poi il commit che lo annulla. È il modo sicuro e collaborativo di dire "questa modifica non andava bene".

## Reset: spostare indietro il ramo

Il comando `git reset` sposta l'etichetta del ramo su un commit precedente, e ha tre modalità che si distinguono per cosa fanno delle tue modifiche. `--soft` sposta indietro il ramo ma tiene tutte le modifiche in staging, pronte per un nuovo commit. `--mixed` (l'impostazione predefinita) sposta indietro il ramo e toglie le modifiche dalla staging area, ma le lascia nella working directory. `--hard` sposta indietro il ramo e **cancella** tutte le modifiche successive, sia in staging sia nella working directory.

```bash
git reset --soft HEAD~1    # annulla l'ultimo commit, tiene le modifiche pronte
git reset --mixed HEAD~1   # annulla l'ultimo commit, tiene le modifiche non in staging
git reset --hard HEAD~1    # annulla l'ultimo commit e butta via le modifiche
```

Il `--hard` è l'unico comando di questa pagina che può davvero far perdere lavoro, ed è potente proprio perché è distruttivo. Come per `--amend` e il rebase, `reset` riscrive la storia locale e non va usato su commit già condivisi: per quelli si usa `revert`.

## La rete di sicurezza: reflog

Ecco lo strumento che ti salva quando pensi di aver combinato un disastro. Git tiene un registro di *ogni* posizione in cui HEAD si è trovato — ogni commit, cambio ramo, reset, rebase — nel *reflog*. Anche se un `reset --hard` ha "cancellato" dei commit, quei commit esistono ancora e il reflog ne conserva il riferimento:

```bash
git reflog
```

L'output elenca gli stati recenti con il loro hash. Se hai fatto un reset di troppo, trovi nel reflog l'hash dello stato precedente e ci torni con `git reset --hard <hash>`, recuperando ciò che credevi perso. Il reflog è la ragione per cui, in Git, quasi nulla è davvero irrecuperabile: prima di farti prendere dal panico, guarda sempre lì.

## Documentazione di riferimento

- Annullare le cose (Pro Git): https://git-scm.com/book/it/v2/Nozioni-di-Base-di-Git-Annullare-le-Cose
- Reset demistificato (Pro Git): https://git-scm.com/book/it/v2/Strumenti-di-Git-Reset-Demistificato
- git stash: https://git-scm.com/docs/git-stash
- git reflog: https://git-scm.com/docs/git-reflog
