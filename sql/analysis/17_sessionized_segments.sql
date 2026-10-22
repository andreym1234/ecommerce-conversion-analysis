WITH first_purchases AS (
    SELECT
        user_id,
        MIN(event_time) AS first_purchase
    FROM raw.events
    WHERE event_type = 'purchase'
      AND user_id IS NOT NULL
    GROUP BY user_id
),

segmented AS (
    SELECT
        CASE
            WHEN s.first_view >= '2019-10-07 00:00:00+00'
             AND s.first_view < '2019-10-28 00:00:00+00'
                THEN 'October'
            ELSE 'November'
        END AS month,

        CASE
            WHEN p.first_purchase < s.session_start
                THEN 'Prior purchaser'
            ELSE 'No prior purchase'
        END AS segment,

        s.last_purchase > s.first_view AS converted

    FROM analytics.sessions s

    LEFT JOIN first_purchases p
        ON s.user_id = p.user_id

    WHERE (
        s.first_view >= '2019-10-07 00:00:00+00'
        AND s.first_view < '2019-10-28 00:00:00+00'
    )
    OR (
        s.first_view >= '2019-11-04 00:00:00+00'
        AND s.first_view < '2019-11-25 00:00:00+00'
    )
)

SELECT
    month,
    segment,
    COUNT(*) AS view_sessions,
    COUNT(*) FILTER (
        WHERE converted
    ) AS converted_sessions,

    ROUND(
        COUNT(*) FILTER (WHERE converted) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS session_cr

FROM segmented
GROUP BY month, segment
ORDER BY month, segment