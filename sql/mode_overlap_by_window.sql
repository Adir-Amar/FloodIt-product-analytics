WITH per_user_starts_counts AS (SELECT user_pseudo_id, COUNTIF(event_name = 'level_start') AS level_start_count, COUNTIF(event_name = 'level_start_quickplay') AS level_start_quickplay_count, IF(LOGICAL_OR(event_name = 'first_open'), 'in', 'pre') AS window_indicator

                                FROM `firebase-public-project.analytics_153293282.events_*`

                                GROUP BY user_pseudo_id),

     player_classifier AS      (SELECT user_pseudo_id, CASE
                                                            WHEN level_start_count = 0 AND level_start_quickplay_count != 0 THEN 'quickplay-only'
                                                            WHEN level_start_count != 0 AND level_start_quickplay_count = 0 THEN 'campaign-only'
                                                            WHEN level_start_count != 0 AND level_start_quickplay_count != 0 THEN 'both'
                                                            ELSE 'neither'
                                                       END AS class, window_indicator

                                FROM per_user_starts_counts)

SELECT class, window_indicator,  COUNT(*) AS n_users

FROM player_classifier

GROUP BY class, window_indicator

ORDER BY class, window_indicator;
