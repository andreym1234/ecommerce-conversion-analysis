SELECT
    DATE_TRUNC(
        'month',
        event_time AT TIME ZONE 'UTC'
    )::date AS month,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(DISTINCT product_id) AS unique_products
FROM raw.events
GROUP BY month
ORDER BY month