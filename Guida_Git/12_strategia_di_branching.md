# La strategia di branching del progetto

Le pagine precedenti hanno spiegato i comandi di Git in generale. Questa spiega come li usiamo *noi*: il flusso di lavoro concordato per il progetto, che tutti devono seguire perché la collaborazione sia ordinata. La strategia è deliberatamente leggera, adatta a un progetto con una sola linea di produzione, ed è la stessa descritta nel documento sulla gestione dei sorgenti, qui declinata in termini operativi di Git.

## Il modello: GitHub Flow con tag

Adottiamo **GitHub Flow più tag di release**. In sintesi: esiste un unico ramo di lunga vita, `main`, che rappresenta sempre lo stato integrato e destinato al rilascio; ogni modifica si sviluppa su un ramo `feature/*` di vita breve, che viene integrato in `main` tramite una Pull Request con revisione; le release si marcano con un tag. Non ci sono rami `develop` o `release` permanenti: sarebbero una complicazione inutile in uno scenario a linea singola.

Questo modello ha due virtù. È semplice, quindi difficile da sbagliare. Ed è coerente con il modo in cui produciamo i rilasci: il tag marca il punto della storia, e la cartella `Releases/<versione>` ne materializza lo snapshot.

## Il flusso ordinario, passo per passo

Il ciclo di una modifica ordinaria — una nuova funzionalità, un miglioramento, una correzione non urgente — segue sempre gli stessi passi.

Si parte allineati, aggiornando `main`:

```bash
git switch main
git pull
```

Si crea un ramo dedicato all'attività, con un nome che ne comunica la natura:

```bash
git switch -c feature/import-ordini
```

Si lavora, creando commit piccoli e a tema man mano che il lavoro procede. Quando il ramo è pronto — codice, test utPLSQL e query di controllo, secondo la Definition of Done — lo si invia al remote:

```bash
git push -u origin feature/import-ordini
```

Su GitHub si apre una **Pull Request** verso `main`, che viene revisionata da un collega. Superata la revisione, la si integra in `main`. Infine si cancella il ramo, che ha esaurito il suo scopo. Il dettaglio delle Pull Request è nella pagina dedicata.

## Le release

Quando `main` contiene tutto ciò che deve entrare in una versione, si produce la release: si appone un tag annotato con il numero di versione, lo si invia al remote e si costruisce la cartella di release corrispondente.

```bash
git switch main
git pull
git tag -a v1.3.0 -m "Release 1.3.0"
git push origin v1.3.0
```

Da questo momento `main` può proseguire con il lavoro destinato alla release successiva, mentre il tag `v1.3.0` resta come riferimento immutabile a ciò che è stato rilasciato.

## Gli hotfix di produzione

C'è una situazione che il flusso ordinario da solo non copre, ed è importante: un bug urgente in produzione quando `main` è già avanzato con lavoro non ancora pronto per il rilascio. Non si può rilasciare `main`, perché spedirebbe funzionalità incomplete. La soluzione è un ramo di hotfix creato **a partire dal tag della versione in produzione**, non dalla testa di `main`.

Si parte dunque dal tag della versione attualmente in esercizio e si crea il ramo di correzione:

```bash
git switch -c hotfix/1.3.1 v1.3.0
```

Vi si sviluppa la correzione, con la consueta Pull Request e revisione. Quando è pronta, si tagga la nuova versione *patch* e si costruisce la relativa cartella di release da consegnare:

```bash
git tag -a v1.3.1 -m "Hotfix 1.3.1: correzione calcolo totale ordine"
git push origin v1.3.1
```

## Il forward-port: la regola da non dimenticare

Ecco la parte che salta più spesso, con conseguenze fastidiose: la correzione fatta nell'hotfix **va riportata anche su `main`**. Se non lo si fa, il bug — corretto in produzione — ricompare puntualmente alla release successiva, perché `main` non contiene quel fix. Questo passaggio, il *forward-port*, è parte integrante e non negoziabile della chiusura di un hotfix. Si riporta la correzione su `main` integrando il ramo di hotfix:

```bash
git switch main
git pull
git merge hotfix/1.3.1
git push
```

In alternativa, se sul ramo di hotfix ci sono più commit e se ne vuole portare solo alcuni, si usa `git cherry-pick <hash>` per riportare i singoli commit. In ogni caso, il principio è inderogabile: **nessun hotfix è concluso finché la sua correzione non è anche su `main`.**

## In sintesi

Il ciclo di vita completo, visto dall'alto, è questo: `main` è sempre rilasciabile; ogni lavoro nasce su un ramo `feature/*`, passa da una Pull Request revisionata e torna in `main`; le versioni si marcano con tag; le emergenze di produzione si correggono su `hotfix/*` a partire dal tag in esercizio, si rilasciano come versione patch e si riportano immancabilmente su `main`. È un modello che sta in mente senza sforzo, ed è proprio questa la sua forza.

## Documentazione di riferimento

- GitHub Flow: https://docs.github.com/it/get-started/using-github/github-flow
- Modelli di branching (Pro Git): https://git-scm.com/book/it/v2/Diramazioni-in-Git-Modelli-di-Diramazione-Git
- Gestione dei sorgenti del progetto: [../Gestione_Sorgenti/sorgenti.md](../Gestione_Sorgenti/sorgenti.md)
