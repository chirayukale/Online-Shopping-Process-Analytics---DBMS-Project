CREATE DATABASE miniproject_dbms2;
USE miniproject_dbms2;

--  DBMS II - Mini Project


-- 1.Join all the tables and create a new table called combined_table.
-- (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)

CREATE TABLE combined_table AS (SELECT mf.*, sd.order_id, sd.ship_mode, sd.ship_date, cd.customer_name, cd.province, cd.region, cd.customer_segment, 
od.order_date, od.order_priority, pd.product_category, pd.product_sub_category FROM market_fact AS mf JOIN shipping_dimen AS sd ON sd.ship_id = mf.ship_id 
JOIN cust_dimen AS cd ON mf.cust_id = cd.cust_id JOIN orders_dimen AS od ON od.ord_id = mf.ord_id JOIN prod_dimen AS pd ON pd.prod_id = mf.prod_id);

SELECT * FROM combined_table;

-- 2.Find the top 3 customers who have the maximum number of orders


SELECT cust_id, SUM(order_quantity) AS total_orders FROM combined_table GROUP BY cust_id 
ORDER BY total_orders DESC LIMIT 3;

-- 3.Create a new column DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.

SELECT * FROM (SELECT mf.*, order_date, ship_date, DATEDIFF(str_to_date(ship_date, '%d-%m-%Y'), str_to_date(order_date, '%d-%m-%Y')) AS daysfordelivery FROM market_fact as mf
JOIN shipping_dimen AS sd ON mf.ship_id = sd.ship_id JOIN orders_dimen AS o ON o.ord_id = mf.ord_id) AS f;


-- 4.Find the customer whose order took the maximum time to get delivered.

SELECT c.Customer_Name, a.order_date, b.ship_date, DATEDIFF(b.ship_date, a.order_date) daysfordelivery FROM orders_dimen AS a JOIN shipping_dimen AS b USING(order_id)
LEFT JOIN market_fact USING(ord_id) JOIN cust_dimen c USING(cust_id) ORDER BY daysfordelivery DESC LIMIT 1;

-- 5.Retrieve total sales made by each product from the data (use Windows function)

SELECT DISTINCT prod_id, SUM(sales) OVER(PARTITION BY prod_id) AS total_sales FROM market_fact;

-- 6.Retrieve total profit made from each product from the data (use windows function)

SELECT DISTINCT prod_id, SUM(profit) OVER(PARTITION BY prod_id) AS total_profit FROM market_fact;

-- 7.Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011

SELECT COUNT(DISTINCT cust_id) AS "unique customers in jan" FROM market_fact JOIN orders_dimen USING(ord_id) WHERE order_date LIKE '%-01-2011';

SELECT cust_id, COUNT(cust_id), GROUP_CONCAT(order_date) AS alldates FROM market_fact JOIN orders_dimen USING(ord_id) GROUP BY cust_id 
HAVING alldates LIKE '%-01-2011%' AND
alldates LIKE "%-02-2011%" AND
alldates LIKE "%-03-2011%" AND
alldates LIKE "%-04-2011%" AND
alldates LIKE "%-05-2011%" AND
alldates LIKE "%-06-2011%" AND
alldates LIKE "%-07-2011%" AND
alldates LIKE "%-08-2011%" AND
alldates LIKE "%-09-2011%" AND
alldates LIKE "%-10-2011%" AND
alldates LIKE "%-11-2011%" AND
alldates LIKE "%-12-2011%";

/* 8.Retrieve month-by-month customer retention rate since the start of the business.(using views)

Tips: 
#1: Create a view where each user’s visits are logged by month, allowing for the possibility that these will have occurred over multiple 
# years since whenever business started operations
# 2: Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.
# 3: Calculate the time gaps between visits
# 4: categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned
# 5: calculate the retention month wise
*/


CREATE VIEW month_by_month AS (SELECT cust_id, DATE_FORMAT(str_to_date(order_date, '%d-%m-%Y'), '%m-%Y') AS this_month,
DATE_FORMAT(ADDDATE(str_to_date(order_date, '%d-%m-%Y'), INTERVAL 1 MONTH), '%m-%Y') AS next_month FROM market_fact AS mf
JOIN orders_dimen AS od ON mf.ord_id = od.ord_id ORDER BY str_to_date(order_date, '%d-%m-%Y'));

SELECT * FROM month_by_month;

CREATE VIEW current_month AS SELECT *, COUNT(*) OVER(PARTITION BY this_month) AS this_month_count FROM month_by_month;

SELECT * FROM current_month;

CREATE VIEW retained_customers AS SELECT *, COUNT(*) OVER(PARTITION BY this_month_count) AS retention_count FROM current_month AS tm
WHERE cust_id IN (SELECT cust_id FROM current_month WHERE tm.next_month = this_month);

SELECT * FROM retained_customers;

SELECT DISTINCT next_month, retention_count/ this_month_count * 100 AS retention_rate FROM retained_customers ORDER BY next_month;


