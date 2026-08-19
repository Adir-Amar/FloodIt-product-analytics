SELECT DISTINCT user_pseudo_id AS player, PARSE_DATE('%Y%m%d', event_date) AS active_day
FROM `firebase-public-project.analytics_153293282.events_*`;
