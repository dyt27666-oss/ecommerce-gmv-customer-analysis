-- =========================================================
-- File: 02_data_cleaning.sql
-- Purpose: Data quality checks, anomaly identification, and
--          order-level analytical dataset creation
-- Database: MySQL 8.x
-- Notes:
-- 1. Run this script after raw tables are loaded.
-- 2. This script does not overwrite raw tables.
-- 3. The wide table is built from order-level aggregated subqueries
--    to avoid revenue duplication caused by one-to-many joins.
-- 4. The wide table keeps all order statuses.
-- 5. Downstream business KPIs such as GMV / Orders / Buyers / AOV /
--    Repeat Rate should default to delivered orders unless stated otherwise.
-- =========================================================

SET NAMES utf8mb4;

-- ---------------------------------------------------------
-- Section 1: Basic row count checks
-- Business meaning:
-- Quickly verify whether each table has been loaded as expected.
-- ---------------------------------------------------------
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'order_items' AS table_name, COUNT(*) AS row_count FROM order_items
UNION ALL
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'reviews' AS table_name, COUNT(*) AS row_count FROM reviews
UNION ALL
SELECT 'payments' AS table_name, COUNT(*) AS row_count FROM payments;


-- ---------------------------------------------------------
-- Section 2: Primary key and duplicate checks
-- Business meaning:
-- Detect duplicated business keys before downstream analysis.
-- ---------------------------------------------------------

-- orders: one row per order_id
SELECT
    'orders.order_id' AS check_item,
    COUNT(*) AS duplicate_key_rows
FROM (
    SELECT order_id
    FROM orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) t;

-- customers: one row per customer_id
SELECT
    'customers.customer_id' AS check_item,
    COUNT(*) AS duplicate_key_rows
FROM (
    SELECT customer_id
    FROM customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) t;

-- products: one row per product_id
SELECT
    'products.product_id' AS check_item,
    COUNT(*) AS duplicate_key_rows
FROM (
    SELECT product_id
    FROM products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) t;

-- order_items: one row per order_id + order_item_id
SELECT
    'order_items.order_id + order_item_id' AS check_item,
    COUNT(*) AS duplicate_key_rows
FROM (
    SELECT order_id, order_item_id
    FROM order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
) t;

-- reviews: expected one row per review_id + order_id in this project
SELECT
    'reviews.review_id + order_id' AS check_item,
    COUNT(*) AS duplicate_key_rows
FROM (
    SELECT review_id, order_id
    FROM reviews
    GROUP BY review_id, order_id
    HAVING COUNT(*) > 1
) t;

-- payments: one row per order_id + payment_sequential
SELECT
    'payments.order_id + payment_sequential' AS check_item,
    COUNT(*) AS duplicate_key_rows
FROM (
    SELECT order_id, payment_sequential
    FROM payments
    GROUP BY order_id, payment_sequential
    HAVING COUNT(*) > 1
) t;


-- ---------------------------------------------------------
-- Section 3: Null value checks on analysis-critical fields
-- Business meaning:
-- Check whether core joins, customer identity, and KPI fields are usable.
-- ---------------------------------------------------------
SELECT 'orders.order_id' AS field_name, COUNT(*) AS null_count
FROM orders
WHERE order_id IS NULL
UNION ALL
SELECT 'orders.customer_id' AS field_name, COUNT(*) AS null_count
FROM orders
WHERE customer_id IS NULL
UNION ALL
SELECT 'orders.order_status' AS field_name, COUNT(*) AS null_count
FROM orders
WHERE order_status IS NULL
UNION ALL
SELECT 'orders.order_purchase_timestamp' AS field_name, COUNT(*) AS null_count
FROM orders
WHERE order_purchase_timestamp IS NULL
UNION ALL
SELECT 'customers.customer_id' AS field_name, COUNT(*) AS null_count
FROM customers
WHERE customer_id IS NULL
UNION ALL
SELECT 'customers.customer_unique_id' AS field_name, COUNT(*) AS null_count
FROM customers
WHERE customer_unique_id IS NULL
UNION ALL
SELECT 'order_items.order_id' AS field_name, COUNT(*) AS null_count
FROM order_items
WHERE order_id IS NULL
UNION ALL
SELECT 'order_items.product_id' AS field_name, COUNT(*) AS null_count
FROM order_items
WHERE product_id IS NULL
UNION ALL
SELECT 'order_items.price' AS field_name, COUNT(*) AS null_count
FROM order_items
WHERE price IS NULL
UNION ALL
SELECT 'order_items.freight_value' AS field_name, COUNT(*) AS null_count
FROM order_items
WHERE freight_value IS NULL
UNION ALL
SELECT 'payments.order_id' AS field_name, COUNT(*) AS null_count
FROM payments
WHERE order_id IS NULL
UNION ALL
SELECT 'payments.payment_value' AS field_name, COUNT(*) AS null_count
FROM payments
WHERE payment_value IS NULL
UNION ALL
SELECT 'reviews.order_id' AS field_name, COUNT(*) AS null_count
FROM reviews
WHERE order_id IS NULL
UNION ALL
SELECT 'reviews.review_score' AS field_name, COUNT(*) AS null_count
FROM reviews
WHERE review_score IS NULL;


