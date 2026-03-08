-- =========================================================
-- File: 03_core_metrics.sql
-- Purpose: Core business metrics analysis based on order_level_dataset
-- Database: MySQL 8.x
-- Notes:
-- 1. Core business metrics default to delivered orders only.
-- 2. GMV uses the gmv field (item price only).
-- 3. payment_value can be used for total payment analysis.
-- 4. order_revenue can be used for item price + freight analysis.
-- 5. Buyers are deduplicated by customer_unique_id.
-- =========================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------
-- Base CTE: Delivered order scope
-- Business meaning:
-- Standardize the default metric scope for all operating KPIs.
-- ---------------------------------------------------------
WITH delivered_orders AS (
    SELECT
        order_id,
        customer_id,
        customer_unique_id,
        order_purchase_timestamp,
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
        gmv,
        freight_value,
        order_revenue,
        payment_value,
        review_score,
        ship_days,
        delivery_days,
        last_mile_days,
        is_late_delivery
    FROM order_level_dataset
    WHERE order_status = 'delivered'
)

-- ---------------------------------------------------------
-- Module 1: Business Overview
-- Business meaning:
-- Measure overall scale, order volume, buyer size, and average order value.
-- ---------------------------------------------------------
SELECT
    ROUND(SUM(gmv), 2) AS total_gmv,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS total_buyers,
    ROUND(SUM(gmv) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS aov
FROM delivered_orders;


-- ---------------------------------------------------------
-- Module 2: Monthly Trend
-- Business meaning:
-- Track monthly business growth in GMV, Orders, Buyers, and AOV.
-- ---------------------------------------------------------
WITH delivered_orders AS (
    SELECT
        order_id,
        customer_unique_id,
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
        gmv
    FROM order_level_dataset
    WHERE order_status = 'delivered'
)
SELECT
    order_month,
    ROUND(SUM(gmv), 2) AS monthly_gmv,
    COUNT(DISTINCT order_id) AS monthly_orders,
    COUNT(DISTINCT customer_unique_id) AS monthly_buyers,
    ROUND(SUM(gmv) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS monthly_aov
FROM delivered_orders
GROUP BY order_month
ORDER BY order_month;


-- ---------------------------------------------------------
-- Module 3: GMV Decomposition
-- Business meaning:
-- Decompose GMV from the perspective of Buyers, Frequency, and AOV.
-- Formula:
-- GMV = Buyers * Avg Frequency * AOV
-- ---------------------------------------------------------
WITH delivered_orders AS (
    SELECT
        order_id,
        customer_unique_id,
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
        gmv
    FROM order_level_dataset
    WHERE order_status = 'delivered'
)
SELECT
    order_month,
    COUNT(DISTINCT customer_unique_id) AS buyers,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(gmv), 2) AS gmv,
    ROUND(COUNT(DISTINCT order_id) / NULLIF(COUNT(DISTINCT customer_unique_id), 0), 4) AS avg_frequency,
    ROUND(SUM(gmv) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS aov
FROM delivered_orders
GROUP BY order_month
ORDER BY order_month;


-- ---------------------------------------------------------
-- Module 4A: New Buyers and Existing Buyers by Month
-- Business meaning:
-- Separate monthly buyers into first-time buyers and returning buyers.
-- ---------------------------------------------------------
WITH delivered_orders AS (
    SELECT
        order_id,
        customer_unique_id,
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month
    FROM order_level_dataset
    WHERE order_status = 'delivered'
),
first_order_month AS (
    SELECT
        customer_unique_id,
        MIN(order_month) AS first_order_month
    FROM delivered_orders
    GROUP BY customer_unique_id
),
monthly_buyer_flags AS (
    SELECT DISTINCT
        d.order_month,
        d.customer_unique_id,
        CASE
            WHEN d.order_month = f.first_order_month THEN 1
            ELSE 0
        END AS is_new_buyer
    FROM delivered_orders d
    INNER JOIN first_order_month f
        ON d.customer_unique_id = f.customer_unique_id
)
SELECT
    order_month,
    SUM(is_new_buyer) AS new_buyer_count,
    COUNT(*) - SUM(is_new_buyer) AS existing_buyer_count,
    COUNT(*) AS total_buyer_count
FROM monthly_buyer_flags
GROUP BY order_month
ORDER BY order_month;


-- ---------------------------------------------------------
-- Module 4B: Repurchase Buyers and Repurchase Rate by Month
-- Business meaning:
-- Identify users with at least two delivered orders in the month.
-- ---------------------------------------------------------
WITH delivered_orders AS (
    SELECT
        order_id,
        customer_unique_id,
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month
    FROM order_level_dataset
    WHERE order_status = 'delivered'
),
monthly_customer_orders AS (
    SELECT
        order_month,
        customer_unique_id,
        COUNT(DISTINCT order_id) AS order_cnt
    FROM delivered_orders
    GROUP BY order_month, customer_unique_id
)
SELECT
    order_month,
    COUNT(DISTINCT customer_unique_id) AS total_buyers,
    COUNT(DISTINCT CASE WHEN order_cnt >= 2 THEN customer_unique_id END) AS repeat_buyers,
    ROUND(
        COUNT(DISTINCT CASE WHEN order_cnt >= 2 THEN customer_unique_id END)
        / NULLIF(COUNT(DISTINCT customer_unique_id), 0),
        4
    ) AS repeat_rate
FROM monthly_customer_orders
GROUP BY order_month
ORDER BY order_month;


-- ---------------------------------------------------------
-- Module 4C: Overall Repeat Rate
-- Business meaning:
-- Repeat Rate = buyers with delivered order count >= 2 / total buyers.
-- ---------------------------------------------------------
WITH delivered_orders AS (
    SELECT
        order_id,
        customer_unique_id
    FROM order_level_dataset
    WHERE order_status = 'delivered'
),
customer_order_counts AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS delivered_order_cnt
    FROM delivered_orders
    GROUP BY customer_unique_id
)
SELECT
    COUNT(DISTINCT customer_unique_id) AS total_buyers,
    COUNT(DISTINCT CASE WHEN delivered_order_cnt >= 2 THEN customer_unique_id END) AS repeat_buyers,
    ROUND(
        COUNT(DISTINCT CASE WHEN delivered_order_cnt >= 2 THEN customer_unique_id END)
        / NULLIF(COUNT(DISTINCT customer_unique_id), 0),
        4
    ) AS repeat_rate
FROM customer_order_counts;


-- ---------------------------------------------------------
-- Module 4D: Purchase Frequency Distribution
-- Business meaning:
-- Show how many buyers placed 1, 2, 3, or more delivered orders.
-- ---------------------------------------------------------
WITH delivered_orders AS (
    SELECT
        order_id,
        customer_unique_id
    FROM order_level_dataset
    WHERE order_status = 'delivered'
),
customer_order_counts AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS delivered_order_cnt
    FROM delivered_orders
    GROUP BY customer_unique_id
)
SELECT
    CASE
        WHEN delivered_order_cnt = 1 THEN '1 order'
        WHEN delivered_order_cnt = 2 THEN '2 orders'
        WHEN delivered_order_cnt = 3 THEN '3 orders'
        WHEN delivered_order_cnt = 4 THEN '4 orders'
        ELSE '5+ orders'
    END AS purchase_frequency_bucket,
    COUNT(*) AS buyer_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (), 4) AS buyer_pct
