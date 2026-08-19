-- Per-level post_score volume, and how many of those posts carry a level_name. One row per level.
--
-- Pivot idiom here is the earlier form — COALESCE nested inside MAX(IF(...)). monetization_lifecycle.sql
-- and post_score_distribution.sql resolve params in a CTE first and pivot in a second stage.
-- Both correct, same result; this is the idiom settling mid-project. Kept as written.

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

-- COUNTIF on a pivoted column measures parameter coverage per level, not event volume.
SELECT
  level,
  COUNT(*) AS n_events,
  COUNTIF(level_name IS NOT NULL) AS n_with_level_name
FROM pivoted
GROUP BY level
ORDER BY SAFE_CAST(level AS INT64);