-- ---------------------------------------------------------
-- Section 4: Time field quality and sequence checks
-- Business meaning:
-- Ensure order lifecycle timestamps are logically consistent.
-- ---------------------------------------------------------

-- Null checks for time fields
SELECT 'order_purchase_timestamp' AS time_field, COUNT(*) AS null_count
FROM orders
WHERE order_purchase_timestamp IS NULL
UNION ALL
SELECT 'order_delivered_carrier_date' AS time_field, COUNT(*) AS null_count
FROM orders
WHERE order_delivered_carrier_date IS NULL
UNION ALL
SELECT 'order_delivered_customer_date' AS time_field, COUNT(*) AS null_count
FROM orders
WHERE order_delivered_customer_date IS NULL
UNION ALL
SELECT 'order_estimated_delivery_date' AS time_field, COUNT(*) AS null_count
FROM orders
WHERE order_estimated_delivery_date IS NULL;

-- Time sequence anomaly checks
SELECT
    COUNT(*) AS purchase_after_carrier_cnt
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_purchase_timestamp > order_delivered_carrier_date;

SELECT
    COUNT(*) AS carrier_after_customer_delivery_cnt
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date > order_delivered_customer_date;

SELECT
    COUNT(*) AS purchase_after_customer_delivery_cnt
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp > order_delivered_customer_date;

SELECT
    COUNT(*) AS estimated_before_purchase_cnt
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
  AND order_estimated_delivery_date < order_purchase_timestamp;

SELECT
    COUNT(*) AS negative_ship_days_cnt
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND DATEDIFF(order_delivered_carrier_date, order_purchase_timestamp) < 0;

SELECT
    COUNT(*) AS negative_delivery_days_cnt
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) < 0;

SELECT
    COUNT(*) AS negative_last_mile_days_cnt
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND DATEDIFF(order_delivered_customer_date, order_delivered_carrier_date) < 0;


-- ---------------------------------------------------------
-- Section 5: Order status distribution
-- Business meaning:
-- Understand how many orders are actually valid for revenue analysis.
-- ---------------------------------------------------------
SELECT
    order_status,
    COUNT(*) AS order_cnt,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS order_pct
FROM orders
GROUP BY order_status
ORDER BY order_cnt DESC;


-- ---------------------------------------------------------
-- Section 6: Cancelled and anomalous order identification
-- Business meaning:
-- Flag orders that should usually be excluded from GMV and customer value analysis.
-- ---------------------------------------------------------

-- Cancelled or unavailable orders
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp
FROM orders
WHERE order_status IN ('canceled', 'unavailable')
ORDER BY order_purchase_timestamp;

-- Delivered orders missing actual delivery timestamp
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- Delivered orders with non-positive item revenue or missing items
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    COALESCE(oi.item_count, 0) AS item_count,
    COALESCE(oi.item_gmv, 0) AS item_gmv,
    COALESCE(oi.freight_value, 0) AS freight_value,
    COALESCE(oi.order_revenue, 0) AS order_revenue
FROM orders o
LEFT JOIN (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS item_gmv,
        SUM(freight_value) AS freight_value,
        SUM(price + freight_value) AS order_revenue
    FROM order_items
    GROUP BY order_id
) oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND (
      COALESCE(oi.item_count, 0) = 0
      OR COALESCE(oi.item_gmv, 0) <= 0
      OR COALESCE(oi.order_revenue, 0) <= 0
  )
ORDER BY o.order_purchase_timestamp;

-- Orders with large gap between recorded payment and order revenue
SELECT
    o.order_id,
    COALESCE(oi.item_gmv, 0) AS gmv,
    COALESCE(oi.freight_value, 0) AS freight_value,
    COALESCE(oi.order_revenue, 0) AS order_revenue,
    COALESCE(py.payment_value, 0) AS payment_value,
    ROUND(COALESCE(py.payment_value, 0) - COALESCE(oi.order_revenue, 0), 2) AS payment_revenue_gap
FROM orders o
LEFT JOIN (
    SELECT
        order_id,
        SUM(price) AS item_gmv,
        SUM(freight_value) AS freight_value,
        SUM(price + freight_value) AS order_revenue
    FROM order_items
    GROUP BY order_id
) oi
    ON o.order_id = oi.order_id
LEFT JOIN (
    SELECT
        order_id,
        SUM(payment_value) AS payment_value
    FROM payments
    GROUP BY order_id
) py
    ON o.order_id = py.order_id
WHERE ABS(COALESCE(py.payment_value, 0) - COALESCE(oi.order_revenue, 0)) > 0.01
ORDER BY ABS(COALESCE(py.payment_value, 0) - COALESCE(oi.order_revenue, 0)) DESC;


