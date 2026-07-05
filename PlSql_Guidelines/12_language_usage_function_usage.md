# Uso del linguaggio — Funzioni di conversione

Questo capitolo riguarda l'uso corretto delle funzioni di conversione Oracle — `to_date`, `to_timestamp`, `to_number` e le loro varianti — con particolare attenzione alle dipendenze dalle impostazioni NLS della sessione, alla gestione degli errori di conversione e all'uso del modificatore `FX` per la corrispondenza esatta del formato.

---

## Conversione da stringa a data e ora

### Specificare sempre il modello di formato nelle conversioni da stringa a data/ora

*Aspetti: Affidabilità, Manutenibilità, Portabilità, Sicurezza — Livello: Blocker*

Le funzioni `to_date`, `to_timestamp`, `to_timestamp_tz` e `cast` senza modello di formato esplicito interpretano la stringa di input in base alle impostazioni NLS della sessione corrente — `nls_date_format`, `nls_timestamp_format`, `nls_timestamp_tz_format`. Il risultato varia a seconda dell'ambiente, del client e delle impostazioni di sistema: lo stesso codice può funzionare in sviluppo e fallire in produzione, o produrre date errate senza sollevare eccezioni.

Omettere il formato espone inoltre a rischi di SQL injection quando il SQL dinamico include valori di data: un input costruito ad arte potrebbe alterare il comportamento della query.

La soluzione è specificare sempre il modello di formato esplicito come secondo argomento. Questo rende la conversione deterministica e indipendente dall'ambiente.

```sql
-- Errato: il formato dipende dalle impostazioni NLS della sessione
declare
    k_DOB_STR  constant    varchar2(10 char) := '1971-03-23';
    l_date                  date;
begin
    l_date := to_date(k_DOB_STR default null on conversion error);
end;
/
```

```sql
-- Corretto: il formato è esplicito e deterministico
declare
    k_DOB_STR  constant    varchar2(10 char) := '1971-03-23';
    l_date                  date;
begin
    l_date := to_date(
                    k_DOB_STR default null on conversion error
                  , 'FXYYYY-MM-DD'
              );
end;
/
```

---

## Conversione da stringa a numero

### Specificare sempre formato e parametri NLS nelle conversioni da stringa a numero

*Aspetti: Affidabilità, Manutenibilità, Portabilità — Livello: Blocker*

Le funzioni `to_number`, `to_binary_double` e `to_binary_float` — così come `cast` verso tipi numerici — senza modello di formato dipendono da `nls_numeric_characters`, che definisce il separatore decimale e il separatore delle migliaia. In ambienti europei il separatore decimale è la virgola; in ambienti anglosassoni è il punto. Lo stesso valore stringa viene interpretato diversamente nelle due configurazioni.

La soluzione corretta è specificare sia il modello di formato sia il parametro `nls_numeric_characters` in forma esplicita. In questo modo la conversione produce sempre lo stesso risultato indipendentemente dall'ambiente di esecuzione.

```sql
-- Errato: il separatore decimale dipende da nls_numeric_characters della sessione
declare
    k_SALARY   constant    varchar2(10 char) := '2500.00';
    l_salary                employees.salary%type;
begin
    l_salary := to_number(k_SALARY default null on conversion error);
end;
/
```

```sql
-- Corretto: formato e parametri NLS sono espliciti
declare
    k_SALARY   constant    varchar2(10 char) := '2500.00';
    l_salary                employees.salary%type;
begin
    l_salary := to_number(
                      k_SALARY default null on conversion error
                    , '9999999.99'
                    , 'nls_numeric_characters=''.,'''
                );
end;
/
```

---

## Gestione degli errori di conversione

### Usare la clausola `default ... on conversion error` per gestire input non validi

*Aspetti: Affidabilità, Manutenibilità — Livello: Major*

Chiamare `to_date`, `to_timestamp` o `to_number` su un valore non convertibile solleva un'eccezione che deve essere catturata dal chiamante. Quando l'input non valido è un caso atteso — ad esempio dati inseriti manualmente da un utente — gestire l'eccezione con un blocco `exception` è verboso e distribuisce la logica di validazione lontano dall'origine.

La clausola `default ... on conversion error`, introdotta in Oracle 12c R2, permette di specificare un valore di ritorno alternativo in caso di errore di conversione direttamente nell'espressione. Il codice risultante è più leggibile e non richiede un blocco di eccezione separato.

```sql
-- Errato: la gestione dell'errore richiede un blocco exception separato
declare
    k_DOB_STR  constant    varchar2(10 char) := 'not-a-date';
    l_date                  date;
begin
    begin
        l_date := to_date(k_DOB_STR, 'FXYYYY-MM-DD');
    exception
        when others then
            l_date := null;
    end;
end;
/
```

```sql
-- Corretto: il valore di default è specificato inline con la clausola on conversion error
declare
    k_DOB_STR  constant    varchar2(10 char) := 'not-a-date';
    l_date                  date;
begin
    l_date := to_date(
                    k_DOB_STR default null on conversion error
                  , 'FXYYYY-MM-DD'
              );
end;
/
```

---

## Corrispondenza esatta del formato

### Usare il modificatore `FX` per la corrispondenza esatta nella conversione da stringa a data/ora

*Aspetti: Affidabilità, Manutenibilità, Portabilità — Livello: Blocker*

Senza il modificatore `FX`, Oracle applica regole di corrispondenza permissive: accetta spazi in eccesso, zeri iniziali omessi e separatori alternativi. Una stringa come `'1971-3-5'` viene accettata dal formato `'YYYY-MM-DD'` anche se non rispetta il formato atteso, perché Oracle la interpreta comunque come una data valida.

Il modificatore `FX` (Format eXact) impone la corrispondenza rigorosa: la stringa di input deve corrispondere esattamente al modello, carattere per carattere. Questo garantisce che solo input nel formato atteso vengano accettati, e che input malformati vengano intercettati — come valore `null` se si usa `default ... on conversion error`, o come eccezione altrimenti.

```sql
-- Errato: senza FX, Oracle accetta formati non conformi come '1971-3-5'
declare
    k_DOB_STR  constant    varchar2(10 char) := '1971-03-23';
    l_date                  date;
begin
    l_date := to_date(
                    k_DOB_STR default null on conversion error
                  , 'YYYY-MM-DD'
              );
end;
/
```

```sql
-- Corretto: FX impone la corrispondenza esatta al formato dichiarato
declare
    k_DOB_STR  constant    varchar2(10 char) := '1971-03-23';
    l_date                  date;
begin
    l_date := to_date(
                    k_DOB_STR default null on conversion error
                  , 'FXYYYY-MM-DD'
              );
end;
/
```
