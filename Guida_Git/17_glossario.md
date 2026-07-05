# Glossario dei termini Git

Il "mondo Git" ha un vocabolario tutto suo, fatto di termini spesso lasciati in inglese anche quando si parla italiano. Questo glossario raccoglie i termini che ricorrono nella guida e nell'uso quotidiano, con una definizione breve. È pensato per essere consultato al volo quando si incontra una parola di cui non si è sicuri.

**Blame** — Comando (`git blame`) che mostra, riga per riga di un file, quale commit e quale autore l'hanno modificata l'ultima volta. Utile per capire quando e perché una riga è stata scritta.

**Branch (ramo)** — Linea di sviluppo indipendente. Tecnicamente, un puntatore mobile a un commit. Permette di lavorare in parallelo su attività diverse.

**Checkout** — Comando storico (`git checkout`) usato per spostarsi tra rami e commit e per estrarre file. Per il cambio ramo è oggi sostituito dal più chiaro `git switch`.

**Cherry-pick** — Operazione (`git cherry-pick`) che applica su un ramo un singolo commit preso da un altro ramo, senza integrare tutto il resto.

**Clone** — Copia completa di un repository remoto sul proprio computer, comprensiva di tutta la storia. Si ottiene con `git clone`.

**Commit** — Un salvataggio: una fotografia dello stato del progetto in un dato momento, con autore, data, messaggio e un identificatore univoco (hash). Anche il verbo per l'atto di crearlo.

**Conflitto (merge conflict)** — Situazione in cui Git non può unire automaticamente due modifiche perché toccano le stesse righe in modo incompatibile, e richiede l'intervento umano.

**Detached HEAD** — Stato in cui HEAD punta direttamente a un commit anziché a un ramo. I commit fatti in questo stato non appartengono ad alcun ramo e rischiano di andare persi.

**Diff** — Le differenze tra due stati dei file: tra la working directory e la staging area, tra questa e l'ultimo commit, o tra due commit qualsiasi. Si consulta con `git diff`.

**Fast-forward** — Tipo di merge in cui il ramo di destinazione può semplicemente avanzare fino al ramo integrato, senza creare un commit di fusione, perché non è divergente. Produce una storia lineare.

**Fetch** — Operazione (`git fetch`) che scarica dal remote i nuovi commit senza integrarli nel lavoro locale. Aggiorna la conoscenza dello stato remoto senza modificare i propri rami.

**Fork** — Copia personale di un repository altrui sul proprio account (concetto di GitHub), da cui si può proporre modifiche all'originale. Da non confondere con il clone.

**Forward-port** — Riportare su `main` una correzione fatta su un ramo di hotfix, perché il bug corretto in produzione non ricompaia nelle release successive. Nel progetto è obbligatorio.

**Git Bash** — Terminale in stile Unix incluso in Git for Windows, ambiente consigliato per eseguire i comandi Git su Windows.

**Hash (SHA)** — Codice esadecimale che identifica in modo univoco un commit (e ogni oggetto Git). Ne bastano i primi caratteri per riferirsi a un commit senza ambiguità.

**HEAD** — Puntatore che indica dove ti trovi nella storia, di norma sull'ultimo commit del ramo corrente.

**Hotfix** — Correzione urgente di un bug in produzione, sviluppata su un ramo dedicato creato a partire dal tag della versione in esercizio.

**Index (staging area)** — Area intermedia dove si preparano le modifiche che entreranno nel prossimo commit. Ci si aggiunge con `git add`.

**Merge** — Operazione (`git merge`) che unisce le modifiche di un ramo in un altro. Può essere un fast-forward o produrre un merge commit.

**Merge commit** — Commit speciale con due genitori, creato quando si uniscono due rami divergenti, che riconcilia le due storie.

**Origin** — Nome convenzionale del remote principale, quello da cui si è clonato il repository.

**Pull** — Operazione (`git pull`) che scarica dal remote i nuovi commit e li integra subito nel ramo locale. Equivale a un fetch seguito da un'integrazione.

**Pull Request (PR)** — Funzionalità di GitHub con cui si propone di integrare un ramo in un altro, sede della revisione del codice e della discussione. Su altre piattaforme è detta Merge Request.

**Push** — Operazione (`git push`) che invia i commit locali al remote, rendendoli disponibili agli altri.

**Rebase** — Operazione (`git rebase`) che riscrive la storia riappoggiando una serie di commit su una nuova base, per ottenere una storia lineare. Da non usare su commit già condivisi.

**Reflog** — Registro locale di tutte le posizioni assunte da HEAD nel tempo. È la rete di sicurezza che permette di recuperare commit apparentemente persi.

**Remote** — Repository ospitato altrove (tipicamente su GitHub) con cui si sincronizza il proprio. Identificato da un nome (es. `origin`) e da un indirizzo.

**Remote-tracking branch** — Riferimento locale (es. `origin/main`) che rappresenta lo stato di un ramo sul remote all'ultima sincronizzazione.

**Repository (repo)** — Il contenitore del progetto e della sua intera storia, custodita nella sottocartella nascosta `.git`.

**Reset** — Operazione (`git reset`) che sposta indietro l'etichetta di un ramo, con tre modalità (`--soft`, `--mixed`, `--hard`) che differiscono per cosa fanno delle modifiche.

**Revert** — Operazione (`git revert`) che annulla gli effetti di un commit creandone uno nuovo che li inverte, senza riscrivere la storia. È il modo sicuro di annullare un commit già condiviso.

**Squash** — Fusione di più commit in uno solo, tipicamente durante un rebase interattivo o all'integrazione di una Pull Request, per condensare la storia.

**SSH** — Metodo di autenticazione verso il remote basato su una coppia di chiavi crittografiche, una privata e una pubblica.

**Stash** — Area in cui mettere temporaneamente da parte modifiche non committate (`git stash`), per riprenderle in seguito.

**Staging area** — Vedi *Index*.

**Switch** — Comando moderno (`git switch`) per creare rami e spostarsi tra essi, introdotto per rendere più chiaro ciò che prima si faceva con `checkout`.

**Tag** — Etichetta fissa che marca in modo permanente un commit, usata per identificare le versioni rilasciate. Può essere leggero o annotato.

**Tracking branch (upstream)** — Ramo remoto a cui un ramo locale è collegato, così che `push` e `pull` sappiano con chi sincronizzarsi senza indicarlo ogni volta.

**Working directory** — La cartella con i file del progetto così come li vedi e li modifichi, distinta dalla staging area e dal repository.

## Documentazione di riferimento

- Glossario ufficiale di Git (in inglese): https://git-scm.com/docs/gitglossary
- Glossario di GitHub: https://docs.github.com/it/get-started/learning-about-github/github-glossary
