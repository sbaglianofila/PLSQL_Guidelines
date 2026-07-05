# Le tabelle di lookup

Molte applicazioni hanno bisogno di decine di piccole liste di valori: i tipi di contatto, i livelli di priorità, i metodi di pagamento, i titoli con cui ci si rivolge a una persona. Sono dati di riferimento — non dati di business veri e propri, ma nemmeno configurazione che regola il comportamento del programma — che compaiono nelle tendine, popolano i menu a discesa e vincolano i valori ammessi di certe colonne. Questo documento definisce il meccanismo con cui il framework gestisce queste liste: una coppia di tabelle generiche, testata e dettaglio, che evita di creare una tabellina dedicata per ogni singola lista, e le regole per decidere quando invece una lista *merita* la sua tabella dedicata.

## Tre cose distinte da non confondere

Prima di descrivere il meccanismo conviene collocarlo rispetto a due concetti vicini, con cui è facile confonderlo.

Le lookup non sono **configurazione**. La configurazione — soglie, flag di comportamento, endpoint, parametri che la logica legge per decidere *come* comportarsi — ha già il suo meccanismo dedicato nel framework: la tabella `cfg_parameters` con il package `lib_config`. La distinzione, ripresa dalle convenzioni di denominazione (`cfg_` contro `ref_`), è di sostanza: una lookup è un *valore di dominio* referenziato dai dati e mostrato all'utente, un parametro di configurazione è una *leva di comportamento* letta dalla logica. Tenerli separati significa non mescolare due cicli di vita e due modalità d'accesso diverse.

Le lookup gestite qui non sono nemmeno **tutte** le tabelle di decodifica. Alcune liste di riferimento hanno attributi propri, relazioni proprie o vengono referenziate così pesantemente da meritare una tabella `ref_` dedicata con una foreign key tipizzata. Il meccanismo generico serve alle liste *piatte*; quelle strutturate restano fuori. La regola per distinguerle è il cuore di questo documento ed è descritta subito sotto.

Infine, gli **stati** che guidano un workflow — lo stato di un ordine, di una pratica, di un documento — non sono lookup, anche se a prima vista somigliano a una lista di valori. Uno stato è un nodo di una macchina a stati, con transizioni ammesse e un audit dei cambiamenti, e vive in un pillar dedicato descritto in `stati_workflow.md`. Qui basti sapere che una lista di stati *non* va messa nelle tabelle di lookup.

## La regola di promozione: generica o dedicata

Una lista di valori vive nelle tabelle di lookup generiche finché di ogni valore si sa soltanto un codice, un'etichetta, un ordinamento e un paio di flag. Nel momento in cui la lista cresce colonne proprie, relazioni proprie, o ha bisogno che le tabelle di business la referenzino con una foreign key tipizzata e pulita, "promuove" a tabella `ref_` dedicata. È una regola di buon senso, ma ha una ragione tecnica precisa che vedremo parlando di integrità referenziale: la tabella generica è debole proprio sulle foreign key, e questo è ciò che fa graduare le liste molto referenziate.

Restano quindi nelle lookup generiche i tipi di contatto, i livelli di priorità, i titoli, il sesso, i sì/no strutturati, i tipi di documento, i metodi di pagamento semplici — liste piccole, piatte, numerose, dove creare una tabella per ciascuna sarebbe sproliferazione inutile. Vanno invece tenute dedicate le liste con attributi propri o molto referenziate: i paesi (`ref_countries`, con codici ISO, prefisso telefonico, valuta), le valute (`ref_currencies`, con numero di decimali e simbolo), le lingue e i locali, le province e le regioni (gerarchiche e numerose), e le festività (`ref_holidays`, che il framework ha già introdotto con `lib_calendar`). E, come detto, gli stati dei workflow, che hanno un pillar tutto loro.

## Esempi di set comuni

Per dare concretezza, la tabella seguente elenca i set che ricorrono più spesso nelle applicazioni gestionali e che sono buoni candidati per le lookup generiche. I codici sono indicativi: ogni progetto adatta i propri, registrando nel glossario le eventuali abbreviazioni. La colonna dei valori tipici è illustrativa, non esaustiva.

