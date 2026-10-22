WITH segmented AS (
    SELECT
        CASE
            WHEN first_view >= '2019-10-07 00:00:00+00'
             AND first_view < '2019-10-28 00:00:00+00'
                THEN 'October'

            WHEN first_view >= '2019-11-04 00:00:00+00'
             AND first_view < '2019-11-25 00:00:00+00'
                THEN 'November'
        END AS month,

        last_purchase > first_view AS converted

    FROM analytics.sessions
    WHERE first_view IS NOT NULL
)

SELECT
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

FROM segmented
WHERE month IS NOT NULL
GROUP BY month
ORDER BY month