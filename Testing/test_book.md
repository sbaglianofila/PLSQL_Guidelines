# Test book

Il test book è l'artefatto che raccoglie, per una funzionalità o una release, tutto ciò che serve a verificarla: i casi di test, lo script con cui si lanciano i test automatici, le query di controllo e l'esito. L'idea portante è avere **una sola sorgente in formato JSON** — versionabile, strutturata, generabile e trasformabile da un programma — da cui produrre automaticamente due output derivati: un **documento** leggibile per la consegna e la lettura, e un **foglio Excel** operativo per la compilazione e il tracciamento degli esiti. Questo documento definisce lo scopo del test book, la struttura del JSON e come da esso si generano gli output.

## Perché una sorgente JSON

Tenere il test book in un documento o in un Excel scritti a mano ha due difetti: il contenuto non è riutilizzabile da un programma, e le due forme — quella leggibile e quella operativa — divergono appena una delle due viene aggiornata. Adottare il JSON come sorgente unica risolve entrambi i problemi. Il JSON è la fonte di verità: lo si versiona insieme al codice, lo si può generare o pre-compilare automaticamente (ad esempio elencando i test utPLSQL esistenti), e da esso un generatore produce sia il documento sia l'Excel, che restano così sempre allineati. Se un domani serve un terzo formato — una pagina web, un report per un cruscotto — basta aggiungere una trasformazione, senza toccare la sorgente.

## Struttura del JSON

Il test book è un oggetto JSON con una sezione di metadati, una sezione di lancio, l'elenco dei casi di test, l'elenco delle query di controllo e un blocco di sign-off finale. Un esempio completo e compilabile è disponibile in `test_book.example.json`; qui se ne descrivono i campi e il significato.

La sezione **metadata** identifica il test book: l'identificativo, il titolo, il progetto (`#APP#`), la release di riferimento, il collegamento all'intervento (Pull Request o ticket), l'autore, la data e l'ambiente su cui si esegue la verifica. Serve a collocare il test book nel tempo e nel contesto, ed è ciò che finisce nell'intestazione del documento generato e nel foglio di riepilogo dell'Excel.

La sezione **launch** contiene lo **script di lancio** dei test automatici e le condizioni per eseguirlo: i prerequisiti (ad esempio la presenza di utPLSQL sull'ambiente), il comando vero e proprio — tipicamente una chiamata a `ut.run` su un ramo del suitepath — e le note operative. Incorporare lo script nel test book significa che chi riceve il documento o l'Excel ha sotto mano esattamente come rieseguire la verifica, senza doverlo cercare altrove.

L'array **test_cases** elenca i casi di test. Ogni caso ha un identificativo, un titolo, un tipo, le precondizioni, i passi, il risultato atteso, il risultato effettivo, lo stato e note. Il campo `type` distingue la natura del caso: `utplsql` per i test automatici (con `reference` che punta alla suite e alla procedura), `manual` per le verifiche eseguite a mano, `control_query` per i casi che consistono nell'eseguire una query di controllo. Lo stato assume i valori `not_run`, `pass`, `fail`, `blocked`, e parte da `not_run` nella sorgente per essere compilato durante l'esecuzione.

L'array **control_queries** raccoglie le query di controllo dell'intervento, secondo le categorie definite in `query_di_controllo.md`. Ogni voce ha un identificativo, la categoria (`object_verification`, `data_consistency`, `functional_data`, `log_reading`), una descrizione, il testo SQL, il risultato atteso — di norma "0 righe" secondo la convenzione di rilevazione delle anomalie — il risultato effettivo, lo stato e note. È qui che confluiscono le query prodotte da chi implementa la funzionalità.

Il blocco **sign_off** chiude il test book con l'esito complessivo: chi ha eseguito la verifica, la data e il risultato finale (`pending`, `passed`, `failed`). È la firma che attesta che la verifica è stata svolta e con quale conclusione.

### Riepilogo dei campi

| Sezione | Campo | Significato |
|---|---|---|
| metadata | `id`, `title`, `project`, `release`, `reference`, `author`, `created_at`, `environment` | Identificazione e contesto del test book |
| launch | `prerequisites`, `script`, `notes` | Come lanciare i test automatici |
| test_cases[] | `id`, `title`, `type`, `reference`, `preconditions`, `steps`, `expected_result`, `actual_result`, `status`, `notes` | Un caso di test |
| control_queries[] | `id`, `category`, `description`, `sql`, `expected_result`, `actual_result`, `status`, `notes` | Una query di controllo |
| sign_off | `tester`, `date`, `outcome` | Esito complessivo della verifica |

## Dagli output: documento ed Excel

Dal JSON un generatore produce i due formati derivati, ciascuno pensato per un uso diverso.

Il **documento** è la forma leggibile, adatta alla consegna e alla revisione. È strutturato in sezioni che rispecchiano il JSON: un'intestazione con i metadati, una sezione "Come eseguire" che riporta prerequisiti e script di lancio, una tabella dei casi di test con precondizioni, passi ed esito atteso, una sezione delle query di controllo che mostra per ciascuna la descrizione, il testo SQL e il risultato atteso, e infine il sign-off. È il documento che un revisore legge per capire cosa è stato verificato e come.

Il **foglio Excel** è la forma operativa, adatta alla compilazione durante l'esecuzione. Ha un foglio di riepilogo con i metadati e il conteggio degli esiti, un foglio "Test Cases" e un foglio "Control Queries" in cui ogni riga è un caso o una query e le colonne rispecchiano i campi, con le colonne di risultato effettivo e stato pronte da compilare. È lo strumento con cui chi esegue la verifica registra man mano gli esiti.

La corrispondenza tra i campi del JSON e le colonne dell'Excel è diretta e uno-a-uno, così che l'Excel compilato possa in prospettiva essere ri-letto e reintegrato nel JSON, chiudendo il ciclo.

## Il generatore

Il generatore è il programma che legge il test book JSON e produce documento ed Excel. Definire adesso lo schema del JSON — cioè il contratto — è ciò che permette di scrivere il generatore in modo indipendente e di cambiarlo senza toccare le sorgenti dei test book. Il generatore non è ancora stato realizzato: è un deliverable pianificato, tracciato in `STATUS.md`. Una collocazione naturale è tra gli strumenti di sviluppo — potenzialmente nello schema di tooling `#APP#_GEN`, se realizzato in PL/SQL, oppure come programma esterno — purché rispetti il contratto qui definito. Finché il generatore non esiste, il JSON resta comunque la sorgente autorevole e leggibile del test book, e gli output si possono produrre manualmente a partire da esso.

## Ciclo di vita

Il test book nasce quando nasce la funzionalità e la accompagna fino alla verifica. La sorgente JSON si crea al termine dello sviluppo — eventualmente pre-compilata elencando le suite utPLSQL già scritte — e vi si aggiungono le query di controllo prodotte da chi ha implementato. In fase di test si compilano i risultati effettivi e gli stati, e si chiude il sign-off con l'esito. Il test book così completato è parte della documentazione dell'intervento e concorre, insieme al codice e ai test, a soddisfare la Definition of Done.
