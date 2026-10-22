WITH weekly_sessions AS (
    SELECT
        DATE_TRUNC(
            'week',
            first_view AT TIME ZONE 'UTC'
        )::date AS week_start,

        last_purchase > first_view AS converted

    FROM analytics.sessions

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
    week_start,
    COUNT(*) AS view_sessions,

    COUNT(*) FILTER (
        WHERE converted
    ) AS converted_sessions,

    ROUND(
        COUNT(*) FILTER (WHERE converted) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS session_cr

FROM weekly_sessions
GROUP BY week_start
ORDER BY week_start