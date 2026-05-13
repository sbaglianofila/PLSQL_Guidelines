# Uso del linguaggio — Control Structures

Le strutture di controllo — cursori, condizionali, loop — sono il tessuto connettivo di ogni programma PL/SQL. Usarle in modo coerente e prevedibile riduce i bug, rende il codice più leggibile e facilita i test. Questo capitolo raccoglie le regole applicabili a ciascuna categoria.

---

## Cursori

### Usare `%notfound` invece di `not %found`

*Aspetti: Manutenibilità — Livello: Minor*

Quando si verifica se un cursore ha restituito dati, le due forme `c%notfound` e `not c%found` sono semanticamente equivalenti, ma la prima è preferibile perché evita la negazione esplicita e rende la condizione immediatamente comprensibile.

```sql
-- Errato: la negazione richiede un passaggio mentale aggiuntivo
declare
    cursor      c_employees
    is
        select  *
          from  employees
         order  by employee_id;

    type    t_employees_type    is table of c_employees%rowtype;
    t_employees                 t_employees_type;
    k_BULK_SIZE     constant    simple_integer  := 10;
begin
    open c_employees;

    <<process_employees>>
    loop
        fetch c_employees
         bulk collect into t_employees
              limit k_BULK_SIZE;

        exit process_employees when not c_employees%found;
    end loop process_employees;

    close c_employees;
end;
/
```

```sql
-- Corretto: la forma positiva è più diretta
declare
    cursor      c_employees
    is
        select  *
          from  employees
         order  by employee_id;

    type    t_employees_type    is table of c_employees%rowtype;
    t_employees                 t_employees_type;
    k_BULK_SIZE     constant    simple_integer  := 10;
begin
    open c_employees;

    <<process_employees>>
    loop
        fetch c_employees
         bulk collect into t_employees
              limit k_BULK_SIZE;

        exit process_employees when c_employees%notfound;
    end loop process_employees;

    close c_employees;
end;
/
```

---

### Non usare `%notfound` subito dopo `fetch` con `bulk collect` e `limit`

*Aspetti: Affidabilità — Livello: Blocker*

Quando si usa `bulk collect` con la clausola `limit`, l'attributo `%notfound` viene impostato a `true` non appena il numero di righe lette è inferiore al limite — ovvero all'ultimo batch, quando le righe rimanenti sono meno di `limit`. Se si controlla `%notfound` immediatamente dopo il `fetch`, l'ultimo gruppo di righe viene saltato.

