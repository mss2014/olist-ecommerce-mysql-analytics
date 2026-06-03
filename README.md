# Olist E-Commerce MySQL Analytics 📊🛒

An end-to-end relational database analytics project leveraging **MySQL** to process, optimize, and analyze the complete **Olist Brazilian E-Commerce Dataset**. This repository documents the structural mapping, data ingestion paths, complex analytical queries, and performance-tuning mechanisms across 9 distinct e-commerce tables.

---

## 🗺️ Database Star Schema Map

The ecosystem is modeled as a star/snowflake schema centered around the historical transactions hub (`orders`):

*   **`orders`** connects to **`customers`** via `customer_id`.
*   **`orders`** connects to **`order_payments`** & **`order_reviews`** via `order_id`.
*   **`order_items`** acts as a bridge table connecting **`orders`** (`order_id`), **`products`** (`product_id`), and **`sellers`** (`seller_id`).
*   **`products`** resolves localized names through **`product_category_name_translation`**.

---

## 🏗️ Project Objectives

1. **Schema Initialization (DDL):** Create explicit database schemas, enforce relational primary/foreign key dependencies, and assign appropriate data types.
2. **Advanced Querying:** Formulate structural metrics combining data filters, multi-table joins, subqueries, and aggregation constraints.
3. **Reusable Modeling:** Build views to encapsulate recurring, high-overhead reporting blocks.
4. **Performance Tuning:** Implement B-Tree indexes on core analytical paths to resolve full-table query bottlenecks.

---

## 🚀 Getting Started

### 1. Database Setup
Execute the following schema statements in your MySQL Client or MySQL Workbench to configure the core structural components before attempting data ingestion:

```SQL
-- Profile directories
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100)
);

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- Transactional hubs
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

2. Ingesting the Data
To import the raw data from your CSV files, utilize the Table Data Import Wizard built into MySQL Workbench (Right-click a table -> Select Import Wizard -> Map your local CSV file) or run native shell expressions if server security configurations allow it:

```SQL
LOAD DATA INFILE '/path/to/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

🔍 Analytical Scripts Showcase
Below are highlights of core analytical tasks implemented within this repository:

A. Geographic Filtering & Aggregations
Identifies regional sales density within key administrative regions:

```SQL
SELECT customer_state, customer_city, COUNT(customer_id) AS total_orders
FROM customers
WHERE customer_state IN ('SP', 'RJ', 'MG')
GROUP BY customer_state, customer_city
HAVING COUNT(customer_id) >= 100
ORDER BY total_orders DESC;

B. Revenue Extraction via Multi-Table Joins
Resolves order pricing data against language translations to derive product category revenue totals:

```SQL
SELECT s.seller_id, s.seller_city, s.seller_state
FROM sellers s
LEFT JOIN order_items oi ON s.seller_id = oi.seller_id
WHERE oi.seller_id IS NULL;

C. Benchmarking metrics with SubqueriesIsolates orders featuring cart checkout values that exceed the global average order volume ($AOV$):

```SQL
SELECT order_id, customer_id, SUM(payment_value) AS total_order_payment
FROM orders o
INNER JOIN order_payments op ON o.order_id = op.order_id
GROUP BY o.order_id, o.customer_id
HAVING SUM(payment_value) > (SELECT AVG(payment_value) FROM order_payments);

⚡ Query Optimization Metrics
When datasets hit enterprise scales (nearly 100,000 rows per table), cross-table scans degrade execution speed. This project configures B-Tree Indexes targeted at key relational points to shift evaluation metrics from linear full scans to efficient tree walks.

```SQL
-- Execution Path Optimizations
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_payments_order_id ON order_payments(order_id);

Verify structural routing using execution tracking:
EXPLAIN SELECT * FROM orders WHERE customer_id = '9ef432eb6251297304e76186b10a928d';
---

This project is licensed under the MIT License.
