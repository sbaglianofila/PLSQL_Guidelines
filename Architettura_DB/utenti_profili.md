# Utenti, profili e autorizzazioni

> **Bozza in via di consolidamento.** L'impianto — un RBAC a strati — e le scelte di fondo sono ormai fissati (vedi "Decisioni prese"). Restano da produrre gli oggetti di database; il documento diventerà stabile con la loro realizzazione.

## Di cosa parla questo documento, e di cosa no

Questo pillar definisce l'**autorizzazione funzionale a livello applicativo**: chi può vedere e usare quali maschere e quali funzioni dell'applicazione, e in che modo — in lettura, in scrittura o in esecuzione. È il modello che risponde alla domanda "questo utente può aprire l'anagrafica clienti? può modificarla? può lanciare l'elaborazione di chiusura?".

Va tenuto rigorosamente distinto dai **ruoli di database** descritti in `schemi.md`. Quelli — `#APP#_app_role`, `#APP#_ro_role`, `#APP#_am_role` — sono ruoli Oracle che governano i privilegi di *schema*: chi può eseguire quali package, leggere quali viste, fare DML su quali tabelle. Sono pochi, statici, definiti in fase di provisioning, e riguardano le *utenze di database* (il front end si connette come `#APP#_APP`, e basta). I ruoli e i profili di questo documento sono invece **dati applicativi**, righe in tabelle `adm_*`, gestiti a runtime dagli amministratori funzionali, e riguardano gli *utenti finali* dell'applicazione — persone, non account Oracle. La parola "ruolo" ha quindi due significati nel framework, e questa è la sede in cui vale il secondo.

Il legame tra i due mondi passa per l'identità di sessione. L'utente finale si autentica verso l'applicazione (con quale meccanismo — SSO, LDAP, tabella credenziali — è una scelta di progetto che questo documento non fissa), e la sua identità viene propagata al database come `CLIENT_IDENTIFIER`, lo stesso valore che il trigger di audit scrive in `created_by`/`modified_by` (vedi `colonne_amministrative.md`) e che l'audit dei cambi di stato registra in `changed_by` (vedi `stati_workflow.md`). Questo pillar è, in un certo senso, l'anagrafe di *chi sono* quelle identità e di *cosa* possono fare.

## Il modello a strati

L'impianto è una catena a quattro entità con tre relazioni molti‑a‑molti in mezzo. In prosa: un **utente** riceve uno o più **profili**; un profilo è un insieme di **ruoli** aziendali; le **funzionalità** — le capacità legate alle maschere — sono grantate ai profili con un modo di accesso. Un utente ottiene così, per transitività, le funzionalità di tutti i profili che gli sono assegnati.

Il ruolo aziendale è l'unità organizzativa atomica ("Contabile", "Responsabile Magazzino"); il profilo è un pacchetto di ruoli che rappresenta una figura lavorativa ("Impiegato amministrativo"); la funzionalità è la singola capacità operativa su una maschera. Questa separazione tra ruolo (mattone organizzativo) e profilo (figura assegnabile) è ciò che rende il tuo "insiemi di ruoli fanno un profilo": il profilo esiste per non dover riassegnare gli stessi ruoli a ogni utente simile.

## Le entità

### Gli utenti: `adm_users`

L'anagrafe degli utenti finali dell'applicazione. Non contiene necessariamente le credenziali — se l'autenticazione è esterna (SSO/LDAP) qui vive solo l'identità e lo stato — ma è il punto in cui l'identità applicativa diventa un dato referenziabile.

| Colonna | Tipo | Scopo |
|---|---|---|
| `user_id` | `number(12)` (`id_medium`) | Chiave primaria surrogata |
| `username` | `varchar2(64 char)`, unique | Identificativo di login, propagato come `CLIENT_IDENTIFIER` |
| `full_name` | `varchar2(128 char)` | Nome per esteso |
| `email` | `email` | Contatto |
| `is_active` | `flag` | Utenza abilitata o disattivata |

### I ruoli aziendali: `adm_roles`

