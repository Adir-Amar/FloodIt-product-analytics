-- What events exist in the export, how often does each fire, and how many distinct users fire it?
-- One row per event type.
SELECT event_name, COUNT(*) AS event_count, COUNT(DISTINCT user_pseudo_id) AS users_per_event
FROM `firebase-public-project.analytics_153293282.events_*`
GROUP BY event_name
ORDER BY event_count DESC, users_per_event DESC;
