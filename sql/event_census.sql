-- Event census: volume and reach of all 37 event types across full window
-- One row per event type.
-- users_per_event is reach: users who fired it at least once. Valid within a row only — these
-- columns never sum across rows, since one user appears in many.
SELECT event_name, COUNT(*) AS event_count, COUNT(DISTINCT user_pseudo_id) AS users_per_event
FROM `firebase-public-project.analytics_153293282.events_*`
GROUP BY event_name
ORDER BY event_count DESC, users_per_event DESC;
