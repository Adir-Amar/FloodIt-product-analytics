-- Which parameters ride on post_score, and how many distinct values does each carry?
-- One row per (event, parameter). Census template — shared body, see mode_param_census.sql.

SELECT event_name, param.key AS parameter_name, COUNT(*) AS n_events_with_it,  COUNT(DISTINCT COALESCE(
    param.value.string_value, 
    CAST(param.value.int_value AS STRING), 
    CAST(param.value.float_value AS STRING), 
    CAST(param.value.double_value AS STRING)
  )) AS n_distinct_values,
     ANY_VALUE(COALESCE(
    param.value.string_value, 
    CAST(param.value.int_value AS STRING), 
    CAST(param.value.float_value AS STRING), 
    CAST(param.value.double_value AS STRING)
  )) AS example_value

FROM `firebase-public-project.analytics_153293282.events_*` CROSS JOIN UNNEST(event_params) AS param
-- n_distinct_values on level and score is what sized all the later per-level work.
-- `time` appears here and is dead — present on the events, never populated.
WHERE event_name = 'post_score'

GROUP BY event_name, parameter_name

ORDER BY event_name;
