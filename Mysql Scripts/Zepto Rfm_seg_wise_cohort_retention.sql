-- SEGMENT-WISE COHORT RETENTION WITH PERCENTAGE
create view Rfm_wise_retention as
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
