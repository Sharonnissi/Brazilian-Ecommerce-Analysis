-- Advanced Business Analysis: Brazilian E-commerce

-- Complex analytical queries using window functions, CTEs, and advanced SQL

-- 1. CUSTOMER LIFETIME VALUE AND RETENTION

-- Customer cohort analysis by registration month
WITH customer_cohorts AS (
    SELECT 
        customer_unique_id,
        DATE_FORMAT(MIN(order_purchase_timestamp), '%Y-%m') as cohort_month,
        MIN(order_purchase_timestamp) as first_order_date
    FROM orders
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id
),
cohort_data AS (
    SELECT 
        cc.cohort_month,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') as order_month,
        COUNT(DISTINCT o.customer_unique_id) as customers
    FROM customer_cohorts cc
    JOIN orders o ON cc.customer_unique_id = o.customer_unique_id
    WHERE o.order_status = 'delivered'
    GROUP BY cc.cohort_month, DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
)
SELECT 
    cohort_month,
    order_month,
    customers,
    ROUND(customers * 100.0 / FIRST_VALUE(customers) OVER (
        PARTITION BY cohort_month 
        ORDER BY order_month
    ), 2) as retention_rate
FROM cohort_data
WHERE cohort_month >= '2017-01' AND cohort_month <= '2018-06'
ORDER BY cohort_month, order_month;

-- Customer RFM Analysis (Recency, Frequency, Monetary)
WITH customer_rfm AS (
    SELECT 
        customer_unique_id,
        DATEDIFF('2018-10-17', MAX(order_purchase_timestamp)) as recency_days,
        COUNT(DISTINCT order_id) as frequency,
        SUM(price + freight_value) as monetary_value
    FROM orders
    WHERE order_status = 'delivered'
        AND price IS NOT NULL
        AND freight_value IS NOT NULL
    GROUP BY customer_unique_id
),
rfm_scores AS (
    SELECT 
        customer_unique_id,
        recency_days,
        frequency,
        monetary_value,
        NTILE(5) OVER (ORDER BY recency_days DESC) as recency_score,
        NTILE(5) OVER (ORDER BY frequency) as frequency_score,
        NTILE(5) OVER (ORDER BY monetary_value) as monetary_score
    FROM customer_rfm
)
SELECT 
    CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 3 AND frequency_score <= 2 AND monetary_score >= 3 THEN 'Potential Loyalists'
        WHEN recency_score >= 4 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'New Customers'
        WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'At Risk'
        WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score >= 3 THEN 'Cannot Lose Them'
        WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score <= 2 THEN 'Hibernating'
        ELSE 'Others'
    END as customer_segment,
    COUNT(*) as customer_count,
    ROUND(AVG(monetary_value), 2) as avg_monetary_value,
    ROUND(AVG(frequency), 1) as avg_frequency,
    ROUND(AVG(recency_days), 1) as avg_recency_days
FROM rfm_scores
GROUP BY customer_segment
ORDER BY customer_count DESC;

-- 2. SELLER PERFORMANCE ANALYSIS
-- Top performing sellers with delivery metrics
WITH seller_metrics AS (
    SELECT 
        seller_id,
        COUNT(*) as total_orders,
        SUM(price) as total_revenue,
        ROUND(AVG(price), 2) as avg_product_price,
        COUNT(DISTINCT product_category_name_english) as categories_sold,
        COUNT(DISTINCT customer_unique_id) as unique_customers,
        AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) as avg_delivery_time,
        SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) as late_deliveries,
        ROUND(SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as late_delivery_rate
    FROM orders
    WHERE order_status = 'delivered'
        AND order_delivered_customer_date IS NOT NULL
        AND order_estimated_delivery_date IS NOT NULL
        AND price IS NOT NULL
    GROUP BY seller_id
    HAVING COUNT(*) >= 50  -- Only sellers with significant volume
)
SELECT 
    seller_id,
    total_orders,
    ROUND(total_revenue, 2) as total_revenue,
    avg_product_price,
    categories_sold,
    unique_customers,
    ROUND(avg_delivery_time, 1) as avg_delivery_time,
    late_deliveries,
    late_delivery_rate,
    ROUND(total_revenue / total_orders, 2) as revenue_per_order
FROM seller_metrics
ORDER BY total_revenue DESC
LIMIT 20;

