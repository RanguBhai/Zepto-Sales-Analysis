
-- Cohort  & Retention Rate analysis
WITH customer_cohort AS (
    SELECT
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m-01')) AS cohort_month
    FROM zepto_orders
    GROUP BY customer_id
)
-- select * from customer_cohort;
,
orders_with_cohort AS (
    SELECT 
        o.customer_id,
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS order_month,
        c.cohort_month
    FROM zepto_orders o
    JOIN customer_cohort c ON o.customer_id = c.customer_id
)
-- select * from orders_with_cohort;
,
cohort_activity AS (
    SELECT 
        cohort_month,
        order_month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM orders_with_cohort
    GROUP BY cohort_month, order_month
)
-- select * from cohort_activity; 
,
cohort_indexed AS (
    SELECT 
        cohort_month,
        order_month,
        TIMESTAMPDIFF(MONTH, cohort_month, order_month) AS month_index,
        active_customers
    FROM cohort_activity
)
-- select * from cohort_indexed;
,
cohort_with_retention AS (
    SELECT 
        cohort_month,
        month_index,
        active_customers,
        FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY month_index) AS cohort_size
    FROM cohort_indexed
)
-- select * from cohort_with_retention;
SELECT
    cohort_month,
    month_index,
    active_customers,
    cohort_size,
    ROUND((active_customers / cohort_size) * 100, 2) AS retention_rate,
    ROUND((1 - (active_customers / cohort_size)) * 100, 2) AS churn_rate
FROM cohort_with_retention
ORDER BY cohort_month, month_index;

-- Average LTV per Cohort
WITH customer_cohort AS (
    SELECT
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m-01')) AS cohort_month
    FROM zepto_orders
    GROUP BY customer_id
)
-- select * from customer_cohort;
,
customer_ltv AS (
    SELECT
        customer_id,
        SUM(o.order_amount) AS total_spent
    FROM zepto_orders o
    GROUP BY o.customer_id
)
-- select * from customer_ltv
SELECT 
    cc.cohort_month,
    ROUND(AVG(cl.total_spent), 2) AS avg_lifetime_value
FROM customer_cohort cc
JOIN customer_ltv cl ON cc.customer_id = cl.customer_id
GROUP BY cc.cohort_month
ORDER BY cc.cohort_month;
-- Zepto Cohort Analysis using Signup Date
with cohort as (
SELECT 
    DATE_FORMAT(c.signup_date, '%Y-%m-01') AS cohort_month,
    DATE_FORMAT(o.order_date, '%Y-%m-01') AS order_month,
    TIMESTAMPDIFF(MONTH, DATE(c.signup_date), DATE(o.order_date)) AS month_index,
    COUNT(DISTINCT c.customer_id) AS active_customers
FROM zepto_customers c
JOIN zepto_orders o ON c.customer_id = o.customer_id
GROUP BY cohort_month, order_month, month_index
ORDER BY cohort_month, month_index
), 
Cohort_Size  as 
(select *,  FIRST_VALUE(active_customers) OVER (PARTITION BY cohort_month ORDER BY month_index) AS cohort_size 
from cohort 
)
 SELECT
    cohort_month,
    month_index,
    active_customers,
    cohort_size,
    ROUND((active_customers / cohort_size) * 100, 2) AS retention_rate,
    ROUND((1 - (active_customers / cohort_size)) * 100, 2) AS churn_rate
FROM cohort_Size
ORDER BY cohort_month, month_index;
