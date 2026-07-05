# Strategia di test

La strategia di test del framework poggia su due livelli complementari, pensati per rispondere a domande diverse e per coprire, insieme, l'intero arco di vita di una modifica: dalla logica scritta in sviluppo fino al comportamento osservato in produzione. Nessuno dei due livelli da solo è sufficiente, ed è la loro combinazione a costituire una verifica completa. Questo documento fa da cappello: definisce i due livelli, spiega perché servono entrambi e rimanda ai documenti operativi che li dettagliano.

## I due livelli

Il primo livello è il **testing automatico della logica** con utPLSQL. Sono unit test che esercitano il codice — in particolare i package di logica col nome pulito (`pkg_orders`), dove vive la logica — in modo isolato e ripetibile, negli ambienti di sviluppo e test. Verificano che una funzione calcoli il valore giusto, che un caso limite sia gestito, che l'eccezione attesa venga sollevata. Sono automatici, deterministici e annullano da sé le proprie modifiche, così da poter essere rieseguiti a ogni cambiamento come rete di protezione contro le regressioni. Il loro dettaglio operativo — come si scrivono, si organizzano e si eseguono — è in `utplsql.md`.

Il secondo livello sono le **query di controllo** per l'Application Maintenance. Sono interrogazioni di sola lettura che verificano lo stato reale del sistema: la validità degli oggetti dopo un rilascio, la coerenza dei dati, l'esito di un'elaborazione letto dai log in esercizio. A differenza dei test utPLSQL, girano sui dati effettivi, anche in produzione, e rispondono non alla domanda "la logica è corretta?" ma alla domanda "cosa sta realmente accadendo ai dati?". Le loro categorie ed esempi sono in `query_di_controllo.md`.

## Perché servono entrambi

I due livelli coprono zone che non si sovrappongono. utPLSQL vive in un mondo controllato: costruisce i propri dati, non conosce la produzione e non può dire nulla su un cliente reale. Le query di controllo vivono nel mondo reale: vedono i dati veri ma non esercitano la logica in isolamento, e non prevengono una regressione prima del rilascio. Un difetto di calcolo si intercetta con utPLSQL prima del merge; un dato incoerente prodotto da un'elaborazione notturna si scopre con una query di controllo il mattino dopo. Affidarsi a uno solo dei due lascia scoperta metà del rischio.

## Il test book

Il piano e l'esito dei test di un intervento sono raccolti in un **test book**: un artefatto strutturato che, per una funzionalità o una release, elenca i casi di test, lo script di lancio, le query di controllo e i risultati. Il test book ha una sorgente unica in formato JSON, da cui si generano automaticamente un documento leggibile e un foglio Excel operativo. Formato e generazione sono descritti in `test_book.md`. Questo tiene insieme, in un unico posto e in una forma sia leggibile sia automatizzabile, tutto ciò che serve a validare un intervento e a rieseguirne la verifica in futuro.

## Esecuzione e integrazione nel processo

Allo stato attuale l'esecuzione dei test utPLSQL è **manuale**: va fatta abitualmente prima di aprire una Pull Request, con gli strumenti descritti in `utplsql.md`. L'introduzione di una pipeline di integrazione continua che li esegua automaticamente sulle Pull Request è un'evoluzione prevista ma non ancora adottata, coerente con la natura di progetto a linea singola.

I tre elementi — codice, test utPLSQL e query di controllo — concorrono insieme a considerare completo un intervento. La Definition of Done, definita nel pilastro Processo, formalizza questo criterio: una funzionalità è conclusa quando la sua logica è coperta da test che passano e quando è accompagnata dalle query di controllo che ne permettono la verifica in esercizio.
