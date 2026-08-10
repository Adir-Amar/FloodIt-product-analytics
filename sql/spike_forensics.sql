WITH user_window AS (SELECT user_pseudo_id, IF(LOGICAL_OR(event_name = 'first_open'), 'in_window', 'pre_window') AS window_group
                     FROM `firebase-public-project.analytics_153293282.events_*`
                     GROUP BY user_pseudo_id),
     
     labeled AS (SELECT e.user_pseudo_id, event_date, event_name, window_group
                 FROM `firebase-public-project.analytics_153293282.events_*` AS e JOIN user_window AS uw
                 ON e.user_pseudo_id = uw.user_pseudo_id),
     
     arm_dates AS (SELECT event_date AS period, window_group, event_name, COUNT(*) AS n_events, COUNT(DISTINCT user_pseudo_id) AS n_users
                   FROM labeled
                   WHERE event_date IN ('20180618','20180619','20180620','20180621','20180622','20180623','20180624','20180625','20180626','20180627','20180628','20180629','20180630','20180701')
                   GROUP BY period, window_group, event_name),
     
     arm_block AS (SELECT 'stable_block' AS period, window_group, event_name, COUNT(*) AS n_events, COUNT(DISTINCT user_pseudo_id) AS n_users
                   FROM labeled
                   WHERE event_date >= '20180702'
                   GROUP BY window_group, event_name)

SELECT * FROM arm_dates
UNION ALL
SELECT * FROM arm_block
