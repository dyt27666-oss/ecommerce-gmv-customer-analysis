-- =========================================================
-- File: 01_create_tables.sql
-- Purpose: Create six analysis tables for the Olist e-commerce project
-- Database: MySQL 8.x
-- Notes:
-- 1. This script creates tables only. It does not load data.
-- 2. Table design favors bulk import stability and analytical querying.
-- 3. Indexes are added for common joins, filtering, time-series analysis, and RFM analysis.
-- =========================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------
-- Table: customers
-- Grain: One row per customer_id
-- Role: Customer dimension; customer_unique_id is the true buyer identifier
-- ---------------------------------------------------------
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id VARCHAR(50) NOT NULL COMMENT 'Order-level customer identifier',
    customer_unique_id VARCHAR(50) NOT NULL COMMENT 'Stable buyer identifier across multiple orders',
    customer_zip_code_prefix VARCHAR(10) NULL COMMENT 'ZIP code prefix',
    customer_city VARCHAR(100) NULL COMMENT 'Customer city',
    customer_state VARCHAR(10) NULL COMMENT 'Customer state',
    PRIMARY KEY (customer_id),
    KEY idx_customers_unique_id (customer_unique_id),
    KEY idx_customers_state_city (customer_state, customer_city)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COMMENT = 'Customer dimension table for buyer and RFM analysis';

-- ---------------------------------------------------------
-- Table: products
-- Grain: One row per product_id
-- Role: Product dimension
-- ---------------------------------------------------------
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product_id VARCHAR(50) NOT NULL COMMENT 'Unique product identifier',
    product_category_name VARCHAR(100) NULL COMMENT 'Product category name',
    product_name_lenght INT NULL COMMENT 'Length of product name in characters',
    product_description_lenght INT NULL COMMENT 'Length of product description in characters',
    product_photos_qty INT NULL COMMENT 'Number of product photos',
    product_weight_g DECIMAL(10,2) NULL COMMENT 'Product weight in grams',
    product_length_cm DECIMAL(10,2) NULL COMMENT 'Product length in centimeters',
    product_height_cm DECIMAL(10,2) NULL COMMENT 'Product height in centimeters',
    product_width_cm DECIMAL(10,2) NULL COMMENT 'Product width in centimeters',
    PRIMARY KEY (product_id),
    KEY idx_products_category (product_category_name)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COMMENT = 'Product dimension table for category and catalog analysis';

-- ---------------------------------------------------------
-- Table: orders
-- Grain: One row per order_id
-- Role: Core order fact table for KPI and fulfillment analysis
-- ---------------------------------------------------------
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id VARCHAR(50) NOT NULL COMMENT 'Unique order identifier',
    customer_id VARCHAR(50) NOT NULL COMMENT 'Linked customer identifier',
    order_status VARCHAR(30) NOT NULL COMMENT 'Order lifecycle status',
    order_purchase_timestamp DATETIME NULL COMMENT 'Timestamp when order was placed',
    order_approved_at DATETIME NULL COMMENT 'Timestamp when payment was approved',
    order_delivered_carrier_date DATETIME NULL COMMENT 'Timestamp when order was handed to carrier',
    order_delivered_customer_date DATETIME NULL COMMENT 'Timestamp when order was delivered to customer',
    order_estimated_delivery_date DATETIME NULL COMMENT 'Promised delivery date',
    PRIMARY KEY (order_id),
    KEY idx_orders_customer_id (customer_id),
    KEY idx_orders_purchase_ts (order_purchase_timestamp),
    KEY idx_orders_status (order_status),
    KEY idx_orders_status_purchase_ts (order_status, order_purchase_timestamp),
    KEY idx_orders_delivery_dates (order_delivered_customer_date, order_estimated_delivery_date)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COMMENT = 'Order fact table for GMV, Orders, Buyers, AOV, Repeat Rate, and fulfillment analysis';

-- ---------------------------------------------------------
-- Table: order_items
-- Grain: One row per order_id + order_item_id
-- Role: Revenue detail fact table
-- ---------------------------------------------------------
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    order_id VARCHAR(50) NOT NULL COMMENT 'Linked order identifier',
    order_item_id INT NOT NULL COMMENT 'Line item number within the order',
    product_id VARCHAR(50) NOT NULL COMMENT 'Linked product identifier',
    seller_id VARCHAR(50) NULL COMMENT 'Seller identifier',
    shipping_limit_date DATETIME NULL COMMENT 'Seller shipping deadline',
    price DECIMAL(10,2) NOT NULL COMMENT 'Item price excluding freight',
    freight_value DECIMAL(10,2) NOT NULL COMMENT 'Freight amount charged for the item',
    PRIMARY KEY (order_id, order_item_id),
    KEY idx_order_items_order_id (order_id),
    KEY idx_order_items_product_id (product_id),
    KEY idx_order_items_seller_id (seller_id),
    KEY idx_order_items_order_product (order_id, product_id)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COMMENT = 'Order item fact table used to calculate GMV and product-level performance';

-- ---------------------------------------------------------
-- Table: reviews
-- Grain: One row per review_id + order_id
-- Role: Customer satisfaction fact table
-- ---------------------------------------------------------
DROP TABLE IF EXISTS reviews;
CREATE TABLE reviews (
    review_id VARCHAR(50) NOT NULL COMMENT 'Review identifier',
    order_id VARCHAR(50) NOT NULL COMMENT 'Linked order identifier',
    review_score TINYINT NULL COMMENT 'Review score from 1 to 5',
    review_comment_title TEXT NULL COMMENT 'Review title text',
    review_comment_message TEXT NULL COMMENT 'Review message text',
    review_creation_date DATETIME NULL COMMENT 'Review creation date',
    review_answer_timestamp DATETIME NULL COMMENT 'Review answer timestamp',
    PRIMARY KEY (review_id, order_id),
    KEY idx_reviews_order_id (order_id),
    KEY idx_reviews_score (review_score),
    KEY idx_reviews_creation_date (review_creation_date)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COMMENT = 'Review fact table used for satisfaction and delivery experience analysis';

-- ---------------------------------------------------------
-- Table: payments
-- Grain: One row per order_id + payment_sequential
-- Role: Payment fact table for reconciliation and payment behavior analysis
-- ---------------------------------------------------------
DROP TABLE IF EXISTS payments;
CREATE TABLE payments (
    order_id VARCHAR(50) NOT NULL COMMENT 'Linked order identifier',
    payment_sequential INT NOT NULL COMMENT 'Sequence number of the payment record within one order',
    payment_type VARCHAR(30) NULL COMMENT 'Payment method',
    payment_installments INT NULL COMMENT 'Number of installments',
    payment_value DECIMAL(10,2) NOT NULL COMMENT 'Payment amount for the record',
    PRIMARY KEY (order_id, payment_sequential),
    KEY idx_payments_order_id (order_id),
    KEY idx_payments_type (payment_type),
    KEY idx_payments_value (payment_value)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COMMENT = 'Payment fact table used for order payment reconciliation and payment method analysis';

SET FOREIGN_KEY_CHECKS = 1;

-- End of file
