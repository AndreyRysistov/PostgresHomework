-- ----------------------------------------------------------------------------
-- Эти таблицы, процедуры и триггеры предназначены для иллюстрации одного
-- из методов хранения иерархических структур данных в базах данных
-- реляционного типа. Этот метод -- Adjacency List (список смежности).
-- 
-- За основу принята книга: Joe Celko. Joe Celko's Trees and hierarchies
-- in SQL for smarties. Параграфы 2.3--2.6.
--
-- В указанной книге имели место опечатки и ошибки в некоторых процедурах.
-- В подобных случаях в тексте этого файла сделаны примечания. Комментарии
-- в книге были приведены на английском языке. Они сохранены, но сделаны
-- их переводы, а также добавлены дополнительные комментарии.
--
-- Книгу Joe Celko читал и комментировал Е. П. Моргунов.
-- Дата: 19 мая 2014 г.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Таблица "Персонал"
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS Personnel CASCADE;

CREATE TABLE Personnel
( emp_nbr INTEGER                   -- код работника
    DEFAULT 0 NOT NULL PRIMARY KEY,
  emp_name VARCHAR( 10 )            -- имя работника
    DEFAULT '{ {vacant} }' NOT NULL,
  address VARCHAR( 35 ) NOT NULL,   -- адрес работника
  birth_date DATE NOT NULL          -- день рождения работника
);

-- Произведем первоначальное заполнение таблицы.
INSERT INTO Personnel VALUES
( 0, 'вакансия', '',                        '2014-05-19' ),
( 1, 'Иван',     'ул. Любителей языка C',   '1962-12-01' ),
( 2, 'Петр',     'ул. UNIX гуру',           '1965-10-21' ),
( 3, 'Антон',    'ул. Ассемблерная',        '1964-04-17' ),
( 4, 'Захар',    'ул. им. СУБД PostgreSQL', '1963-09-27' ),
( 5, 'Ирина',    'просп. Программистов',    '1968-05-12' ),
( 6, 'Анна',     'пер. Перловый',           '1969-03-20' ),
( 7, 'Андрей',   'пл. Баз данных',          '1945-11-07' ),
( 8, 'Николай',  'наб. ОС Linux',           '1944-12-01' );


-- ----------------------------------------------------------------------------
-- Таблица "Организационная структура"
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS Org_chart CASCADE;