-- 3. SEASONAL AND TREND ANALYSIS
-- Monthly growth rates and trends
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') as month,
        COUNT(DISTINCT order_id) as total_orders,
        SUM(price + freight_value) as total_revenue,
        COUNT(DISTINCT customer_unique_id) as unique_customers
    FROM orders
    WHERE order_status = 'delivered'
        AND price IS NOT NULL
        AND freight_value IS NOT NULL
    GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
)
SELECT 
    month,
    total_orders,
    ROUND(total_revenue, 2) as total_revenue,
    unique_customers,
    ROUND(total_revenue / total_orders, 2) as avg_order_value,
    LAG(total_revenue) OVER (ORDER BY month) as prev_month_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY month)) 
        / LAG(total_revenue) OVER (ORDER BY month) * 100, 2
    ) as revenue_growth_rate,
    SUM(total_revenue) OVER (ORDER BY month) as running_total_revenue
FROM monthly_revenue
WHERE month >= '2017-01'
ORDER BY month;

-- Day of week analysis
SELECT 
    DAYNAME(order_purchase_timestamp) as day_of_week,
    COUNT(*) as total_orders,
    ROUND(SUM(price + freight_value), 2) as total_revenue,
    ROUND(AVG(price + freight_value), 2) as avg_order_value,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage_of_orders
FROM orders
WHERE order_status = 'delivered'
    AND price IS NOT NULL
    AND freight_value IS NOT NULL
GROUP BY DAYNAME(order_purchase_timestamp), DAYOFWEEK(order_purchase_timestamp)
ORDER BY DAYOFWEEK(order_purchase_timestamp);

-- 4. PRODUCT CATEGORY DEEP DIVE
-- Category performance with growth trends
WITH category_monthly AS (
    SELECT 
        product_category_name_english,
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') as month,
        COUNT(*) as orders,
        SUM(price) as revenue
    FROM orders
    WHERE order_status = 'delivered'
        AND product_category_name_english IS NOT NULL
        AND price IS NOT NULL
    GROUP BY product_category_name_english, DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
),
category_growth AS (
    SELECT 
        product_category_name_english,
        month,
        orders,
        revenue,
        LAG(revenue) OVER (PARTITION BY product_category_name_english ORDER BY month) as prev_month_revenue,
        ROUND(
            (revenue - LAG(revenue) OVER (PARTITION BY product_category_name_english ORDER BY month)) 
            / LAG(revenue) OVER (PARTITION BY product_category_name_english ORDER BY month) * 100, 2
        ) as growth_rate
    FROM category_monthly
)
SELECT 
    product_category_name_english,
    COUNT(*) as months_active,
    ROUND(AVG(growth_rate), 2) as avg_monthly_growth_rate,
    ROUND(SUM(revenue), 2) as total_revenue,
    ROUND(STDDEV(growth_rate), 2) as growth_volatility
FROM category_growth
WHERE growth_rate IS NOT NULL
GROUP BY product_category_name_english
HAVING COUNT(*) >= 12  -- Categories active for at least 12 months
ORDER BY total_revenue DESC
LIMIT 15;

-- 5. GEOGRAPHIC DISTANCE ANALYSIS
-- Average distance between customers and sellers (using coordinates)
WITH order_distances AS (
    SELECT 
        order_id,
        customer_unique_id,
        seller_id,
        geolocation_state_customer,
        price + freight_value as order_value,
        freight_value,
        -- Calculate distance using Haversine formula (approximate)
        ROUND(
            6371 * 2 * ASIN(
                SQRT(
                    POWER(SIN((RADIANS(geolocation_lat_seller) - RADIANS(geolocation_lat_customer))/2), 2) +
                    COS(RADIANS(geolocation_lat_customer)) * COS(RADIANS(geolocation_lat_seller)) *
                    POWER(SIN((RADIANS(geolocation_lng_seller) - RADIANS(geolocation_lng_customer))/2), 2)
                )
            ), 2
        ) as distance_km
    FROM orders
    WHERE order_status = 'delivered'
        AND geolocation_lat_customer IS NOT NULL
        AND geolocation_lng_customer IS NOT NULL
        AND geolocation_lat_seller IS NOT NULL
        AND geolocation_lng_seller IS NOT NULL
        AND price IS NOT NULL
        AND freight_value IS NOT NULL
)
SELECT 
    geolocation_state_customer,
    COUNT(*) as total_orders,
    ROUND(AVG(distance_km), 2) as avg_distance_km,
    ROUND(AVG(freight_value), 2) as avg_freight_value,
    ROUND(AVG(freight_value / distance_km), 4) as freight_per_km,
    ROUND(AVG(order_value), 2) as avg_order_value
FROM order_distances
WHERE distance_km > 0 AND distance_km < 5000  -- Remove outliers
GROUP BY geolocation_state_customer
HAVING COUNT(*) >= 100
ORDER BY avg_distance_km DESC
LIMIT 15;
