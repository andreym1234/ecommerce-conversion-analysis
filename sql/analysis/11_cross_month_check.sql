WITH sessions AS (
    SELECT
        user_id,
        user_session,
        MIN(event_time) FILTER (
            WHERE event_type = 'view'
        ) AS first_view,
        MAX(event_time) FILTER (
            WHERE event_type = 'purchase'
              AND event_time < '2019-11-01 00:00:00+00'
        ) AS last_purchase_october,
        MAX(event_time) FILTER (
            WHERE event_type = 'purchase'
        ) AS last_purchase_all
    FROM raw.events
    WHERE user_id IS NOT NULL
      AND user_session IS NOT NULL
    GROUP BY user_id, user_session
)

SELECT
    COUNT(*) FILTER (
        WHERE last_purchase_october > first_view
    ) AS converted_october_only,

    COUNT(*) FILTER (
        WHERE last_purchase_all > first_view
    ) AS converted_with_november

FROM sessions
WHERE first_view >= '2019-10-07 00:00:00+00'
  AND first_view < '2019-10-28 00:00:00+00'