-- Basic data overview
-- Screenshot: https://github.com/Sharonnissi/Brazilian-Ecommerce-Analysis/blob/main/screenshots/query1.png
SELECT 'Total Orders' AS metric, COUNT(*) AS value FROM orders
UNION ALL
SELECT 'Unique Customers', COUNT(DISTINCT customer_unique_id) FROM orders
UNION ALL
SELECT 'Unique Sellers', COUNT(DISTINCT seller_id) FROM orders
UNION ALL
SELECT 'Unique Products', COUNT(DISTINCT product_id) FROM orders;

-- Date range of data
-- Screenshot: https://github.com/Sharonnissi/Brazilian-Ecommerce-Analysis/blob/main/screenshots/query2.png
SELECT 
    'Order Date Range' AS metric,
    MIN(order_purchase_timestamp) AS start_date,
    MAX(order_purchase_timestamp) AS end_date,
    DATEDIFF(MAX(order_purchase_timestamp), MIN(order_purchase_timestamp)) AS days_span
FROM orders;

-- Order status distribution
-- Screenshot: https://github.com/Sharonnissi/Brazilian-Ecommerce-Analysis/blob/main/screenshots/query3.png
SELECT 
    order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

-- Product categories overview
-- Screenshot: https://github.com/Sharonnissi/Brazilian-Ecommerce-Analysis/blob/main/screenshots/query4.png
SELECT 
    product_category_name_english,
    COUNT(*) AS order_count,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(AVG(freight_value), 2) AS avg_freight
FROM orders
WHERE product_category_name_english IS NOT NULL
GROUP BY product_category_name_english
ORDER BY order_count DESC
LIMIT 15;

-- Geographic distribution (top states)
-- Screenshot: https://github.com/Sharonnissi/Brazilian-Ecommerce-Analysis/blob/main/screenshots/query5.png
SELECT 
    geolocation_state_customer,
    COUNT(*) AS order_count,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    ROUND(AVG(price + freight_value), 2) AS avg_order_value
FROM orders
WHERE geolocation_state_customer IS NOT NULL
GROUP BY geolocation_state_customer
ORDER BY order_count DESC
LIMIT 10;

-- Payment methods
-- Screenshot: https://github.com/Sharonnissi/Brazilian-Ecommerce-Analysis/blob/main/screenshots/query6.png
SELECT 
    payment_type,
    COUNT(*) AS transaction_count,
    ROUND(AVG(payment_value), 2) AS avg_payment_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM orders
WHERE payment_type IS NOT NULL
GROUP BY payment_type
ORDER BY transaction_count DESC;

-- Data quality check
-- Screenshot: https://github.com/Sharonnissi/Brazilian-Ecommerce-Analysis/blob/main/screenshots/query7.png
SELECT 
    'Missing Order Status' AS issue,
    COUNT(*) AS count
FROM orders 
WHERE order_status IS NULL
UNION ALL
SELECT 
    'Missing Product Category' AS issue,
    COUNT(*) 
FROM orders 
WHERE product_category_name_english IS NULL
UNION ALL
SELECT 
    'Missing Price' AS issue,
    COUNT(*)
FROM orders 
WHERE price IS NULL
UNION ALL
SELECT 
    'Missing Customer State' AS issue,
    COUNT(*)
FROM orders 
WHERE geolocation_state_customer IS NULL;

