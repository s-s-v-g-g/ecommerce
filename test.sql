CREATE DATABASE test;
USE test;
CREATE TABLE table_test
(
    column_1 INT PRIMARY KEY,
    column_2 NVARCHAR(4) UNIQUE,
    column_3 DATE
);

SELECT * FROM table_test;

INSERT INTO table_test (column_1, column_2, column_3)
VALUES (1, '第一行', '2025-05-09'),
	   (2, '第二行', '2025-05-10'),
	   (3, '第三行', '2025-05-11');
       
SELECT * FROM table_test;