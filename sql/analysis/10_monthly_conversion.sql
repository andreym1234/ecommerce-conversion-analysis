WITH monthly_events AS (
    SELECT
        CASE
            WHEN event_time < '2019-11-01'
                THEN 'October'
            ELSE 'November'
        END AS month,
        user_id,
        user_session,
        event_time,
        event_type
    FROM raw.events
    WHERE event_time >= '2019-10-01'
      AND event_time < '2019-12-01'
      AND user_id IS NOT NULL
      AND user_session IS NOT NULL
),

sessions AS (
    SELECT
        month,
        user_id,
        user_session,
        MIN(event_time) FILTER (
            WHERE event_type = 'view'
        ) AS first_view,
        MAX(event_time) FILTER (
            WHERE event_type = 'purchase'
        ) AS last_purchase
    FROM monthly_events
    GROUP BY month, user_id, user_session
),

filtered_sessions AS (
    SELECT *
    FROM sessions
    WHERE
        (
            month = 'October'
            AND first_view >= '2019-10-07'
            AND first_view < '2019-10-28'
        )
        OR
        (
            month = 'November'
            AND first_view >= '2019-11-04'
            AND first_view < '2019-11-25'
        )
)

SELECT
    month,
    COUNT(*) AS view_sessions,
    COUNT(*) FILTER (
        WHERE last_purchase > first_view
    ) AS converted_sessions,
    ROUND(
        COUNT(*) FILTER (
            WHERE last_purchase > first_view
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS session_cr
FROM filtered_sessions
GROUP BY month
ORDER BY CASE WHEN month = 'October' THEN 1 ELSE 2 END