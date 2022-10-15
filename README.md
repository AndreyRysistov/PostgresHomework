##  (ДЗ №2) Глава №3. Ответы на контрольные вопросы и задания ##

### **Задание 1.**

Дан запрос:

```SQL
INSERT INTO aircrafts
VALUES ( 'SU9', 'Sukhoi SuperJet-100', 3000 );
```

Запрос выполняется с ошибкой:
```
ОШИБКА: повторяющееся значение ключа нарушает ограничение
уникальности "aircrafts_pkey"
ПОДРОБНОСТИ: Ключ "(aircraft_code)=(SU9)" уже существует.
```
Подумайте, почему появилось сообщение. 

>**Ответ:**
указанная операция не выполниться, так как атрибут `aircraft_code` в таблице `aircrafts`  является первичным ключем и по определению должен быть уникальным. Строка с индексом 'SU9' уже содержиться в таблице.

### **Задание 2.**

Самостоятельно напишите команду для выборки всех строк из таблицы aircrafts, чтобы строки были упорядочены по убыванию значения атрибута «Максимальная дальность полета, км» (range).

>**Ответ:** команда для выборки всех строк из таблицы `aircraft` с сортировкой по убыванию относительно атрибута range:
```SQL 
SELECT * 
  FROM bookingaircrafts 
  ORDER BY aircraft_code DESC;
```
**Результат запроса:**
```
 aircraft_code |        model        | range 
---------------+---------------------+-------
 SU9           | Sukhoi SuperJet-100 |  3500
 CR2           | Bombardier CRJ-200  |  2700
 CN1           | Cessna 208 Caravan  |  1200
 773           | Boeing 777-300      | 11100
 763           | Boeing 767-300      |  7900
 733           | Boeing 737-300      |  4200
 321           | Airbus A321-200     |  5600
 320           | Airbus A320-200     |  5700
 319           | Airbus A319-100     |  6700
(9 rows)
```

### **Задание 3.**

Самостоятельно напишите команду UPDATE полностью, при
этом не забудьте, что увеличить дальность полета нужно только у одной модели — Sukhoi SuperJet, поэтому необходимо использовать условие WHERE. Затем с помощью команды SELECT проверьте полученный результат.

> Ответ: команда для увеличения значения `range` в два раза у модели `Sukhoi SuperJet-100` следующая:
```SQL 
UPDATE aircrafts SET range = range * 2
WHERE model = 'Sukhoi SuperJet-100';

SELECT range 
  FROM aircrafts 
 WHERE model = 'Sukhoi SuperJet-100';
```

### **Задание 4.**

Самостоятельно смоделируйте описанную ситуацию, подобрав условие, которому гарантированно не соответствует ни одна строка в таблице «Самолеты» (aircrafts).

> **Ответ:** пример SQL запроса на данной БД который не удалит не одной строки в таблице:
```SQL 
DELETE FROM aircrafts WHERE range < 0;
```

## (ДЗ №2) Глава №4. Ответы на контрольные вопросы и задания ##

### **Задание 2.**

> **Ответ:** создадим таблицу test_numetic и заполним ее числами numeric с различной точностью:

```SQL 
CREATE TABLE test_numeric( 
    measurement numeric,
    description text
);

INSERT INTO test_numeric 
VALUES (1234567890.0987654321, 'Точность 20 знаков, масштаб 10 знаков'),
       (1.5, 'Точность 2 знака, масштаб 1 знак' ),
       (0.12345678901234567890, 'Точность 21 знак, масштаб 20 знаков'),
       (1234567890, 'Точность 10 знаков, масштаб 0 знаков (целое число)');

SELECT * 
  FROM test_numeric;

DROP TABLE test_numeric;
```

**Результат запроса:**
```
      measurement       |                    description                     
------------------------+----------------------------------------------------
  1234567890.0987654321 | Точность 20 знаков, масштаб 10 знаков
                    1.5 | Точность 2 знака, масштаб 1 знак
 0.12345678901234567890 | Точность 21 знак, масштаб 20 знаков
             1234567890 | Точность 10 знаков, масштаб 0 знаков (целое число)
(4 rows)

```

### **Задание 4.**

> **Ответ:** посмотрим поведение PostgreSQL на верхних границах допустимых значений типов real и double precision