CREATE TABLE Org_chart
( job_title VARCHAR( 30 )  -- наименование должности
    NOT NULL PRIMARY KEY,  
  emp_nbr INTEGER          -- код работника
    DEFAULT 0 NOT NULL     -- 0 означает вакантную должность
    REFERENCES Personnel( emp_nbr )    -- внешний ключ
      ON DELETE SET DEFAULT
      ON UPDATE CASCADE
      -- Это ограничение будет отключаться при выполнении одной
      -- из хранимых процедур, поэтому DEFERRABLE.
      DEFERRABLE,
  boss_emp_nbr INTEGER     -- код начальника данного работника
    DEFAULT 0
    -- Поскольку null означает корень иерархии, то ограничение NOT NULL
    -- вводить не будем.
    REFERENCES Personnel( emp_nbr )    -- внешний ключ
      ON DELETE SET DEFAULT
      ON UPDATE CASCADE
      -- Это ограничение будет отключаться при выполнении одной
      -- из хранимых процедур, поэтому DEFERRABLE.
      DEFERRABLE,
  salary DECIMAL( 12, 4 )  -- зарплата работника, занимающего эту должность
    NOT NULL CHECK ( salary >= 0.00 ),
  -- Работник не может быть сам себе начальником, т. е. код работника 
  -- не должен совпадать с кодом начальника);
  -- если должность не занята, то код работника и код начальника равны 0.
  CHECK ( ( boss_emp_nbr <> emp_nbr ) OR 
          ( boss_emp_nbr = 0 AND emp_nbr = 0 )
        ),
  -- Longer cycles are prevented with a UNIQUE (emp, boss) constraint that
  -- limits an employee to one (and only one) boss.
  -- Длинные циклы предотвращаются с помощью ограничения UNIQUE (emp, boss),
  -- которое ограничивает число начальников у данного работника числом 1.
  -- ПРИМЕЧАНИЕ. Уберем это ограничение, поскольку оно не обепечивает
  -- выполнение условия, согласно которому у работника может быть только один
  -- начальник?
  -- UNIQUE ( emp_nbr, boss_emp_nbr ) DEFERRABLE,

  -- Без этого внешнего ключа возможна ситуация, когда удаляется запись,
  -- значение поля emp_nbr которой используется в качестве значения
  -- поля boss_emp_nbr в других записях. Другими словами, работник, которого
  -- нет в орг. структуре, является начальником других работников, 
  -- присутствующих в орг. структуре (ограничение добавлено мною. -- Е. М.).
  FOREIGN KEY ( boss_emp_nbr )
    REFERENCES Org_chart ( emp_nbr )
    ON DELETE SET DEFAULT
    ON UPDATE CASCADE
    DEFERRABLE,

  -- Пришлось добавить и это ограничение, иначе внешний ключ 
  -- FOREIGN KEY ( boss_emp_nbr ) создать невозможно.
  UNIQUE ( emp_nbr )  

  -- Подзапросы в ограничениях CHECK в СУБД PostgreSQL не работают,
  -- поэтому закомментируем их. Проверки же перенесем в триггеры и хранимые
  -- процедуры.

  -- We know that the number of edges in a tree is the number of nodes minus
  -- one, therefore this is a connected graph. That constraint looks like this:
  -- Мы знаем, что число ребер в дереве равно числу узлов минус 1, вследствие
  -- этого получается связанный граф. Получаем такое ограничение:
  --  CHECK ( ( SELECT COUNT( * ) FROM Org_chart ) - 1              -- узлы
  --          = ( SELECT COUNT( boss_emp_nbr ) FROM Org_chart ) )   -- ребра
  -- The COUNT (boss_emp_nbr) will drop the NULL in the root row. That
  -- gives us the effect of having a constraint to check for one NULL:
  -- Выражение COUNT (boss_emp_nbr) не учитывает NULL в корневой записи, что
  -- дает нам эффект проверки налчиия только одного знаыения NULL в таблице.
  -- CHECK ( ( SELECT COUNT( * ) FROM Org_chart 
  --           WHERE boss_emp_nbr IS NULL ) = 1 )
);

-- Произведем первоначальное заполнение таблицы.
-- Обратите внимание, что у главы компании нет начальника -- значение NULL.
INSERT INTO Org_chart VALUES
( 'Президент',           1, NULL, 1000.00 ),
( 'Вице-президент 1',    2, 1,    900.00 ),
( 'Вице-президент 2',    3, 1,    800.00 ),
( 'Архитектор',          4, 3,    700.00 ),
( 'Ведущий программист', 5, 3,    600.00 ),
( 'Программист C',       6, 3,    500.00 ),
( 'Программист Perl',    7, 5,    450.00 ),
( 'Оператор',            8, 5,    400.00 );


-- ----------------------------------------------------------------------------
-- Параграф 2.3.
-- Создание триггера для обеспечения целостности БД.
-- ----------------------------------------------------------------------------

-- Сначала создадим хранимую процедуру.
CREATE OR REPLACE FUNCTION check_org_chart() RETURNS trigger AS
$$
BEGIN
  -- Эта функция только не позволяет сделать две и более записи
  -- с идентификатором босса, равным null, но против зацикливаний она 
  -- бессильна.

  -- Это условие не позволяет удалить из таблицы последнюю запись
  -- (главный босс должен быть всегда -- это так и нужно?)
  -- ПРИМЕЧАНИЕ. Условие COUNT( boss_emp_nbr ) подсчитывает только
  -- те записи, у которых значение поля boss_emp_nbr не равно NULL. 
  -- Условие COUNT( * ) подсчитывает все записи.
  IF ( SELECT COUNT( * ) FROM Org_chart ) - 1 <>
     ( SELECT COUNT( boss_emp_nbr ) FROM Org_chart )
  THEN
    RAISE EXCEPTION 'Bad orgchart structure';
  ELSE
    -- В зависимости от вида операции (встроенная переменная TG_OP) с таблицей
    -- возвратим либо старую (OLD), либо новую (NEW) версии строки таблицы.
    IF ( TG_OP = 'DELETE' ) THEN
      RETURN OLD;
    ELSIF ( TG_OP = 'UPDATE' ) THEN
      RETURN NEW;
    ELSIF ( TG_OP = 'INSERT' ) THEN
      RETURN NEW;
    END IF;
    RETURN NULL;
  END IF;
