# Glossario di Progetto

Questo documento è il riferimento normativo per la terminologia del progetto. È composto da due sezioni: le abbreviazioni standard da usare nei nomi di oggetti e identificatori, e il vocabolario comune che stabilisce quale termine usare per i concetti chiave del dominio.

Le regole d'uso sono descritte nel capitolo sulle convenzioni di denominazione (`02_naming_conventions.md`). Questo documento contiene esclusivamente il contenuto del glossario.

---

## Abbreviazioni

Ogni termine che compare in un nome di oggetto del database o in un identificatore PL/SQL deve usare l'abbreviazione indicata in questa tabella. Non sono ammesse varianti.

| Termine completo | Abbreviazione | Note |
|---|---|---|
| address | adr | |
| amount | amt | |
| archive | arc | coerente con il prefisso funzionale `arc_` |
| category | cat | |
| code | cod | solo in nomi composti; evitare come termine autonomo |
| configuration | cfg | coerente con il prefisso funzionale `cfg_` |
| contract | ctr | |
| count | cnt | solo per contatori; preferire nomi specifici dove possibile |
| customer | cus | |
| date | dt | solo in nomi composti (es. `start_dt`); preferire il termine completo dove la lunghezza lo permette |
| department | dept | |
| description | dsc | |
| detail | dtl | |
| document | doc | |
| employee | empl | |
| error | err | coerente con il prefisso funzionale `err_` |
| history | his | coerente con il prefisso funzionale `his_` |
| invoice | inv | |
| line | ln | solo in nomi composti (es. `order_ln`) |
| message | msg | |
| number | num | solo per numeri di sequenza o identificativi esterni; evitare per contatori interni |
| order | ord | |
| parameter | prm | |
| product | prd | |
| quantity | qty | |
| reference | ref | coerente con il prefisso funzionale `ref_` |
| sequence | seq | |
| status | sts | |
| type | typ | solo in nomi composti |
| user | usr | |
| working / staging | wrk | coerente con il prefisso funzionale `wrk_` |

---

## Terminologia comune

Questa sezione stabilisce quale termine usare per i concetti chiave del dominio, nei casi in cui esistano sinonimi o forme alternative che potrebbero generare ambiguità. La colonna *Da usare* è la forma ufficiale; le forme nella colonna *Da evitare* non devono comparire in nomi di oggetti, commenti o documentazione.

| Concetto | Da usare | Da evitare | Note |
|---|---|---|---|
| | | | |

> Aggiungere una riga per ogni termine del dominio che il team ha ritenuto ambiguo o per cui esistono sinonimi in uso. Esempi tipici: cliente vs utente vs account; ordine vs richiesta vs documento; riga vs linea vs voce; elaborazione vs processo vs job.