I ruoli organizzativi atomici. Tabella piccola e stabile, quindi chiave primaria naturale sul codice, coerentemente con la scelta fatta per le lookup.

| Colonna | Tipo | Scopo |
|---|---|---|
| `role_code` | `varchar2(32 char)` | Chiave primaria: codice del ruolo (`'ACCOUNTANT'`) |
| `name` | `varchar2(128 char)` | Nome leggibile |
| `description` | `varchar2(512 char)` | A cosa corrisponde il ruolo |
| `is_system` | `flag` | Ruolo predefinito del framework, non modificabile dagli amministratori |

### I profili: `adm_profiles`

I pacchetti di ruoli, ossia le figure assegnabili agli utenti. Stessa logica di chiave naturale.

| Colonna | Tipo | Scopo |
|---|---|---|
| `profile_code` | `varchar2(32 char)` | Chiave primaria: codice del profilo (`'ADMIN_CLERK'`) |
| `name` | `varchar2(128 char)` | Nome leggibile della figura |
| `description` | `varchar2(512 char)` | Descrizione della figura lavorativa |
| `is_system` | `flag` | Profilo predefinito, non modificabile |

### Le maschere: `adm_masks`

Le schermate dell'applicazione, ciascuna delle quali raggruppa una o più funzionalità. Si è scelto di dare alle maschere una tabella dedicata, e non un semplice attributo testuale sulle funzionalità, perché la maschera porta attributi propri — un titolo, il modulo applicativo di appartenenza, un ordinamento a menu — che ne fanno un'entità a sé e non una semplice etichetta.

| Colonna | Tipo | Scopo |
|---|---|---|
| `mask_code` | `varchar2(32 char)` | Chiave primaria: codice della maschera |
| `name` | `varchar2(128 char)` | Titolo della maschera |
| `description` | `varchar2(512 char)` | A cosa serve la schermata |
| `module_code` | `varchar2(32 char)` | Modulo applicativo di appartenenza |
| `sort_order` | `number` | Ordinamento nel menu |
| `is_active` | `flag` | Maschera attiva o dismessa |

### Le funzionalità: `adm_functionalities`

Le capacità operative dell'applicazione, ciascuna legata a una maschera. Una funzionalità è la cosa che si granta: "Anagrafica Clienti", "Distinta base", "Chiusura di periodo". Una maschera espone tipicamente più funzionalità distinte — una per azione o area — e la relazione con la maschera è quindi molti‑a‑uno, materializzata da una foreign key.

| Colonna | Tipo | Scopo |
|---|---|---|
| `functionality_code` | `varchar2(32 char)` | Chiave primaria: codice della funzionalità |
| `mask_code` | `varchar2(32 char)` | Foreign key verso `adm_masks`: la schermata di appartenenza |
| `name` | `varchar2(128 char)` | Nome leggibile |
| `description` | `varchar2(512 char)` | Cosa consente di fare |

## Le relazioni

Le tre relazioni molti‑a‑molli che cuciono insieme le entità sono altrettante tabelle di associazione.

**`adm_profile_roles`** — la composizione di un profilo in ruoli, chiave `(profile_code, role_code)`. È la materializzazione di "insiemi di ruoli fanno un profilo".

**`adm_user_profiles`** — l'assegnazione dei profili a un utente, chiave `(user_id, profile_code)`. È il punto in cui un utente diventa "qualcuno che può fare qualcosa". Poiché un utente può avere più profili, e ogni profilo porta più ruoli, ne discende che un utente ha effettivamente più ruoli aziendali — l'unione dei ruoli dei suoi profili — che è il senso del tuo "l'utente può avere diversi ruoli".

**`adm_profile_functionalities`** — i grant delle funzionalità ai profili, con il modo di accesso. Chiave `(profile_code, functionality_code)`, più i flag di modo.

