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
    WHERE user_id IS NOT NULL
      AND user_session IS NOT NULL
    GROUP BY user_id, user_session
)

SELECT
    DATE_TRUNC(
        'week',
        first_view AT TIME ZONE 'UTC'
    )::date AS week_start,

    COUNT(*) AS view_sessions,

    COUNT(*) FILTER (
        WHERE last_purchase > first_view
    ) AS converted_sessions,

    ROUND(
        COUNT(*) FILTER (
            WHERE last_purchase > first_view
        ) * 100.0 / COUNT(*),
        2
    ) AS session_cr

FROM sessions
WHERE first_view >= '2019-10-07'
  AND first_view < '2019-10-28'

GROUP BY week_start
ORDER BY week_start