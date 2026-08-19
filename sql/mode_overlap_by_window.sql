-- Do players use one game mode or both, and does that differ between in-window installers and
-- pre-window users? One row per (player class, window group) — the 8-cell overlap table.
WITH per_user_starts_counts AS (SELECT user_pseudo_id,
                                -- COUNTIF gives per-user totals for both modes in a single pass over the stream.
                                COUNTIF(event_name = 'level_start') AS level_start_count,
                                COUNTIF(event_name = 'level_start_quickplay') AS level_start_quickplay_count,
                                -- LOGICAL_OR inside the per-user GROUP BY resolves the window label once per user: fired first_open
                                -- anywhere in the export = 'in', otherwise 'pre'. A user cannot straddle both.
                                -- (spike_forensics.sql derives the same label and spells it 'in_window' / 'pre_window'.)
                                IF(LOGICAL_OR(event_name = 'first_open'), 'in', 'pre') AS window_indicator

                                FROM `firebase-public-project.analytics_153293282.events_*`

                                GROUP BY user_pseudo_id),
                                                       -- Four exhaustive classes from two counts. 'neither' catches users who never started a level
                                                       -- in either mode — they exist, and dropping them silently would misstate the denominators.
     player_classifier AS      (SELECT user_pseudo_id, CASE
                                                            WHEN level_start_count = 0 AND level_start_quickplay_count != 0 THEN 'quickplay-only'
                                                            WHEN level_start_count != 0 AND level_start_quickplay_count = 0 THEN 'level_mode-only'
                                                            WHEN level_start_count != 0 AND level_start_quickplay_count != 0 THEN 'both'
                                                            ELSE 'neither'
                                                       END AS class, window_indicator

                                FROM per_user_starts_counts)

SELECT class, window_indicator,  COUNT(*) AS n_users

FROM player_classifier

GROUP BY class, window_indicator

ORDER BY class, window_indicator;
