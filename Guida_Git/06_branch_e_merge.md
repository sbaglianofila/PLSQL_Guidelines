# Branch e merge

I branch sono la funzionalità che rende Git così potente per il lavoro di squadra. Un *branch* (ramo) è una linea di sviluppo indipendente: ti permette di lavorare a una modifica isolandoti dal resto, senza disturbare il ramo principale e senza essere disturbato, per poi riunire il tuo lavoro quando è pronto. È attorno ai branch che ruota la strategia di collaborazione del progetto, descritta nella pagina dedicata.

## Cos'è davvero un branch

Tecnicamente un branch è solo un puntatore mobile a un commit. Quando crei un ramo, Git crea una nuova etichetta che punta al commit corrente; man mano che aggiungi commit su quel ramo, l'etichetta avanza. Questo rende i branch estremamente leggeri — crearne uno è istantaneo — e spiega perché in Git è normale crearne e distruggerne di continuo, uno per ogni attività. Il puntatore speciale HEAD indica su quale ramo ti trovi in quel momento.

## Creare e cambiare ramo

Il comando moderno per creare un ramo e spostarcisi è `git switch`. Con l'opzione `-c` (create) crea il ramo e vi si sposta in un colpo solo:

```bash
git switch -c feature/aggiunta-colonna-spedizione
```

Per spostarsi tra rami già esistenti si usa `git switch <nome-ramo>`, e per vedere l'elenco dei rami `git branch`:

```bash
git switch main                 # torna al ramo principale
git branch                      # elenca i rami locali
git branch -a                   # include anche i rami remoti
```

Troverai spesso, nella documentazione e nei progetti più datati, il comando `git checkout` usato per lo stesso scopo (`git checkout -b <nome>` per creare, `git checkout <nome>` per spostarsi). `switch` è la versione più recente e più chiara, introdotta proprio per separare l'operazione di cambio ramo da altri usi di `checkout`; i due sono equivalenti per questo scopo.

### Convenzione dei nomi dei rami

I nomi dei rami dovrebbero comunicare a colpo d'occhio la natura del lavoro. Il progetto usa prefissi coerenti: `feature/` per le nuove funzionalità e le modifiche ordinarie, `hotfix/` per le correzioni urgenti di produzione. Dopo il prefisso, una descrizione breve e in minuscolo, con i trattini al posto degli spazi: `feature/import-ordini`, `hotfix/1.2.1`.

## Unire il lavoro con merge

Quando il lavoro su un ramo è concluso, lo si riunisce nel ramo di destinazione — tipicamente `main` — con un'operazione di *merge*. Ci si sposta prima sul ramo che deve ricevere le modifiche, poi si fondono quelle del ramo di lavoro:

```bash
git switch main
git merge feature/import-ordini
```

### Fast-forward e merge commit

Il merge può avvenire in due modi, a seconda della storia. Se `main` non ha ricevuto nuovi commit da quando hai creato il tuo ramo, Git può semplicemente far avanzare l'etichetta di `main` fino al tuo ultimo commit: è il cosiddetto *fast-forward*, un merge senza cicatrici che produce una storia perfettamente lineare. Se invece `main` è andato avanti nel frattempo, le due linee sono divergenti e Git crea un *merge commit*: un commit speciale con due genitori, che unisce le due storie e le riconcilia. Il merge commit è del tutto normale e registra il momento in cui due linee di sviluppo si sono riunite.

## Cancellare un ramo

Dopo aver integrato un ramo, lo si cancella: ha esaurito il suo scopo e lasciarlo in giro genera solo confusione. Si cancella un ramo locale con:

```bash
git branch -d feature/import-ordini
```

L'opzione `-d` (minuscola) è prudente: Git rifiuta di cancellare un ramo che non è stato ancora integrato, per proteggerti dalla perdita di lavoro. La variante `-D` (maiuscola) forza la cancellazione, e va usata solo quando sei certo di voler buttare via quel lavoro.

## I conflitti

Quando due rami hanno modificato le stesse righe dello stesso file in modi incompatibili, il merge non può decidere da solo quale versione tenere e si ferma segnalando un *conflitto*. Non è un errore né un dramma: è Git che ti chiede di intervenire. La risoluzione dei conflitti è un argomento importante e ha una pagina tutta sua in questa guida.

## Documentazione di riferimento

- I branch in breve (Pro Git): https://git-scm.com/book/it/v2/Diramazioni-in-Git-I-Branch-in-Breve
- Branch e merge, le basi (Pro Git): https://git-scm.com/book/it/v2/Diramazioni-in-Git-Nozioni-Base-su-Diramazione-e-Fusione
- git switch: https://git-scm.com/docs/git-switch
