WITH converted_sessions AS (
    SELECT
        user_id,
        user_session,
        session_number,
        first_view,
        last_purchase,
        CASE
            WHEN first_view >= '2019-10-07 00:00:00+00'
             AND first_view < '2019-10-28 00:00:00+00'
                THEN 'October'
            ELSE 'November'
        END AS month
    FROM analytics.sessions
    WHERE last_purchase > first_view
      AND (
          (
              first_view >= '2019-10-07 00:00:00+00'
              AND first_view < '2019-10-28 00:00:00+00'
          )
          OR
          (
              first_view >= '2019-11-04 00:00:00+00'
              AND first_view < '2019-11-25 00:00:00+00'
          )
      )
),

cart_stats AS (
    SELECT
        s.month,
        s.user_id,
        s.user_session,
        s.session_number,
        s.last_purchase,
        COUNT(e.event_time) AS cart_events,
        MIN(e.event_time) FILTER (
            WHERE e.event_time > s.first_view
        ) AS first_cart_after_view
    FROM converted_sessions s
    LEFT JOIN analytics.session_events e
        ON s.user_id = e.user_id
       AND s.user_session = e.user_session
       AND s.session_number = e.session_number
       AND e.event_type = 'cart'
    GROUP BY
        s.month,
        s.user_id,
        s.user_session,
        s.session_number,
        s.last_purchase
),

classified AS (
    SELECT
        month,
        CASE
            WHEN first_cart_after_view < last_purchase
                THEN 'Full funnel'
            WHEN cart_events = 0
                THEN 'No cart'
            WHEN first_cart_after_view IS NULL
                THEN 'Cart before/at view'
            WHEN first_cart_after_view = last_purchase
                THEN 'Same timestamp'
            ELSE 'Purchase before cart'
        END AS reason
    FROM cart_stats
)

SELECT
    month,
    reason,
    COUNT(*) AS sessions
FROM classified
GROUP BY month, reason
ORDER BY month, sessions DESC