FROM customer_order_counts
GROUP BY
    CASE
        WHEN delivered_order_cnt = 1 THEN '1 order'
        WHEN delivered_order_cnt = 2 THEN '2 orders'
        WHEN delivered_order_cnt = 3 THEN '3 orders'
        WHEN delivered_order_cnt = 4 THEN '4 orders'
        ELSE '5+ orders'
    END
ORDER BY
    CASE
        WHEN purchase_frequency_bucket = '1 order' THEN 1
        WHEN purchase_frequency_bucket = '2 orders' THEN 2
        WHEN purchase_frequency_bucket = '3 orders' THEN 3
        WHEN purchase_frequency_bucket = '4 orders' THEN 4
        ELSE 5
    END;


-- ---------------------------------------------------------
-- Module 5A: Fulfillment Performance Summary
-- Business meaning:
-- Measure average shipping and delivery efficiency on delivered orders.
-- ---------------------------------------------------------
WITH delivered_orders AS (
    SELECT
        order_id,
        ship_days,
        delivery_days,
        last_mile_days,
        is_late_delivery
    FROM order_level_dataset
    WHERE order_status = 'delivered'
)
SELECT
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(ship_days), 2) AS avg_ship_days,
    ROUND(AVG(last_mile_days), 2) AS avg_last_mile_days,
    ROUND(AVG(is_late_delivery), 4) AS late_delivery_rate
