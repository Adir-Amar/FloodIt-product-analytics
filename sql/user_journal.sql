-- First install date per user, from the earliest first_open. One row per in-window installer.
-- Users whose first_open predates the export never appear here — that absence is what defines the cohort.

SELECT DISTINCT user_pseudo_id AS player, PARSE_DATE('%Y%m%d', event_date) AS active_day
FROM `firebase-public-project.analytics_153293282.events_*`;
