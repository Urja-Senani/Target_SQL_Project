create database project;
use project;

select * from customers;
select * from geolocation;
select * from order_items;
select * from order_reviews;
select * from sellers;
select * from orders;

-- 1.
-- 1.1 Data type of columns in a table 
-- Customers
select column_name,data_type from information_schema.columns where table_name = 'Customers';
-- Geolocation
select column_name,data_type from information_schema.columns where table_name = 'Geolocation';
-- Order_items
select column_name,data_type from information_schema.columns where table_name = 'Order_items';
-- order_reviews
select column_name,data_type from information_schema.columns where table_name = 'order_reviews';
-- orders
select column_name,data_type from information_schema.columns where table_name = 'orders';
-- payments
select column_name,data_type from information_schema.columns where table_name = 'payments';
-- products
select column_name,data_type from information_schema.columns where table_name = 'products';
-- sellers
select column_name,data_type from information_schema.columns where table_name = 'sellers';

-- 1.2. Time period for which the data is given.
select min(order_purchase_timestamp) as min_date, max(order_purchase_timestamp) as max_date from orders;

-- 1.3 Cities and states of customers ordered during the given period
select count(distinct(geolocation_city)) as city,count(distinct(geolocation_state))as state from geolocation;
select distinct(geolocation_city) as city, (geolocation_state)as state from geolocation;

-- 4 
-- 4.1 % increase in cost of orders from 2017 to 2018 
with S1 as (
 SELECT Round(Sum(pay.payment_value),2) as sum2017
 FROM orders as ord
 JOIN payments as pay using (order_id)
 Where Extract(Year from ord.order_purchase_timestamp) = 2017
 and Extract(Month from ord.order_purchase_timestamp) BETWEEN 1 and 8
),
S2 as (
 SELECT Round(Sum(pay.payment_value),2) as sum2018
 FROM orders as ord
 JOIN payments as pay using (order_id)
 Where Extract(Year from ord.order_purchase_timestamp) = 2018
 and Extract(Month from ord.order_purchase_timestamp) BETWEEN 1 and 8
)
Select sum2018 as Sumof2018,sum2017 as Sumof2017, Round((sum2018-
sum2017)/sum2017*100,2) as increaseValue from S1,S2;

-- 4.2 Mean & Sum of price and freight value by customer state
SELECT 
    cust.customer_state,
    ROUND(AVG(price), 2) AS priceaverage,
    ROUND(AVG(freight_value), 2) AS avgfreightvalue,
    ROUND(SUM(price), 2) AS sumprice,
    ROUND(SUM(freight_value), 2) AS sumfreightvalue
FROM
    order_items AS ord
        JOIN
    customers AS cust ON sel.seller_zip_code_prefix = cust.customer_zip_code_prefix
GROUP BY cust.customer_state;

-- 5
-- 5.1 .Days between purchasing, delivering and estimated delivery
SELECT order_id,order_purchase_timestamp as purchasetime,
 DATEDIFF(Extract(Date FROM order_delivered_customer_date),Extract(Date FROM
order_purchase_timestamp) ,Day) as Day_between_deliver_purchase,
 DATEDIFF(Extract(Date FROM order_estimated_delivery_date),Extract(Date FROM
order_purchase_timestamp),Day) as Day_between_exstimate_purchase,
 DATEDIFF(Extract(Date FROM order_estimated_delivery_date),Extract(Date FROM
order_delivered_customer_date),Day) as Day_between_estimated_delivery,
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


-- 5.2 days between purchasing, delivering and estimated delivery
SELECT order_id,
 TIMESTAMPDIFF(order_delivered_customer_date,order_purchase_timestamp,DAY) AS
time_to_delivery,
abs(TIMESTAMPDIFF(order_estimated_delivery_date,order_delivered_customer_date,DAY))
AS diff_estimated_delivery;


-- 5.2 time_to_delivery & diff_estimated_delivery
With S1 as(
 SELECT order_id,
TIMESTAMP_DIFF(order_delivered_customer_date,order_purchase_timestamp,DAY) AS
time_to_delivery,
TIMESTAMPDIFF(order_estimated_delivery_date,order_delivered_customer_date,DAY) AS
diff_estimated_delivery,
 FROM orders 
 WHERE order_delivered_customer_date IS NOT NULL
)
SELECT cust.customer_state, round(avg(ord.freight_value),2) as
average_freight_value,
 round(avg(OD.time_to_delivery),2) as average_time_to_delivery,
 round(avg(OD.diff_estimated_delivery),2) as average_diff_estimated_delivery
FROM order_items as ord
JOIN sellers as sel Using(seller_id)
JOIN customers as cust
ON sel.seller_zip_code_prefix = cust.customer_zip_code_prefix
JOIN S1 as OD
ON ord.order_id = OD.order_id
Group BY cust.customer_state;

-- 5.3 	Group data by state, take mean of freight_value, time_to_delivery, diff_estimated_delivery
SELECT cust.customer_state as tstate,round(avg(ord.freight_value),2) as
avg_freighttop
 FROM order_items as ord
 JOIN sellers as sel Using(seller_id)
 JOIN customers as cust
 ON sel.seller_zip_code_prefix = cust.customer_zip_code_prefix
 Group BY cust.customer_state
 order by avg_freighttop desc;
 
-- 5.4 
-- 5.4 a) Top 5 states with highest/lowest average freight value - sort in desc/asc limit 5
SELECT cust.customer_state,
round(avg(TIMESTAMPDIFF(order_delivered_customer_date,order_purchase_timestamp,DAY
)),2) AS time_to_delivery
FROM orders as ord
JOIN customers as cust
ON ord.customer_id = cust.customer_id
Group BY cust.customer_state
order by time_to_delivery desc limit 5;

-- 5.4 b) Top 5 states with highest average time to delivery
SELECT cust.customer_state,
round(avg(TIMESTAMPDIFF(order_delivered_customer_date,order_purchase_timestamp,DAY)),
2) AS time_to_delivery
FROM orders as ord
JOIN customers as cust
ON ord.customer_id = cust.customer_id
Group BY cust.customer_state
order by time_to_delivery asc limit 5;

-- 5.4 c) Top 5 states with highest average time to delivery
SELECT cust.customer_state,
avg(ABS(TIMESTAMPDIFF(order_delivered_customer_date,order_estimated_delivery_date,DAY
))) AS diff_estimated_delivery
FROM orders as od
JOIN order_items as ord using(order_id)
JOIN sellers as sel Using(seller_id)
JOIN customers as cust
ON sel.seller_zip_code_prefix = cust.customer_zip_code_prefix
Where order_status ="delivered"
and order_delivered_customer_date is not null
Group BY cust.customer_state order by diff_estimated_delivery asc limit 5;

-- 6 
-- 6.1 Month over Month count of orders for different payment types
SELECT pay.payment_type,Extract(Month FROM order_purchase_timestamp) as
month,count(1)
FROM payments as pay JOIN orders as ord using(order_id)
group by month,payment_type order by pay.payment_type,month;

-- 6.2 Count of orders based on the no. of payment installments
select payment_installments,Count(order_id) as ordercount
from payments
group by payment_installments;

