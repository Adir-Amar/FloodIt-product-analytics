-- When in a user's lifetime do monetization events land? One row per event (1912 ad_reward + 27 in_app_purchase).
WITH params AS (SELECT user_pseudo_id,
                       event_date,
                       event_timestamp,
                       event_name,
                       param.key AS parameter_name,
                       -- Four typed slots, one populated; COALESCE picks the live one.
                       COALESCE(param.value.string_value,
                                CAST(param.value.int_value    AS STRING),
                                CAST(param.value.float_value  AS STRING),
                                CAST(param.value.double_value AS STRING)) AS param_value
                FROM `firebase-public-project.analytics_153293282.events_*` CROSS JOIN UNNEST(event_params) AS param
                WHERE event_name IN ('in_app_purchase', 'ad_reward')),
     -- MAX(IF(key='x', value, NULL)) pivots long param rows into one wide row per event.
     -- MAX is an arbitrary picker, not a maximum — each key appears at most once per event.
     pivoted AS (SELECT user_pseudo_id, event_date, event_timestamp, event_name,
                     MAX(IF(parameter_name = 'product_id', param_value, NULL)) AS product_id,
                     MAX(IF(parameter_name = 'price', param_value, NULL)) AS price,
                     MAX(IF(parameter_name = 'currency', param_value, NULL)) AS currency,
                     MAX(IF(parameter_name = 'validated', param_value, NULL)) AS validated,
                     MAX(IF(parameter_name = 'type', param_value, NULL)) AS type,
                     MAX(IF(parameter_name = 'value', param_value, NULL)) AS value
                 FROM params
                 GROUP BY user_pseudo_id, event_date, event_timestamp, event_name)
-- Boundary rule: types and units are stamped here, at the exit, never mid-pipeline — strings ride
-- the CTEs. price arrives in GA4 micros, so ÷1e6 gives currency units. `value` is polysemous
-- (steps on ad rows, micro-money on purchase rows); cast, but do not sum across event types.
SELECT user_pseudo_id, event_date, event_timestamp, event_name, product_id, SAFE_CAST(price AS FLOAT64)/1000000 AS price, currency, validated, type, SAFE_CAST(value AS FLOAT64) AS value
FROM pivoted
ORDER BY user_pseudo_id, event_timestamp
