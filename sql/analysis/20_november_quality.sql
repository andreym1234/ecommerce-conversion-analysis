SELECT
    COUNT(*) AS total_events,

    COUNT(*) FILTER (
        WHERE user_session IS NULL
    ) AS missing_sessions,

    COUNT(*) FILTER (
        WHERE category_code IS NULL
    ) AS missing_categories,

    COUNT(*) FILTER (
        WHERE brand IS NULL
    ) AS missing_brands,

    COUNT(*) FILTER (
        WHERE price < 0
    ) AS negative_prices,

    COUNT(*) FILTER (
        WHERE event_type = 'purchase'
    ) AS purchase_events,

    COUNT(*) FILTER (
        WHERE event_type = 'purchase'
          AND price <= 0
    ) AS invalid_purchase_prices,

    COUNT(*) FILTER (
        WHERE event_type NOT IN (
            'view',
            'cart',
            'remove_from_cart',
            'purchase'
        )
    ) AS unknown_event_types

FROM raw.events
WHERE event_time >= '2019-11-01 00:00:00+00'
  AND event_time < '2019-12-01 00:00:00+00'