END;
$$
LANGUAGE plpgsql;

-- Создадим триггер, который использует эту хранимую процедуру
-- (предварительно удалим его, если он уже существует).
DROP TRIGGER IF EXISTS check_org_chart ON Org_chart;

-- Триггер выполняется после каждой операции с таблицей.
-- Он выполняется для КАЖДОЙ обрабатываемой строки таблицы.
CREATE TRIGGER check_org_chart
AFTER INSERT OR UPDATE OR DELETE ON Org_chart
    FOR EACH ROW EXECUTE PROCEDURE check_org_chart();


-- ----------------------------------------------------------------------------
-- Параграфы 2.3--2.6.
-- Хранимые процедуры для работы с иерархией.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- Функция для проверки структуры дерева на предмет отсутствия циклов.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION tree_test() RETURNS CHAR( 6 ) AS
$$
BEGIN
  -- Такой способ предлагал J. Celko:
  -- put a copy in a temporary table
  --  INSERT INTO Tree SELECT emp, boss FROM Org_chart;

  -- Создадим временную таблицу на основе иерархии должностей.
  CREATE TEMP TABLE Tree ON COMMIT DROP AS
    SELECT emp_nbr, boss_emp_nbr FROM Org_chart;

  -- prune the leaves
  -- Удаляем листья дерева. Условие означает следующее:
  --  SELECT COUNT( * ) -- общее фактическое число узлов
  --  дерева, т. к. каждая запись в таблице соответствует
  --  одному узлу;
  --  SELECT COUNT( * ) - 1 -- теоретическое число ребер
  --  дерева, которое должно быть на 1 меньше фактического
  --  числа узлов;
  --  SELECT COUNT( boss_emp_nbr ) -- число записей, для которых
  --  значение поля boss_emp_nbr не равно NULL (см. описание функции
  --  COUNT()), должно быть ровно на 1 меньше, чем COUNT( * ),
  --  т. к. только у одного работника значение поля
  --  boss_emp_nbr может быть равно NULL -- это глава организации.
  WHILE ( SELECT COUNT( * ) FROM Tree ) - 1
          = ( SELECT COUNT( boss_emp_nbr ) FROM Tree )
  LOOP 
    -- Удаляем записи (строки) о работниках, которые не являются
    -- начальниками ни для одного из других работников
    -- (в подзапросе выбираются все начальники).
    DELETE 
    FROM Tree
    WHERE Tree.emp_nbr NOT IN ( SELECT T2.boss_emp_nbr
                                FROM Tree AS T2
                                WHERE T2.boss_emp_nbr IS NOT NULL );
  END LOOP;   -- команда перенесена сюда мною (Е. М.)

  -- Эта проверка должна выполняться уже после завершения удаления
  -- записей из таблицы Tree. Если записей не осталось, значит, дерево
  -- связанное.
  IF NOT EXISTS ( SELECT * FROM Tree )
  THEN
    RETURN ( 'Tree' );
  -- Если хоть одна запись осталась, значит, в дереве есть циклы.
  ELSE
    RETURN ( 'Cycles' );
  END IF;
  -- Команда ограничения тела цикла была здесь (Е. М.) --
  -- это не работает: получаем результат 'Cycles' на "правильном" дереве.
  -- END LOOP;
END;
$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- Функция для обхода дерева снизу вверх, начиная с конкретного узла.
-- ВАРИАНТ 1.
-- Параграф. 2.4.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION up_tree_traversal( IN current_emp_nbr INTEGER )
  RETURNS TABLE( emp_nbr INTEGER, boss_emp_nbr INTEGER ) AS
