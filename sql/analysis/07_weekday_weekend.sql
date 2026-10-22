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
),

segmented AS (
    SELECT
        CASE
            WHEN EXTRACT(ISODOW FROM first_view AT TIME ZONE 'UTC') IN (6, 7)
                THEN 'Weekend'
            ELSE 'Weekday'
        END AS segment,
        last_purchase > first_view AS converted
    FROM sessions
    WHERE first_view >= '2019-10-07'
      AND first_view < '2019-10-28'
)

SELECT
    segment,
    COUNT(*) AS view_sessions,
    COUNT(*) FILTER (WHERE converted) AS converted_sessions,
    ROUND(
        COUNT(*) FILTER (WHERE converted) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS session_cr
FROM segmented
GROUP BY segment
ORDER BY segment