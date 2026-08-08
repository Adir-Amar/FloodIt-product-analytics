-- When in a user's lifetime do monetization events land? One row per event (1912 ad_reward + 27 in_app_purchase).
WITH params AS (SELECT user_pseudo_id,
                       event_date,
                       event_timestamp,
                       event_name,
                       param.key AS parameter_name,
                       COALESCE(param.value.string_value,
                                CAST(param.value.int_value    AS STRING),
                                CAST(param.value.float_value  AS STRING),
                                CAST(param.value.double_value AS STRING)) AS param_value
                FROM `firebase-public-project.analytics_153293282.events_*` CROSS JOIN UNNEST(event_params) AS param
                WHERE event_name IN ('in_app_purchase', 'ad_reward')),
     
     pivoted AS (SELECT user_pseudo_id, event_date, event_timestamp, event_name,
                     MAX(IF(parameter_name = 'product_id', param_value, NULL)) AS product_id,
                     MAX(IF(parameter_name = 'price', param_value, NULL)) AS price,
                     MAX(IF(parameter_name = 'currency', param_value, NULL)) AS currency,
                     MAX(IF(parameter_name = 'validated', param_value, NULL)) AS validated,
                     MAX(IF(parameter_name = 'type', param_value, NULL)) AS type,
                     MAX(IF(parameter_name = 'value', param_value, NULL)) AS value
                 FROM params
                 GROUP BY user_pseudo_id, event_date, event_timestamp, event_name)

SELECT user_pseudo_id, event_date, event_timestamp, event_name, product_id, SAFE_CAST(price AS FLOAT64)/1000000 AS price, currency, validated, type, SAFE_CAST(value AS FLOAT64) AS value
FROM pivoted
ORDER BY user_pseudo_id, event_timestamp
