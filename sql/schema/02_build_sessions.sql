BEGIN;

SET LOCAL work_mem = '16MB';

CREATE SCHEMA IF NOT EXISTS analytics;

DROP TABLE IF EXISTS analytics.sessions;
DROP TABLE IF EXISTS analytics.session_events;

CREATE TABLE analytics.session_events AS

WITH ordered AS (
    SELECT
        e.*,
        e.ctid AS row_locator,

        LAG(event_time) OVER (
            PARTITION BY user_id, user_session
            ORDER BY event_time, e.ctid
        ) AS previous_event_time

    FROM raw.events e
    WHERE user_id IS NOT NULL
      AND user_session IS NOT NULL
),

marked AS (
    SELECT
        *,
        CASE
            WHEN previous_event_time IS NULL
              OR event_time - previous_event_time > INTERVAL '30 minutes'
            THEN 1
            ELSE 0
        END AS new_session
    FROM ordered
),

numbered AS (
    SELECT
        *,
        SUM(new_session) OVER (
            PARTITION BY user_id, user_session
            ORDER BY event_time, row_locator
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS session_number
    FROM marked
)

SELECT
    event_time,
    event_type,
    product_id,
    category_id,
    category_code,
    brand,
    price,
    user_id,
    user_session,
    session_number
FROM numbered;


CREATE INDEX idx_session_events
ON analytics.session_events (
    user_id,
    user_session,
    session_number,
    event_time
);


CREATE TABLE analytics.sessions AS
SELECT
    user_id,
    user_session,
    session_number,

    MIN(event_time) AS session_start,
    MAX(event_time) AS session_end,

    MIN(event_time) FILTER (
        WHERE event_type = 'view'
    ) AS first_view,

    MAX(event_time) FILTER (
        WHERE event_type = 'purchase'
    ) AS last_purchase,

    COUNT(*) AS event_count

FROM analytics.session_events
GROUP BY
    user_id,
    user_session,
    session_number;


CREATE INDEX idx_sessions_first_view
ON analytics.sessions (first_view);

COMMIT