-- Brazilian E-commerce Data Exploration

-- Basic data overview
SELECT 'Total Orders' as metric, COUNT(*) as value FROM orders
UNION ALL
SELECT 'Unique Customers', COUNT(DISTINCT customer_unique_id) FROM orders
UNION ALL
SELECT 'Unique Sellers', COUNT(DISTINCT seller_id) FROM orders
UNION ALL
SELECT 'Unique Products', COUNT(DISTINCT product_id) FROM orders;

-- Date range of data
SELECT 
    'Order Date Range' as metric,
    MIN(order_purchase_timestamp) as start_date,
    MAX(order_purchase_timestamp) as end_date,
    DATEDIFF(MAX(order_purchase_timestamp), MIN(order_purchase_timestamp)) as days_span
FROM orders;

-- Order status distribution
SELECT 
    order_status,
    COUNT(*) as order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- Product categories overview
SELECT 
    product_category_name_english,
    COUNT(*) as order_count,
    ROUND(AVG(price), 2) as avg_price,
    ROUND(AVG(freight_value), 2) as avg_freight
FROM orders
WHERE product_category_name_english IS NOT NULL
GROUP BY product_category_name_english
ORDER BY order_count DESC
LIMIT 15;

-- Geographic distribution (top states)
SELECT 
    geolocation_state_customer,
    COUNT(*) as order_count,
    COUNT(DISTINCT customer_unique_id) as unique_customers,
    ROUND(AVG(price + freight_value), 2) as avg_order_value
FROM orders
WHERE geolocation_state_customer IS NOT NULL
GROUP BY geolocation_state_customer
ORDER BY order_count DESC
LIMIT 10;

-- Payment methods
SELECT 
    payment_type,
    COUNT(*) as transaction_count,
    ROUND(AVG(payment_value), 2) as avg_payment_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM orders
WHERE payment_type IS NOT NULL
GROUP BY payment_type
ORDER BY transaction_count DESC;

-- Data quality check
SELECT 
    'Missing Order Status' as issue,
    COUNT(*) as count
FROM orders 
WHERE order_status IS NULL
UNION ALL
SELECT 
    'Missing Product Category',
    COUNT(*)
FROM orders 
WHERE product_category_name_english IS NULL
UNION ALL
SELECT 
    'Missing Price',
    COUNT(*)
FROM orders 
WHERE price IS NULL
UNION ALL
SELECT 
    'Missing Customer State',
    COUNT(*)
FROM orders 
WHERE geolocation_state_customer IS NULL;
