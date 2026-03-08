-- =========================================================
-- File: 04_rfm_analysis.sql
-- Purpose: Build RFM customer segmentation results based on
--          order_level_dataset
-- Database: MySQL 8.x
-- Notes:
-- 1. RFM is calculated only on delivered orders.
-- 2. customer_unique_id is the customer grain.
-- 3. analysis_date is defined as:
--    DATE(MAX(order_purchase_timestamp)) + 1 day
--    based on delivered orders in order_level_dataset.
-- 4. R = days since last purchase to analysis_date
--    F = delivered order count
--    M = total GMV = SUM(gmv)
-- =========================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------
-- Section 1: Create RFM result table
-- Business meaning:
-- Build one row per customer_unique_id for downstream segmentation,
-- retention analysis, and CRM targeting.
-- ---------------------------------------------------------
DROP TABLE IF EXISTS rfm_customer_segments;

CREATE TABLE rfm_customer_segments AS
WITH delivered_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,
        gmv
    FROM order_level_dataset
    WHERE order_status = 'delivered'
      AND customer_unique_id IS NOT NULL
),
analysis_params AS (
    SELECT
        DATE_ADD(DATE(MAX(order_purchase_timestamp)), INTERVAL 1 DAY) AS analysis_date
    FROM delivered_orders
),
rfm_base AS (
    SELECT
        d.customer_unique_id,
        DATEDIFF(p.analysis_date, DATE(MAX(d.order_purchase_timestamp))) AS recency,
        COUNT(DISTINCT d.order_id) AS frequency,
        ROUND(SUM(d.gmv), 2) AS monetary
    FROM delivered_orders d
    CROSS JOIN analysis_params p
    GROUP BY d.customer_unique_id, p.analysis_date
),
rfm_scored AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),
rfm_segmented AS (
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CONCAT(r_score, f_score, m_score) AS rfm_score,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'High Value'
            WHEN frequency = 1 AND r_score >= 4 THEN 'New Customers'
            WHEN r_score >= 4 AND (f_score >= 3 OR m_score >= 3) THEN 'Potential'
            WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 3) THEN 'At Risk'
            WHEN r_score = 1 AND f_score <= 2 AND m_score <= 2 THEN 'Dormant'
            ELSE 'Regular'
        END AS segment_name
    FROM rfm_scored
)
SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_score,
    segment_name
FROM rfm_segmented;


-- ---------------------------------------------------------
-- Section 2: Add indexes to the RFM result table
-- Business meaning:
-- Improve performance for segmentation lookup and summary queries.
-- ---------------------------------------------------------
ALTER TABLE rfm_customer_segments
    ADD PRIMARY KEY (customer_unique_id),
    ADD KEY idx_rfm_segment_name (segment_name),
    ADD KEY idx_rfm_score (rfm_score),
    ADD KEY idx_rfm_recency (recency),
    ADD KEY idx_rfm_frequency (frequency),
    ADD KEY idx_rfm_monetary (monetary);


-- ---------------------------------------------------------
-- Section 3: Query full RFM result sample
-- Business meaning:
-- Review customer-level RFM output after table creation.
-- ---------------------------------------------------------
SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_score,
    segment_name
FROM rfm_customer_segments
ORDER BY monetary DESC, frequency DESC, recency ASC
LIMIT 50;


-- ---------------------------------------------------------
-- Section 4: Segment customer count
-- Business meaning:
-- Show how many customers fall into each RFM segment.
-- ---------------------------------------------------------
SELECT
    segment_name,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 4) AS customer_pct
FROM rfm_customer_segments
GROUP BY segment_name
ORDER BY customer_count DESC;


-- ---------------------------------------------------------
-- Section 5: Segment quality summary
-- Business meaning:
-- Compare segment value using average monetary, frequency,
-- and recency indicators.
-- ---------------------------------------------------------
SELECT
    segment_name,
    COUNT(*) AS customer_count,
    ROUND(AVG(recency), 2) AS avg_recency,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary,
    ROUND(SUM(monetary), 2) AS total_monetary
FROM rfm_customer_segments
GROUP BY segment_name
ORDER BY avg_monetary DESC, avg_frequency DESC;


-- ---------------------------------------------------------
-- Section 6: Score distribution summary
-- Business meaning:
-- Validate the R/F/M score assignment and check score balance.
-- ---------------------------------------------------------
SELECT
    r_score,
    f_score,
    m_score,
    COUNT(*) AS customer_count
FROM rfm_customer_segments
GROUP BY r_score, f_score, m_score
ORDER BY r_score DESC, f_score DESC, m_score DESC;

-- End of file