```SQL
/* Границы типа double precision 1E-307 до 1E+308 с точностью 15. Для очень больших (на границе) принимается в расчет только первые 16 старших десятичных разрядов */

SELECT '1e+308'::double precision + '1e+89'::double precision = '1e+308'::double precision; 

-- True
-- В данном случае 17 старший разряд обрезается, поэтому числа считаются равными 

/* У типа real границы следующие 1E-37 до 1E+37, а точность 6 на них поведение идентично типу double precision */

SELECT '1e+38'::real + '1e+31'::real = '1e+38'::real; 

-- False 
-- В данном случае старший десятичный разряд  учитывается следовательно числа не равны

SELECT '1e+38'::real + '1e+30'::real = '1e+38'::real; 

-- True
-- В данном случае вторая единица не учитывается, поэтому числа будут считаться равными
```

### **Задание 8.**

> **Ответ:** создадим таблицу test_serial и поупражняемся в работе со столбцом типа series, являющимся первичным ключом.

```SQL 
CREATE TABLE test_serial( 
    PRIMARY KEY (id),

    id serial,
    name text    
);

INSERT INTO test_serial (name) 
VALUES ('Вишневая'); 
-- Для данной записи будет присвоено id=1, для следующего id=2
INSERT INTO test_serial (id, name) 
VALUES ( 2, 'Прохладная' ); 
-- В данном случае мы явным образом указываем id, при этом обновление последовательности для id не происходит, поэтому при добавлении следующей записи id по прежнему 2, что нарушает условие уникальности первичного ключа
INSERT INTO test_serial (name) 
VALUES ('Грушевая'); 
-- Ошибка, так как запись с id=2 уже существует, однако последовательность serial уже обновилась (обновление последовательности происходит раньше, чем проверка условия уникальности первичного ключа)
INSERT INTO test_serial (name) 
VALUES ('Грушевая'); 
-- Запрос выполняется успешно, так как последовательность обновилось несмотря на ошибку при прошлом запросе. Текущее значение последовательность id=3.
INSERT INTO test_serial (name) 
VALUES ('Зеленая'); 
--Запрос выполняется успешно. Текущий id=4.
DELETE 
  FROM test_serial 
 WHERE id = 4; 
--Удаляем строку с id=4, однако значение последовательности при этом остается неизменным.
INSERT INTO test_serial (name) 
VALUES ('Луговая'); 
-- Запрос выполняется успешно. Запись добавлена с id=5. 

SELECT * 
  FROM test_serial; 

DROP TABLE test_serial;
```

**Результат запроса:**
```
 id |    name    
----+------------
  1 | Вишневая
  2 | Прохладная
  3 | Грушевая
  5 | Луговая
(4 rows)
```

### **Задание 12.**

>**Ответ:** поэкспериментируем с форматом даты в PostgreSQL (параметр datestyle) - используем традиционный стиль и региональный стиль German.

```SQL 
-- Запрос для установки формата в традиционный стиль
SET datestyle TO DEFAULT; 

-- Результат: 17.12.1997
SELECT '17.12.1997'::date; 


-- Ошибка так как вторым значением по формату даты DMY является месяц
SELECT '12.17.1997'::date; 

/*
Поменяем формат даты на 'German, MDY' и теперь данный запрос успешно выполниться
*/


-- Запрос для установки формата в региональный стиль
SET datestyle TO 'German, MDY'; 


-- Результат: 17.12.1997
SELECT '12.17.1997'::date; 


/* В качестве эксперимента повторим то же самое с форматом даты SQL*/

SET datestyle TO 'SQL, DMY';

-- Результат: 17/12/1997
SELECT '17/12/1997'::date; 

-- Ошибка
SELECT '12/17/1997'::date; 

-- Изменим формат даты SQL
SET datestyle TO 'SQL, MDY';

-- Теперь запрос отрабатывает без ошибок
SELECT '12/17/1997'::date; 

```

### **Задание 15.**

> **Ответ:** поэкспериментируем с форматированием метки времени в строку с помощью функции to_char:

