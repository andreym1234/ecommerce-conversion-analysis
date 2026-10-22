WITH sessions AS (
    SELECT
        user_id,
        user_session,
        MIN(event_time) FILTER (
            WHERE event_type = 'view'
        ) AS first_view,
        MAX(event_time) FILTER (
            WHERE event_type = 'purchase'
        ) AS last_purchase
    FROM raw.events
    WHERE user_session IS NOT NULL
      AND user_id IS NOT NULL
    GROUP BY user_id, user_session
)

SELECT
    COUNT(*) FILTER (
        WHERE first_view IS NOT NULL
    ) AS view_sessions,

    COUNT(*) FILTER (
        WHERE last_purchase > first_view
    ) AS converted_sessions,

    ROUND(
        COUNT(*) FILTER (
            WHERE last_purchase > first_view
        ) * 100.0
        / NULLIF(
            COUNT(*) FILTER (
                WHERE first_view IS NOT NULL
            ), 0
        ),
        2
    ) AS session_cr
FROM sessions