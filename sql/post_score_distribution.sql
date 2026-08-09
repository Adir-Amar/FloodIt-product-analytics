-- Score distribution by mode × level: is the score-21 ceiling real, how do modes differ? One row per (mode, level, score).
WITH params AS (SELECT user_pseudo_id,
                       event_timestamp,
                       param.key AS parameter_name,
                       COALESCE(param.value.string_value,
                                CAST(param.value.int_value    AS STRING),
                                CAST(param.value.float_value  AS STRING),
                                CAST(param.value.double_value AS STRING)) AS param_value
                FROM `firebase-public-project.analytics_153293282.events_*` CROSS JOIN UNNEST(event_params) AS param
                WHERE event_name = 'post_score'),
     
     pivoted AS (SELECT user_pseudo_id, event_timestamp,
                     MAX(IF(parameter_name = 'level', param_value, NULL)) AS level,
                     MAX(IF(parameter_name = 'score', param_value, NULL)) AS score
                 FROM params
                 GROUP BY user_pseudo_id, event_timestamp)

SELECT level, score, CASE WHEN SAFE_CAST(level AS INT64) = 0 THEN 'quickplay' ELSE 'level_mode' END AS mode, COUNT(*) AS n_posts
FROM pivoted
GROUP BY level, score, mode
ORDER BY SAFE_CAST(level AS INT64), SAFE_CAST(score AS INT64)
