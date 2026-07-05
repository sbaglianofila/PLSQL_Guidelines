# Tag e release

Un *tag* è un'etichetta che marca in modo permanente un punto preciso della storia, di solito per identificare una versione rilasciata. A differenza di un branch, che è un puntatore mobile e avanza man mano che aggiungi commit, un tag è fisso: una volta apposto su un commit, ci resta. È lo strumento con cui diciamo "questa è la versione 1.2.0", e nel nostro progetto i tag hanno un ruolo centrale nel legare la storia in Git ai pacchetti di rilascio.

## Tag annotati e tag leggeri

Git conosce due tipi di tag. Un *tag leggero* è semplicemente un nome che punta a un commit, senza altre informazioni. Un *tag annotato* è un oggetto completo, che memorizza anche chi lo ha creato, quando, e un messaggio descrittivo. Per le release si usano sempre **tag annotati**, perché la release è un evento che merita di essere documentato: chi l'ha prodotta, quando e con quale nota.

Si crea un tag annotato con l'opzione `-a` e un messaggio:

```bash
git tag -a v1.2.0 -m "Release 1.2.0: import ordini e API ordini aperti"
```

Questo appone il tag sul commit corrente. Se vuoi taggare un commit passato, aggiungi il suo hash in fondo al comando.

## Il versionamento semantico

I nomi dei tag di release seguono il *versionamento semantico*, nella forma `vMAJOR.MINOR.PATCH`. Le tre parti hanno un significato preciso: si incrementa **MAJOR** quando si introduce un cambiamento non retro-compatibile, che richiede attenzione in fase di aggiornamento; si incrementa **MINOR** quando si aggiungono funzionalità in modo compatibile con l'esistente; si incrementa **PATCH** per le correzioni, tipicamente il prodotto di un hotfix. Così il solo numero di versione comunica la portata di una release: passare da `1.2.0` a `1.2.1` segnala una correzione, a `1.3.0` una nuova funzionalità, a `2.0.0` un cambiamento importante.

## Inviare i tag al remote

Un dettaglio che sorprende chi inizia: i tag **non** vengono inviati automaticamente con un normale `git push`. Vanno spinti esplicitamente. Puoi inviare un tag specifico o tutti i tag:

```bash
git push origin v1.2.0    # invia un tag specifico
git push origin --tags    # invia tutti i tag locali
```

## Il legame con i rilasci del progetto

Nel nostro progetto il tag è uno dei tre elementi che, insieme, materializzano una release, come descritto nel documento sulla gestione dei sorgenti. Il tag in Git marca il punto esatto della storia da cui la release è stata prodotta; la cartella corrispondente in `Releases/<versione>` ne contiene lo snapshot consegnabile ai DBA; e il numero di versione tiene allineati i due. Il flusso tipico è: si integra tutto ciò che deve entrare nella release, si appone il tag annotato con il numero di versione, lo si invia al remote, e si costruisce la cartella di release corrispondente. Da quel momento il tag è il riferimento immutabile a cui tornare — ad esempio per far partire un hotfix, come vedremo nella pagina sulla strategia di branching.

## Consultare e usare i tag

Per elencare i tag esistenti si usa `git tag`; per vedere il dettaglio di un tag annotato, con il suo messaggio e il commit a cui punta, `git show`:

```bash
git tag                 # elenca tutti i tag
git show v1.2.0         # dettagli del tag e del commit taggato
```

Se un domani serve ripartire dallo stato esatto di una versione rilasciata — è il caso dell'hotfix — si crea un ramo a partire dal tag:

```bash
git switch -c hotfix/1.2.1 v1.2.0
```

## Documentazione di riferimento

- Tag in Git (Pro Git): https://git-scm.com/book/it/v2/Nozioni-di-Base-di-Git-Tag
- Specifica del versionamento semantico: https://semver.org/lang/it/
