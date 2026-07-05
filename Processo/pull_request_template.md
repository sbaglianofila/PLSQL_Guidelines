<!--
  Template di Pull Request del progetto.

  Per attivarlo su GitHub, copia questo file in:
      .github/pull_request_template.md
  nella radice del repository dell'applicazione. GitHub lo userà come corpo
  predefinito di ogni nuova Pull Request.

  Le righe tra <!-- --> sono istruzioni per chi compila e non compaiono nel
  testo renderizzato: puoi lasciarle o rimuoverle.
-->

## Descrizione

<!-- Cosa fa questa modifica e, soprattutto, perché. Il "cosa" si legge dal
     codice; qui conta il "perché": il problema risolto, il contesto, le scelte
     fatte e le eventuali alternative scartate. -->



## Tipo di modifica

<!-- Barra ciò che si applica. -->

- [ ] Nuova funzionalità (`feature/*`)
- [ ] Correzione non urgente (`feature/*`)
- [ ] Hotfix di produzione (`hotfix/*` dal tag in esercizio)
- [ ] Refactoring / pulizia, senza cambi di comportamento
- [ ] Documentazione

## Ticket collegato

<!-- Es. "Closes #317" per chiudere automaticamente la issue all'integrazione. -->



## Come verificare

<!-- Come si prova questa modifica: lo script di lancio dei test utPLSQL
     (es. begin ut.run('#APP#:orders'); end;), le precondizioni, i dati di
     prova, e le query di controllo principali da eseguire. Rimanda al test
     book se presente. -->



## Impatto su sorgenti e rilascio

<!-- Segnala migrazioni introdotte, nuovi oggetti, modifiche agli orchestratori
     di install, e se la modifica va inclusa in una release specifica. -->

- [ ] Introduce migrazioni (`.alt` / `.scr`) datate e immutabili
- [ ] Aggiorna gli orchestratori di install
- [ ] Introduce/modifica oggetti esposti (verificato il meccanismo guscio: logica col nome pulito, guscio `_shell` grantato)
- [ ] Nessun impatto sui sorgenti oltre al codice

## Checklist autore (Definition of Done)

<!-- Da spuntare prima di richiedere la revisione. Riprende la Definition of
     Done: una casella non spuntata è un lavoro non concluso. -->

- [ ] Codice conforme a naming, stile, uso del linguaggio e pattern
- [ ] API esposte con meccanismo guscio (logica col nome pulito, guscio `_shell` grantato); commenti dizionario presenti; commenti in inglese
- [ ] Nuovi termini nel glossario; nuovi tipi ricondotti ai domini (o eccezioni documentate)
- [ ] File nelle cartelle corrette con le sotto-estensioni giuste; migrazioni datate
- [ ] Nessun segreto nei sorgenti
- [ ] Test utPLSQL sulla logica (casi limite ed eccezioni inclusi); i test passano
- [ ] Query di controllo prodotte (oggetti, consistenza, funzionale, log), stile "zero righe = ok"
- [ ] Test book compilato

## Note per il revisore

<!-- Punti su cui vuoi attenzione particolare, dubbi aperti, aree delicate. -->


