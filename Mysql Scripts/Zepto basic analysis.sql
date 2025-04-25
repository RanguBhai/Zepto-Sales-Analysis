--  Total Orders, Revenue, Customers
SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.order_amount), 2) AS total_revenue,
    COUNT(DISTINCT o.customer_id) AS total_customers
FROM zepto_orders o;

--  Total Revenue and orders by Year and Month
SELECT 
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    SUM(order_amount) AS total_revenue,
    COUNT(order_id) AS total_orders
FROM zepto_orders
GROUP BY year, month
ORDER BY year, month;

--  Total Revenue byTop 10 Cities
SELECT 
    c.city,
    COUNT(o.order_id) AS total_orders,
    SUM(o.order_amount) AS total_revenue
FROM zepto_orders o
JOIN zepto_customers c ON o.customer_id = c.customer_id
GROUP BY c.city
ORDER BY total_revenue DESC
limit 10;

--  Total Revenue by top 10  Products
SELECT 
    p.product_name,
    SUM(oi.Total_amount) AS total_revenue
FROM zepto_order_items oi
JOIN zepto_product_catalog p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC
limit 10;

-- Top Categories by Revenue
SELECT 
    p.category,
    SUM(quantity) AS total_quantity_sold,
    ROUND(SUM(total_amount), 2) AS total_revenue
FROM zepto_product_catalog p left join zepto_order_items  o
on p.product_id= o.product_id
GROUP BY category
ORDER BY total_revenue DESC;

-- Top 10 Products by  Quantities Sold
SELECT 
    product_name,
    SUM(quantity) AS total_quantity_sold,
   round(sum(total_amount),2) as total_revenue
   from zepto_product_catalog p left join zepto_order_items oi on p.product_id=oi.product_id
GROUP BY product_name
ORDER BY total_quantity_sold DESC
LIMIT 10;

-- CUSTOMER LIFETIME VALUE (LTV) Per Customer
SELECT
    customer_id,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(order_amount), 2) AS total_spent,
    ROUND(SUM(order_amount) / COUNT(order_id), 2) AS avg_order_value
FROM zepto_orders
GROUP BY customer_id
ORDER BY total_spent DESC;

--  Average Order Value (AOV) per Month
SELECT 
    year(order_date) AS year,
    month(order_date) AS month,
    ROUND(SUM(order_amount) / COUNT(order_id), 2) AS avg_order_value
FROM zepto_orders
GROUP BY year, month
ORDER BY  avg_order_value desc;

--  Total Amount Spent by top 10  Customer
SELECT 
    c.customer_id,
    c.customer_name,
    round(SUM(o.order_amount),2) AS total_spent
FROM zepto_orders o
JOIN zepto_customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC
limit 10;

--  Unique Customers per Month
SELECT 
    YEAR(order_date) AS year,
    MONTH(order_date) AS month,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM zepto_orders
GROUP BY year, month
ORDER BY unique_customers;

--  Total Orders  Day of Week
SELECT 
    DAYNAME(order_date) AS day_of_week,
    COUNT(order_id) AS total_orders
FROM zepto_orders
GROUP BY day_of_week 
ORDER BY total_orders desc;