```SQL 
-- Вывод в формате 'минута:секунда' (например, 47:29)
SELECT to_char(current_timestamp, 'mi:ss'); 
-- Вывод в формате 'номер дня в месяце' (например, 12)
SELECT to_char(current_timestamp, 'dd'); 
-- Вывод текущей даты в численном формате 'год-месяц-день' (например, 2022-10-12)
SELECT to_char(current_timestamp, 'yyyy-mm-dd'); 
-- Вывод текущей даты в численном формате 'год-месяц-день:число секунд с начала суток' (например, 2022-10-12:75005)
SELECT to_char( current_timestamp, 'yyyy-mm-dd:SSSS' );
-- Вывод текущей даты в численном формате 'год месяц(текстом) день' (например, 2022 OCTOBER 12)
SELECT to_char( current_timestamp, 'yyyy MONTHdd' ); 
```

### **Задание 21.**

> **Ответ:**: при добавлении интервала PostgreSQL учитывает различное число дней в месяцах, так, например, при добавлении к дате, соответствующей концу какого либо месяца, СУБД автоматически просматривает число дней в следующем месяце и, в случае если оно меньше, то в качестве результата запроса используется последнее число следующего месяца. Проверим это на примерах.

```SQL
/* Добавляем интервал в 1 месяц к 31 января. Февраль в 2016 году содержит 29 дней, поэтому результатом запроса является 29 февраля 2016 года.*/
SELECT to_char(('2016-01-31'::date + '1 mon'::interval) :: timestamp,   'yyyy-mm-dd') AS new_date;
```
**Результат запроса**:
```
      new_date       
---------------------
 2016-02-29 00:00:00
(1 row) */
```

```SQL

/* Добавляем интервал в 1 месяц к 29 февраля. По итогу запроса должны получить дату 29 марта 2016 года.*/
SELECT to_char(('2016-02-29'::date + '1 mon'::interval) :: timestamp,   'yyyy-mm-dd') AS new_date;
```

**Результат запроса:**
```
      new_date       
---------------------
 2016-03-29 00:00:00
(1 row) */
```

### **Задание 30.**

> **Ответ:** поэкспериментируем с типом данных boolean и проверим достимые значения столбца этого типа на примере таблицы test_bool.

```SQL
CREATE TABLE test_bool( 
    a boolean,
    b text
);

/*  Допустимые boolean значения: 
      TRUE, true, 't', 'true', 'y', 'yes', 'on', '1'
      FALSE, false, 'f', 'false', 'n', 'no', 'off', '0'
*/

-- Запрос корректен: TRUE является ключевым словом типа boolean
INSERT INTO test_bool 
VALUES (TRUE, 'yes'); 

-- Запрос некорректен: токен yes не зарезервирован под boolean
INSERT INTO test_bool 
VALUES (yes, 'yes'); 

-- Запрос корректен: второй аргумент неявным образом преобразуется в строку
INSERT INTO test_bool 
VALUES ('yes', true); 

-- Запрос корректен: строка 'yes' зарезервирована под тип boolearn и неявным образом преобразуется в true, в свою очередь TRUE неявным образом преобразуется в строку
INSERT INTO test_bool 
VALUES ('yes', TRUE); 

-- Запрос корректен: строка '1' зарезервирована под тип boolearn и неявным образом преобразуется в true
INSERT INTO test_bool 
VALUES ('1', 'true'); 

-- Запрос некорректен: токен 1 не зарезервирован под boolean
INSERT INTO test_bool 
VALUES (1, 'true'); 

-- Запрос корректен: строка 't' зарезервирована под тип boolean и неявным образом преобразуется в true
INSERT INTO test_bool 
VALUES ('t', 'true'); 

-- Запрос некорректен: токен truth не зарезервирован под boolean
INSERT INTO test_bool 
VALUES ('t', truth); 

-- Запрос корректен: true неявным образом преобразуется в строку
INSERT INTO test_bool 
VALUES (true, true); 

-- Запрос корректен: конвертация любого числа, кроме 0, в boolean дает TRUE 
INSERT INTO test_bool 
VALUES (1::boolean, 'true'); 

-- Запрос корректен: аналогично предыдущему
INSERT INTO test_bool 
VALUES (111::boolean, 'true'); 

SELECT * 
  FROM test_bool;


DROP TABLE test_bool;
```

### **Задание 33.**

> **Ответ:** создадим таблицу pilots с полями pilot_name (имя пилота), schedule (раписание полетов) и meal(обеды). При этом столбцы schedule и meal будут является массивом чисел и двумерным тестовым массивом соответственно. Поэкспериментируем в работе с массивами, выполнив несколько запросов на выборку и обновление.

