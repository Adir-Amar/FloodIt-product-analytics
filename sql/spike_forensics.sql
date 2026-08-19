-- Daily event volume and reach across the spike days, the normal days interleaved between them, and
-- a stable baseline block. One row per (period, window group, event).
--
-- Built to separate more people from more logging: n_users is the reach axis, n_events the volume
-- axis. They answer different questions and are read separately, never as one number.
WITH user_window AS (SELECT user_pseudo_id,
                     -- Window label resolved once per user, so a user cannot straddle both groups.
                     -- Same derivation as mode_overlap_by_window.sql, spelled out longer here.
                     IF(LOGICAL_OR(event_name = 'first_open'), 'in_window', 'pre_window') AS window_group
                     FROM `firebase-public-project.analytics_153293282.events_*`
                     GROUP BY user_pseudo_id),
     
     labeled AS (SELECT e.user_pseudo_id, event_date, event_name, window_group
                 FROM `firebase-public-project.analytics_153293282.events_*` AS e JOIN user_window AS uw
                 ON e.user_pseudo_id = uw.user_pseudo_id),
                                                                                                                                  -- COUNT(DISTINCT) per (day, event): valid within a row only, never summable across rows.
     arm_dates AS (SELECT event_date AS period, window_group, event_name, COUNT(*) AS n_events, COUNT(DISTINCT user_pseudo_id) AS n_users
                   FROM labeled
                   -- Fourteen consecutive days, 18 June – 1 July: the spike days and the non-spike
                   -- days interleaved between them. Matched windows — same fortnight, same app
                   -- version mix — so raw counts compare directly without normalising to shares.
                   WHERE event_date IN ('20180618','20180619','20180620','20180621','20180622','20180623','20180624','20180625','20180626','20180627','20180628','20180629','20180630','20180701')
                   GROUP BY period, window_group, event_name),
  
     -- Everything from 2 July on collapses to one baseline row per (window group, event).
     -- YYYYMMDD text sorts chronologically, so the string comparison is a valid date filter.
     -- The 'stable_block' literal makes `period` polysemous: on the pandas side it loads as str,
     -- never parse_dates.
                   -- The literal leads the SELECT because UNION ALL matches by position, not name.
     arm_block AS (SELECT 'stable_block' AS period, window_group, event_name, COUNT(*) AS n_events, COUNT(DISTINCT user_pseudo_id) AS n_users
                   FROM labeled
                   WHERE event_date >= '20180702'
                   GROUP BY window_group, event_name)

SELECT * FROM arm_dates
UNION ALL
SELECT * FROM arm_block;
