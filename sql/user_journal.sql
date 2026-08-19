-- Every day each user was active, on any event at all. One row per (user, active day).
-- DISTINCT collapses a day's many events into a single row; this pair is the unit retention is measured on.

SELECT DISTINCT user_pseudo_id AS player, PARSE_DATE('%Y%m%d', event_date) AS active_day
FROM `firebase-public-project.analytics_153293282.events_*`;
