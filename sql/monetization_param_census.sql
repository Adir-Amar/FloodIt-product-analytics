-- Which parameters ride on the monetization events, and how well populated are they?
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
-- This census is where the `value` polysemy surfaced: steps on ad_reward rows, micro-money on
-- purchase rows. Same column name, two meanings, never aggregate across the two event types.
WHERE event_name IN ('ad_reward', 'in_app_purchase')

GROUP BY event_name, parameter_name

ORDER BY event_name;
