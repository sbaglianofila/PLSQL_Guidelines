# Gestione dei conflitti

Un *conflitto* si verifica quando Git non può decidere da solo come unire due modifiche, perché due rami hanno cambiato le stesse righe dello stesso file in modi diversi. Succede durante un merge o un rebase, ed è una situazione del tutto normale nel lavoro di squadra: non è un errore che hai commesso, è Git che, correttamente, si rifiuta di indovinare e ti chiede di decidere tu. Imparare a gestire i conflitti con calma è una competenza che toglie molta ansia dall'uso quotidiano di Git.

## Perché e quando accadono

Git sa unire automaticamente modifiche che toccano parti diverse di un file: se tu hai cambiato l'inizio e un collega la fine, le due modifiche convivono senza problemi. Il conflitto nasce solo quando le modifiche si sovrappongono — la stessa riga, o righe adiacenti, cambiate in modo incompatibile — e non esiste un modo oggettivo per stabilire quale versione sia quella giusta. Quella scelta richiede giudizio umano, e Git te la delega.

## Cosa succede quando c'è un conflitto

Quando un merge (o un rebase) incontra un conflitto, Git si ferma, lo segnala e mette il file conflittuale in uno stato speciale. Eseguendo `git status` vedrai i file "unmerged", cioè quelli che aspettano una tua decisione. Aprendo uno di quei file, troverai le zone in conflitto delimitate da marcatori:

```
<<<<<<< HEAD
    and status = 'OPEN'
=======
    and status = 'PENDING'
>>>>>>> feature/import-ordini
```

Il blocco tra `<<<<<<< HEAD` e `=======` è la versione presente nel ramo su cui ti trovi; il blocco tra `=======` e `>>>>>>>` è la versione proveniente dal ramo che stai integrando. I marcatori sono lì solo per mostrarti le due alternative: sta a te decidere.

## Risolvere un conflitto

Risolvere significa modificare il file lasciandolo nello stato finale corretto e **rimuovendo i marcatori**. Puoi tenere una delle due versioni, l'altra, o una combinazione delle due — spesso la soluzione giusta non è "una o l'altra" ma una fusione ragionata di entrambe. Nell'esempio sopra, potresti decidere che la condizione corretta le comprende entrambe:

```
    and status in ('OPEN', 'PENDING')
```

L'importante è che, quando hai finito, il file contenga esattamente ciò che deve contenere e nessuna traccia dei marcatori `<<<<<<<`, `=======`, `>>>>>>>`. È buona norma, dopo aver risolto, rileggere l'intero blocco per assicurarsi che il risultato abbia senso e compili.

## Completare l'operazione

Una volta sistemati i file, si comunica a Git che il conflitto è risolto mettendoli in staging, e poi si porta a termine l'operazione. In un merge:

```bash
git add percorso/del/file.sql
git commit
```

Il commit finale del merge conclude l'integrazione. In un rebase, invece, dopo aver messo in staging i file risolti si prosegue con:

```bash
git add percorso/del/file.sql
git rebase --continue
```

Se a metà di un'operazione conflittuale decidi che è meglio fermarsi e ripensarci, puoi sempre annullare tutto e tornare allo stato di partenza: `git merge --abort` durante un merge, `git rebase --abort` durante un rebase.

## Strumenti che aiutano

Risolvere i conflitti a mano nel testo è del tutto fattibile, ma per i casi complessi esistono strumenti di *merge* visuali che mostrano le due versioni affiancate e la risultante, rendendo più facile scegliere. Molti editor, Visual Studio Code in particolare, evidenziano le zone di conflitto e offrono pulsanti per accettare l'una o l'altra versione. Git può lanciare uno strumento di merge configurato con `git mergetool`. Anche gli strumenti visuali come TortoiseGit, trattati più avanti, offrono un editor di conflitti dedicato.

## Come ridurre i conflitti

I conflitti non si eliminano del tutto, ma si riducono con qualche abitudine. Sincronizzarsi spesso — fare `pull` regolarmente e integrare frequentemente il ramo principale nel proprio lavoro — evita che i rami divergano troppo, perché più a lungo due linee restano separate, più è probabile che si sovrappongano. Anche i commit piccoli e ben delimitati aiutano, perché restringono la superficie su cui un conflitto può nascere. Infine, una buona comunicazione nel team su chi sta lavorando dove previene le sovrapposizioni più grosse alla radice.

## Documentazione di riferimento

- Nozioni base su diramazione e fusione, con i conflitti (Pro Git): https://git-scm.com/book/it/v2/Diramazioni-in-Git-Nozioni-Base-su-Diramazione-e-Fusione
- Risolvere i conflitti di merge (GitHub): https://docs.github.com/it/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts/about-merge-conflicts
