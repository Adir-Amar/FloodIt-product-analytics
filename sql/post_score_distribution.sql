-- What does each level's own score support look like? One row per (mode, level, score).
-- The per-level split is the point: pooled across levels these are thirty different supports
-- stacked on one axis, and features of the pooled shape can belong to no single level.

WITH params AS (SELECT user_pseudo_id,
                       event_timestamp,
                       param.key AS parameter_name,
                       COALESCE(param.value.string_value,
                                CAST(param.value.int_value    AS STRING),
                                CAST(param.value.float_value  AS STRING),
                                CAST(param.value.double_value AS STRING)) AS param_value
                FROM `firebase-public-project.analytics_153293282.events_*` CROSS JOIN UNNEST(event_params) AS param
                WHERE event_name = 'post_score'),
  
     -- (user, timestamp) is the event key. It leaks 12 rows in 242K to timestamp collisions — measured,
     -- accepted, immaterial at this grain.
     pivoted AS (SELECT user_pseudo_id, event_timestamp,
                     MAX(IF(parameter_name = 'level', param_value, NULL)) AS level,
                     MAX(IF(parameter_name = 'score', param_value, NULL)) AS score
                 FROM params
                 GROUP BY user_pseudo_id, event_timestamp)
  
                     -- Level-0 sentinel: quickplay posts all carry level 0, so level 0 is the mode flag, not a level.
SELECT level, score, CASE WHEN SAFE_CAST(level AS INT64) = 0 THEN 'quickplay' ELSE 'level_mode' END AS mode,
              COUNT(*) AS n_posts
FROM pivoted
GROUP BY level, score, mode
  
-- level and score are strings; SAFE_CAST sorts them numerically. Lexically it would be 1, 10, 11, 2.
ORDER BY SAFE_CAST(level AS INT64), SAFE_CAST(score AS INT64);
