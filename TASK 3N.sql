use ecommerce_practice;
show tables;


## 1 & 4. Core Data Retrieval, Filtering, and Aggregations
## Concepts used: SELECT, WHERE, GROUP BY, ORDER BY, SUM(), AVG(), COUNT()

## To understand your geographic footprint, this query filters for top-tier economic states, lists the customer concentration per city, and ranks them.
SELECT customer_state, customer_city, COUNT(customer_id) AS total_orders
FROM customers
WHERE customer_state IN ('SP', 'RJ', 'MG')
GROUP BY customer_state, customer_city
HAVING COUNT(customer_id) >= 100
ORDER BY total_orders DESC;

## 2. Complex Relations with Joins
## Concepts used: LEFT JOIN, RIGHT JOIN
## a. LEFT JOIN (Identifying Dormant Sellers)

##This identifies registered sellers who have never successfully closed a transaction item sale.
SELECT s.seller_id, s.seller_city, s.seller_state
FROM sellers s
LEFT JOIN order_items oi ON s.seller_id = oi.seller_id
WHERE oi.seller_id IS NULL;

## b. RIGHT JOIN (Unreviewed Orders)

## This tracks customer engagement gaps by highlighting orders that successfully completed but received no corresponding entries in the reviews dataset.
SELECT o.order_id, o.order_status, r.review_id
FROM order_reviews r
RIGHT JOIN orders o ON r.order_id = o.order_id
WHERE r.review_id IS NULL;

## 3. Advanced Deep Dives using Subqueries1. 
## High-Value Orders Subquery

## This isolates orders where the combined payments exceed the platform's overall average transactional payment value ($\text{AOV}$).
SELECT o.order_id, o.customer_id,SUM(op.payment_value) AS total_order_payment
FROM orders o
INNER JOIN order_payments op ON o.order_id = op.order_id
GROUP BY o.order_id, o.customer_id
HAVING SUM(op.payment_value) > (-- Subquery: Calculates global average payment per order line
SELECT AVG(payment_value) 
        FROM order_payments)
ORDER BY total_order_payment DESC;

## 5. Creating Views for Business Intelligence
## Views encapsulate multi-table joins into tidy, virtual reporting tables, making it simple for dashboards to fetch synchronized transactional profiles.

CREATE VIEW view_order_fulfillment_analytics AS
SELECT o.order_id,o.order_status,o.order_purchase_timestamp,c.customer_city,c.customer_state,
    COALESCE(SUM(op.payment_value), 0) AS total_monetary_value,
    AVG(r.review_score) AS average_satisfaction_score
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_payments op ON o.order_id = op.order_id
LEFT JOIN order_reviews r ON o.order_id = r.order_id
GROUP BY o.order_id, o.order_status, o.order_purchase_timestamp, c.customer_city, c.customer_state;

SELECT * FROM view_order_fulfillment_analytics 
WHERE order_status = 'delivered' AND average_satisfaction_score < 2.0;

## 6. Optimizing Queries with Indexes
## Running queries over nearly $100,000$ records with multi-stage JOIN conditions creates compute overhead. 
## Creating targeted indexes on foreign keys changes table lookup complexities from $O(N)$ full-scans to $O(\log N)$ binary tree searches.

-- Speed up customer-to-order grouping lookups
CREATE INDEX idx_orders_customer_id ON orders(customer_id);

-- Speed up itemized order cross-referencing
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Speed up payment processing joins
CREATE INDEX idx_order_payments_order_id ON order_payments(order_id);

EXPLAIN SELECT * FROM orders WHERE customer_id = '9ef432eb6251297304e76186b10a928d';