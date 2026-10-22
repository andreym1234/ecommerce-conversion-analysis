SELECT
    event_type,
    COUNT(*) AS event_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS event_percent
FROM raw.events
GROUP BY event_type
ORDER BY event_count DESC