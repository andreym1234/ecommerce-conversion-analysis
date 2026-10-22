WITH sessions AS (
    SELECT
        user_id,
        user_session,
        MIN(event_time) AS session_start,
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

first_purchases AS (
    SELECT
        user_id,
        MIN(event_time) AS first_purchase
    FROM raw.events
    WHERE event_type = 'purchase'
    GROUP BY user_id
),

segmented AS (
    SELECT
        CASE
            WHEN p.first_purchase < s.session_start
                THEN 'Prior purchaser'
            ELSE 'No prior purchase'
        END AS segment,

        s.last_purchase > s.first_view AS converted

    FROM sessions s
    LEFT JOIN first_purchases p
        ON s.user_id = p.user_id

    WHERE s.first_view >= '2019-10-07'
      AND s.first_view < '2019-10-28'
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