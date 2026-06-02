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

## 🛠️ Project Structure & Architecture

### 1. Data Definition & Tables Initialization (`DDL`)
The database schema explicitly configures primary keys, foreign key constraints, and performance data types. Execute the scripts within your MySQL client to build the architecture before running imports:

*   `customers`
*   `geolocation`
*   `sellers`
*   `products`
*   `product_category_name_translation`
*   `orders`
*   `order_items`
*   `order_payments`
*   `order_reviews`

*(Note: Ensure independent structural lookups like customers, sellers, and products are initialized prior to loading transactions to prevent foreign key constraint violations.)*

---

## 🔍 Featured SQL Queries Showcase

The repository contains modular scripts organized by analytical complexity:

### A. Core Extractions & Regional Volumetrics
Isolates geo-concentrations using `SELECT`, `WHERE`, `GROUP BY`, and `HAVING`:
```sql
SELECT 
    customer_state, customer_city, COUNT(customer_id) AS total_orders
FROM customers
WHERE customer_state IN ('SP', 'RJ', 'MG')
GROUP BY customer_state, customer_city
HAVING COUNT(customer_id) >= 100
ORDER BY total_orders DESC;

### **B. Relational Joins & Financial Aggregations**
Combines transaction files to generate revenue intelligence by product vertical:
```sql
SELECT 
    t.product_category_name_english AS category,
    COUNT(oi.order_id) AS items_sold,
    SUM(oi.price) AS total_revenue,
    AVG(oi.price) AS average_item_price
FROM order_items oi
INNER JOIN products p ON oi.product_id = p.product_id
INNER JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY total_revenue DESC;

### **C. Advanced Deep-Dives & Subqueries**
Tracks high-value cart metrics relative to global benchmarks:
```sql
SELECT order_id, customer_id, SUM(payment_value) AS total_order_payment
FROM orders o
INNER JOIN order_payments op ON o.order_id = op.order_id
GROUP BY o.order_id, o.customer_id
HAVING SUM(payment_value) > (SELECT AVG(payment_value) FROM order_payments)
ORDER BY total_order_payment DESC;

 Performance Optimization MetricsWhen datasets exceed nearly 100,000 rows, full-table scans drastically impact retrieval speeds. This project incorporates strategic B-Tree Indexes mapped onto relational paths to pivot performance from $O(N)$ linear scans into optimized $O(\log N)$ structural evaluations.
-- Query Speed-up Indexes
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_payments_order_id ON order_payments(order_id);

-- You can measure execution cost impacts using profiling metrics
EXPLAIN SELECT * FROM orders WHERE customer_id = '9ef432eb6251297304e76186b10a928d';

