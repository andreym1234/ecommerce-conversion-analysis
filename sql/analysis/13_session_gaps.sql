WITH ordered_events AS (
    SELECT
        user_id,
        user_session,
        event_time,
        LAG(event_time) OVER (
            PARTITION BY user_id, user_session
            ORDER BY event_time
        ) AS previous_event_time
    FROM raw.events
    WHERE event_time >= '2019-10-01 00:00:00+00'
      AND event_time < '2019-11-01 00:00:00+00'
      AND user_id IS NOT NULL
      AND user_session IS NOT NULL
)

SELECT
    COUNT(*) FILTER (
        WHERE event_time - previous_event_time > INTERVAL '30 minutes'
    ) AS gaps_over_30m,

    COUNT(*) FILTER (
        WHERE event_time - previous_event_time > INTERVAL '24 hours'
    ) AS gaps_over_24h

FROM ordered_events