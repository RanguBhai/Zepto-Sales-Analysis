create view Rfm_segments
as WITH rfm_raw AS (
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
)
 SELECT 
 customer_id,
 CONCAT(recency_score, frequency_score, monetary_score) AS rfm_segment
FROM rfm_scored;


