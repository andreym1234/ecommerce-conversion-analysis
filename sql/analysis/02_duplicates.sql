WITH duplicates AS (
    SELECT
        COUNT(*) AS duplicate_count
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
    COALESCE(SUM(duplicate_count - 1), 0) AS duplicate_rows,
    COUNT(*) FILTER (WHERE duplicate_count > 1) AS duplicate_groups
FROM duplicates