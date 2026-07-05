# Risoluzione dei problemi comuni

Anche seguendo tutte le buone pratiche, prima o poi ci si imbatte in una situazione che spiazza: un messaggio di errore che non si capisce, uno stato del repository che sembra bloccato, la sensazione di aver perso del lavoro. Questa pagina raccoglie i casi più frequenti e come uscirne con calma. Il principio generale, prima di ogni cosa, è: non farti prendere dal panico e non forzare comandi a caso. In Git quasi nulla è irrecuperabile, e `git status` di solito spiega già cosa sta succedendo.

## "Updates were rejected" al push

È forse il messaggio più comune. Provi a fare `push` e Git lo rifiuta dicendo che gli aggiornamenti sono stati respinti perché il remote contiene lavoro che non hai in locale. Significa che qualcuno ha inviato commit sul ramo dopo la tua ultima sincronizzazione. La soluzione **non** è forzare il push: sovrascriveresti il lavoro altrui. La soluzione è integrare prima le loro modifiche, poi inviare le tue:

```bash
git pull
# risolvi eventuali conflitti
git push
```

## "Detached HEAD"

A volte, dopo aver eseguito un `checkout` di un commit specifico o di un tag, Git avvisa che sei in stato di *detached HEAD*. Significa che non ti trovi su un ramo, ma direttamente su un commit: se facessi commit qui, non apparterrebbero a nessun ramo e rischieresti di perderli. Non è un errore, ma va gestito. Se volevi solo dare un'occhiata, torna su un ramo:

```bash
git switch main
```

Se invece ti accorgi di aver fatto dei commit in questo stato e vuoi tenerli, creaci sopra un ramo prima di spostarti:

```bash
git switch -c nome-nuovo-ramo
```

## Ho committato sul ramo sbagliato

Capita di fare commit su `main` quando si intendeva lavorare su un ramo, o viceversa. Finché non hai inviato nulla, si rimedia facilmente. Crea il ramo giusto (che partirà dal commit corrente, portandosi dietro il lavoro) e riporta indietro il ramo sbagliato:

```bash
git switch -c feature/ramo-giusto   # crea il ramo con i tuoi commit
git switch main
git reset --hard origin/main        # riporta main allo stato del remote
```

Attenzione al `reset --hard`: assicurati che i commit siano al sicuro sul nuovo ramo prima di eseguirlo.

## Ho fatto un reset --hard di troppo

Pensi di aver perso dei commit con un reset troppo aggressivo. Quasi certamente non li hai persi: il reflog conserva i riferimenti a dove eri prima. Consultalo, trova l'hash dello stato che vuoi recuperare e tornaci:

```bash
git reflog
git reset --hard <hash-dello-stato-buono>
```

## Un conflitto mi ha bloccato e voglio ripartire

Se sei nel mezzo di un merge o di un rebase conflittuale e vuoi semplicemente annullare tutto e tornare com'eri prima di iniziare:

```bash
git merge --abort     # durante un merge
git rebase --abort    # durante un rebase
```

## Ho committato un file che non dovevo

Se hai incluso in un commit un file che non doveva esserci — un file generato, un file con un segreto — e non hai ancora inviato, puoi rimuoverlo dalla staging e correggere il commit. Per smettere di tracciare un file lasciandolo sul disco:

```bash
git rm --cached percorso/del/file
git commit --amend
```

Ricordati poi di aggiungere quel file a `.gitignore`. Se il file conteneva un segreto ed è già stato inviato al remote, il segreto va considerato compromesso: va revocato e sostituito, non basta cancellarlo.

## Git mi chiede le credenziali a ogni operazione

Se ogni `push` o `pull` ti chiede utente e password, manca la configurazione dell'autenticazione persistente. La soluzione dipende dal metodo: con SSH, verifica che la chiave sia caricata nell'agente; con HTTPS, configura il credential helper che memorizza il token. La pagina sull'autenticazione tratta entrambi i casi.

## Quando proprio non ne esci

Se una situazione ti sembra irrecuperabile, prima di tentativi disperati fermati e chiedi aiuto a un collega più esperto, mostrandogli l'output di `git status` e `git reflog`. Molte situazioni che sembrano disastri sono in realtà banali da sistemare per chi le ha già viste, e un secondo paio di occhi evita di trasformare un piccolo problema in uno grande con un comando forzato.

## Documentazione di riferimento

- git reflog: https://git-scm.com/docs/git-reflog
- Annullare le cose (Pro Git): https://git-scm.com/book/it/v2/Nozioni-di-Base-di-Git-Annullare-le-Cose
- Detached HEAD e git switch: https://git-scm.com/docs/git-switch
