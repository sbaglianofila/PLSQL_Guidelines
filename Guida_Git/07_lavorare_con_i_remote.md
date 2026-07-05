# Lavorare con i remote: push, pull, fetch

Finora abbiamo lavorato in locale. Ma il senso di Git in un team è condividere il lavoro, e questo avviene attraverso i *remote*: repository ospitati altrove — nel nostro caso su GitHub — con cui sincronizzi il tuo. Sincronizzarsi significa due cose speculari: inviare i tuoi commit al remote perché gli altri li vedano, e ricevere i loro.

## Cos'è un remote

Un remote è un riferimento a un repository esterno, identificato da un nome e da un indirizzo. Per convenzione, il remote principale — quello da cui hai clonato — si chiama `origin`. Puoi vedere i remote configurati e i loro indirizzi con:

```bash
git remote -v
```

Un repository può avere più remote, ma nella pratica ordinaria del progetto ne basta uno, `origin`, che punta al repository su GitHub.

## Inviare i commit con push

Quando hai creato dei commit in locale e vuoi renderli disponibili sul remote, usi `git push`. Se il ramo su cui lavori è già collegato a un ramo remoto (cosa che avviene automaticamente per i rami clonati, o che imposti con `-u` la prima volta), basta:

```bash
git push
```

La prima volta che invii un ramo nuovo, però, devi dire a Git dove mandarlo e stabilire il collegamento, con l'opzione `-u`:

```bash
git push -u origin feature/import-ordini
```

Da quel momento il ramo locale è collegato al suo omologo remoto, e i successivi `git push` e `git pull` sanno da soli con chi sincronizzarsi.

## Ricevere le modifiche: fetch e pull

Per ricevere il lavoro altrui ci sono due comandi, e la differenza tra loro è importante. `git fetch` scarica dal remote i nuovi commit **senza** toccare il tuo lavoro: aggiorna la tua conoscenza dello stato remoto, ma non modifica i tuoi rami locali. È l'operazione sicura per "dare un'occhiata" a cosa è cambiato prima di integrarlo.

```bash
git fetch
```

`git pull` fa un passo in più: scarica i nuovi commit **e** li integra subito nel tuo ramo locale. In pratica è un `fetch` seguito da un'integrazione automatica.

```bash
git pull
```

L'abitudine sana è **fare `pull` prima di iniziare a lavorare** e prima di fare `push`, per partire sempre dall'ultima versione e ridurre le occasioni di conflitto.

## Quando il push viene rifiutato

Capita, ed è normale: provi a fare `push` e Git lo rifiuta con un messaggio che parla di aggiornamenti "non fast-forward". Significa che nel frattempo qualcun altro ha inviato commit sullo stesso ramo, e il tuo lavoro locale è basato su una versione ormai superata. Git ti impedisce di sovrascrivere il lavoro altrui. La soluzione non è forzare, ma **integrare prima le modifiche remote**: fai `git pull`, risolvi l'eventuale conflitto, e poi fai di nuovo `push`. A quel punto il tuo lavoro è basato sull'ultima versione e viene accettato.

## I rami di tracciamento remoto

Quando fai `fetch`, Git aggiorna dei riferimenti speciali chiamati *remote-tracking branches*, che rappresentano lo stato dei rami sul remote così come lo conosci dall'ultima sincronizzazione. Li vedi con nomi come `origin/main`. Sono utili per confrontare il tuo ramo locale con quello remoto: ad esempio, `git log main..origin/main` mostra i commit che esistono sul remote ma non ancora da te.

## Documentazione di riferimento

- Lavorare con i remoti (Pro Git): https://git-scm.com/book/it/v2/Nozioni-di-Base-di-Git-Lavorare-con-i-Remoti
- git push: https://git-scm.com/docs/git-push
- git fetch e git pull: https://git-scm.com/docs/git-pull
