-- Which parameters ride on the two level_start events, and what shape are their values?
-- One row per (event, parameter).
--
-- Census template: this body is identical in monetization_param_census.sql and
-- post_score_param_census.sql, which differ only in the WHERE clause. Three files, one query.

SELECT event_name, param.key AS parameter_name, COUNT(*) AS n_events_with_it,
    -- GA4 stores each parameter value in exactly one of four typed slots; COALESCE collapses
    -- them into one string so a mixed-type census is countable.
    COUNT(DISTINCT COALESCE(
    param.value.string_value, 
    CAST(param.value.int_value AS STRING), 
    CAST(param.value.float_value AS STRING), 
    CAST(param.value.double_value AS STRING)
  )) AS n_distinct_values,
     -- ANY_VALUE picks an arbitrary value, not a representative one — a shape sample, not a statistic.
     ANY_VALUE(COALESCE(
    param.value.string_value, 
    CAST(param.value.int_value AS STRING), 
    CAST(param.value.float_value AS STRING), 
    CAST(param.value.double_value AS STRING)
  )) AS example_value
-- UNNEST explodes each event into one row per parameter. Parameters are not guaranteed present
-- on any event, so n_events_with_it is a coverage count, not a total.
FROM `firebase-public-project.analytics_153293282.events_*`CROSS JOIN UNNEST(event_params) AS param

WHERE event_name IN ('level_start', 'level_start_quickplay')

GROUP BY event_name, parameter_name

ORDER BY event_name;