| Set (`lookup_code`) | Cosa contiene | Valori tipici |
|---|---|---|
| `CONTACT_TYPE` | Canali di contatto | `EMAIL`, `PHONE`, `MOBILE`, `FAX`, `PEC` |
| `ADDRESS_TYPE` | Tipi di indirizzo | `RESIDENCE`, `DOMICILE`, `SHIPPING`, `BILLING` |
| `SALUTATION` | Appellativi | `MR`, `MRS`, `MS`, `DR`, `PROF` |
| `GENDER` | Sesso | `M`, `F`, `X` |
| `MARITAL_STATUS` | Stato civile | `SINGLE`, `MARRIED`, `DIVORCED`, `WIDOWED` |
| `PRIORITY` | Livelli di priorità | `LOW`, `MEDIUM`, `HIGH`, `URGENT` |
| `PAYMENT_METHOD` | Metodi di pagamento | `TRANSFER`, `CARD`, `CASH`, `SEPA` |
| `DOCUMENT_TYPE` | Tipi di documento | `INVOICE`, `ORDER`, `DDT`, `CONTRACT` |
| `ID_DOCUMENT_TYPE` | Documenti di identità | `ID_CARD`, `PASSPORT`, `DRIVING_LICENSE` |
| `CUSTOMER_TYPE` | Tipologia cliente | `INDIVIDUAL`, `COMPANY`, `PA` |
| `LEGAL_FORM` | Forma giuridica | `SRL`, `SPA`, `SNC`, `SOLE_PROP` |
| `NOTIFICATION_CHANNEL` | Canali di notifica | `EMAIL`, `SMS`, `PUSH` |
| `FREQUENCY` | Frequenze | `DAILY`, `WEEKLY`, `MONTHLY`, `YEARLY` |
| `CHANNEL` | Canale operativo | `WEB`, `MOBILE`, `BRANCH`, `CALL_CENTER` |
| `UNIT_OF_MEASURE` | Unità di misura semplici | `PCS`, `KG`, `L`, `M`, `H` |

Questi set mostrano bene anche l'uso degli slot tipizzati del dettaglio. `PRIORITY` può portare in `num_value` il peso numerico con cui ordinare o confrontare le priorità (`LOW` = 10, `URGENT` = 40), rendendo l'ordinamento un dato invece che una regola cablata. `CONTACT_TYPE` può usare `char_value` per il nome dell'icona o della classe CSS da mostrare accanto a ciascun canale. Sono proprio i casi per cui gli slot esistono: una proprietà scalare per valore, senza scomodare una tabella dedicata.

Due voci dell'elenco sono al confine e vale la pena notarle, perché illustrano la regola di promozione all'opera. `UNIT_OF_MEASURE` va bene come lookup finché serve solo l'elenco delle unità; nel momento in cui l'applicazione deve *convertire* tra unità (chili in quintali, litri in metri cubi) servono fattori di conversione e relazioni tra unità, e la lista promuove a tabella dedicata. Allo stesso modo `LEGAL_FORM` resta una lookup se è solo un'etichetta, ma se dovesse pilotare regole fiscali o civilistiche diverse per forma giuridica, quelle regole spingono verso una struttura propria.

## La testata: `ref_lookups`

La testata contiene una riga per ciascuna lista — un *set di codici*. La sua chiave primaria è naturale, il codice mnemonico del set (`lookup_code`), e non un surrogato: è una tabella minuscola e stabile, dove un identificativo surrogato non aggiungerebbe nulla e toglierebbe leggibilità. Questa scelta, come si vedrà, è anche ciò che rende accettabile la foreign key composita verso il dettaglio, perché la costante che vi comparirà sarà il codice leggibile del set e non un numero opaco.

| Colonna | Tipo | Scopo |
|---|---|---|
| `lookup_code` | `varchar2(32 char)` | Chiave primaria: mnemonico del set, usato nel codice (`'CONTACT_TYPE'`) |
| `name` | `varchar2(128 char)` | Etichetta leggibile del set |
| `description` | `varchar2(512 char)` | A cosa serve la lista |
| `is_system` | `varchar2(1 char)` (`flag`) | Set di proprietà del framework/applicazione, non modificabile dagli amministratori funzionali |
| `allow_custom_values` | `varchar2(1 char)` (`flag`) | Se gli amministratori funzionali possono aggiungere valori al set |

Oltre a queste, la testata porta le sette colonne amministrative standard con il relativo trigger, come ogni tabella (`colonne_amministrative.md`).

I due flag di governance meritano una parola. `is_system` distingue i set che la logica applicativa dà per scontati — quelli dove il codice contiene, ad esempio, un `case` su valori attesi — dai set che gli utenti possono davvero gestire. Aggiungere un valore a mano a un set di sistema romperebbe il codice che non lo conosce, e il flag serve proprio a impedirlo dall'interfaccia di amministrazione. `allow_custom_values` è più fine: anche in un set non di sistema, si può voler bloccare l'aggiunta di nuovi valori dopo un certo punto, pur permettendo di modificare quelli esistenti.

