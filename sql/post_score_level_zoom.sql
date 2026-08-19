WITH pivoted AS (
  SELECT
    user_pseudo_id,
    event_timestamp,

    MAX(IF(param.key = 'level',
           COALESCE(param.value.string_value,
                    CAST(param.value.int_value    AS STRING),
                    CAST(param.value.float_value  AS STRING),
                    CAST(param.value.double_value AS STRING)),
           NULL)) AS level,
    MAX(IF(param.key = 'level_name',
           COALESCE(param.value.string_value,
                    CAST(param.value.int_value    AS STRING),
                    CAST(param.value.float_value  AS STRING),
                    CAST(param.value.double_value AS STRING)),
           NULL)) AS level_name
  FROM `firebase-public-project.analytics_153293282.events_*`
  CROSS JOIN UNNEST(event_params) AS param
  WHERE event_name = 'post_score'
  GROUP BY user_pseudo_id, event_timestamp
)
SELECT
  level,
  COUNT(*) AS n_events,
  COUNTIF(level_name IS NOT NULL) AS n_with_level_name
FROM pivoted
GROUP BY level
ORDER BY SAFE_CAST(level AS INT64);
