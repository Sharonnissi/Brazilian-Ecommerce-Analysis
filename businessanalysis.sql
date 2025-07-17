-- Business Analysis: Brazilian E-commerce


-- Key business questions and insights


-- 1. REVENUE ANALYSIS
-- Monthly revenue trends
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') as month,
    COUNT(DISTINCT order_id) as total_orders,
    SUM(price) as product_revenue,
    SUM(freight_value) as shipping_revenue,
    SUM(price + freight_value) as total_revenue,
    ROUND(AVG(price + freight_value), 2) as avg_order_value
FROM orders
WHERE order_status = 'delivered'
    AND order_purchase_timestamp IS NOT NULL
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY month;

-- Top revenue generating product categories
SELECT 
    product_category_name_english,
    COUNT(*) as total_orders,
    ROUND(SUM(price), 2) as total_revenue,
    ROUND(AVG(price), 2) as avg_product_price,
    ROUND(SUM(freight_value), 2) as total_shipping_costs,
    ROUND(SUM(freight_value) / SUM(price) * 100, 2) as shipping_cost_percentage
FROM orders
WHERE order_status = 'delivered' 
    AND product_category_name_english IS NOT NULL
    AND price IS NOT NULL
GROUP BY product_category_name_english
ORDER BY total_revenue DESC
LIMIT 15;

-- 2. CUSTOMER ANALYSIS
-- Customer segmentation by purchase behavior
WITH customer_metrics AS (
    SELECT 
        customer_unique_id,
        COUNT(*) as total_orders,
        SUM(price + freight_value) as total_spent,
        ROUND(AVG(price + freight_value), 2) as avg_order_value,
        MIN(order_purchase_timestamp) as first_order,
        MAX(order_purchase_timestamp) as last_order,
        DATEDIFF(MAX(order_purchase_timestamp), MIN(order_purchase_timestamp)) as customer_lifespan_days
    FROM orders
    WHERE order_status = 'delivered'
        AND price IS NOT NULL
        AND freight_value IS NOT NULL
    GROUP BY customer_unique_id
)
SELECT 
    CASE 
        WHEN total_orders = 1 THEN 'One-time Buyer'
        WHEN total_orders BETWEEN 2 AND 5 THEN 'Occasional Buyer'
        WHEN total_orders > 5 THEN 'Frequent Buyer'
    END as customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_lifetime_value,
    ROUND(AVG(avg_order_value), 2) as avg_order_size,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage_of_customers
FROM customer_metrics
GROUP BY customer_segment
ORDER BY customer_count DESC;

-- Top customers by lifetime value
WITH customer_metrics AS (
    SELECT 
        customer_unique_id,
        COUNT(*) as total_orders,
        SUM(price + freight_value) as total_spent,
        geolocation_state_customer,
        MIN(order_purchase_timestamp) as first_order,
        MAX(order_purchase_timestamp) as last_order
    FROM orders
    WHERE order_status = 'delivered'
        AND price IS NOT NULL
        AND freight_value IS NOT NULL
    GROUP BY customer_unique_id, geolocation_state_customer
)
SELECT 
    customer_unique_id,
    geolocation_state_customer,
    total_orders,
    ROUND(total_spent, 2) as total_spent,
    ROUND(total_spent / total_orders, 2) as avg_order_value,
    DATEDIFF(last_order, first_order) as customer_lifespan_days
FROM customer_metrics
ORDER BY total_spent DESC
LIMIT 20;

-- 3. GEOGRAPHIC ANALYSIS
-- Revenue by state (top performing states)
SELECT 
    geolocation_state_customer,
    COUNT(DISTINCT customer_unique_id) as unique_customers,
    COUNT(*) as total_orders,
    ROUND(SUM(price + freight_value), 2) as total_revenue,
    ROUND(AVG(price + freight_value), 2) as avg_order_value,
    ROUND(SUM(price + freight_value) / COUNT(DISTINCT customer_unique_id), 2) as revenue_per_customer
FROM orders
WHERE order_status = 'delivered'
    AND geolocation_state_customer IS NOT NULL
    AND price IS NOT NULL
    AND freight_value IS NOT NULL
GROUP BY geolocation_state_customer
ORDER BY total_revenue DESC;

-- City-level performance (top 20 cities)
SELECT 
    geolocation_city_customer,
    geolocation_state_customer,
    COUNT(*) as total_orders,
    ROUND(SUM(price + freight_value), 2) as total_revenue,
    COUNT(DISTINCT customer_unique_id) as unique_customers,
    ROUND(AVG(price + freight_value), 2) as avg_order_value
FROM orders
WHERE order_status = 'delivered'
    AND geolocation_city_customer IS NOT NULL
    AND price IS NOT NULL
    AND freight_value IS NOT NULL
GROUP BY geolocation_city_customer, geolocation_state_customer
HAVING COUNT(*) >= 50  -- Only cities with significant volume
ORDER BY total_revenue DESC
LIMIT 20;

-- 4. OPERATIONAL PERFORMANCE
-- Delivery performance analysis
SELECT 
    order_status,
    COUNT(*) as order_count,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) as avg_delivery_days,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)), 1) as avg_delay_days,
    SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) as late_deliveries,
    ROUND(SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as late_delivery_rate
FROM orders
WHERE order_delivered_customer_date IS NOT NULL 
    AND order_estimated_delivery_date IS NOT NULL
    AND order_purchase_timestamp IS NOT NULL
GROUP BY order_status
ORDER BY order_count DESC;

-- Late delivery analysis by product category
SELECT 
    product_category_name_english,
    COUNT(*) as total_orders,
    SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) as late_deliveries,
    ROUND(SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as late_delivery_rate,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 1) as avg_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL 
    AND order_estimated_delivery_date IS NOT NULL
    AND product_category_name_english IS NOT NULL
GROUP BY product_category_name_english
HAVING COUNT(*) >= 100  -- Only categories with significant volume
ORDER BY late_delivery_rate DESC
LIMIT 15;

-- 5. PAYMENT ANALYSIS
-- Payment method preferences and performance
SELECT 
    payment_type,
    COUNT(*) as transaction_count,
    ROUND(SUM(payment_value), 2) as total_payment_value,
    ROUND(AVG(payment_value), 2) as avg_payment_amount,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage_of_orders,
    ROUND(AVG(price), 2) as avg_product_price,
    ROUND(AVG(payment_value - price), 2) as avg_payment_vs_price_diff
FROM orders
WHERE order_status = 'delivered'
    AND payment_type IS NOT NULL
    AND payment_value IS NOT NULL
    AND price IS NOT NULL
GROUP BY payment_type
ORDER BY transaction_count DESC;
