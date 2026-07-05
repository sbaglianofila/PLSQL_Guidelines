# Il ciclo base: add, commit, log

Il lavoro quotidiano con Git ruota attorno a un ciclo semplice: si modificano i file, si scelgono le modifiche da salvare, si crea un commit e, quando serve, si consulta la storia. Capire bene questo ciclo — e in particolare il ruolo della staging area — è la base di tutto il resto.

## Le tre aree

Git lavora con tre spazi distinti, ed è la comprensione di questi che rende tutto il resto chiaro. La **working directory** è la cartella con i tuoi file, dove modifichi il codice. La **staging area** (o *index*) è un'anticamera dove raccogli le modifiche che vuoi includere nel prossimo commit. Il **repository** è dove i commit, una volta creati, vengono conservati in modo permanente nella storia.

Il passaggio da un'area all'altra è esplicito: le modifiche ai file vivono nella working directory, con `git add` le sposti nella staging area, con `git commit` le consolidi nel repository. Questo doppio passaggio non è una complicazione fine a sé stessa: è ciò che ti permette di costruire un commit con precisione, scegliendo esattamente quali modifiche includere anche quando ne hai fatte molte e disparate.

## Vedere cosa è cambiato

Il punto di partenza di ogni operazione è sapere cosa è cambiato. `git status` mostra quali file sono stati modificati, quali sono già in staging e quali non sono tracciati:

```bash
git status
```

Per vedere nel dettaglio le differenze riga per riga, `git diff` mostra le modifiche nella working directory non ancora in staging, mentre `git diff --staged` mostra quelle già in staging, cioè ciò che finirà nel prossimo commit:

```bash
git diff            # modifiche non ancora in staging
git diff --staged   # modifiche già pronte per il commit
```

## Preparare le modifiche con add

Il comando `git add` sposta nella staging area le modifiche che vuoi committare. Puoi aggiungere un singolo file, tutti i file modificati, oppure — molto utile — scegliere interattivamente porzioni di un file:

```bash
git add percorso/del/file.sql   # un file specifico
git add .                       # tutte le modifiche nella cartella corrente
git add -p                      # scegli interattivamente quali blocchi includere
```

L'opzione `-p` (patch) è preziosa quando in un file hai fatto due modifiche non correlate e vuoi metterle in due commit distinti: Git ti presenta un blocco alla volta e ti chiede se includerlo.

Se aggiungi qualcosa in staging per sbaglio, lo rimuovi senza perdere la modifica con:

```bash
git restore --staged percorso/del/file.sql
```

## Salvare con commit

Quando la staging area contiene ciò che vuoi salvare, crei il commit. Con l'opzione `-m` fornisci il messaggio direttamente; senza, Git apre l'editor per scriverlo:

```bash
git commit -m "Aggiunge il vincolo di check sullo stato dell'ordine"
```

### Scrivere buoni messaggi di commit

Il messaggio di commit è documentazione che resta per sempre, e un messaggio scritto bene ripaga ogni volta che qualcuno — spesso tu stesso, mesi dopo — cerca di capire perché una modifica è stata fatta. La convenzione consolidata prevede una prima riga breve e sintetica, scritta all'imperativo e sotto i cinquanta caratteri, che riassume *cosa* fa il commit; se serve, una riga vuota e poi un corpo più esteso che spiega il *perché* della modifica, il contesto e le eventuali conseguenze. Il *cosa* si legge dal codice; è il *perché* che il messaggio deve catturare.

Un buon commit è anche **atomico**: contiene una sola modifica logica e coerente. Un commit che mescola una correzione di bug, una nuova funzionalità e una riformattazione è difficile da revisionare e impossibile da annullare selettivamente. Meglio più commit piccoli e a tema che uno grande e confuso.

## Consultare la storia

Il comando `git log` mostra la storia dei commit, dal più recente. Nella sua forma grezza è verboso; le opzioni che lo rendono davvero utile lo compattano e ne mostrano la struttura a rami:

```bash
git log                                    # storia completa e verbosa
git log --oneline                          # una riga per commit
git log --oneline --graph --decorate --all # grafico dei rami, molto usato
```

Per ispezionare un singolo commit — vederne il messaggio completo e le modifiche introdotte — si usa `git show`:

```bash
git show <hash-del-commit>
```

Non serve digitare l'hash per intero: bastano i primi caratteri, purché identifichino il commit senza ambiguità.

## Documentazione di riferimento

- Registrare le modifiche nel repository (Pro Git): https://git-scm.com/book/it/v2/Nozioni-di-Base-di-Git-Registrare-le-Modifiche-nel-Repository
- Visualizzare la storia dei commit (Pro Git): https://git-scm.com/book/it/v2/Nozioni-di-Base-di-Git-Visualizzare-la-Storia-dei-Commit
