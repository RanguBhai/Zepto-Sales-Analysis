-- View: view_zepto_rfm_seg_wise_cohort_retention
CREATE OR REPLACE VIEW zepto_rfm_seg_wise_cohort_retention AS
-- SEGMENT-WISE COHORT RETENTION WITH PERCENTAGE
WITH rfm_raw AS (
    SELECT
        o.customer_id,
        DATEDIFF('2024-12-31', MAX(o.order_date)) AS recency,
        COUNT(o.order_id) AS frequency,
        SUM(o.order_amount) AS monetary
    FROM zepto_orders o
    GROUP BY o.customer_id
),
rfm_scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score
    FROM rfm_raw
),
rfm_segments AS (
    SELECT
        customer_id,
        CONCAT(recency_score, frequency_score, monetary_score) AS rfm_segment
    FROM rfm_scored
),
customer_cohort AS (
    SELECT
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m-01')) AS cohort_month
    FROM zepto_orders
    GROUP BY customer_id
),
orders_with_cohort AS (
    SELECT 
        o.customer_id,
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS order_month,
        c.cohort_month
    FROM zepto_orders o
    JOIN customer_cohort c ON o.customer_id = c.customer_id
),
cohort_indexed AS (
    SELECT 
        owc.customer_id,
        owc.cohort_month,
        owc.order_month,
        TIMESTAMPDIFF(MONTH, owc.cohort_month, owc.order_month) AS month_index
    FROM orders_with_cohort owc
),
segment_retention AS (
    SELECT
        r.rfm_segment,
        ci.cohort_month,
        ci.month_index,
        COUNT(DISTINCT ci.customer_id) AS active_customers
    FROM cohort_indexed ci
    JOIN rfm_segments r ON ci.customer_id = r.customer_id
    GROUP BY r.rfm_segment, ci.cohort_month, ci.month_index
),
cohort_size AS (
    SELECT
        r.rfm_segment,
        ci.cohort_month,
        COUNT(DISTINCT ci.customer_id) AS cohort_size
    FROM cohort_indexed ci
    JOIN rfm_segments r ON ci.customer_id = r.customer_id
    WHERE ci.month_index = 0
    GROUP BY r.rfm_segment, ci.cohort_month
),
final_retention AS (
    SELECT
        sr.rfm_segment,
        sr.cohort_month,
        sr.month_index,
        sr.active_customers,
        cs.cohort_size,
        ROUND(100.0 * sr.active_customers / cs.cohort_size, 2) AS retention_rate
    FROM segment_retention sr
    JOIN cohort_size cs
        ON sr.rfm_segment = cs.rfm_segment
        AND sr.cohort_month = cs.cohort_month
)

-- FINAL OUTPUT
SELECT *
FROM final_retention
ORDER BY rfm_segment, cohort_month, month_index;

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

-- View: view_zepto_cohort_analysis
 create view Zepto_cohort_analysis_with_order_date AS
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

create view Zepto_Avg_ltv_cohort as
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

create view Zepto_cohort_analysis_with_signup_date as
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

-- View: view_zepto_churn_analysis
CREATE OR REPLACE VIEW zepto_churn_list_analysis AS
-- Churn Analysis SQL: Customers who haven't ordered in the last 60 days
SELECT 
    c.customer_id,
    c.customer_name,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF('2025-01-01', MAX(o.order_date)) AS days_since_last_order
FROM zepto_customers c
LEFT JOIN zepto_orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING days_since_last_order > 60
ORDER BY days_since_last_order DESC;

CREATE OR REPLACE VIEW zepto_churn_count_analysis AS
-- Churn customer count : No orders in the last 60 days
WITH latest_orders AS (
    SELECT 
        customer_id,
        MAX(order_date) AS last_order_date
    FROM zepto_orders
    GROUP BY customer_id
),
churned_customers AS (
    SELECT 
        lo.customer_id,
        DATEDIFF('2025-01-01', lo.last_order_date) AS days_since_last_order
    FROM latest_orders lo
)
-- select * from churned_customers;

SELECT 
    COUNT(*) AS churned_customers_count
FROM churned_customers
WHERE days_since_last_order > 60;

-- View: view_zepto_rfn_analysis
CREATE OR REPLACE VIEW zepto_rfm__score_analysis AS
-- RFM ANALYSIS FOR ZEPTO CUSTOMERS
-- customers in each rfm segment 
WITH rfm_raw AS (
    SELECT
        o.customer_id,
        DATEDIFF('2024-12-31', MAX(o.order_date)) AS recency,
        COUNT(o.order_id) AS frequency,
        SUM(o.order_amount) AS monetary
    FROM zepto_orders o
    GROUP BY o.customer_id
),
rfm_scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score
    FROM rfm_raw
),
rfm_final AS (
    SELECT 
        customer_id,
        CONCAT(recency_score, frequency_score, monetary_score) AS rfm_segment
    FROM rfm_scored
)
SELECT 
    rfm_segment,
    COUNT(*) AS customer_count
FROM rfm_final
GROUP BY rfm_segment
ORDER BY customer_count DESC;

CREATE OR REPLACE VIEW zepto_rfm_segmentation_analysis AS
WITH customer_orders AS (
    SELECT 
        o.customer_id,
        MAX(o.order_date) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        round(SUM(o.order_amount),2) AS monetary
    FROM zepto_orders o
    GROUP BY o.customer_id
),
rfm_base AS (
    SELECT
        co.customer_id,
        DATEDIFF('2024-12-31', co.last_order_date) AS recency,
        co.frequency,
        co.monetary
    FROM customer_orders co
),
rfm_scored AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)
SELECT *,
       CONCAT(r_score, f_score, m_score) AS rfm_segment,
       (r_score + f_score + m_score) AS rfm_score,
       CASE
           WHEN r_score = 5 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
           WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal Customers'
           WHEN r_score >= 4 THEN 'Potential Loyalist'
           WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
           WHEN r_score = 1 AND f_score = 1 AND m_score = 1 THEN 'Lost'
           ELSE 'Others'
       END AS customer_segment
FROM rfm_scored
ORDER BY rfm_score DESC;

