# Installazione e configurazione

Prima di poter usare Git bisogna installarlo e configurarlo. La configurazione iniziale è un passaggio da fare una volta sola per macchina, e determina alcuni comportamenti importanti — a partire da come vengono firmati i tuoi commit — quindi conviene farla con attenzione.

## Installazione

### Windows

Su Windows si installa **Git for Windows**, scaricabile da https://git-scm.com/download/win. Il pacchetto include, oltre a Git, un terminale chiamato **Git Bash** che fornisce un ambiente a riga di comando in stile Unix: è l'ambiente in cui conviene eseguire i comandi di questa guida, perché è coerente con la documentazione ufficiale. Durante l'installazione le opzioni predefinite vanno bene nella grande maggioranza dei casi; l'unica scelta a cui prestare attenzione riguarda la gestione dei fine riga, trattata più avanti.

### macOS

Su macOS il modo più semplice è tramite il gestore di pacchetti **Homebrew**, con `brew install git`. In alternativa, eseguendo `git --version` in un terminale, il sistema proporrà di installare gli strumenti da riga di comando di Xcode, che includono Git.

### Linux

Su Linux si usa il gestore di pacchetti della distribuzione: `sudo apt install git` sulle distribuzioni basate su Debian e Ubuntu, `sudo dnf install git` su quelle basate su Fedora e Red Hat.

### Verificare l'installazione

In ogni caso, dopo l'installazione, si verifica che tutto sia a posto chiedendo a Git la sua versione:

```bash
git --version
```

Se il comando risponde con un numero di versione, Git è installato correttamente.

## Configurazione iniziale

Git legge la propria configurazione da tre livelli, dal più generale al più specifico: il livello *system* (tutta la macchina), il livello *global* (il tuo utente) e il livello *local* (il singolo repository). Il livello più specifico vince su quello più generale. Nella pratica, la configurazione personale si fa a livello *global* con l'opzione `--global`, e viene ereditata da tutti i tuoi repository.

### Identità

La prima cosa da impostare è la tua identità, perché ogni commit registra chi lo ha creato. Usa il tuo nome e l'indirizzo email associato all'account GitHub:

```bash
git config --global user.name "Nome Cognome"
git config --global user.email "nome.cognome@esempio.it"
```

### Nome del branch iniziale

Conviene impostare `main` come nome predefinito del ramo iniziale quando si crea un nuovo repository, coerentemente con la convenzione più diffusa e con quella del progetto:

```bash
git config --global init.defaultBranch main
```

### Gestione dei fine riga

Windows e i sistemi Unix usano convenzioni diverse per andare a capo nei file di testo. Se non si gestisce questa differenza, si rischiano differenze spurie in cui *tutte* le righe di un file risultano modificate senza motivo. Su Windows la configurazione consigliata converte i fine riga in stile Windows quando estrai i file e li normalizza quando committi:

```bash
# Windows
git config --global core.autocrlf true

# macOS e Linux
git config --global core.autocrlf input
```

### Editor e comportamento di pull

Alcuni comandi aprono un editor per farti scrivere un messaggio; puoi indicare quale usare. Ed è utile stabilire come si comporta `git pull` quando la storia locale e quella remota sono divergenti — il progetto predilige un aggiornamento lineare, che si ottiene così:

```bash
git config --global core.editor "code --wait"   # esempio: Visual Studio Code
git config --global pull.ff only                 # pull solo se lineare, altrimenti avvisa
```

### Verificare la configurazione

Per vedere tutta la configurazione attiva e da quale file proviene ciascuna voce:

```bash
git config --list --show-origin
```

### Alias: comandi più brevi

Git permette di definire abbreviazioni per i comandi usati più spesso. Non sono obbligatori, ma fanno risparmiare battute. Alcuni esempi diffusi:

```bash
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.lg "log --oneline --graph --decorate --all"
```

Da quel momento `git st` equivale a `git status`, e `git lg` mostra la storia in forma grafica e compatta.

## Documentazione di riferimento

- Download di Git: https://git-scm.com/downloads
- Installazione di Git (Pro Git): https://git-scm.com/book/it/v2/Per-Iniziare-Installare-Git
- Configurazione iniziale (Pro Git): https://git-scm.com/book/it/v2/Per-Iniziare-Configurazione-Iniziale-di-Git