```SQL
CREATE TABLE pilots( 
    pilot_name text,
    schedule integer[],
    meal text[][]
);
/*Добавим строки в созданную таблицу:*/ 

INSERT INTO pilots 
VALUES( 'Ivan', '{ 1, 3, 5, 6, 7 }'::integer[],
        '{ 
            { "сосиска", "макароны", "кофе" }, 
            { "куриное филе", "пюре", "какао" }, 
            { "рагу", "сэндвич с семгой", "морс ягодный" }, 
            { "шарлотка яблочная", "гречка", "компот вишевый" }, 
            { "омлет с овощами", "бекон", "кофе" } 
        }'::text[][]
        ),
        ( 
        'Petr', '{ 1, 2, 5, 7 }'::integer[],
        '{ 
            { "котлета", "каша", "кофе" },
            { "куринная отбивная", "рис", "компот" },
            { "манная каша", "билины с мясом", "компот" },
            { "мясо запеченное", "пюре", "какао" } 
        }'::text[][]
        ),
        ( 
            'Pavel', '{ 2, 5 }'::integer[],
            '{ 
                { "сосиска", "каша", "кофе" },
                { "мясо запеченное", "пюре", "какао" }
            }'::text[][]
        ),
        ( 
            'Boris', '{ 3, 5, 6 }'::integer[],
            '{ 
                { "котлета", "каша", "чай" },
                { "куринная отбивная", "рис", "компот" },
                { "сосиска", "макароны", "кофе" }
            }'::text[][]
        );

SELECT * 
  FROM pilots;
```
**Результат запроса:**
```
 pilot_name |  schedule   |                      meal                                                                                     
 Ivan       | {1,3,5,6,7} | {{сосиска,макароны,кофе},
                            {"куриное филе",пюре,какао},
                            {рагу,"сэндвич с семгой","морс ягодный"},
                            {"шарлотка яблочная",гречка,"компот вишевый"},
                            {"омлет с овощами",бекон,кофе}}
 Petr       | {1,2,5,7}   | {{котлета,каша,кофе},
                            {"куринная отбивная",рис,компот},
                            {"манная каша","билины с мясом",компот},
                            {"мясо запеченное",пюре,какао}}
 Pavel      | {2,5}       | {{сосиска,каша,кофе},
                            {"мясо запеченное",пюре,какао}}
 Boris      | {3,5,6}     | {{котлета,каша,чай},
                            {"куринная отбивная",рис,компот},
                            {сосиска,макароны,кофе}}
(4 rows)
```
```SQL
/* Выведем имена пилотов которые в первый день их работы едят макароны или рис */
SELECT pilot_name, meal
  FROM pilots 
 WHERE meal[1][1] IN('макароны','рис') 
    OR meal[1][2] IN('макароны','рис') 
    OR meal[1][3] IN('макароны','рис');
```
**Результат запроса:**
```
 pilot_name |                               meal                                                                                     
 Ivan       | {{сосиска,макароны,кофе},
                {"куриное филе",пюре,какао},
                {рагу,"сэндвич с семгой","морс ягодный"},
                {"шарлотка яблочная",гречка,"компот вишевый"},
                {"омлет с овощами",бекон,кофе}}
(4 rows)
```

```SQL
/*Изменим расписание полетов пилота Boris и его меню в первый день работы*/

UPDATE pilots 
   SET schedule[1] = 2, 
       meal[1][:] = '{"груша", "куриная грудка", "чай"}' :: text[]
 WHERE pilot_name='Boris';

SELECT * 
  FROM pilots 
 WHERE pilot_name='Boris';


DROP TABLE pilots;
```

**Результат запроса:**

```
 pilot_name | schedule |           meal                                           
 Boris      | {2,5,6}  | {{груша,"куриная грудка",чай},
                          {"куринная отбивная",рис,компот},
                          {сосиска,макароны,кофе}}
(1 rows)
```

### **Задание 35.**

