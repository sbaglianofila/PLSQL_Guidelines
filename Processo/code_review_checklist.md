# Checklist di code review

La revisione del codice è il momento in cui una seconda persona guarda un intervento prima che entri in `main`. Il suo scopo non è cercare colpe, ma alzare la qualità collettiva: intercettare difetti quando costano poco correggerli, diffondere la conoscenza del codice nel team e mantenere l'uniformità che rende l'intero progetto manutenibile. Una buona revisione è un dialogo tra pari con un obiettivo condiviso — codice corretto, sicuro e conforme — non un esame con un giudice e un imputato.

Questa checklist guida il revisore attraverso le aree da controllare. Non tutte le voci si applicano a ogni intervento, e la checklist non sostituisce il giudizio: è un promemoria strutturato perché nulla di importante venga dimenticato. Il revisore la percorre tenendo presente la Definition of Done, di cui la revisione è il presidio.

## Correttezza

La prima domanda è la più semplice e la più importante: il codice fa ciò che deve fare? Si verifica che la logica risolva davvero il problema dichiarato, che i casi limite siano gestiti — il valore nullo, l'insieme vuoto, i confini degli intervalli — e che non ci siano errori evidenti nel flusso. Si controlla che le eccezioni siano gestite in modo appropriato, che non vengano silenziosamente ingoiate, e che il codice non lasci il database in uno stato incoerente in caso di errore.

- [ ] La logica risolve il problema dichiarato nella descrizione.
- [ ] I casi limite (null, vuoto, confini) sono gestiti.
- [ ] Le eccezioni sono gestite correttamente e non nascoste.
- [ ] Non ci sono transazioni lasciate incoerenti in caso di errore.

## Conformità alle convenzioni

Si verifica che il codice rispetti le convenzioni del progetto, perché è l'uniformità a rendere il codice leggibile da chiunque. I nomi seguono le convenzioni di denominazione e usano l'inglese; lo stile di codifica è rispettato; i pattern applicati sono quelli previsti. I nuovi termini di dominio sono nel glossario, i nuovi tipi ricondotti ai domini.

- [ ] Nomi conformi alle convenzioni di denominazione, in inglese.
- [ ] Stile di codifica rispettato.
- [ ] Nuovi termini nel glossario; nuovi tipi ricondotti ai domini o eccezioni documentate.
- [ ] Commenti nel codice in inglese, che spiegano il perché; commenti dizionario su tabelle e colonne.

## Sicurezza

La sicurezza in PL/SQL passa da alcuni controlli precisi. Le funzionalità esposte ai consumatori rispettano il meccanismo guscio: la logica sta negli oggetti col nome pulito (`pkg_*`, viste `_v`) non grantati, e solo i gusci (`pkg_*_shell`, viste `_shell_v`) sono esposti. Lo SQL dinamico, se presente, usa i bind variable e non concatena input nell'istruzione, per non aprire a SQL injection. Nessun segreto compare nel codice. I grant seguono il privilegio minimo.

- [ ] Le API esposte seguono il meccanismo guscio (logica col nome pulito, guscio `_shell` grantato); nulla di sensibile è grantato direttamente.
- [ ] Lo SQL dinamico usa bind variable, senza concatenare input esterni.
- [ ] Nessun segreto (password, token) nel codice o negli script.
- [ ] I grant rispettano il privilegio minimo e vanno ai ruoli corretti.

## Prestazioni

Senza cadere nell'ottimizzazione prematura, si guarda che non ci siano sprechi prevedibili. Le operazioni massive usano i costrutti bulk anziché cicli riga per riga; le query hanno il supporto degli indici dove serve; non ci sono operazioni ripetute inutilmente dentro i cicli. L'attenzione è agli sprechi che emergono quando i volumi crescono, non alla micro-ottimizzazione di ogni istruzione.

- [ ] Le operazioni massive usano costrutti bulk, non cicli riga per riga.
- [ ] Le query hanno il supporto degli indici appropriati.
- [ ] Nessuna operazione costosa ripetuta inutilmente nei cicli.

## Test

Si verifica che la logica introdotta o modificata sia coperta da test utPLSQL sensati — non test che rieseguono l'implementazione, ma test che ne verificano il comportamento atteso, inclusi i casi limite e le eccezioni — e che i test passino. Si controlla che le query di controllo siano presenti e utili, secondo le categorie previste, e che il test book sia compilato.

- [ ] La logica è coperta da test utPLSQL significativi; i test passano.
- [ ] Le query di controllo sono presenti (oggetti, consistenza, funzionale, log) e in stile "zero righe = ok".
- [ ] Il test book è compilato.

## Sorgenti e migrazioni

Si controlla che i file siano collocati correttamente, con le sotto-estensioni giuste, e che la distinzione tra oggetti ripetibili, baseline e migrazioni sia rispettata. Le migrazioni portano la datazione e non modificano file già integrati. Gli orchestratori di install includono i nuovi oggetti nell'ordine corretto.

- [ ] File nelle cartelle corrette con le sotto-estensioni giuste.
- [ ] Ripetibili in file unico; migrazioni datate e non modificate se già integrate.
- [ ] Orchestratori di install aggiornati nell'ordine di dipendenza.

## Leggibilità e manutenibilità

Infine, la domanda che riassume tutte le altre: fra sei mesi, qualcun altro capirà questo codice? Si guarda che i nomi siano parlanti, che le funzioni non siano troppo lunghe o troppo intricate, che l'intento sia chiaro senza bisogno di decifrarlo. Un codice che funziona ma è incomprensibile è un debito che il progetto pagherà; segnalarlo in revisione è parte del lavoro.

- [ ] I nomi sono parlanti e l'intento è chiaro.
- [ ] Le unità di codice hanno dimensione e complessità ragionevoli.
- [ ] Non c'è codice morto, commentato o duplicato senza motivo.

## Come condurre la revisione

Alcune indicazioni sul *come*, oltre al *cosa*. I commenti del revisore sono specifici e costruttivi: indicano il problema e, dove possibile, suggeriscono una direzione. Si distingue ciò che è bloccante — un difetto di correttezza o sicurezza — da ciò che è un suggerimento migliorativo, così che l'autore sappia cosa deve cambiare e cosa può valutare. La revisione è tempestiva: una Pull Request che resta ferma a lungo rallenta tutto il team. E vale il rispetto reciproco: si commenta il codice, non la persona.

## Documentazione di riferimento

- Definition of Done: [definition_of_done.md](definition_of_done.md)
- Template di Pull Request: [pull_request_template.md](pull_request_template.md)
- Pull Request su GitHub: [../Guida_Git/13_pull_request_su_github.md](../Guida_Git/13_pull_request_su_github.md)