$$
BEGIN
  -- Выбираем запись для текущего работника. На первой итерации это будет
  -- работник, с которого начинается обход дерева вверх.
  WHILE EXISTS ( SELECT * 
                 FROM Org_chart AS O
                 WHERE O.emp_nbr = current_emp_nbr )
  LOOP              
    -- take some action on the current node of the traversal
    -- Если нужно, то выполним какое-либо действие для текущего узла дерева
    -- (т. е. для текущего работника). Для этого нужно процедуру SomeProc
    -- заменить на какую-то полезную процедуру.
    -- CALL SomeProc (current_emp_nbr);

    -- Добавим очередную пару (работник; начальник) к формируемому
    -- множеству таких пар.
    -- ПРИМЕЧАНИЕ. Этот оператор RETURN не завершает выполнение процедуры,
    -- а лишь ДОБАВЛЯЕТ очередную запись (строку) к результирующей таблице.
    RETURN QUERY SELECT O.emp_nbr, O.boss_emp_nbr 
                 FROM Org_chart AS O
                 WHERE O.emp_nbr = current_emp_nbr;

    -- go up the tree toward the root
    -- Идем вверх по дереву к корню. Теперь текущим работником становится
    -- начальник только что обработанного работника, тем самым мы перемещаемся
    -- на один уровень вверх по дереву. Когда текущим работником станет 
    -- главный начальник, у которого уже нет начальника, тогда результатом 
    -- этого запроса будет current_emp_nbr = NULL, в результате чего
    -- условие цикла будет не выполнено, и цикл завершится.
    current_emp_nbr = ( SELECT O.boss_emp_nbr
                        FROM Org_chart AS O
                        WHERE O.emp_nbr = current_emp_nbr );
  END LOOP;
END;
$$
LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- Функция для обхода дерева снизу вверх, начиная с конкретного узла.
-- ВАРИАНТ 2.
-- Параграф. 2.4.
-- Этот вариант отличается только типом возвращаемого значения.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION up_tree_traversal2( IN current_emp_nbr INTEGER )
  RETURNS SETOF RECORD AS
$$
DECLARE
  rec RECORD;
BEGIN
  -- Выбираем запись для текущего работника. На первой итерации это будет
  -- работник, с которого начинается обход дерева вверх.
  WHILE EXISTS ( SELECT * 
                 FROM Org_chart AS O
                 WHERE O.emp_nbr = current_emp_nbr )
  LOOP              
    -- take some action on the current node of the traversal
    -- Если нужно, то выполним какое-либо действие для текущего узла дерева
    -- (т. е. для текущего работника). Для этого нужно процедуру SomeProc
    -- заменить на какую-то полезную процедуру.
    -- CALL SomeProc (current_emp_nbr);

    -- Добавим очередную пару (работник; начальник) к формируемому
    -- множеству таких пар.
    SELECT O.emp_nbr, O.boss_emp_nbr 
    INTO rec
    FROM Org_chart AS O
    WHERE O.emp_nbr = current_emp_nbr;

    -- ПРИМЕЧАНИЕ. Этот оператор RETURN не завершает выполнение процедуры,
    -- а лишь ДОБАВЛЯЕТ очередную запись к результирующему множеству.
    RETURN NEXT rec;
    
    -- go up the tree toward the root
    -- Идем вверх по дереву к корню. Теперь текущим работником становится
    -- начальник только что обработанного работника, тем самым мы перемещаемся
    -- на один уровень вверх по дереву. Когда текущим работником станет 
    -- главный начальник, у которого уже нет начальника, тогда результатом 
    -- этого запроса будет current_emp_nbr = NULL, в результате чего
    -- условие цикла будет не выполнено, и цикл завершится.
    current_emp_nbr = ( SELECT O.boss_emp_nbr
                        FROM Org_chart AS O
                        WHERE O.emp_nbr = current_emp_nbr );
  END LOOP;
  RETURN;
END;
$$
LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- Функция для удаления поддерева.
-- п. 2.6.1
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION Delete_subtree( IN dead_guy INTEGER )
  RETURNS VOID AS
