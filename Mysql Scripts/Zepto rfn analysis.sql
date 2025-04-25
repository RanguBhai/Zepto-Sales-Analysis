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
