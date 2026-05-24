# Domini e tipi standard

Questo documento è il catalogo dei domini approvati per il progetto. Le regole d'uso sono descritte nel capitolo sulle convenzioni di denominazione (`02_naming_conventions.md`).

Per ogni dominio sono indicati: il tipo Oracle corrispondente, l'uso tipico, e gli eventuali vincoli impliciti. L'ultima sezione contiene il DDL per la creazione degli oggetti `DOMAIN` su Oracle 23c+.

---

## Identificatori

Tre livelli di dimensione per le chiavi primarie e i riferimenti, scelti in base al volume atteso della tabella.

| Dominio | Tipo Oracle | Uso tipico |
|---|---|---|
| `id_short` | `number(4)` | Tabelle di decodifica e lookup (`ref_*`): poche decine o centinaia di righe stabili nel tempo |
| `id_medium` | `number(12)` | Entità principali: clienti, ordini, contratti, prodotti |
| `id_long` | `number(24)` | Tabelle di log, audit e tracciamento ad alto volume |

---

## Testi

| Dominio | Tipo Oracle | Uso tipico |
|---|---|---|
| `short_name` | `varchar2(64 char)` | Etichette brevi, nomi di codice, denominazioni compatte |
| `name` | `varchar2(128 char)` | Nomi di persone, ragioni sociali, denominazioni standard |
| `description` | `varchar2(512 char)` | Descrizioni di entità, voci di catalogo |
| `note` | `varchar2(4000 char)` | Testo libero, annotazioni, commenti estesi |
| `code` | `varchar2(32 char)` | Codici applicativi, codici di stato, identificativi mnemonici |

---

## Valori numerici e monetari

| Dominio | Tipo Oracle | Uso tipico | Vincoli |
|---|---|---|---|
| `amount` | `number(15,2)` | Importi monetari | — |
| `quantity` | `number(12,4)` | Quantità fisiche | — |
| `percentage` | `number(5,2)` | Percentuali | valore tra 0,00 e 100,00 |
| `rate` | `number(10,6)` | Tassi, cambi valuta, coefficienti | — |

---

## Date e timestamp

| Dominio | Tipo Oracle | Uso tipico | Note |
|---|---|---|---|
| `date_only` | `date` | Date senza componente oraria | Per convenzione non si memorizza l'ora; si usa `trunc()` in lettura se necessario |
| `datetime_val` | `timestamp(6)` | Data e ora con precisione al microsecondo | — |
| `datetime_tz` | `timestamp(6) with time zone` | Data e ora con fuso orario esplicito | Da preferire in sistemi multi-regione o con integrazione verso sistemi esterni |

---

## Flag e stati

| Dominio | Tipo Oracle | Uso tipico | Valori ammessi |
|---|---|---|---|
| `flag` | `varchar2(1 char)` | Flag booleano su versioni pre-23c | `'Y'` / `'N'` |
| `status_code` | `varchar2(32 char)` | Codici di stato applicativi | Definiti dalla tabella di lookup corrispondente |

> Su Oracle 23c+ il tipo `boolean` è disponibile anche per le colonne di tabella e va preferito a `flag` per i nuovi schemi.

---

## Contatti e riferimenti

| Dominio | Tipo Oracle | Vincoli | Note |
|---|---|---|---|
| `email` | `varchar2(128 char)` | formato `x@y.z` | RFC 5321 indica 254 come max; 128 è sufficiente per la quasi totalità dei casi reali |
| `phone` | `varchar2(20 char)` | — | Includere il prefisso internazionale (`+39`) nel valore |
| `url` | `varchar2(2048 char)` | — | Limite basato sul massimo supportato dai browser principali |

---

## Domini specifici italiani

| Dominio | Tipo Oracle | Lunghezza | Vincolo di formato |
|---|---|---|---|
| `codice_fiscale` | `varchar2(16 char)` | esattamente 16 | pattern alfanumerico; validazione algoritmica consigliata a livello applicativo |
| `partita_iva` | `varchar2(11 char)` | esattamente 11 | solo cifre; checksum sull'ultima cifra |
| `cap` | `varchar2(5 char)` | esattamente 5 | solo cifre |
| `iban` | `varchar2(34 char)` | 15–34 | formato `CCnn` + BBAN; validazione mod-97 a livello applicativo |
| `codice_sdi` | `varchar2(7 char)` | esattamente 7 | codice destinatario per fatturazione elettronica |

---

## Implementazione come Oracle DOMAIN (23c+)

Su Oracle Database 23c e versioni successive, i domini possono essere creati come oggetti del database con `CREATE DOMAIN`. Il vantaggio rispetto alla sola convenzione documentata è che il tipo e i vincoli vengono applicati automaticamente dal motore su ogni colonna che dichiara quel dominio, senza bisogno di replicare i check constraint.

Il pattern di base:

```sql
create domain id_short as number(4)
    constraint id_short_positive_ck check (value > 0);

create domain id_medium as number(12)
    constraint id_medium_positive_ck check (value > 0);

create domain id_long as number(24)
    constraint id_long_positive_ck check (value > 0);

create domain name as varchar2(128 char)
    not null;

create domain email as varchar2(128 char)
    constraint email_format_ck
        check (regexp_like(value, '^[^@\s]+@[^@\s]+\.[^@\s]+$'));

create domain percentage as number(5,2)
    constraint percentage_range_ck check (value between 0 and 100);

create domain codice_fiscale as varchar2(16 char)
    constraint cf_length_ck check (length(value) = 16);

create domain partita_iva as varchar2(11 char)
    constraint piva_length_ck  check (length(value) = 11)
    constraint piva_numeric_ck check (regexp_like(value, '^\d{11}$'));

create domain cap as varchar2(5 char)
    constraint cap_length_ck  check (length(value) = 5)
    constraint cap_numeric_ck check (regexp_like(value, '^\d{5}$'));
```

Uso in DDL:

```sql
create table customers (
    customer_id     id_medium     generated always as identity primary key
  , customer_name   name          not null
  , email           email
  , partita_iva     partita_iva
  , codice_fiscale  codice_fiscale
);
```

Il DDL completo di tutti i domini va versionato negli script di migrazione del progetto come qualsiasi altro oggetto del database.