-- ---------------------------------------------------------
-- Section 7: Build order-level analytical wide table
-- Business meaning:
-- Create a clean order-grain dataset for KPI analysis, RFM modeling,
-- fulfillment analysis, and review analysis.
--
-- Important:
-- 1. The wide table keeps all order statuses for operational analysis.
-- 2. Downstream business metrics such as GMV / Orders / Buyers / AOV /
--    Repeat Rate should default to delivered orders.
--
-- Anti-duplication design:
-- 1. Aggregate order_items to one row per order_id before joining.
-- 2. Aggregate payments to one row per order_id before joining.
-- 3. Aggregate reviews to one row per order_id before joining.
-- This avoids inflated GMV, freight, revenue, or payment values caused
-- by one-to-many joins.
-- ---------------------------------------------------------
DROP TABLE IF EXISTS order_level_dataset;

CREATE TABLE order_level_dataset AS
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    o.order_purchase_timestamp,
    o.order_status,
    COALESCE(oi.item_count, 0) AS item_count,
    COALESCE(oi.item_gmv, 0.00) AS gmv,
    COALESCE(oi.freight_value, 0.00) AS freight_value,
    COALESCE(oi.order_revenue, 0.00) AS order_revenue,
    COALESCE(py.payment_value, 0.00) AS payment_value,
    rv.review_score,
    CASE
        WHEN o.order_purchase_timestamp IS NOT NULL
         AND o.order_delivered_carrier_date IS NOT NULL
        THEN DATEDIFF(o.order_delivered_carrier_date, o.order_purchase_timestamp)
        ELSE NULL
    END AS ship_days,
    CASE
        WHEN o.order_purchase_timestamp IS NOT NULL
         AND o.order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)
        ELSE NULL
    END AS delivery_days,
    CASE
        WHEN o.order_delivered_carrier_date IS NOT NULL
         AND o.order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(o.order_delivered_customer_date, o.order_delivered_carrier_date)
        ELSE NULL
    END AS last_mile_days,
    CASE
        WHEN o.order_delivered_customer_date IS NULL
          OR o.order_estimated_delivery_date IS NULL
        THEN NULL
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN 1
        ELSE 0
    END AS is_late_delivery,
    COALESCE(oi.product_category_count, 0) AS product_category_count
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
LEFT JOIN (
    SELECT
        oi.order_id,
        COUNT(*) AS item_count,
        SUM(oi.price) AS item_gmv,
        SUM(oi.freight_value) AS freight_value,
        SUM(oi.price + oi.freight_value) AS order_revenue,
        COUNT(DISTINCT p.product_category_name) AS product_category_count
    FROM order_items oi
    LEFT JOIN products p
        ON oi.product_id = p.product_id
    GROUP BY oi.order_id
) oi
    ON o.order_id = oi.order_id
LEFT JOIN (
    SELECT
        order_id,
        SUM(payment_value) AS payment_value
    FROM payments
    GROUP BY order_id
) py
    ON o.order_id = py.order_id
LEFT JOIN (
    SELECT
        order_id,
        AVG(review_score) AS review_score
    FROM reviews
    GROUP BY order_id
) rv
    ON o.order_id = rv.order_id;


-- ---------------------------------------------------------
-- Section 8: Add indexes to the analytical wide table
-- Business meaning:
-- Improve downstream query performance for trend analysis, buyer analysis,
-- RFM analysis, and fulfillment analysis.
-- ---------------------------------------------------------
ALTER TABLE order_level_dataset
    ADD PRIMARY KEY (order_id),
    ADD KEY idx_old_customer_id (customer_id),
    ADD KEY idx_old_customer_unique_id (customer_unique_id),
    ADD KEY idx_old_purchase_ts (order_purchase_timestamp),
    ADD KEY idx_old_order_status (order_status),
    ADD KEY idx_old_late_delivery (is_late_delivery);


-- ---------------------------------------------------------
-- Section 9: Validate the analytical wide table
-- Business meaning:
-- Confirm the new table is at order grain and ready for analysis.
-- ---------------------------------------------------------

-- Row count should match orders table row count
SELECT
    'orders' AS table_name,
    COUNT(*) AS row_count
FROM orders
UNION ALL
SELECT
    'order_level_dataset' AS table_name,
    COUNT(*) AS row_count
FROM order_level_dataset;

-- Duplicate key check on wide table
SELECT
    COUNT(*) AS duplicate_order_id_cnt
FROM (
    SELECT order_id
    FROM order_level_dataset
    GROUP BY order_id
    HAVING COUNT(*) > 1
) t;

-- Sample output for quick manual review
SELECT
    order_id,
    customer_id,
    customer_unique_id,
    order_purchase_timestamp,
    order_status,
    item_count,
    gmv,
    freight_value,
    order_revenue,
    payment_value,
    review_score,
    ship_days,
    delivery_days,
    last_mile_days,
    is_late_delivery,
    product_category_count
FROM order_level_dataset
ORDER BY order_purchase_timestamp
LIMIT 20;

-- End of file