La condizione di uscita corretta è basata sul numero di elementi effettivamente caricati nella collection: si esce quando `t_employees.count() = 0` (il cursore è esaurito) oppure quando `t_employees.count() < k_BULK_SIZE` (l'ultimo batch, più piccolo del limite).

```sql
-- Errato: se la tabella ha 107 righe e il limite è 10, vengono lette solo 100
-- perché %notfound diventa true prima che l'ultimo batch venga elaborato
declare
    cursor      c_employees
    is
        select  *
          from  employees
         order  by employee_id;

    type    t_employees_type    is table of c_employees%rowtype;
    t_employees                 t_employees_type;
    k_BULK_SIZE     constant    simple_integer  := 10;
begin
    open c_employees;

    <<process_employees>>
    loop
        fetch c_employees
         bulk collect into t_employees
              limit k_BULK_SIZE;

        exit process_employees when c_employees%notfound;

        <<display_employees>>
        for i in 1..t_employees.count()
        loop
            dbms_output.put_line(t_employees(i).last_name);
        end loop display_employees;
    end loop process_employees;

    close c_employees;
end;
/
```

```sql
-- Corretto: si esce in base al conteggio degli elementi caricati,
-- garantendo che anche l'ultimo batch venga elaborato
declare
    cursor      c_employees
    is
        select  *
          from  employees
         order  by employee_id;

    type    t_employees_type    is table of c_employees%rowtype;
    t_employees                 t_employees_type;
    k_BULK_SIZE     constant    simple_integer  := 10;
begin
    open c_employees;

    <<process_employees>>
    loop
        fetch c_employees
         bulk collect into t_employees
              limit k_BULK_SIZE;

        exit process_employees when t_employees.count() = 0;

        <<display_employees>>
        for i in 1..t_employees.count()
        loop
            dbms_output.put_line(t_employees(i).last_name);
        end loop display_employees;
    end loop process_employees;

    close c_employees;
end;
/
```

---

### Chiudere sempre i cursori aperti localmente

*Aspetti: Efficienza, Affidabilità — Livello: Blocker*

Un cursore aperto occupa memoria nell'SGA di Oracle. Lasciare cursori aperti al termine di un blocco consuma risorse inutilmente e, nel caso di aperture ripetute in sessioni di lunga durata, può portare a superare il limite configurato nel parametro `open_cursors`, generando l'errore `ORA-01000: maximum open cursors exceeded`.

La regola è semplice: ogni cursore aperto esplicitamente deve essere chiuso nello stesso blocco dove è stato aperto, preferibilmente nella sezione `exception` se c'è il rischio che un'eccezione interrompa il flusso prima della chiusura.

```sql
-- Errato: il cursore rimane aperto se si verifica un'eccezione prima della return,
-- o se semplicemente ci si dimentica di chiuderlo
create or replace
package body employee_api
as
    function department_salary
        ( in_dept_id    in  departments.department_id%type )
        return number
    is
        cursor c_dept_salary
            ( p_dept_id  in  departments.department_id%type )
        is
            select  sum(emp.salary)  sum_salary
              from  employees  emp
             where  emp.department_id = p_dept_id;

        r_dept_salary   c_dept_salary%rowtype;
        k_DEPT_ID       constant    departments.department_id%type  := in_dept_id;
    begin
        open  c_dept_salary(p_dept_id => k_DEPT_ID);
        fetch c_dept_salary into r_dept_salary;
        return r_dept_salary.sum_salary;
        -- cursore non chiuso
    end department_salary;
end employee_api;
/
```

```sql
-- Corretto: il cursore viene chiuso prima del return
create or replace
package body employee_api
as
    function department_salary
        ( in_dept_id    in  departments.department_id%type )
        return number
    is
        cursor c_dept_salary
            ( p_dept_id  in  departments.department_id%type )
        is
            select  sum(emp.salary)  sum_salary
              from  employees  emp
             where  emp.department_id = p_dept_id;

        r_dept_salary   c_dept_salary%rowtype;
        k_DEPT_ID       constant    departments.department_id%type  := in_dept_id;
    begin
        open  c_dept_salary(p_dept_id => k_DEPT_ID);
        fetch c_dept_salary into r_dept_salary;
        close c_dept_salary;
        return r_dept_salary.sum_salary;
    end department_salary;
end employee_api;
/
```

---

### Non interporre istruzioni tra un'operazione SQL e i suoi attributi di cursore

*Aspetti: Affidabilità — Livello: Blocker*

Gli attributi dei cursori impliciti — `sql%rowcount`, `sql%found`, `sql%notfound` — riflettono lo stato dell'ultima operazione SQL eseguita nella sessione corrente. Se si inserisce qualsiasi altra istruzione tra l'operazione SQL e la lettura di questi attributi, il valore restituito potrebbe essere quello dell'istruzione intermedia, non quello dell'operazione originale.

La soluzione è salvare immediatamente il valore dell'attributo in una variabile locale, prima di eseguire qualsiasi altra chiamata.

```sql
-- Errato: la chiamata a process_dept avviene tra il delete e la verifica di sql%rowcount;
-- se process_dept esegue una DML, sql%rowcount restituirà il suo valore, non quello del delete
create or replace
package body employee_api
as
    procedure remove_employee
        ( in_employee_id    in  employees.employee_id%type )
    is
        k_EMPLOYEE_ID   constant    employees.employee_id%type  := in_employee_id;
        l_dept_id                   employees.department_id%type;
        k_ONE           constant    simple_integer              := 1;
    begin
        delete from employees  emp
              where emp.employee_id = k_EMPLOYEE_ID
          returning emp.department_id into l_dept_id;

        process_dept(in_dept_id => l_dept_id);  -- potrebbe azzerare sql%rowcount

        if sql%rowcount > k_ONE then
            rollback;
        end if;
    end remove_employee;
end employee_api;
/
```

```sql
-- Corretto: sql%rowcount viene salvato subito dopo il delete
create or replace
package body employee_api
as
    procedure remove_employee
        ( in_employee_id    in  employees.employee_id%type )
    is
        k_EMPLOYEE_ID   constant    employees.employee_id%type  := in_employee_id;
        l_dept_id                   employees.department_id%type;
        l_deleted_count             simple_integer;
        k_ONE           constant    simple_integer              := 1;
    begin
        delete from employees  emp
              where emp.employee_id = k_EMPLOYEE_ID
          returning emp.department_id into l_dept_id;

        l_deleted_count := sql%rowcount;

        process_dept(in_dept_id => l_dept_id);

        if l_deleted_count > k_ONE then
            rollback;
        end if;
    end remove_employee;
end employee_api;
/
```

---

## CASE, IF e funzioni condizionali

### Preferire `case` a `if` con più `elsif`

*Aspetti: Manutenibilità, Verificabilità — Livello: Minor*

Quando una variabile viene confrontata contro più valori distinti in una catena di `if`/`elsif`, un'istruzione `case` è quasi sempre più leggibile e più facile da testare. Il `case` rende esplicito che si sta valutando una singola variabile contro un insieme di alternative, e la struttura visiva è più compatta.

```sql
-- Errato: la catena di elsif diventa difficile da seguire al crescere dei rami
declare
    l_color     types_up.color_code_type;
begin
    if l_color = constants_up.k_RED then
        my_package.do_red();
    elsif l_color = constants_up.k_BLUE then
        my_package.do_blue();
    elsif l_color = constants_up.k_BLACK then
        my_package.do_black();
    end if;
end;
/
```

```sql
-- Corretto: la struttura case rende evidente il confronto su una singola variabile
declare
    l_color     types_up.color_code_type;
begin
    case l_color
        when constants_up.k_RED   then my_package.do_red();
        when constants_up.k_BLUE  then my_package.do_blue();
        when constants_up.k_BLACK then my_package.do_black();
        else null;
    end case;
end;
/
```

---

### Preferire `case` a `decode`

*Aspetti: Manutenibilità, Portabilità — Livello: Major*

La funzione `decode` è specifica di Oracle e non è disponibile in altri database. La sua sintassi — una lista di valori alternati a coppie — è difficile da leggere e non supporta condizioni complesse. Il `case`, introdotto dallo standard SQL-92, offre la stessa funzionalità con una sintassi più chiara, funziona sia in SQL che in PL/SQL, ed è portabile.

Una differenza rilevante: il `case` semplice (con variabile dopo `case`) non gestisce confronti con `null` — per quel caso si usa il `case` ricercato con `is null`.

```sql
-- Errato: decode è prolisso, dipendente da Oracle e difficile da leggere
select decode( ctry.country_code
             , constants_up.k_CTRY_IT, constants_up.k_LANG_ITALIAN
             , constants_up.k_CTRY_FR, constants_up.k_LANG_FRENCH
             , constants_up.k_CTRY_DE, constants_up.k_LANG_GERMAN
             ,                         constants_up.k_LANG_NOT_SUPPORTED
             )
  from countries  ctry;
```

```sql
-- Corretto: case semplice per confronti su valori not-null
select case ctry.country_code
           when constants_up.k_CTRY_IT then constants_up.k_LANG_ITALIAN
           when constants_up.k_CTRY_FR then constants_up.k_LANG_FRENCH
           when constants_up.k_CTRY_DE then constants_up.k_LANG_GERMAN
           else                             constants_up.k_LANG_NOT_SUPPORTED
       end
  from countries  ctry;
```

```sql
-- Corretto: case ricercato quando una delle alternative è null
select case
           when ctry.country_code = constants_up.k_CTRY_IT then constants_up.k_LANG_ITALIAN
           when ctry.country_code = constants_up.k_CTRY_FR then constants_up.k_LANG_FRENCH
           when ctry.country_code is null                  then constants_up.k_LANG_UNKNOWN
           else                                                 constants_up.k_LANG_NOT_SUPPORTED
       end
  from countries  ctry;
```

---

### Preferire `coalesce` a `nvl` quando il secondo argomento è una funzione

*Aspetti: Efficienza, Affidabilità — Livello: Critical*

La funzione `nvl(expr1, expr2)` valuta sempre entrambi gli argomenti prima di decidere quale restituire. Se `expr2` è una chiamata di funzione costosa o una sottoquery, viene eseguita anche quando `expr1` è già non nulla — uno spreco inutile e potenzialmente pericoloso.

`coalesce` utilizza invece una valutazione cortocircuitata: i valori vengono valutati in ordine e la valutazione si ferma al primo non nullo. Quando il secondo argomento è una funzione, `coalesce` è sempre preferibile a `nvl`.

```sql
-- Errato: expensive_null viene chiamata anche se dummy non è null
select nvl( dummy, my_package.expensive_null(in_value => dummy) )
  from dual;
```

```sql
-- Corretto: expensive_null viene chiamata solo se dummy è null
select coalesce( dummy, my_package.expensive_null(in_value => dummy) )
  from dual;
```

---

### Preferire `case` a `nvl2` quando i parametri sono funzioni

*Aspetti: Efficienza, Affidabilità — Livello: Critical*

Come `nvl`, la funzione `nvl2(expr1, expr2, expr3)` valuta sempre tutti e tre i parametri prima di scegliere il risultato. Se `expr2` o `expr3` sono chiamate di funzione, entrambe vengono eseguite indipendentemente dal valore di `expr1`.

In questo caso si usa un `case` ricercato, che valuta le espressioni solo nel ramo effettivamente eseguito.

```sql
-- Errato: sia expensive_nn che expensive_null vengono sempre chiamate
select nvl2( dummy
           , my_package.expensive_nn  (in_value => dummy)
           , my_package.expensive_null(in_value => dummy)
           )
  from dual;
```

```sql
-- Corretto: solo la funzione del ramo pertinente viene eseguita
select case
           when dummy is null then my_package.expensive_null(in_value => dummy)
           else                    my_package.expensive_nn  (in_value => dummy)
       end
  from dual;
```

---

### Evitare condizioni identiche in rami diversi di `if` o `case`

*Aspetti: Manutenibilità, Affidabilità, Verificabilità — Livello: Blocker*

In una catena di `if`/`elsif` o in un `case`, le condizioni vengono valutate dall'alto verso il basso: il primo ramo la cui condizione risulta vera viene eseguito, tutti gli altri vengono ignorati. Se due rami hanno la stessa condizione, il secondo non potrà mai essere raggiunto — è codice morto, spesso residuo di un copia/incolla incompleto.

```sql
-- Errato: il secondo when k_RED non verrà mai eseguito
declare
    l_color     types_up.color_code_type;
begin
    case l_color
        when constants_up.k_RED  then my_package.do_red();
        when constants_up.k_BLUE then my_package.do_blue();
        when constants_up.k_RED  then my_package.do_black();  -- mai raggiunto
        else null;
    end case;
end;
/
```

```sql
-- Corretto: ogni ramo ha una condizione distinta
declare
    l_color     types_up.color_code_type;
begin
    case l_color
        when constants_up.k_RED   then my_package.do_red();
        when constants_up.k_BLUE  then my_package.do_blue();
        when constants_up.k_BLACK then my_package.do_black();
        else null;
    end case;
end;
/
```

---

### Evitare la negazione con `not` su confronti

*Aspetti: Manutenibilità, Verificabilità — Livello: Minor*

Negare un confronto con `not` aggiunge un passaggio mentale inutile. In quasi tutti i casi esiste un operatore opposto che esprime la stessa condizione in modo più diretto: `not (a = b)` diventa `a <> b`, `not (a > b)` diventa `a <= b`. Il codice risultante è più leggibile e meno soggetto a fraintendimenti.

```sql
-- Errato: la doppia negazione richiede attenzione per essere interpretata correttamente
if not l_color != constants_up.k_RED then
    my_package.do_red();
end if;
```

```sql
-- Corretto: il confronto diretto è immediato
if l_color = constants_up.k_RED then
    my_package.do_red();
end if;
```

---

### Non confrontare valori booleani con letterali booleani

*Aspetti: Manutenibilità, Verificabilità — Livello: Minor*

Un valore booleano usato in una condizione `if` non ha bisogno di essere confrontato con `true` o `false` — il confronto è ridondante. La forma diretta è più concisa e non aggiunge alcuna informazione.

```sql
-- Errato: il confronto con true è superfluo
declare
    k_STRING    constant    types_up.text   := '42';
    l_is_valid              boolean;
begin
    l_is_valid := my_package.is_valid_number(in_string => k_STRING);

    if l_is_valid = true then
        my_package.convert_number(in_string => k_STRING);
    end if;
end;
/
```

```sql
-- Corretto: il valore booleano si usa direttamente come condizione
declare
    k_STRING    constant    types_up.text   := '42';
    l_is_valid              boolean;
begin
    l_is_valid := my_package.is_valid_number(in_string => k_STRING);

    if l_is_valid then
        my_package.convert_number(in_string => k_STRING);
    end if;
end;
/
```

---

## Controllo del flusso

### Non usare `goto`

*Aspetti: Manutenibilità, Verificabilità — Livello: Major*

Il `goto` rompe il flusso sequenziale del codice e rende impossibile costruire una struttura di indentazione coerente che ne rappresenti la logica. In PL/SQL esistono sempre alternative valide: loop etichettati con `exit`, strutture `if`/`case` nidificate, suddivisione in sottoprogrammi. Qualsiasi logica implementabile con `goto` può essere riscritta in modo più leggibile usando questi costrutti.

```sql
-- Errato: il goto salta all'etichetta check_other_things interrompendo il doppio loop
create or replace
package body my_package
as
    procedure password_check
        ( in_password   in  varchar2 )
    is
        k_PASSWORD      constant    dba_users.password%type     := in_password;
        k_DIGITS        constant    varchar2(10 char)            := '0123456789';
        k_LOWER         constant    simple_integer              := 1;
        k_ERRNO         constant    simple_integer              := -20501;
        k_ERRMSG        constant    varchar2(100 char)          := 'La password deve contenere una cifra.';
        l_has_digit                 boolean                     := false;
        l_len_pw                    pls_integer;
        l_len_digits                pls_integer;
    begin
        l_len_pw     := length(k_PASSWORD);
        l_len_digits := length(k_DIGITS);

        <<check_digit>>
        for i in k_LOWER..l_len_digits
        loop
            <<check_pw_char>>
            for j in k_LOWER..l_len_pw
            loop
                if substr(k_PASSWORD, j, 1) = substr(k_DIGITS, i, 1) then
                    l_has_digit := true;
                    goto check_other_things;
                end if;
            end loop check_pw_char;
        end loop check_digit;

        <<check_other_things>>
        null;

        if not l_has_digit then
            raise_application_error(k_ERRNO, k_ERRMSG);
        end if;
    end password_check;
end my_package;
/
```

```sql
-- Corretto: la stessa logica si esprime con exit su loop etichettato
create or replace
package body my_package
as
    procedure password_check
        ( in_password   in  varchar2 )
    is
        k_PASSWORD      constant    dba_users.password%type     := in_password;
        k_DIGITS        constant    varchar2(10 char)            := '0123456789';
        k_LOWER         constant    simple_integer              := 1;
        k_ERRNO         constant    simple_integer              := -20501;
        k_ERRMSG        constant    varchar2(100 char)          := 'La password deve contenere una cifra.';
        l_has_digit                 boolean                     := false;
        l_len_pw                    pls_integer;
        l_len_digits                pls_integer;
    begin
        l_len_pw     := length(k_PASSWORD);
        l_len_digits := length(k_DIGITS);

        <<check_digit>>
        for i in k_LOWER..l_len_digits
        loop
            <<check_pw_char>>
            for j in k_LOWER..l_len_pw
            loop
                if substr(k_PASSWORD, j, 1) = substr(k_DIGITS, i, 1) then
                    l_has_digit := true;
                    exit check_digit;
                end if;
            end loop check_pw_char;
        end loop check_digit;

        if not l_has_digit then
            raise_application_error(k_ERRNO, k_ERRMSG);
        end if;
    end password_check;
end my_package;
/
```

---

### Non riusare la stessa etichetta in scope annidati

*Aspetti: Manutenibilità, Affidabilità, Verificabilità — Livello: Major*

Assegnare la stessa etichetta a un blocco esterno e a un blocco interno crea ambiguità: un `exit my_label` o un riferimento a variabile qualificato con quell'etichetta potrebbe risolvere a un livello di annidamento diverso da quello atteso, generando comportamenti inattesi e difficili da diagnosticare.

```sql
-- Errato: my_label appare sia sul blocco esterno sia sul loop interno
<<my_label>>
declare
    k_MIN   constant    simple_integer  := 1;
    k_MAX   constant    simple_integer  := 8;
begin
    <<my_label>>
    for i in k_MIN..k_MAX
    loop
        dbms_output.put_line(i);
    end loop my_label;
end my_label;
/
```

```sql
-- Corretto: etichette distinte per blocco e loop
<<output_values>>
declare
    k_MIN   constant    simple_integer  := 1;
    k_MAX   constant    simple_integer  := 8;
begin
    <<process_values>>
    for i in k_MIN..k_MAX
    loop
        dbms_output.put_line(i);
    end loop process_values;
end output_values;
/
```

---

### Usare il cursor `for` loop per iterare su un cursore completo

*Aspetti: Manutenibilità — Livello: Major*

Quando si deve elaborare l'intero risultato di un cursore, il cursor `for` loop è la forma più leggibile: apre il cursore, itera sulle righe e lo chiude automaticamente. Non richiede di gestire esplicitamente `open`, `fetch` e `close`, e rende immediatamente chiaro al lettore che tutte le righe vengono elaborate.

Questa regola si applica quando si usa la modalità riga per riga. Per volumi elevati è preferibile `bulk collect` (vedi capitolo DML & SQL).

```sql
-- Errato: la gestione esplicita del cursore è più prolissa e introduce più punti di errore
declare
    cursor c_employees
    is
        select  emp.last_name
          from  employees  emp
         where  emp.department_id = 10;

    r_employee  c_employees%rowtype;
begin
    open c_employees;

    <<fetch_employees>>
    loop
        fetch c_employees into r_employee;
        exit fetch_employees when c_employees%notfound;
        dbms_output.put_line(r_employee.last_name);
    end loop fetch_employees;

    close c_employees;
end;
/
```

```sql
-- Corretto: il cursor for loop gestisce open/fetch/close automaticamente
begin
    <<process_employees>>
    for r_employee in (
        select  emp.last_name
          from  employees  emp
         where  emp.department_id = 10
    )
    loop
        dbms_output.put_line(r_employee.last_name);
    end loop process_employees;
end;
/
```

---

### Usare il `for` numerico per array densi, il `while` per array sparsi

*Aspetti: Manutenibilità, Efficienza, Affidabilità — Livello: Major*

Per iterare su una collection densa — ovvero in cui tutti gli indici da 1 a `count()` sono presenti — il `for` numerico è la forma più leggibile: rende esplicito che si attraversa l'intera struttura dall'inizio alla fine. I varray sono sempre densi; le nested table possono diventare sparse dopo operazioni di `delete`.

Per le collection sparse si usa invece un loop `while` con `first()` e `next()`, perché il `for` numerico su una collection con buchi genera un'eccezione `no_data_found` per ogni indice mancante.

I limiti del `for` su array densi devono sempre essere `1` e `count()`: usare `first()..last()` solleva `value_error` se la collection è vuota, mentre `count()` restituisce sempre 0 in quel caso, lasciando il loop inattivo senza errori.

```sql
-- Errato: uso di first()..last() solleva value_error su collection vuota
declare
    type    t_employee_type     is table of employees.employee_id%type;
    t_employees                 t_employee_type := t_employee_type();
begin
    <<process_employees>>
    for i in t_employees.first()..t_employees.last()
    loop
        dbms_output.put_line(t_employees(i));
    end loop process_employees;
end;
/
```

```sql
-- Corretto: for numerico con 1..count() per array denso (non solleva eccezioni su vuoto)
declare
    type    t_employee_type     is table of employees.employee_id%type;
    t_employees                 t_employee_type;
    k_ROGERS    constant    integer := 134;
    k_MCEWEN    constant    integer := 158;
begin
    t_employees := t_employee_type(k_ROGERS, k_MCEWEN);

    <<process_employees>>
    for i in 1..t_employees.count()
    loop
        dbms_output.put_line(t_employees(i));
    end loop process_employees;
end;
/
```

```sql
-- Corretto: while con first()/next() per array sparso (con elementi eliminati)
declare
    type    t_employee_type     is table of employees.employee_id%type;
    t_employees                 t_employee_type;
    k_ROGERS    constant    integer := 134;
    k_MATOS     constant    integer := 143;
    k_MCEWEN    constant    integer := 158;
    k_IDX_DEL   constant    integer := 2;
    l_index                 pls_integer;
begin
    t_employees := t_employee_type(k_ROGERS, k_MATOS, k_MCEWEN);
    t_employees.delete(k_IDX_DEL);

    l_index := t_employees.first();

    <<process_employees>>
    while l_index is not null
    loop
        dbms_output.put_line(t_employees(l_index));
        l_index := t_employees.next(l_index);
    end loop process_employees;
end;
/
```

---

### Non usare `continue` o `exit` incondizionali

*Aspetti: Manutenibilità, Verificabilità — Livello: Major*

Un `continue` o un `exit` senza clausola `when` interrompe sempre il flusso nello stesso punto, rendendo irraggiungibile qualsiasi istruzione successiva all'interno dello stesso ciclo — codice morto. Se è necessario interrompere o saltare un'iterazione, la condizione deve essere esplicita nella clausola `when`.

```sql
-- Errato: some_further_processing è irraggiungibile perché il continue è incondizionale
begin
    <<process_employees>>
    loop
        my_package.some_processing();
        continue process_employees;
        my_package.some_further_processing();  -- mai eseguito
    end loop process_employees;
end;
/
```

```sql
-- Corretto: il continue ha una condizione esplicita
declare
    k_FIRST_YEAR    constant    pls_integer := 1900;
begin
    <<process_employees>>
    loop
        my_package.some_processing();
        continue process_employees when extract(year from sysdate) > k_FIRST_YEAR;
        my_package.some_further_processing();
    end loop process_employees;
end;
/
```

---

### Usare `exit` solo nel basic loop; usare `exit when` al posto di `if ... exit`

*Aspetti: Manutenibilità — Livello: Major*

I loop `for` e `while` hanno condizioni di terminazione intrinseche: il range del `for` e la condizione del `while`. Aggiungere un `exit` esplicito a questi loop significa che la condizione di terminazione scelta non è quella giusta — in quel caso si dovrebbe usare un basic loop con le condizioni di uscita gestite dentro di esso.

Quando si usa un `exit` in un basic loop, la forma corretta è sempre `exit when <condizione>`, non `if <condizione> then exit; end if;`. La forma `exit when` è semanticamente equivalente ma più compatta e più leggibile.

```sql
-- Errato: exit all'interno di un while o for riduplica la condizione di terminazione
declare
    i               pls_integer;
    k_MIN   constant    simple_integer  := 1;
    k_MAX   constant    simple_integer  := 10;
    k_INCR  constant    simple_integer  := 1;
begin
    i := k_MIN;

    <<while_loop>>
    while ( i <= k_MAX )
    loop
        i := i + k_INCR;
        exit while_loop when i > k_MAX;  -- ridondante con la condizione del while
    end loop while_loop;
end;
/
```

```sql
-- Errato: if + exit è più prolisso di exit when
declare
    k_FIRST_YEAR    constant    pls_integer := 1900;
begin
    <<process_employees>>
    loop
        my_package.some_processing();
        if extract(year from sysdate) > k_FIRST_YEAR then
            exit process_employees;
        end if;
        my_package.some_further_processing();
    end loop process_employees;
end;
/
```

```sql
-- Corretto: exit when nel basic loop, condizione di uscita una sola volta
declare
    k_FIRST_YEAR    constant    pls_integer := 1900;
begin
    <<process_employees>>
    loop
        my_package.some_processing();
        exit process_employees when extract(year from sysdate) > k_FIRST_YEAR;
        my_package.some_further_processing();
    end loop process_employees;
end;
/
```

L'`exit when` va sempre etichettato con il nome del loop da cui si vuole uscire, specialmente nei loop annidati: rende esplicito a quale livello di annidamento appartiene l'uscita, evitando ambiguità.

```sql
-- Errato: exit without label in loop annidati: a quale loop si riferisce?
declare
    k_INIT  constant    simple_integer  := 0;
    k_INCR  constant    simple_integer  := 1;
    k_EXIT  constant    simple_integer  := 3;
    l_outer             pls_integer;
    l_inner             pls_integer;
begin
    l_outer := k_INIT;

    <<outer_loop>>
    loop
        l_inner  := k_INIT;
        l_outer  := nvl(l_outer, k_INIT) + k_INCR;

        <<inner_loop>>
        loop
            l_inner := nvl(l_inner, k_INIT) + k_INCR;
            exit when l_inner = k_EXIT;  -- esce dall'inner loop, ma non è chiaro
        end loop inner_loop;

        exit when l_inner = k_EXIT;  -- stessa condizione ripetuta per uscire dall'outer
    end loop outer_loop;
end;
/
```

```sql
-- Corretto: l'etichetta chiarisce esattamente da quale loop si esce
declare
    k_INIT  constant    simple_integer  := 0;
    k_INCR  constant    simple_integer  := 1;
    k_EXIT  constant    simple_integer  := 3;
    l_outer             pls_integer;
    l_inner             pls_integer;
begin
    l_outer := k_INIT;

    <<outer_loop>>
    loop
        l_inner  := k_INIT;
        l_outer  := nvl(l_outer, k_INIT) + k_INCR;

        <<inner_loop>>
        loop
            l_inner := nvl(l_inner, k_INIT) + k_INCR;
            exit outer_loop when l_inner = k_EXIT;
        end loop inner_loop;
    end loop outer_loop;
end;
/
```

---

### Non usare un cursor `for` loop per verificare se un cursore restituisce dati

*Aspetti: Efficienza — Livello: Critical*

Se lo scopo è solo verificare se esistono righe che soddisfano una condizione, un cursor `for` loop è inefficiente: può leggere tutte le righe della tabella prima di terminare. È sufficiente aprire il cursore, eseguire un singolo `fetch` e leggere l'attributo `%found`.

```sql
-- Errato: il loop itera su tutti gli impiegati solo per sapere se ne esiste almeno uno
declare
    l_employee_found    boolean := false;

    cursor c_employees
    is
        select  emp.employee_id
              , emp.last_name
          from  employees  emp;
begin
    <<check_employees>>
    for r_employee in c_employees
    loop
        l_employee_found := true;
    end loop check_employees;

    if l_employee_found then
        null;  -- elaborazione
    end if;
end;
/
```

```sql
-- Corretto: un singolo fetch è sufficiente per determinare se esistono righe
declare
    l_employee_found    boolean := false;

    cursor c_employees
    is
        select  emp.employee_id
              , emp.last_name
          from  employees  emp;

    r_employee  c_employees%rowtype;
begin
    open  c_employees;
    fetch c_employees into r_employee;
    l_employee_found := c_employees%found;
    close c_employees;

    if l_employee_found then
        null;  -- elaborazione
    end if;
end;
/
```

---

### Non usare un `for` loop per query che restituiscono al massimo una riga

*Aspetti: Affidabilità, Efficienza, Manutenibilità — Livello: Blocker*

Un `for` loop su una query che dovrebbe restituire al massimo una riga maschera due eccezioni importanti: `no_data_found` se la riga non esiste, e `too_many_rows` se ne esistono più di una. Il lettore non può distinguere se l'assenza di dati sia gestita intenzionalmente o sia un bug silenzioso.

La forma corretta è una `select ... into`, che solleva esplicitamente `no_data_found` e `too_many_rows`. Queste eccezioni vanno poi gestite in modo appropriato nella sezione `exception`.

```sql
-- Errato: il for loop nasconde no_data_found e too_many_rows
create or replace
package body employee_api
as
    function emp_name
        ( in_empno  in  emp.empno%type )
        return emp.ename%type
    is
        l_ename     emp.ename%type;
    begin
        <<fetch_name>>
        for r in (
            select  emp.ename
              from  emp
             where  emp.empno = in_empno
        )
        loop
            l_ename := r.ename;
        end loop fetch_name;

        return l_ename;
    end emp_name;
end employee_api;
/
```

```sql
-- Corretto: select into con gestione esplicita delle eccezioni
create or replace
package body employee_api
as
    function emp_name
        ( in_empno  in  emp.empno%type )
        return emp.ename%type
    is
        l_ename     emp.ename%type;
    begin
        select  emp.ename
          into  l_ename
          from  emp
         where  emp.empno = in_empno;

        return l_ename;
    exception
        when no_data_found then
            return null;
        when too_many_rows then
            raise;
    end emp_name;
end employee_api;
/
```

---

### Evitare indici di `for` loop non usati nel corpo

*Aspetti: Efficienza — Livello: Major*

Se l'indice di un `for` numerico non viene mai referenziato nel corpo del loop, è probabile che il loop non sia la struttura giusta, o che la logica interna debba essere riscritta in modo da sfruttare l'indice stesso. Un loop il cui indice serve solo come contatore ma non viene mai letto suggerisce che le variabili ausiliarie gestite manualmente potrebbero essere eliminate.

```sql
-- Errato: l'indice i non viene mai usato nel corpo del loop
declare
    l_row   pls_integer;
    l_value pls_integer;
    k_MIN   constant    simple_integer  := 1;
    k_MAX   constant    simple_integer  := 5;
    k_INCR  constant    simple_integer  := 1;
    k_VINCR constant    simple_integer  := 10;
    k_FIRST constant    simple_integer  := 100;
    k_SEP   constant    varchar2(1 char) := ' ';
begin
    l_row   := k_MIN;
    l_value := k_FIRST;

    <<for_loop>>
    for i in k_MIN..k_MAX
    loop
        dbms_output.put_line(l_row || k_SEP || l_value);
        l_row   := l_row   + k_INCR;
        l_value := l_value + k_VINCR;
    end loop for_loop;
end;
/
```

```sql
-- Corretto: l'indice i viene usato direttamente per calcolare riga e valore
declare
    k_MIN   constant    simple_integer  := 1;
    k_MAX   constant    simple_integer  := 5;
    k_VINCR constant    simple_integer  := 10;
    k_FIRST constant    simple_integer  := 100;
    k_SEP   constant    varchar2(1 char) := ' ';
begin
    <<for_loop>>
    for i in k_MIN..k_MAX
    loop
        dbms_output.put_line(i || k_SEP || to_char(k_FIRST + i * k_VINCR));
    end loop for_loop;
end;
/
```

---

### Non usare valori literali come limiti di un `for` numerico

*Aspetti: Modificabilità, Manutenibilità — Livello: Minor*

I limiti inferiore e superiore di un `for` numerico scritti come valori literali (`for i in 1..5`) sono difficili da modificare in modo coerente se lo stesso valore compare in più punti. La regola generale sui literali (definire le costanti in un package dedicato) si applica anche qui: i limiti devono essere costanti con nome.

```sql
-- Errato: i limiti 1 e 5 sono hardcoded
begin
    <<for_loop>>
    for i in 1..5
    loop
        dbms_output.put_line(i);
    end loop for_loop;
end;
/
```

```sql
-- Corretto: limiti definiti come costanti con nome
declare
    k_MIN   constant    simple_integer  := 1;
    k_MAX   constant    simple_integer  := 5;
begin
    <<for_loop>>
    for i in k_MIN..k_MAX
    loop
        dbms_output.put_line(i);
    end loop for_loop;
end;
/
```