```sql
create table ref_lookups
   ( lookup_code          varchar2(32 char)   constraint ref_lookups_pk primary key
   , name                 varchar2(128 char)  constraint ref_lookups_nn_name not null
   , description          varchar2(512 char)
   , is_system            varchar2(1 char)    default 'N' constraint ref_lookups_nn_is_system not null
   , allow_custom_values  varchar2(1 char)    default 'Y' constraint ref_lookups_nn_allow_custom not null
   , constraint ref_lookups_ck_is_system   check (is_system in ('Y','N'))
   , constraint ref_lookups_ck_allow_custom check (allow_custom_values in ('Y','N'))
   -- + colonne amministrative (vedi colonne_amministrative.md)
   );
```

## Il dettaglio: `ref_lookup_values`

Il dettaglio contiene una riga per ciascun valore di ciascun set. Qui, oltre all'anagrafica minima del valore, stanno gli slot per le proprietà che un valore può portare con sé.

| Colonna | Tipo | Scopo |
|---|---|---|
| `value_id` | `number(12)` (`id_medium`) | Chiave primaria surrogata |
| `lookup_code` | `varchar2(32 char)` | Foreign key verso `ref_lookups` |
| `value_code` | `varchar2(32 char)` | Il codice memorizzato e referenziato dai dati (`'MOBILE'`) |
| `label` | `varchar2(128 char)` | Testo mostrato a video |
| `description` | `varchar2(512 char)` | Spiegazione estesa del valore |
| `sort_order` | `number` | Ordine di presentazione nelle tendine |
| `is_valid` | `varchar2(1 char)` (`flag`) | Se il valore è attualmente selezionabile o è stato ritirato |
| `is_default` | `varchar2(1 char)` (`flag`) | Se è il valore predefinito del set |
| `num_value` | `number` | Proprietà numerica associata al valore |
| `char_value` | `varchar2(256 char)` | Proprietà testuale associata al valore |
| `date_value` | `date` | Proprietà di tipo data associata al valore |

con l'unicità della coppia `(lookup_code, value_code)` e, come per la testata, le sette colonne amministrative.

La distinzione tra `value_code` e `value_id` è deliberata. `value_code` è ciò che le tabelle di business memorizzano e ciò che l'utente riconosce; `value_id` è un identificativo surrogato interno, comodo come chiave stabile della riga e come bersaglio di eventuali riferimenti tecnici, ma non è il codice che gira nei dati. I riferimenti dalle tabelle di business, come si vede più avanti, passano per la coppia leggibile `(lookup_code, value_code)`, non per il surrogato.

Il flag `is_valid` risolve un problema pratico ricorrente: un valore che non deve più essere proposto ma che non si può cancellare, perché righe storiche lo referenziano ancora. Invece di eliminarlo — rompendo l'integrità dei dati passati — lo si marca non valido: sparisce dalle tendine ma resta un codice legittimo per i record che lo portano. `is_default` marca il valore preselezionato del set, evitando di cablare questa scelta nell'applicazione.

I tre slot tipizzati — `num_value`, `char_value`, `date_value` — sono la risposta misurata al bisogno di attaccare "qualche proprietà" a un valore. Si è scelto deliberatamente di *non* usare colonne generiche numerate (`attr1`, `attr2`, …), illeggibili e prive di tipo, né una tabella figlia chiave-valore, scomoda da interrogare e validare. Tre slot ben tipizzati coprono la stragrande maggioranza dei casi reali — una soglia numerica legata al codice, un colore o una classe CSS, una data di riferimento — restando interrogabili e vincolabili. Il prezzo di questa scelta è la sua rigidità: se un valore dovesse portare più di una proprietà per tipo, o proprietà strutturate, quello è il segnale che la lista sta chiedendo di promuovere a tabella dedicata, dove le proprietà diventano colonne vere.

```sql
create table ref_lookup_values
   ( value_id     number(12)          constraint ref_lookup_values_pk primary key
   , lookup_code  varchar2(32 char)   constraint ref_lookup_values_nn_lookup not null
   , value_code   varchar2(32 char)   constraint ref_lookup_values_nn_value  not null
   , label        varchar2(128 char)  constraint ref_lookup_values_nn_label  not null
   , description  varchar2(512 char)
   , sort_order   number              default 0   constraint ref_lookup_values_nn_sort  not null
   , is_valid     varchar2(1 char)    default 'Y' constraint ref_lookup_values_nn_valid not null
   , is_default   varchar2(1 char)    default 'N' constraint ref_lookup_values_nn_deflt not null
   , num_value    number
   , char_value   varchar2(256 char)
   , date_value   date
   , constraint ref_lookup_values_fk_lookup foreign key (lookup_code)
        references ref_lookups (lookup_code)
   , constraint ref_lookup_values_uk_code   unique (lookup_code, value_code)
   , constraint ref_lookup_values_ck_valid  check (is_valid   in ('Y','N'))
   , constraint ref_lookup_values_ck_deflt  check (is_default in ('Y','N'))
   -- + colonne amministrative (vedi colonne_amministrative.md)
   );
```