$$
-- параметр dead_guy -- код работника, возглавляющего поддерево.
BEGIN
  -- Создадим врЕменную последовательность. Она нужна для того, чтобы
  -- формировать отрицательные значения для полей emp_nbr и boss_emp_nbr.
  -- У J. Celko использовалось значение -99999, которое записывалось
  -- в поля emp_nbr и boss_emp_nbr удаляемых записей. Это значение служило
  -- меткой удаляемой записи. Но мы добавили ограничение UNIQUE ( emp_nbr )
  -- в таблицу Org_chart. Поэтому теперь уже стало невозможно иметь более
  -- одной записи со значением поля emp_nbr равным -99999. Мы вынуждены
  -- записывать в это поле РАЗЛИЧНЫЕ значения в разных записях таблицы
  -- Org_chart. А такие значения удобно формировать, используя 
  -- последовательность.
  CREATE TEMP SEQUENCE New_emp_nbr START WITH 1;

  -- Создадим временную таблицу.
  -- В книге эта таблица имела два поля, но поле boss_emp_nbr не используется.
  -- CREATE TEMP TABLE Working_table ( boss_emp_nbr INTEGER,
  --                                   emp_nbr INTEGER NOT NULL )
  CREATE TEMP TABLE Working_table ( emp_nbr INTEGER NOT NULL )
    ON COMMIT DROP;

  -- Отложим проверку всех ограничений FOREIGN KEY до конца транзакции,
  -- иначе СУБД не позволит нам выполнять обновления полей emp_nbr и 
  -- boss_emp_nbr: мы будем записывать в них отрицательные значения, 
  -- а этих значений нет в таблице Personnel, на которую ссылается
  -- таблица Org_chart.
  SET CONSTRAINTS org_chart_emp_nbr_fkey, org_chart_boss_emp_nbr_fkey,
                  org_chart_boss_emp_nbr_fkey1
    DEFERRED;

  -- mark root of subtree and immediate subordinates
  -- Пометим корень удаляемого поддерева и всех непосредственных
  -- подчиненных путем записи в поле emp_nbr или в поле boss_emp_nbr
  -- отрицательного значения, формируемого с помощью последовательности.
  UPDATE Org_chart
  SET emp_nbr = CASE WHEN emp_nbr = dead_guy
                     THEN nextval( 'New_emp_nbr' ) * -1
                     ELSE emp_nbr
                END,
      boss_emp_nbr = CASE WHEN boss_emp_nbr = dead_guy
                     THEN nextval( 'New_emp_nbr' ) * -1
                     ELSE boss_emp_nbr
                END
  -- Условие WHERE означает, что выбираются лишь записи, в которых
  -- либо в поле emp_nbr, либо в поле boss_emp_nbr стоит значение 
  -- идентификатора "главы" удаляемого поддерева.
  WHERE dead_guy IN ( emp_nbr, boss_emp_nbr );

  -- mark leaf nodes
  -- Помечаем листья дерева, т. е. записи для работников, не являющихся
  -- начальниками для других работников.
  WHILE EXISTS ( SELECT * FROM Org_chart
                 WHERE boss_emp_nbr < 0 AND emp_nbr >= 0 )
  LOOP
    -- get list of next level subordinates
    -- Получим список подчиненных следующего уровня.

    -- Сначала удалим все записи из временной таблицы.
    DELETE FROM Working_table;
    
    -- Выбираем подчиненных.
    INSERT INTO Working_table
      SELECT emp_nbr FROM Org_chart
      WHERE boss_emp_nbr < 0;

    -- mark next level of subordinates
    -- Пометим следующий уровень подчиненных.
    -- Это оригинальная команда из книги J. Celko:
    --    UPDATE Org_chart
    --    SET emp_nbr = -99999
    --    WHERE boss_emp_nbr IN ( SELECT emp_nbr FROM Working_table );
    -- Получаем очередное число из последовательности и умножаем его на -1,
    -- поскольку нам нужны отрицательные коды работников, т. к. именно
    -- отрицательные значения являются меткой удаляемой записи.
    UPDATE Org_chart
    SET emp_nbr = nextval( 'New_emp_nbr' ) * -1
    WHERE emp_nbr IN ( SELECT emp_nbr FROM Working_table );

    -- Помечаем начальников следующего уровня (при движении вниз по дереву)
    -- (этой команды в книге J. Celko не было).
    UPDATE Org_chart
    SET boss_emp_nbr = nextval( 'New_emp_nbr' ) * -1
    WHERE boss_emp_nbr IN ( SELECT emp_nbr FROM Working_table );
  END LOOP;

  -- delete all marked nodes
  -- Удаляем все помеченные узлы.
  -- В книге J. Celko было так:
  --   DELETE FROM Org_chart WHERE emp_nbr = -99999;
  DELETE FROM Org_chart WHERE emp_nbr < 0;

  -- Снова активизируем все ограничения.
  SET CONSTRAINTS ALL IMMEDIATE;

  -- Удалим врЕменную последовательность.
  DROP SEQUENCE New_emp_nbr;
