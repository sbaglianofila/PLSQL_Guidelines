# Definition of Done

La Definition of Done è il criterio condiviso che stabilisce quando un intervento — una nuova funzionalità, una correzione, una modifica — può considerarsi *concluso*. Non è un adempimento formale: è il patto che il team fa con sé stesso per evitare che "finito" significhi cose diverse per persone diverse. Un lavoro che soddisfa la Definition of Done è pronto per essere integrato e, a valle, rilasciato, senza sorprese per chi lo manterrà. Un lavoro che non la soddisfa non è finito, per quanto il codice possa sembrare funzionante.

Il principio che tiene insieme tutti i criteri è che un intervento è completo quando poggia su tre gambe: il **codice**, i **test automatici** che ne verificano la logica, e le **query di controllo** con cui l'Application Maintenance ne accerta lo stato in esercizio. Mancando anche una sola delle tre, l'intervento è zoppo: codice senza test è fragile, codice senza query di controllo è cieco in produzione. Le sezioni seguenti dettagliano cosa significa, in concreto, ciascuna gamba, insieme ai criteri di contorno che le rendono davvero utilizzabili.

## Il codice è conforme

Il codice rispetta le convenzioni del progetto senza eccezioni non motivate: le convenzioni di denominazione, lo stile di codifica, l'uso del linguaggio e i pattern definiti nelle guidelines. Gli oggetti che espongono funzionalità ai consumatori seguono il meccanismo guscio, con la logica nei package e nelle viste dal nome pulito (`pkg_*`, `_v`) — mai grantati — e i gusci `_shell` (`pkg_*_shell`, `_shell_v`) come interfaccia esposta e grantata. Ogni nuovo termine di dominio è stato tradotto correttamente e registrato nel glossario; ogni nuovo tipo ricondotto a un dominio, o documentato come eccezione. Le tabelle e le colonne hanno i loro commenti nel dizionario dati, e i commenti nel codice sono in inglese e spiegano il *perché*, non il *cosa*. Ogni nuova tabella di business porta le sette colonne amministrative standard e il trigger `<table>_audit_trg` che le popola, secondo `../Architettura_DB/colonne_amministrative.md`.

## I sorgenti sono a posto

I file sono collocati nelle cartelle corrette dell'alberatura, con le sotto-estensioni giuste, secondo le regole di gestione dei sorgenti. Gli oggetti ripetibili vivono in un unico file per oggetto; le migrazioni portano la datazione `YYYYMMDD_NN` e, una volta integrate, non si toccano più. Gli orchestratori di install sono aggiornati perché i nuovi oggetti vengano eseguiti nell'ordine di dipendenza corretto. Nessun segreto — password, token, stringhe di connessione — compare nei sorgenti, e gli script di provisioning `SYS` usano solo segnaposto.

## La logica è coperta da test utPLSQL

La logica di business introdotta o modificata è coperta da test utPLSQL che la esercitano, inclusi i casi limite e la gestione delle eccezioni, e **i test passano**. I test mirano ai package di implementazione, dove la logica vive. L'esecuzione, allo stato attuale, è manuale: va effettuata prima di proporre l'intervento, e l'esito fa parte di ciò che si dichiara. Un intervento la cui logica non è verificabile perché priva di test non è concluso.

## Le query di controllo esistono

L'intervento è accompagnato dalle query di controllo che ne permettono la verifica in esercizio: quelle che accertano la validità degli oggetti dopo il rilascio, quelle che verificano la consistenza dei dati, quelle che confermano il risultato funzionale sulle tabelle finali e quelle che leggono i log per capire come è andata un'elaborazione. Le query seguono la convenzione per cui *zero righe significa "tutto a posto"*, e sono documentate con scopo ed esito atteso. Sono raccolte nel test book dell'intervento.

## Il test book è compilato

Il test book dell'intervento — nel formato JSON descritto nel pilastro Testing — è compilato con i casi di test, lo script di lancio, le query di controllo e l'esito. È il documento che riunisce in un unico posto tutto ciò che serve a validare l'intervento e a rieseguirne la verifica in futuro.

## La revisione è avvenuta

L'intervento è stato proposto tramite una Pull Request, revisionato da un collega secondo la checklist di code review, approvato e integrato in `main`. Il ramo di lavoro, esaurito il suo scopo, è stato cancellato. La revisione non è un passaggio saltabile: è il momento in cui una seconda persona verifica correttezza e conformità prima che il codice diventi ufficiale.

## Sintesi operativa

I criteri qui sopra si traducono in una lista di controllo che l'autore verifica prima di considerare concluso l'intervento e che il template di Pull Request riprende.

- [ ] Il codice rispetta naming, stile, uso del linguaggio e pattern.
- [ ] Le API esposte seguono il meccanismo guscio (logica col nome pulito, guscio `_shell` grantato); i commenti dizionario ci sono; i commenti nel codice sono in inglese.
- [ ] Nuovi termini nel glossario e nuovi tipi ricondotti ai domini (o eccezioni documentate).
- [ ] Ogni nuova tabella porta le sette colonne amministrative e il trigger `<table>_audit_trg`.
- [ ] File nelle cartelle corrette con le sotto-estensioni giuste; migrazioni datate; orchestratori aggiornati.
- [ ] Nessun segreto nei sorgenti.
- [ ] Test utPLSQL presenti sulla logica, casi limite ed eccezioni inclusi; i test passano.
- [ ] Query di controllo prodotte (oggetti, consistenza, funzionale, log) in stile "zero righe = ok".
- [ ] Test book compilato.
- [ ] Pull Request revisionata, approvata e integrata; ramo cancellato.

## Documentazione di riferimento

- Strategia di test: [../Testing/strategia_test.md](../Testing/strategia_test.md)
- Query di controllo: [../Testing/query_di_controllo.md](../Testing/query_di_controllo.md)
- Test book: [../Testing/test_book.md](../Testing/test_book.md)
- Checklist di code review: [code_review_checklist.md](code_review_checklist.md)
