WITH grouped_events AS (
    SELECT
        event_type,
        COUNT(*) AS cnt
    FROM raw.events
    GROUP BY
        event_time,
        event_type,
        product_id,
        category_id,
        category_code,
        brand,
        price,
        user_id,
        user_session
)
SELECT
    event_type,
    SUM(cnt) AS total_events,
    SUM(cnt - 1) AS duplicate_rows,
    ROUND(
        100.0 * SUM(cnt - 1) / SUM(cnt),
        2
    ) AS duplicate_percent
FROM grouped_events
GROUP BY event_type
ORDER BY duplicate_rows DESC