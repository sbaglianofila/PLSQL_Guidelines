# Query di controllo

Le query di controllo sono interrogazioni di sola lettura che verificano lo stato reale di un sistema: l'esistenza e la validità degli oggetti, la coerenza dei dati, l'esito di un'elaborazione. Sono lo strumento con cui il gruppo di Application Maintenance accerta che una modifica sia sana prima e dopo il rilascio, e con cui in esercizio si diagnostica se qualcosa non ha funzionato. Questo documento definisce cosa sono, in quali categorie si articolano e come vanno scritte, con esempi per ciascuna categoria. Non contiene la libreria completa delle query di un progetto: quelle le produce chi implementa una funzionalità, al termine dello sviluppo, come parte della Definition of Done.

## Perché esistono, accanto ai test utPLSQL

I test utPLSQL e le query di controllo rispondono a domande diverse e complementari, e per questo servono entrambi. I test utPLSQL verificano la **logica** in modo automatico e isolato, in sviluppo e test: costruiscono i propri dati, esercitano il codice e annullano tutto al termine. Non vedono la produzione, e per loro natura non dicono nulla su cosa sta realmente accadendo ai dati di un cliente. Le query di controllo verificano lo **stato reale**: girano sui dati effettivi — anche in produzione — e rispondono a domande come "gli oggetti rilasciati sono tutti validi?", "ci sono ordini senza cliente?", "il batch di stanotte ha scartato righe?". Dove utPLSQL protegge dalla regressione della logica, le query di controllo proteggono dalla deriva dei dati e danno visibilità sull'esercizio.

## Principi di scrittura

Una query di controllo deve rispettare alcune proprietà che ne fanno uno strumento affidabile. È **di sola lettura**: non modifica mai i dati, e va poter essere eseguita dallo schema di sola lettura o dall'AM senza rischi. È **interpretabile senza contesto**: chi la esegue deve capire dall'esito se la situazione è sana o no, senza dover conoscere l'implementazione — per questo è buona norma progettarla in stile *rilevazione di anomalie*, in modo che **zero righe significhi "tutto a posto"** e ogni riga restituita rappresenti un problema da guardare. È **documentata**: porta con sé una descrizione di cosa verifica e di quale sia l'esito atteso. Ed è **deterministica e ripetibile**: due esecuzioni ravvicinate danno lo stesso quadro, a meno che i dati non siano effettivamente cambiati.

La convenzione dell'esito atteso è particolarmente importante perché rende le query automatizzabili e non ambigue. Una query che restituisce le righe *anomale* è immediata da leggere e potrà un domani essere inserita in un controllo automatico; una query che restituisce "tutti i dati" lasciando all'operatore il compito di cercare l'anomalia a occhio è fragile e non scala.

## Le categorie

Le query di controllo si raggruppano in quattro categorie, per scopo. Comprenderle aiuta a coprire un intervento in modo completo: una funzionalità ben verificata ha tipicamente controlli in più di una di esse.

### Verifica degli oggetti

Servono a confermare che un rilascio abbia prodotto la struttura attesa: che gli oggetti esistano, siano validi, e che le migrazioni siano state applicate. Sono le prime da eseguire subito dopo un deploy.

```sql
-- Oggetti non validi nello schema owner: atteso 0 righe
select object_name, object_type, status
  from all_objects
 where owner  = '#APP#'
   and status <> 'VALID'
 order by object_type, object_name;
```

```sql
-- Verifica che una migrazione sia stata applicata (la colonna esiste): atteso 1
select count(*) as column_present
  from all_tab_columns
 where owner       = '#APP#'
   and table_name  = 'ORDERS'
   and column_name = 'SHIPPING_DATE';
```

### Consistenza e integrità dei dati

Verificano che i dati rispettino le regole che li governano — relazioni, unicità, domini, stati — indipendentemente da come ci sono arrivati. Sono utili sia come controllo puntuale dopo un intervento, sia come monitoraggio ricorrente in esercizio.

```sql
-- Ordini senza cliente corrispondente (integrità logica): atteso 0 righe
select o.order_id
  from #APP#.orders o
 where not exists (select 1
                     from #APP#.customers c
                    where c.customer_id = o.customer_id);
```

```sql
-- Chiavi di business duplicate: atteso 0 righe
select customer_code, count(*) as occurrences
  from #APP#.customers
 group by customer_code
having count(*) > 1;
```

```sql
-- Valori fuori dal dominio ammesso: atteso 0 righe
select order_id, status
  from #APP#.orders
 where status not in ('OPEN', 'PROCESSED', 'CANCELLED');
```

### Verifica funzionale sui dati finali

Confermano che un'elaborazione abbia prodotto nelle tabelle finali il risultato atteso: quadrature, conteggi, riconciliazioni tra testata e righe. Sono il controllo che lega l'esito di una procedura al dato che ci si aspettava di trovare.

```sql
-- Quadratura testata/righe: atteso 0 righe (totale testata = somma righe)
select o.order_id, o.total_amount, sum(l.line_amount) as lines_total
  from #APP#.orders o
  join #APP#.order_lines l on l.order_id = o.order_id
 group by o.order_id, o.total_amount
having o.total_amount <> sum(l.line_amount);
```

### Lettura dei log in produzione

Interrogano le tabelle di log e di errore — i prefissi `log_` ed `err_` delle convenzioni di denominazione — per capire *come è andata* un'elaborazione: quali errori ha registrato, quante righe ha scartato, quanto è durata, con quale esito. Sono lo strumento con cui, in esercizio, si ricostruisce il comportamento di un processo senza doverlo rieseguire.

```sql
-- Errori registrati oggi da un processo: atteso 0 righe se il run è pulito
select logged_at, error_code, error_message
  from #APP#.log_errors
 where process_name = 'ORDER_IMPORT'
   and logged_at   >= trunc(sysdate)
 order by logged_at desc;
```

```sql
-- Righe scartate da un batch, raggruppate per motivo
select reason, count(*) as rows_rejected
  from #APP#.err_import_rows
 where batch_id = :batch_id
 group by reason
 order by rows_rejected desc;
```

```sql
-- Esito e durata degli ultimi run di un processo
select process_name
     , started_at
     , ended_at
     , (ended_at - started_at) day to second as duration
     , status
     , rows_processed
  from #APP#.log_process_runs
 where process_name = 'ORDER_IMPORT'
 order by started_at desc
 fetch first 10 rows only;
```

## Convenzioni, collocazione e responsabilità

Ogni query di controllo va corredata di un'intestazione che ne dichiari lo scopo e l'esito atteso, nella stessa forma degli esempi qui sopra: una riga che dice cosa verifica e cosa significa il risultato. Questa disciplina è ciò che permette a un operatore dell'AM di eseguire la query mesi dopo, in un contesto diverso, e capirne immediatamente il senso.

Le query di controllo di un intervento vengono raccolte nel **test book** della funzionalità, insieme ai casi di test e allo script di lancio, così che chi valida o chi mantiene abbia in un unico posto tutto ciò che serve a verificare. La produzione di queste query è responsabilità di chi implementa la funzionalità, e avviene **al termine dello sviluppo**: una funzionalità non è completa finché non è accompagnata dalle query che ne permettono la verifica. In questo senso le query di controllo sono, insieme al codice e ai test utPLSQL, uno dei tre elementi che concorrono alla Definition of Done.
