# Creare o clonare un repository

Ci sono due modi per iniziare a lavorare con Git su un progetto: crearne uno nuovo da zero, oppure agganciarsi a uno che esiste già. Nella pratica di squadra il caso più frequente è il secondo — ci si unisce a un progetto esistente clonandolo — ma è utile conoscere entrambi.

## Clonare un repository esistente

Clonare significa scaricare una copia completa di un repository remoto, con tutta la sua storia, sul proprio computer. È l'operazione con cui ti unisci a un progetto già avviato. Si usa l'indirizzo del repository, in formato SSH o HTTPS a seconda di come ti sei autenticato:

```bash
git clone git@github.com:organizzazione/nome-repo.git
```

Questo crea una cartella `nome-repo` contenente i file del progetto e la sottocartella nascosta `.git` con la storia. Git configura automaticamente il remote `origin` puntato all'indirizzo da cui hai clonato, così sei già pronto a sincronizzarti. Entrando nella cartella (`cd nome-repo`) sei dentro il repository e puoi iniziare a lavorare.

## Creare un repository nuovo

Se invece parti da una cartella locale che non è ancora sotto controllo di versione, la trasformi in repository con `git init`. Il flusso completo — inizializzare, fare il primo commit, collegare il remote e inviare — è il seguente:

```bash
cd percorso/del/progetto
git init
git add .
git commit -m "Primo commit"
```

A questo punto hai un repository locale con un primo commit, ma nessun remote. Per collegarlo a un repository vuoto creato su GitHub e inviarvi il lavoro:

```bash
git remote add origin git@github.com:organizzazione/nome-repo.git
git branch -M main
git push -u origin main
```

L'opzione `-u` (abbreviazione di `--set-upstream`) stabilisce un legame tra il tuo ramo `main` locale e quello remoto, così che in futuro sia sufficiente scrivere `git push` e `git pull` senza ripetere ogni volta la destinazione.

In alternativa, il percorso più comune è creare prima il repository vuoto su GitHub e poi clonarlo: si evita così la configurazione manuale del remote.

## Il file `.gitignore`

Non tutti i file di una cartella di progetto vanno versionati. File generati automaticamente, log, artefatti di compilazione, cartelle di dipendenze, file di configurazione locali e — soprattutto — file che contengono segreti come password o token non devono finire nel repository. Il file `.gitignore`, posto nella radice del progetto, elenca i percorsi che Git deve ignorare.

Un esempio di `.gitignore` contiene righe come queste:

```gitignore
# Log e file temporanei
*.log
*.tmp

# Artefatti e output
/build/
/dist/

# Configurazioni locali e segreti
.env
*.local

# File di sistema
Thumbs.db
.DS_Store
```

È importante capire che `.gitignore` agisce solo sui file **non ancora tracciati**: se un file è già stato committato in passato, aggiungerlo a `.gitignore` non lo rimuove dalla storia né smette di tracciarlo. Per smettere di tracciare un file già versionato si usa `git rm --cached <file>`. Per generare `.gitignore` adatti a un linguaggio o a uno strumento specifico esistono raccolte pronte, come quelle su https://www.toptal.com/developers/gitignore.

Il file `.gitignore` stesso *va* versionato e condiviso: è parte delle regole del progetto, e serve che tutti ignorino le stesse cose.

## Capire lo stato del repository

In qualsiasi momento, per sapere in che stato ti trovi — su quale ramo sei, quali file sono stati modificati, cosa è pronto per il commit — si usa il comando che consulterai più di ogni altro:

```bash
git status
```

È il primo comando da eseguire quando hai un dubbio su cosa sta succedendo: Git ti dice lo stato attuale e spesso suggerisce anche i comandi che potresti voler usare.

## Documentazione di riferimento

- Ottenere un repository Git (Pro Git): https://git-scm.com/book/it/v2/Nozioni-di-Base-di-Git-Ottenere-un-Repository-Git
- Clonare un repository (GitHub): https://docs.github.com/it/repositories/creating-and-managing-repositories/cloning-a-repository
- Ignorare i file (GitHub): https://docs.github.com/it/get-started/getting-started-with-git/ignoring-files
