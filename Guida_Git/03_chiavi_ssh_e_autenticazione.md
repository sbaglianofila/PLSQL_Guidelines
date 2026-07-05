# Chiavi SSH e autenticazione

Per scambiare codice con GitHub — inviare i tuoi commit e riceverne di altri — devi autenticarti, così che il servizio sappia chi sei e cosa ti è permesso fare. Esistono due modi principali: tramite **SSH**, usando una coppia di chiavi crittografiche, oppure tramite **HTTPS**, usando un token di accesso personale. Entrambi funzionano bene; SSH, una volta configurato, è il più comodo perché non richiede di inserire credenziali a ogni operazione.

## SSH: la coppia di chiavi

L'autenticazione SSH si basa su una coppia di chiavi: una **chiave privata**, che resta sul tuo computer e non va mai condivisa con nessuno, e una **chiave pubblica**, che carichi su GitHub. Quando ti connetti, GitHub verifica che tu possieda la chiave privata corrispondente alla pubblica che gli hai fornito. È come una serratura (la chiave pubblica, che puoi distribuire) e la sua unica chiave (la privata, che tieni tu).

### Generare la chiave

Si genera la coppia con `ssh-keygen`, scegliendo l'algoritmo moderno `ed25519` e indicando la propria email come etichetta:

```bash
ssh-keygen -t ed25519 -C "nome.cognome@esempio.it"
```

Il comando chiede dove salvare la chiave — l'impostazione predefinita, nella cartella `.ssh` del tuo profilo, va bene — e una *passphrase*. La passphrase è una protezione aggiuntiva: se qualcuno mettesse le mani sul file della chiave privata, senza la passphrase non potrebbe usarla. È fortemente consigliata. Al termine avrai due file: `id_ed25519` (la chiave privata, da custodire) e `id_ed25519.pub` (la chiave pubblica, da caricare su GitHub).

### Attivare l'agente SSH

L'*agente SSH* è un programma che tiene in memoria la chiave privata sbloccata, così da non doverti chiedere la passphrase a ogni operazione. Lo si avvia e vi si aggiunge la chiave:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

Su Windows, dentro Git Bash, questi comandi funzionano allo stesso modo.

### Caricare la chiave pubblica su GitHub

Bisogna ora comunicare a GitHub la chiave pubblica. Prima si copia il suo contenuto:

```bash
cat ~/.ssh/id_ed25519.pub
```

Si copia l'intera riga stampata. Poi, su GitHub, si va in **Settings → SSH and GPG keys → New SSH key**, si incolla il contenuto e si salva. Da questo momento GitHub riconosce la tua chiave.

### Verificare la connessione

Per accertarsi che tutto funzioni:

```bash
ssh -T git@github.com
```

La prima volta viene chiesto di confermare l'autenticità del server: si risponde `yes`. Se la configurazione è corretta, GitHub risponde con un messaggio di benvenuto che include il tuo nome utente. Da qui in poi, usando gli indirizzi dei repository in formato SSH (`git@github.com:organizzazione/repo.git`), non ti verranno più chieste credenziali.

## HTTPS: il token di accesso personale

L'alternativa è usare gli indirizzi in formato HTTPS (`https://github.com/organizzazione/repo.git`). In questo caso, quando Git chiede una password, **non** si usa la password dell'account GitHub — che non è più accettata per questo scopo — ma un **Personal Access Token (PAT)**, un codice che si genera su GitHub in **Settings → Developer settings → Personal access tokens** e a cui si assegnano permessi specifici. Il token si comporta come una password monouso per gli strumenti.

Perché non doverlo reinserire ogni volta, Git può memorizzarlo tramite un *credential helper*. Su Windows, Git for Windows installa il **Git Credential Manager**, che gestisce e memorizza le credenziali in modo sicuro senza ulteriore configurazione. Su macOS si può usare il portachiavi di sistema:

```bash
git config --global credential.helper manager   # Windows (Git Credential Manager)
git config --global credential.helper osxkeychain  # macOS
```

## Quale scegliere

Per un uso quotidiano e continuativo, SSH è di solito la scelta più comoda: si configura una volta e poi si dimentica. HTTPS con token è altrettanto valido, ed è talvolta preferito in reti aziendali dove il traffico SSH è filtrato. L'importante è essere coerenti: l'indirizzo con cui cloni un repository determina quale metodo verrà usato per quel repository.

## Documentazione di riferimento

- Connettersi a GitHub con SSH: https://docs.github.com/it/authentication/connecting-to-github-with-ssh
- Generare una nuova chiave SSH: https://docs.github.com/it/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
- Gestione dei token di accesso personali: https://docs.github.com/it/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