FROM delivered_orders;


-- ---------------------------------------------------------
-- Module 5B: Review Score Distribution
-- Business meaning:
-- Understand customer satisfaction distribution on delivered orders.
-- ---------------------------------------------------------
WITH delivered_orders AS (
    SELECT
        order_id,
        review_score
    FROM order_level_dataset
    WHERE order_status = 'delivered'
      AND review_score IS NOT NULL
)
SELECT
    review_score,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(COUNT(DISTINCT order_id) / SUM(COUNT(DISTINCT order_id)) OVER (), 4) AS order_pct
FROM delivered_orders
GROUP BY review_score
ORDER BY review_score;


-- ---------------------------------------------------------
-- Module 5C: Review Score Comparison by Delivery Timeliness
-- Business meaning:
-- Compare customer experience between late and on-time delivery.
-- ---------------------------------------------------------
WITH delivered_orders AS (
    SELECT
        order_id,
        review_score,
        is_late_delivery
    FROM order_level_dataset
    WHERE order_status = 'delivered'
      AND review_score IS NOT NULL
      AND is_late_delivery IS NOT NULL
)
SELECT
    CASE
        WHEN is_late_delivery = 1 THEN 'late_delivery'
        ELSE 'on_time_delivery'
    END AS delivery_group,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM delivered_orders
GROUP BY
    CASE
        WHEN is_late_delivery = 1 THEN 'late_delivery'
        ELSE 'on_time_delivery'
    END
ORDER BY delivery_group;


-- ---------------------------------------------------------
-- Module 6A: Top 10 Categories by GMV
-- Business meaning:
-- Identify the highest-GMV product categories under delivered-order scope.
-- Notes:
-- Category analysis uses delivered orders from the order-level wide table
-- and joins back to item/category tables for product-category granularity.
-- ---------------------------------------------------------
WITH delivered_order_ids AS (
    SELECT
        order_id
    FROM order_level_dataset
    WHERE order_status = 'delivered'
)
SELECT
    COALESCE(p.product_category_name, 'unknown') AS product_category_name,
    ROUND(SUM(oi.price), 2) AS category_gmv,
    COUNT(DISTINCT oi.order_id) AS category_order_count
FROM delivered_order_ids d
INNER JOIN order_items oi
    ON d.order_id = oi.order_id
LEFT JOIN products p
    ON oi.product_id = p.product_id
GROUP BY COALESCE(p.product_category_name, 'unknown')
ORDER BY category_gmv DESC
LIMIT 10;


-- ---------------------------------------------------------
-- Module 6B: Top 10 Categories by Order Count
-- Business meaning:
-- Identify the categories with the broadest order participation.
-- ---------------------------------------------------------
WITH delivered_order_ids AS (
    SELECT
        order_id
    FROM order_level_dataset
    WHERE order_status = 'delivered'
)
SELECT
    COALESCE(p.product_category_name, 'unknown') AS product_category_name,
    COUNT(DISTINCT oi.order_id) AS category_order_count,
    ROUND(SUM(oi.price), 2) AS category_gmv
FROM delivered_order_ids d
INNER JOIN order_items oi
    ON d.order_id = oi.order_id
LEFT JOIN products p
    ON oi.product_id = p.product_id
GROUP BY COALESCE(p.product_category_name, 'unknown')
ORDER BY category_order_count DESC, category_gmv DESC
LIMIT 10;

-- End of file