END;
$$
LANGUAGE plpgsql;


-- ----------------------------------------------------------------------------
-- Представление (VIEW) для реконструирования организационной структуры.
-- Параграф 2.3.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS Personnel_org_chart CASCADE;

CREATE VIEW Personnel_org_chart
 ( emp_nbr, emp, boss_emp_nbr, boss ) AS
  -- В книге ошибка: вместо O1.boss_emp_nbr написано E1.boss_emp_nbr
  --  SELECT E1.emp_nbr, E1.emp_name, E1.boss_emp_nbr, B1.emp_name
  --  SELECT E1.emp_nbr, E1.emp_name, O1.boss_emp_nbr, B1.emp_name
  --  FROM Personnel AS E1, Personnel AS B1, Org_chart AS O1
  -- В книге ошибка: в условии WHERE вместо O1 написано P1
  --  WHERE B1.emp_nbr = P1.boss_emp_nbr AND
  --        E1.emp_nbr = P1.emp_nbr;
  --  WHERE B1.emp_nbr = O1.boss_emp_nbr AND
  --        E1.emp_nbr = O1.emp_nbr;
  -- В книге неудачно расположены имена таблиц в фразе FROM
  -- и в условии WHERE.

  -- Мой вариант (за основу принимается таблица Org_chart).
  -- ПРИМЕЧАНИЕ. LEFT OUTER JOIN необходим, т. к. у руководителя организации
  -- нет начальника и значение поля boss_emp_nbr у него NULL.
  SELECT O1.emp_nbr, E1.emp_name, O1.boss_emp_nbr, B1.emp_name
  FROM ( Org_chart AS O1 LEFT OUTER JOIN Personnel AS B1 
         ON O1.boss_emp_nbr = B1.emp_nbr ), Personnel AS E1
  WHERE O1.emp_nbr = E1.emp_nbr;


-- ----------------------------------------------------------------------------
-- Построение всех путей сверху дерева вниз
-- (только для четырех уровней иерархии)
-- Параграф 2.4.2.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS Create_paths;

CREATE VIEW Create_paths ( level1, level2, level3, level4 ) AS
  SELECT O1.emp AS e1, O2.emp AS e2, O3.emp AS e3, O4.emp AS e4
  FROM Personnel_org_chart AS O1
  LEFT OUTER JOIN Personnel_org_chart AS O2 ON O1.emp = O2.boss
  LEFT OUTER JOIN Personnel_org_chart AS O3 ON O2.emp = O3.boss 
  LEFT OUTER JOIN Personnel_org_chart AS O4 ON O3.emp = O4.boss
  -- Если закомментировать условие WHERE, тогда будут построены
  -- цепочки, начинающиеся с каждого работника, а не только с главного
  -- руководителя.
  WHERE O1.emp = 'Иван';


-- ----------------------------------------------------------------------------
-- Функция для удаления элемента иерархии и продвижения
-- дочерних элементов на один уровень вверх (т. е. к "бабушке").
-- Параграф 2.6.3.
-- Мой вариант.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION Delete_and_promote_subtree( IN dead_guy INTEGER )
  RETURNS VOID AS
$$
-- параметр dead_guy -- код работника, возглавляющего поддерево.
BEGIN
  -- Назначить нового начальника всем непосредственным подчиненным
  -- удаляемого работника.
  UPDATE Org_chart
  -- Получим код начальника для удаляемого работника.
  SET boss_emp_nbr = ( SELECT boss_emp_nbr
                       FROM Org_chart
                       WHERE emp_nbr = dead_guy
                     )
  WHERE boss_emp_nbr = dead_guy;

  -- Теперь удаляем работника. Все его подчиненные уже переподчинены
  -- вышестоящему начальнику.
  DELETE FROM Org_chart WHERE emp_nbr = dead_guy;
END;
$$
LANGUAGE plpgsql;
