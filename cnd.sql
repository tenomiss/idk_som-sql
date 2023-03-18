CREATE TABLE employees (
    employee_id   NUMERIC       NOT NULL,
    first_name    VARCHAR(1000) NOT NULL,
    last_name     VARCHAR(900)  NOT NULL,
    date_of_birth DATE                   ,
    phone_number  VARCHAR(1000) NOT NULL,
    junk          CHAR(1000)             ,
    CONSTRAINT employees_pk
       PRIMARY KEY NONCLUSTERED (employee_id)
);
GO
IF OBJECT_ID('rand_helper') IS NOT NULL
   DROP VIEW rand_helper;
GO

CREATE VIEW rand_helper AS SELECT RND=RAND();
GO
IF OBJECT_ID('random_string') IS NOT NULL
   DROP FUNCTION random_string;
GO

CREATE FUNCTION random_string (@maxlen int)
   RETURNS VARCHAR(255)
AS BEGIN
   DECLARE @rv VARCHAR(255)
   DECLARE @loop int
   DECLARE @len int

   SET @len = (SELECT CAST(rnd * (@maxlen-3) AS INT) + 3
                 FROM rand_helper)
   SET @rv = ''
   SET @loop = 0

   WHILE @loop < @len BEGIN
      SET @rv = @rv 
              + CHAR(CAST((SELECT rnd * 26
                             FROM rand_helper) AS INT )+97)
      IF @loop = 0 BEGIN
          SET @rv = UPPER(@rv)
      END
      SET @loop = @loop +1;
   END

   RETURN @rv
END
GO
IF OBJECT_ID('random_date') IS NOT NULL
   DROP FUNCTION random_date;
GO

CREATE FUNCTION random_date (@mindays int, @maxdays int) 
   RETURNS VARCHAR(255)
AS BEGIN
   DECLARE @rv date
   SET @rv = (SELECT GetDate() 
                   - rnd * (@maxdays-@mindays)
                   - @mindays
                FROM rand_helper)
   RETURN @rv
END
GO
IF OBJECT_ID('random_int') IS NOT NULL
   DROP FUNCTION random_int;
GO

CREATE FUNCTION random_int (@min int, @max int)
   RETURNS INT
AS BEGIN
   DECLARE @rv INT
   SET @rv = (SELECT rnd * (@max) + @min
                FROM rand_helper)
   RETURN @rv
END
GO
WITH generator (n) AS
( SELECT 1
   UNION ALL
  SELECT n + 1 FROM generator
WHERE n < 1000
)
INSERT INTO employees (employee_id
                     , first_name, last_name
                     , date_of_birth, phone_number, junk)
select n employee_id
     , [dbo].random_string(11) first_name
     , [dbo].random_string(11) last_name  
     , [dbo].random_date(20*365, 60*365) dob
     , 'N/A' phone
     , 'junk' junk
  from generator
OPTION (MAXRECURSION 1000)
GO
UPDATE employees 
   SET first_name='Markus', 
       last_name='Winand'
 WHERE employee_id=123;

exec sp_updatestats;
GO

ALTER TABLE employees ADD subsidiary_id NUMERIC;
GO
UPDATE      employees SET subsidiary_id = 30;
GO
ALTER TABLE employees ALTER COLUMN subsidiary_id 
                                   NUMERIC NOT NULL;
GO

ALTER TABLE employees DROP CONSTRAINT employees_pk;
GO
ALTER TABLE employees ADD  CONSTRAINT employees_pk 
      PRIMARY KEY NONCLUSTERED (employee_id, subsidiary_id);
GO


WITH generator (n) as
( select 1
union all
select n + 1 from generator
where N < 9000
)
INSERT INTO employees (employee_id
                     , first_name, last_name
                     , date_of_birth, phone_number
                     , junk, subsidiary_id)
SELECT n employee_id
     , [dbo].random_string(11) first_name
     , [dbo].random_string(11) last_name  
     , [dbo].random_date(20*365, 60*365) dob
     , 'N/A' phone
     , 'junk' junk
     , [dbo].random_int(1, (n*29)/9000) subsidiary_id
  FROM generator
OPTION (MAXRECURSION 9000)
GO

CREATE UNIQUE NONCLUSTERED INDEX 
       employees_pk_tmp 
       on employees (employee_id, subsidiary_id);
GO
ALTER TABLE employees DROP CONSTRAINT employees_pk;
GO
ALTER TABLE employees ADD CONSTRAINT employees_pk
      PRIMARY KEY NONCLUSTERED (employee_id, subsidiary_id);
GO
DROP INDEX employees_pk_tmp ON employees;
GO

exec sp_updatestats;
GO

CREATE NONCLUSTERED INDEX 
       emp_sub_id ON employees (subsidiary_id);

exec sp_updatestats;

ALTER TABLE employees DROP CONSTRAINT employees_pk;
GO
ALTER TABLE employees ADD  CONSTRAINT employees_pk 
      PRIMARY KEY NONCLUSTERED (subsidiary_id, employee_id);
GO

DROP INDEX emp_sub_id ON employees;

exec sp_updatestats;

CREATE TABLE messages (
     id numeric not null,
     processed char(1) not null,
     receiver numeric not null,
     message varchar(255),
     primary key (id)
);

WITH generator (n) AS
( SELECT 1
   UNION ALL
  SELECT n + 1 FROM generator
WHERE n < 1000
)
INSERT INTO messages (id, processed, receiver, message)
select n id
     , case WHEN n % 5 =0 then 'N' else 'Y' end 
     , n/10 receiver
     , 'junk' message
  from generator
OPTION (MAXRECURSION 1000)

-- regular index
--CREATE INDEX messages_todo
--          ON messages (receiver, processed) INCLUDE (message);

-- filtered index
CREATE INDEX messages_only_todo
          ON messages (receiver) INCLUDE (message)
       WHERE processed = 'N';


declare @r numeric
set @r = 4

SELECT message
   FROM messages
  WHERE processed = 'N'
    AND receiver  = @r;