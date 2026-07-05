# Rebase

Il *rebase* è uno degli strumenti più utili di Git, e anche uno di quelli che più facilmente si prestano a fare danni se non se ne capisce il funzionamento. In una frase: il rebase riscrive la storia, spostando una serie di commit su una nuova base. Serve a mantenere la storia pulita e lineare, ma proprio perché *riscrive* la storia va usato con una regola d'oro che vedremo alla fine e che non ammette eccezioni.

## Rebase e merge a confronto

Sia il merge sia il rebase servono a integrare il lavoro di un ramo in un altro, ma lo fanno in modo diverso e producono storie diverse. Immagina di aver creato un ramo `feature` da `main`, e che nel frattempo `main` sia andato avanti. Con il *merge* unisci i due rami creando un merge commit che li riconcilia: la storia conserva la traccia del fatto che il lavoro è avvenuto in parallelo e poi è stato riunito. Con il *rebase*, invece, prendi i commit del tuo ramo e li riappoggi uno per uno *sopra* l'ultimo commit di `main`, come se li avessi scritti a partire da lì: la storia risulta lineare, come se il lavoro fosse avvenuto in sequenza e non in parallelo.

Nessuno dei due è "giusto" in assoluto. Il merge preserva la storia reale ed è più sicuro; il rebase produce una storia più pulita e facile da leggere, al prezzo di riscriverla.

## Fare un rebase

Per riappoggiare il ramo corrente sopra un altro ramo — tipicamente per aggiornare il tuo `feature` con gli ultimi commit di `main` — ci si posiziona sul ramo da spostare e si indica la nuova base:

```bash
git switch feature/import-ordini
git rebase main
```

Git riapplica i tuoi commit uno alla volta sopra `main`. Se uno di essi entra in conflitto, il rebase si ferma e ti chiede di risolverlo; dopo aver sistemato i file e averli messi in staging, si prosegue con `git rebase --continue`. In qualsiasi momento puoi annullare tutto e tornare alla situazione di partenza con `git rebase --abort`.

## Il rebase interattivo

Una variante molto potente è il *rebase interattivo*, che permette di rimaneggiare una serie di commit prima di consolidarli: unirne più d'uno in uno solo (*squash*), riscriverne i messaggi, riordinarli, eliminarne. Si avvia indicando fin dove risalire; per intervenire sugli ultimi tre commit:

```bash
git rebase -i HEAD~3
```

Git apre un editor con l'elenco dei commit e, accanto a ciascuno, un'azione modificabile: `pick` per tenerlo com'è, `squash` per fonderlo con il precedente, `reword` per cambiarne il messaggio, `drop` per eliminarlo. È lo strumento con cui si "pulisce" un ramo prima di proporlo per l'integrazione, trasformando una serie di commit di lavoro disordinati in una sequenza chiara e leggibile.

## La regola d'oro

Ecco la regola che non va mai violata: **non riscrivere mai la storia che è già stata condivisa con altri**. Poiché il rebase crea nuovi commit al posto di quelli vecchi (cambiano gli hash), se rebasi commit che hai già inviato al remote e su cui altri potrebbero aver basato il loro lavoro, crei una divergenza velenosa: la loro storia e la tua non combaciano più, e riconciliarle diventa un incubo. La regola pratica è semplice: **rebase liberamente sui tuoi commit locali non ancora inviati; non rebasare mai i commit già pubblicati e condivisi.** Il rebase è uno strumento per pulire il *tuo* lavoro prima di condividerlo, non per riscrivere ciò che è già pubblico.

## Forzare il push dopo un rebase, con prudenza

Se hai rebasato commit che *avevi già inviato al tuo ramo personale* — situazione accettabile finché sei l'unico a lavorare su quel ramo — un normale `push` verrà rifiutato, perché la storia è cambiata. In questo caso si usa un push forzato, ma nella variante prudente `--force-with-lease`, che rifiuta l'operazione se nel frattempo qualcun altro ha inviato commit sul ramo, proteggendoti dal cancellare inavvertitamente il lavoro altrui:

```bash
git push --force-with-lease
```

Il push forzato "secco" (`--force`) va evitato: `--force-with-lease` fa la stessa cosa ma con una rete di sicurezza.

## Documentazione di riferimento

- Rebase (Pro Git): https://git-scm.com/book/it/v2/Diramazioni-in-Git-Rebase
- git rebase: https://git-scm.com/docs/git-rebase
