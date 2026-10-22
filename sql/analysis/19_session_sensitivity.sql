SET work_mem = '32MB';

WITH ordered_events AS (
    SELECT
        user_id,
        user_session,
        session_number,
        event_time,
        event_type,
        LAG(event_time) OVER (
            PARTITION BY user_id, user_session, session_number
            ORDER BY event_time
        ) AS previous_event_time
    FROM analytics.session_events
),

numbered_15 AS (
    SELECT
        *,
        SUM(
            CASE
                WHEN previous_event_time IS NULL
                  OR event_time - previous_event_time > INTERVAL '15 minutes'
                THEN 1 ELSE 0
            END
        ) OVER (
            PARTITION BY user_id, user_session, session_number
            ORDER BY event_time
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS part_15
    FROM ordered_events
),

sessions_15 AS (
    SELECT
        MIN(event_time) FILTER (
            WHERE event_type = 'view'
        ) AS first_view,
        MAX(event_time) FILTER (
            WHERE event_type = 'purchase'
        ) AS last_purchase
    FROM numbered_15
    GROUP BY user_id, user_session, session_number, part_15
),

ordered_sessions AS (
    SELECT
        *,
        LAG(session_end) OVER (
            PARTITION BY user_id, user_session
            ORDER BY session_number
        ) AS previous_session_end
    FROM analytics.sessions
),

numbered_60 AS (
    SELECT
        *,
        SUM(
            CASE
                WHEN previous_session_end IS NULL
                  OR session_start - previous_session_end > INTERVAL '60 minutes'
                THEN 1 ELSE 0
            END
        ) OVER (
            PARTITION BY user_id, user_session
            ORDER BY session_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS part_60
    FROM ordered_sessions
),

sessions_60 AS (
    SELECT
        MIN(first_view) AS first_view,
        MAX(last_purchase) AS last_purchase
    FROM numbered_60
    GROUP BY user_id, user_session, part_60
),

all_sessions AS (
    SELECT
        15 AS threshold_minutes,
        first_view,
        last_purchase
    FROM sessions_15

    UNION ALL

    SELECT
        30,
        first_view,
        last_purchase
    FROM analytics.sessions

    UNION ALL

    SELECT
        60,
        first_view,
        last_purchase
    FROM sessions_60
),

filtered AS (
    SELECT
        threshold_minutes,
        CASE
            WHEN first_view >= '2019-10-07 00:00:00+00'
             AND first_view < '2019-10-28 00:00:00+00'
                THEN 'October'
            ELSE 'November'
        END AS month,
        last_purchase > first_view AS converted
    FROM all_sessions
    WHERE (
        first_view >= '2019-10-07 00:00:00+00'
        AND first_view < '2019-10-28 00:00:00+00'
    )
    OR (
        first_view >= '2019-11-04 00:00:00+00'
        AND first_view < '2019-11-25 00:00:00+00'
    )
)

SELECT
    threshold_minutes,
    month,
    COUNT(*) AS view_sessions,
    COUNT(*) FILTER (
        WHERE converted
    ) AS converted_sessions,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE converted)
        / NULLIF(COUNT(*), 0),
        2
    ) AS session_cr
FROM filtered
GROUP BY threshold_minutes, month
ORDER BY
    threshold_minutes,
    CASE WHEN month = 'October' THEN 1 ELSE 2 END