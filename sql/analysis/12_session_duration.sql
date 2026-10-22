WITH sessions AS (
    SELECT
        DATE_TRUNC(
            'month',
            event_time AT TIME ZONE 'UTC'
        )::date AS month,
        user_id,
        user_session,
        MIN(event_time) AS session_start,
        MAX(event_time) AS session_end
    FROM raw.events
    WHERE user_id IS NOT NULL
      AND user_session IS NOT NULL
    GROUP BY 1, 2, 3
),

durations AS (
    SELECT
        month,
        EXTRACT(EPOCH FROM (
            session_end - session_start
        )) / 3600 AS duration_hours
    FROM sessions
)

SELECT
    month,
    COUNT(*) AS total_sessions,
    COUNT(*) FILTER (
        WHERE duration_hours > 24
    ) AS sessions_over_24h,
    COUNT(*) FILTER (
        WHERE duration_hours > 168
    ) AS sessions_over_7d,
    ROUND(MAX(duration_hours), 2) AS max_duration_hours
FROM durations
GROUP BY month
ORDER BY month