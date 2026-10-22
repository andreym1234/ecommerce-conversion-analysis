WITH first_views AS (
    SELECT
        user_id,
        user_session,
        MIN(event_time) AS first_view
    FROM raw.events
    WHERE event_type = 'view'
      AND user_id IS NOT NULL
      AND user_session IS NOT NULL
    GROUP BY user_id, user_session
),

first_carts AS (
    SELECT
        e.user_id,
        e.user_session,
        MIN(e.event_time) AS first_cart
    FROM raw.events e
    JOIN first_views v
      ON e.user_id = v.user_id
     AND e.user_session = v.user_session
    WHERE e.event_type = 'cart'
      AND e.event_time > v.first_view
    GROUP BY e.user_id, e.user_session
),

first_purchases AS (
    SELECT
        e.user_id,
        e.user_session,
        MIN(e.event_time) AS first_purchase
    FROM raw.events e
    JOIN first_carts c
      ON e.user_id = c.user_id
     AND e.user_session = c.user_session
    WHERE e.event_type = 'purchase'
      AND e.event_time > c.first_cart
    GROUP BY e.user_id, e.user_session
),

counts AS (
    SELECT
        (SELECT COUNT(*) FROM first_views) AS views,
        (SELECT COUNT(*) FROM first_carts) AS carts,
        (SELECT COUNT(*) FROM first_purchases) AS purchases
)

SELECT
    views,
    carts,
    purchases,
    ROUND(carts * 100.0 / NULLIF(views, 0), 2) AS view_to_cart_cr,
    ROUND(purchases * 100.0 / NULLIF(carts, 0), 2) AS cart_to_purchase_cr,
    ROUND(purchases * 100.0 / NULLIF(views, 0), 2) AS full_funnel_cr
FROM counts