> **Ответ:** продемонстрируем функции для работы с JSON в PostreSQL из [документации](https://postgrespro.ru/docs/postgrespro/9.6/functions-json).

```SQL

/* Функция to_json() преобразует типы PostgreSQL в строку json*/
SELECT to_json('Hello world!'::text); 
/* 
       to_json       
---------------------
 "Hello world!"
(1 row)*/

SELECT to_json('{"sports": "хоккей", "trips": 5 }'::text); 
/* 
       to_json       
---------------------
 "{\"sports\": \"хоккей\", \"trips\": 5 }"
(1 row)*/

/*Функция json_build_object() предназначена для построения json строки из кортежа формата (ключ_1, значение_1, ключ_2, значение_2,..., ключ_n, значение_n)*/
SELECT json_build_object('sports', 'хоккей', 'trips', 25); 
/* 
   json_build_object    
------------------------
 {"sports":"хоккей","trips":25}
(1 row)
*/

/* Функция json_object_keys() предназначена для получения ключей JSON строки */
SELECT json_object_keys('{"apple": 150, "banana": 25, "pineapple": 10}'); 
/*
 json_object_keys 
------------------
 apple
 banana
 pineapple
(3 строки)
*/
```

## (ДЗ №4) Глава №5. Ответы на контрольные вопросы и задания ##

Приведем запросы для создания таблиц "Студенты" (students) и "Успеваемость" (progress) , с которыми мы будем работать при выполнении заданий:

```SQL
/* Создаем таблицу для хранения данных о студентах students */
CREATE TABLE students( 
    PRIMARY KEY (record_book),

    record_book numeric(5) NOT NULL, -- номер зачетной книжки
    name        text       NOT NULL, -- ФИО студента
    doc_ser     numeric(4),          -- серия документа
    doc_num     numeric(6)           -- номер документа
);

/*Создаем таблицу для хранения данных об успеваемости студентов progress */
CREATE TABLE progress(
    FOREIGN KEY (record_book) 
     REFERENCES students (record_book)
      ON DELETE CASCADE
      ON UPDATE CASCADE 

    record_book numeric(5) NOT NULL, -- номер зачетной книжки
    subject     text       NOT NULL, -- название предмета 
    acad_year   text       NOT NULL, -- академический год
    term        numeric(1) NOT NULL  -- номера семестра
        CHECK  (term = 1 OR term = 2),
    mark        numeric(1) NOT NULL  -- оценка 
        CHECK (mark >= 2 AND mark <= 5) DEFAULT 5,
);
```


### **Задание 2.**

> **Ответ:** Посмотрим, какие ограничения уже наложены на атрибуты таблицы «Успеваемость» (progress). 

```SQL
edu=# \d progress 
                             Таблица "public.progress"
   Столбец   |     Тип      | Правило сортировки | Допустимость NULL | По умолчанию 
-------------+--------------+--------------------+-------------------+--------------
 record_book | numeric(5,0) |                    | not null          | 
 subject     | text         |                    | not null          | 
 acad_year   | text         |                    | not null          | 
 term        | numeric(1,0) |                    | not null          | 
 mark        | numeric(1,0) |                    | not null          | 5
Ограничения-проверки:
    "progress_mark_check" CHECK (mark >= 2::numeric AND mark <= 5::numeric)
    "progress_term_check" CHECK (term = 1::numeric OR term = 2::numeric)
Ограничения внешнего ключа:
    "progress_record_book_fkey" FOREIGN KEY (record_book) REFERENCES students(record_book) ON UPDATE CASCADE ON DELETE CASCADE
```

Добавим в таблицу progress еще один атрибут — «Форма проверки знаний» (test_form), который можетпринимать только два значения: «экзамен» или «зачет». Тогда набор допустимых значений атрибута «Оценка» (mark) будет зависеть от того, экзамен или зачет предусмотрены по данной дисциплине. Если предусмотрен экзамен, тогда
допускаются значения 3, 4, 5, если зачет — тогда 0 (не зачтено) или 1 (зачтено).

```SQL
-- Добавим в таблицу progress колонку test_form
ALTER TABLE progress
 ADD COLUMN test_form text; 

-- А также дополнительное условие  
ALTER TABLE progress                         
  ADD CHECK ((test_form = 'экзамен' AND mark IN (3,4,5))
              OR 
             (test_form = 'зачет' AND mark IN (0, 1))
);
```

Проверим, как будет работать новое ограничение в модифицированной таблице progress. Для этого выполним команды INSERT, как удовлетворяющие
ограничению, так и нарушающие его.

```SQL
-- Добавим данные
INSERT INTO students 
     VALUES (24014, 'Rysistov A.V', 4524, 153335);
SELECT * FROM students;
-
-- Запись с экзаменом добавляется корректно 
INSERT INTO progress 
     VALUES (24014, 'Математический анализ', '2022-2023', 1, 5, 'экзамен'); 
SELECT * FROM progress;

/* Запись с зачетом добавляется с ошибкой, так как срабатывает проверка progress_mark_check, которое мы создавали при инициализации таблицы*/ 

INSERT INTO progress 
     VALUES (24014, 'Психология', '2021-2022', 1, 1, 'зачет'); 
/* ERROR:  new row for relation "progress" violates check constraint "progress_mark_check"*/

-- Удалим проверку progress_mark_check, так как ее полностью покрывает проверка test_form

ALTER TABLE     progress 
DROP CONSTRAINT progress_mark_check;

-- Произведем добавление данных повторно, чтобы удостовериться в том, что запрос отработает корректно

INSERT INTO progress 
     VALUES (24014, 'Психология', '2021-2022', 1, 1, 'зачет'); 
SELECT * FROM progress;
```

Добавим новое ограничение в таблицу progress на атрибут acad_year (академический год). Ограничим возможные значения столбца acad_year: теперь значения из этого столбца должны представлять собой два учебных года, написанных через дефис, причем возможные значения года лежат в диапазоне от 2000 до 2099 года включительно.

```SQL
-- Добавляем заявленную проверку
ALTER TABLE progress 
  ADD CHECK (acad_year ~ $$^20[0-9]{2}\-20[0-9]{2}$$); 

-- Протестируем установленное ограничение, добавив в таблицу корректные и некорректные примеры:
-- Корректный пример значения столбца acad_year:
INSERT INTO progress 
     VALUES (24014, 'Проектирование баз данных', '2021-2022', 1, 5, 'экзамен'); 
SELECT * FROM progress;

-- Некорректный пример значения столбца acad_year:
INSERT INTO progress 
    VALUES (24014, 'Управление IT-проектами', '2021--2022', 1, 1, 'зачет');
SELECT * FROM progress;
/*ERROR:  new row for relation "progress" violates check constraint "progress_acad_year_check"*/
```
Добавленное ограничение работает корректно. 


### **Задание 9.**

В таблице «Студенты» (students) есть текстовый атрибут name, на который наложено ограничение NOT NULL. Проверим, что будет, если при вводе новой строки в эту таблицу дать атрибуту name в качестве значения пустую строку.

```SQL
/* При добавлении пустых строчек в колонках типа text NOT NULL никаких ошибок не возникает 

Следующий запрос выполнится без ошибок и строка будет добавлена в таблицу:*/

INSERT INTO students 
     VALUES (83515, ' ', 5353, 98373); 
```

Исправим это, добавив ограничение на имя студента. 

```SQL
-- Удалим все записи из таблицы students, в которых имя является пустой строкой
DELETE * 
  FROM students 
 WHERE TRIM(name) = ''; 
-- Добавим новую проверку в таблицу
ALTER TABLE students 
  ADD CHECK (TRIM(name) <> '');

-- Попробуем произвести вставку. Теперь запрос выполнится с ошибкой.
INSERT INTO students 
     VALUES (83515, ' ', 5353, 98373);  
```

> Отметим, что такими же "слабыми местами" обладает и таблица progress, в которой также есть текстовые поля. Исправим этот недостаток, наложив ограничение на текстовые столбцы таблицы progress

```SQL
ALTER TABLE progress 
  ADD CHECK (TRIM(subject) <> '');
  ADD CHECK (TRIM(acad_year) <> '');
```

### **Задание 17.**
Подумаем, какие представления было бы целесообразно создать для нашей базы данных «Авиаперевозки». Необходимо учесть наличие различных групп пользователей, например: пилоты, диспетчеры, пассажиры, кассиры. Создайте представления и проверьте их в работе.

Создадим представление с вылетами из Москвы. Представление будет содержать следующие столбцы:
* номер рейса (flight_no);
* город отправления (departure_city)
* аэропорт отправления (departure_airport);
* город отправления (arrival_city)
* аэропорт прибытия (arrival_airport);
* время вылета по расписанию (scheduled_departure) 
* время посадки по расписанию (scheduled_arrival) 
* статус рейса (status)
* код самолета (aircraft_code)
* реальное время отправления (actual_departure)
* реальное время посадки (actual_arrival)

```SQL
CREATE OR REPLACE VIEW flights_from_Moscow AS 
    SELECT 
        temp.flight_no, 
        temp.departure_city,
        temp.departure_airport,
        aa.city as arrival_city,
        aa.airport_name as arrival_airport,        
        temp.scheduled_departure, 
        temp.scheduled_arrival, 
        temp.status, 
        temp.aircraft_code, 
        temp.actual_departure, 
        temp.actual_arrival 
      FROM (
        SELECT 
            f.flight_no, 
            a.airport_name as departure_airport, 
            f.arrival_airport, 
            a.city as departure_city,
            f.scheduled_departure, 
            f.scheduled_arrival, 
            f.status, 
            f.aircraft_code, 
            f.actual_departure, 
            f.actual_arrival 
          FROM 
            bookings.flights as f
                LEFT JOIN bookings.airports as a
                       ON f.departure_airport = a.airport_code
         WHERE a.city = 'Москва' 
    ) as temp
        LEFT JOIN bookings.airports as aa
            ON temp.arrival_airport = aa.airport_code;
```
Проверим полученное представление в действии. Выполним несколько запросов:

```SQL
-- Выберем первые 10 строк представления. Для экономии размера выводимой таблицы ограничим количество столбцов

SELECT flight_no,  departure_city, departure_airport, arrival_city, arrival_airport
FROM flights_from_Moscow
LIMIT 10;
```

**Результат запроса:**
```
 flight_no | departure_city | departure_airport |  arrival_city   | arrival_airport 
-----------+----------------+-------------------+-----------------+-----------------
 PG0405    | Москва         | Домодедово        | Санкт-Петербург | Пулково
 PG0404    | Москва         | Домодедово        | Санкт-Петербург | Пулково
 PG0405    | Москва         | Домодедово        | Санкт-Петербург | Пулково
 PG0402    | Москва         | Домодедово        | Санкт-Петербург | Пулково
 PG0405    | Москва         | Домодедово        | Санкт-Петербург | Пулково
 PG0404    | Москва         | Домодедово        | Санкт-Петербург | Пулково
 PG0403    | Москва         | Домодедово        | Санкт-Петербург | Пулково
 PG0402    | Москва         | Домодедово        | Санкт-Петербург | Пулково
 PG0405    | Москва         | Домодедово        | Санкт-Петербург | Пулково
 PG0402    | Москва         | Домодедово        | Санкт-Петербург | Пулково
(10 rows)
```

Посчитаем количество рейсов из Москвы в Санкт-Петербург:

``` SQL
SELECT count(*)
  FROM flights_from_Moscow
 WHERE departure_city = 'Москва' AND arrival_city = 'Санкт-Петербург'

-- 732
```

Посчитаем количество вылетов из каждого московского аэропорта

```SQL
SELECT   count(*), departure_airport 
  FROM   flights_from_Moscow 
GROUP BY departure_airport;
```
**Результат запроса:**
```
 count | depature_airport 
-------+------------------
  1719 | Внуково
  2981 | Шереметьево
  3217 | Домодедово
(3 rows) */
```

### **Задание 18.**

Подумаем, какие еще таблицы было бы целесообразно дополнить столбцами типа json/jsonb. Вспомните, что, например, в таблице «Билеты» (tickets) уже есть столбец такого типа — contact_data. Выполните модификации таблиц и измените в них одну-две строки для проверки правильности ваших решений.

Добавим в таблицу bookings в качестве json поля  информамцию о периоде действия брони: начало действия брони и ее окончание

```SQL
-- Добавляем столбец booking_period в таблицу bookings
ALTER TABLE bookings.bookings 
 ADD COLUMN booking_period jsonb;

-- Обновим одну из строк таблицы:
UPDATE bookings.bookings
   SET booking_period = '{"booking_start": "06.10.2020", 
                          "booking_end": "16.10.2020"}'
 WHERE book_ref='000181';


SELECT * 
  FROM bookings.bookings 
 WHERE book_ref='000181';
```

**Результат запроса:**
```
 book_ref |       book_date        | total_amount |   booking_period
----------+------------------------+--------------+-------------------------------------------------------------
 000181   | 2016-10-08 12:28:00+03 |    131800.00 | {"booking_end": "16.10.2020", "booking_start": "06.10.2020"}
(1 rows)
```
