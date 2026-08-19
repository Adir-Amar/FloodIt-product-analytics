-- First install date per user, from the earliest first_open. One row per in-window installer.
-- Users whose first_open predates the export never appear here — that absence is what defines the cohort.
SELECT user_pseudo_id, MIN(PARSE_DATE('%Y%m%d', event_date)) AS day_0
FROM `firebase-public-project.analytics_153293282.events_*`
WHERE event_name = 'first_open'
GROUP BY user_pseudo_id;
