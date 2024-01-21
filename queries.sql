/*
1 - Get all columns from a table
*/
USE sqldatabase;
SELECT * FROM Employees

/*
2 - Get some columns from a table
*/
USE sqldatabase;
SELECT first_name, last_name, tenure, deparment FROM Employees

/*
3 - Get all columns from a table with one text filter
*/
USE sqldatabase;
SELECT * FROM Sales
WHERE continent = "Europe"

/*
4 - Get all columns from a table with several text filters
*/
USE sqldatabase;
SELECT * FROM Sales
WHERE country IN ("USA", "CA", "MX") -- NOT IN

/*
5 - Get all columns from a table with numeric filters
*/
USE sqldatabase;
SELECT * FROM Sales
WHERE total > 10000 -- <, >=, <=, =, !=, <>

/*
6 - Get all columns from a table with several filters (AND)
*/
USE sqldatabase;
SELECT * FROM Customers
WHERE membership = 1
AND total > 20000

/*
7 - Get all columns from a table with several filters (OR)
*/
USE sqldatabase;
SELECT * FROM Incidents
WHERE ticket_resolved != "Resolved"
OR incident = "Recent"

/*
8 - Get all columns from a table with a time interval
*/
SELECT * FROM Sales
WHERE transaction_date >= "2024-1-1" AND transaction_date <= CURDATE() -- NOW(), DAY(), MONTH(), YEAR(), DAYNAME(), MONTHNAME()

/*
9 - Get some columns and create one condicional column from a table (IF)
*/
USE sqldatabase;
SELECT first_name, IF(total>100000, "In target", "Out of target") AS employeePerformance FROM Sales

/*
10 - Get some columns and create one condicional column from a table (CASE)
*/
USE sqldatabase;
SELECT first_name, 
CASE
WHEN leads_close < 20 THEN 0
WHEN leads_close BETWEEN 20 AND 30 THEN 1000
WHEN leads_close > 30 THEN 2000
ELSE "Wrong Number" END AS Bonus_amount FROM Sales

/*
11 - Get some columns and all codes that starts with...
*/
USE sqldatabase;
SELECT code FROM Incidents
WHERE code LIKE "%ASC" -- "ASC%"

/*
12 - Get the top sellers
*/
USE sqldatabase;
SELECT first_name, total_sales FROM Sales
ORDER BY total_sales ASC
LIMIT 5

/*
13 - Get the employee list alphabetically
*/
USE sqldatabase;
SELECT last_name, first_name, age FROM Employees
ORDER BY last_name DESC, first_name DESC, age ASC

/*
14 - Exclude all the nulls values
*/
USE sqldatabase;
SELECT incident, current_status FROM Incidents
WHERE current_status IS NOT NULL -- IS NULL

/*
15 - Getting the best and worst seller
*/
USE sqldatabase;
SELECT first_name FROM Sales
ORDER BY total DESC
LIMIT 1
UNION
SELECT first_name FROM Sales
ORDER BY total ASC
LIMIT 1

/*
16 - Get some columns and create a column from a table
*/
USE sqldatabase;
SELECT supplier_name, CONCAT(country,zip,current_status) AS unique_code FROM Suppliers

/*
17 - Get some columns and a same format column
*/
USE sqldatabase;
SELECT supplier_name, UPPER(country), TRIM(current_status) AS country FROM Suppliers -- LOWER(), LTRIM(), RTRIM()

/*
18 - Get some columns and the first tree letter of a code
*/
USE sqldatabase;
SELECT supplier_name, LEFT(unique_code, 3) AS country FROM Suppliers -- RIGHT(), SUBSTRING()

/*
19 - Get some columns and rounding the discount
*/
USE sqldatabase;
SELECT first_name, total, ROUND(discount) AS discount, total-discount AS total_disc FROM Customers -- CEILING(), FLOOR(), ABS()

/*
20 - Get some columns and aggregations columns from a table, grouping and filtering
*/
USE sqldatabase;
SELECT supplier_name, SUM(sales) AS sum_sales FROM Suppliers -- AVG(), MAX(), MIN(), COUNT(), COUNT(DISTINCT)
GROUP BY supplier_name WITH ROLLUP
HAVING sum_sales > 50000

/*
21 - Get some columns from different tables
*/
USE sqldatabase;
SELECT a.supplier_name, b.location, c.industry_name from Supplier a
JOIN Locations b ON a.locationID = b.locationID -- FULL JOIN, LEFT JOIN, RIGHT JOIN, CROSS JOIN
JOIN Industry c USING(industryID)

/*
22 - Getting all sellers above the average on sales
*/
USE sqldatabase;
SELECT first_name, SUM(sales) AS total_sales, AVG(sales) AS AverageSales FROM Sellers
WHERE total_sales > (SELECT AVG(sales) from Sellers)

/*
23 - Getting all sellers that had a sale
*/
USE sqldatabase;
SELECT first_name, SUM(sales) AS total_sales FROM Sellers
WHERE employee_ID IN (SELECT employee_ID from Employees) --EXISTS

/*
24 - Getting all expenses by some deparments higher than 5 000 000 ordered from highest to smallest 
*/
USE sqldatabase;
SELECT a.deparment, SUM(b.expense_amount) AS total_expense FROM Deparments a
JOIN Expenses b ON a.deparmentID = b.deparmentID
WHERE a.deparment IN ("HR", "Accounting", "Operations", "Management")
GROUP BY a.deparment
HAVING total_expense > 5000000
ORDER BY total_expense DESC

/*
25 - Creating a view for a repetitive query
*/
CREATE VIEW SalesLast30Days AS
SELECT SUM(sales) FROM Sales
WHERE transaction_date >= CURDATE() - INTERVAL 30 DAY AND transaction_date <= CURDATE