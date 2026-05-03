# Stile di scrittura per documenti tecnici

## Principio generale

I documenti tecnici devono essere chiari, precisi e sufficientemente approfonditi. L'obiettivo è che il lettore capisca non solo *cosa* fare o *come* funziona qualcosa, ma anche *perché* — il ragionamento sottostante, i casi limite, le implicazioni pratiche. La superficialità è un difetto: un documento tecnico che si limita a elencare passaggi senza spiegarli non è utile.

---

## Struttura del testo

### Il corpo del testo è prosa

La forma principale di comunicazione è il paragrafo discorsivo. Ogni sezione deve essere sviluppata in forma narrativa, con frasi complete che guidino il lettore attraverso il ragionamento. Si spiega, si argomenta, si contestualizza.

Non si scrive mai in stile telegrafico. Non si frammentano le informazioni in punti elenco quando sarebbe possibile — e più efficace — spiegarle in modo fluido.

### Elenchi puntati e numerati

Gli elenchi si usano come *complemento* alla spiegazione, non come sostituto. Sono appropriati nei seguenti casi:

- enumerare elementi omogenei che non hanno una relazione causale tra loro (ad esempio: una lista di prerequisiti, una serie di opzioni configurabili);
- riassumere passaggi sequenziali quando l'ordine è rilevante e i passi sono già stati descritti nel testo;
- mettere in evidenza elementi che altrimenti andrebbero persi in un paragrafo lungo.

Un elenco puntato non deve mai essere usato per sostituire una spiegazione. Se ogni punto richiede più di una riga di contesto per essere compreso, quei punti appartengono al corpo del testo, non a un elenco.

### Tabelle

Le tabelle sono uno strumento per confrontare o strutturare dati omogenei: parametri di configurazione, confronti tra opzioni, valori di riferimento. Sono utili quando il lettore ha bisogno di consultare l'informazione in modo rapido, non di leggerla in sequenza.

Anche in questo caso, la tabella integra la spiegazione. Non si usa una tabella per evitare di scrivere.

---

## Profondità e dettaglio

I documenti devono entrare nel merito. Questo significa:

- spiegare le scelte architetturali o di design, non solo il risultato finale;
- descrivere il comportamento atteso nei casi normali *e* in quelli anomali o limite;
- indicare le dipendenze, i presupposti, i vincoli rilevanti;
- chiarire cosa succede se qualcosa va storto e come diagnosticarlo.

Se un concetto è complesso, va scomposto e spiegato gradualmente, non accennato e rimandato al lettore.

---

## Tono e registro

Il tono è tecnico ma non arido. Si scrive in modo diretto, senza essere freddi. Si può usare la seconda persona ("quando configuri il servizio…") per rendere il testo più immediato, oppure la forma impersonale, a seconda del contesto. L'importante è che il registro sia coerente all'interno dello stesso documento.

Si evita:

- il linguaggio burocratico e le perifrasi inutili;
- le formule vaghe come "in genere", "solitamente", "potrebbe" quando è possibile essere precisi;
- l'abuso di maiuscole, grassetti e corsivi come sostituto della chiarezza argomentativa.

Il grassetto si usa con parsimonia, solo per termini tecnici alla prima occorrenza o per avvertenze importanti. Il corsivo si usa per termini stranieri o enfasi rarissime.

---

## Lunghezza

Un documento tecnico deve essere lungo quanto serve, non di più e non di meno. Non si taglia per brevità quando il dettaglio è necessario. Non si aggiunge materiale per fare volume.

Se una sezione può essere omessa senza perdere informazioni utili al lettore, va omessa.

---

## Esempio di approccio sbagliato vs. corretto

**Sbagliato** — stile puramente a elenchi, senza spiegazione:

> Configurazione del timeout:
> - Valore predefinito: 30s
> - Modificabile tramite env var
> - Impatta le connessioni in entrata

**Corretto** — spiegazione discorsiva con elenco di supporto:

> Il timeout di connessione controlla per quanto tempo il servizio attende una risposta prima di considerare la richiesta fallita. Il valore predefinito è 30 secondi, scelto come compromesso tra reattività e tolleranza a latenze temporanee di rete. In ambienti con latenza elevata o dietro proxy lenti, potrebbe essere necessario aumentarlo tramite la variabile d'ambiente `CONNECTION_TIMEOUT` (il valore si esprime in millisecondi).
>
> È importante tenere presente che questo timeout si applica alle connessioni in entrata: un valore troppo basso causerà il rifiuto di richieste legittime in momenti di carico, mentre un valore troppo alto può mascherare problemi di rete reali e ritardare il rilevamento dei guasti.

