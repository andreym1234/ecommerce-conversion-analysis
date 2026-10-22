WITH selected_sessions AS (
    SELECT
        user_id,
        user_session,
        session_number,
        first_view,
        last_purchase,
        CASE
            WHEN first_view >= '2019-10-07'
             AND first_view < '2019-10-28'
                THEN 'October'
            ELSE 'November'
        END AS month
    FROM analytics.sessions
    WHERE
        (
            first_view >= '2019-10-07'
            AND first_view < '2019-10-28'
        )
        OR
        (
            first_view >= '2019-11-04'
            AND first_view < '2019-11-25'
        )
),

first_carts AS (
    SELECT
        s.user_id,
        s.user_session,
        s.session_number,
        MIN(e.event_time) AS first_cart
    FROM selected_sessions s
    JOIN analytics.session_events e
        ON s.user_id = e.user_id
       AND s.user_session = e.user_session
       AND s.session_number = e.session_number
    WHERE e.event_type = 'cart'
      AND e.event_time > s.first_view
    GROUP BY
        s.user_id,
        s.user_session,
        s.session_number
),

first_purchases AS (
    SELECT
        c.user_id,
        c.user_session,
        c.session_number,
        MIN(e.event_time) AS first_purchase
    FROM first_carts c
    JOIN analytics.session_events e
        ON c.user_id = e.user_id
       AND c.user_session = e.user_session
       AND c.session_number = e.session_number
    WHERE e.event_type = 'purchase'
      AND e.event_time > c.first_cart
    GROUP BY
        c.user_id,
        c.user_session,
        c.session_number
)

SELECT
    s.month,
    COUNT(*) AS view_sessions,

    COUNT(c.first_cart) AS cart_sessions,

    COUNT(p.first_purchase) AS purchase_sessions,

    ROUND(
        COUNT(c.first_cart) * 100.0 / COUNT(*), 2
    ) AS view_to_cart_cr,

    ROUND(
        COUNT(p.first_purchase) * 100.0
        / NULLIF(COUNT(c.first_cart), 0), 2
    ) AS cart_to_purchase_cr,

    ROUND(
        COUNT(p.first_purchase) * 100.0 / COUNT(*), 2
    ) AS full_funnel_cr

FROM selected_sessions s

LEFT JOIN first_carts c
    ON s.user_id = c.user_id
   AND s.user_session = c.user_session
   AND s.session_number = c.session_number

LEFT JOIN first_purchases p
    ON s.user_id = p.user_id
   AND s.user_session = p.user_session
   AND s.session_number = p.session_number

GROUP BY s.month
ORDER BY s.month