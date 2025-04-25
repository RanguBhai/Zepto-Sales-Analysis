
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