| Colonna | Tipo | Scopo |
|---|---|---|
| `profile_code` | `varchar2(32 char)` | Profilo a cui si concede la funzionalità |
| `functionality_code` | `varchar2(32 char)` | Funzionalità concessa |
| `can_read` | `flag` | Accesso in lettura |
| `can_write` | `flag` | Accesso in scrittura |
| `can_execute` | `flag` | Accesso in esecuzione |

## I modi di accesso

I tre modi — lettura, scrittura, esecuzione — sono modellati come tre flag distinti sul grant, e non come un unico livello, perché non sono strettamente gerarchici: una figura può avere lettura e scrittura su una maschera anagrafica ma non l'esecuzione di un'azione che quella maschera espone, oppure la sola esecuzione di un'elaborazione senza vederne i dati. Tre booleani indipendenti esprimono qualunque combinazione senza forzare una scala. Quando un utente ha più profili che concedono la stessa funzionalità con modi diversi, il modo effettivo è l'**unione** (l'OR) dei flag: basta che un profilo conceda la scrittura perché l'utente scriva.

## La risoluzione dei permessi effettivi

Il permesso effettivo di un utente su una funzionalità si ottiene percorrendo la catena: dall'utente ai suoi profili (`adm_user_profiles`), dai profili ai grant (`adm_profile_functionalities`), aggregando in OR i modi concessi. Questa risoluzione non va sparsa nel codice applicativo: vive in un package di base — chiamiamolo `lib_authz` — che espone le domande ricorrenti, `has_access(i_user, i_functionality, i_mode)` che risponde sì/no, e `functionalities_of(i_user)` che restituisce l'elenco delle funzionalità con i modi effettivi, tipicamente per costruire il menu dell'utente all'accesso. Come gli altri package di lettura di dati stabili (`lib_config`, `lib_lookup`), `lib_authz` tiene in cache i permessi risolti per sessione, dato che cambiano di rado nell'arco di una sessione. Questo package va aggiunto al catalogo dei pacchetti base.

## Le colonne amministrative

Tutte le tabelle `adm_*`, comprese quelle di associazione, portano le sette colonne amministrative standard con il loro trigger di audit (`colonne_amministrative.md`). Qui non è un automatismo formale ma un requisito sostanziale: sapere chi ha assegnato un profilo a un utente, chi ha concesso una funzionalità a un profilo e quando, è informazione di sicurezza di prima importanza, e un cambiamento non tracciato alla mappa dei permessi è esattamente ciò che un audit di sicurezza deve poter ricostruire.

## Decisioni prese

I quattro nodi lasciati aperti nella prima stesura sono stati sciolti.

L'**assegnazione e i grant** restano come impostati: l'utente riceve *profili* (`adm_user_profiles`) e le funzionalità sono grantate ai *profili* (`adm_profile_functionalities`); i ruoli sono il tessuto organizzativo che compone il profilo, non un'unità che gate direttamente le funzionalità. È il modello più semplice e corrisponde all'enunciato originario.

Le **maschere** hanno una tabella dedicata `adm_masks`, e le funzionalità la referenziano con una foreign key: una maschera raggruppa più funzionalità e porta attributi propri (titolo, modulo, ordinamento a menu) che giustificano l'entità separata.

L'**autenticazione** è assunta **esterna**: il framework riceve a valle solo l'identità (`username` → `CLIENT_IDENTIFIER`) e non gestisce credenziali né password. Se un progetto dovesse gestirle internamente, sarà un'estensione da definire esplicitamente (memorizzazione con hash, policy, `dbms_crypto`), non un'assunzione di questo impianto.

I **modi di accesso** sono tre flag indipendenti (`can_read`/`can_write`/`can_execute`) sul grant, adatti a tre modi fissi; non si adotta una lookup dei modi, che avrebbe senso solo con modi numerosi o variabili.

## Possibile estensione futura

Una **gerarchia di funzionalità** — una funzionalità padre che ne raccoglie di figlie, per concedere in blocco un'intera area — non è prevista in questa versione, ma è un'aggiunta naturale se un progetto ne mostrasse il bisogno: si realizzerebbe con un'auto‑referenza su `adm_functionalities`, senza toccare il resto dell'impianto.