## L'integrità referenziale: la foreign key composita con costante

Questo è il punto in cui la tabella generica mostra il suo limite, e va spiegato con onestà perché è la ragione tecnica della regola di promozione. Con una tabella di lookup *dedicata* garantire che una colonna di business contenga solo valori validi è banale: una foreign key tipizzata verso quella tabella. Con la tabella generica no, perché la colonna di business contiene solo il `value_code` (`'MOBILE'`), non la coppia `(lookup_code, value_code)` che identifica univocamente il valore nel dettaglio generico.

La soluzione, dove l'integrità dichiarativa conta davvero, è aggiungere alla tabella di business una **colonna virtuale** che vale la costante del set, e definire la foreign key sulla coppia. La colonna virtuale non occupa spazio, è calcolata e sempre uguale, e rende la foreign key auto-documentante:

```sql
  contact_type       varchar2(32 char)
, contact_type_lkp   varchar2(32 char) generated always as ('CONTACT_TYPE') virtual
, constraint persons_fk_contact_type
     foreign key (contact_type_lkp, contact_type)
     references ref_lookup_values (lookup_code, value_code)
```

Si legge "questa colonna referenzia il set `CONTACT_TYPE`", ed è qui che la scelta di dare a `ref_lookups` una chiave primaria naturale ripaga: la costante nella colonna virtuale è il codice leggibile del set, non un numero surrogato opaco che sarebbe stato una mina per chi legge la tabella mesi dopo. La foreign key punta all'unicità `(lookup_code, value_code)` del dettaglio, non alla sua chiave primaria surrogata, e questo è pienamente lecito in Oracle: una foreign key può referenziare qualunque chiave unica.

Questo meccanismo si applica **solo dove l'integrità conta davvero**. Dove non è critico, la validazione del valore avviene nella Table API in fase di scrittura, senza vincolo dichiarativo. La foreign key composita è uno strumento opt-in, riferimento per riferimento, non un obbligo su ogni colonna che pesca da una lookup. Va infine verificato in fase di compilazione sull'istanza che la foreign key su colonna virtuale sia accettata nella configurazione target: è una costruzione supportata da Oracle, ma il codice del framework non è ancora stato compilato su un database e questa è una delle cose da confermare.

## L'accesso in lettura

Perché le `select` sulle lookup non si sparpaglino in tutto il codice, il meccanismo ha bisogno di un'API di lettura, un package di base — chiamiamolo `lib_lookup` — gemello di `lib_config` sul versante dei dati di riferimento. Esporrebbe le operazioni ricorrenti: l'elenco ordinato dei valori validi di un set (`values_of`), l'etichetta di un valore dato il suo codice (`label_of`), la verifica che un codice appartenga a un set (`is_valid`), il valore predefinito di un set (`default_of`). Come `lib_config`, terrebbe in cache i set letti, dato che le lookup cambiano di rado ed è uno spreco rileggerle a ogni chiamata. Questo package è il naturale complemento del meccanismo e va aggiunto al catalogo dei pacchetti base; la sua realizzazione seguirà la definizione delle tabelle.

## Le colonne amministrative

Sia la testata che il dettaglio portano le sette colonne amministrative standard e il rispettivo trigger di audit. Non è un automatismo cieco: chi ha aggiunto un valore a una lookup, chi ne ha ritirato un altro e quando, è esattamente il tipo di tracciamento che qui serve, perché le lookup sono spesso manutenute a mano dagli amministratori funzionali e un cambiamento silenzioso a un set può avere effetti sull'intera applicazione.

## Improvement disponibili con Oracle 23ai

Il meccanismo è pensato per la baseline 19c e non richiede nulla oltre a essa. Su Oracle 23ai due funzionalità offrirebbero varianti opzionali. La prima è il tipo `boolean` nativo per le colonne di tabella, che sostituirebbe i flag `varchar2(1)` con `'Y'/'N'` di `is_system`, `allow_custom_values`, `is_valid` e `is_default`. La seconda riguarda l'eventuale bisogno futuro di proprietà libere oltre ai tre slot tipizzati: se quel bisogno emergesse, il tipo `json` nativo della 23ai sarebbe il modo pulito per aggiungere una colonna di attributi estensibili senza tornare alle colonne numerate o all'EAV — ma, coerentemente col principio del framework, resta un improvement da valutare se e quando serve, non una struttura da anticipare.
