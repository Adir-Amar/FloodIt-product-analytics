-- D-N retention (D1/D3/D7/D14/D30) for in-window installers: flags CTE chain + conditional aggregation

WITH day_0_table AS (
  SELECT user_pseudo_id, MIN(PARSE_DATE('%Y%m%d', event_date)) AS day_0
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
),

user_journal AS (
  SELECT DISTINCT user_pseudo_id, PARSE_DATE('%Y%m%d', event_date) AS active_day
  FROM `firebase-public-project.analytics_153293282.events_*`
),

-- The two CTEs above are day_0.sql and user_journal.sql inlined, so the curve runs as one file.
player_flags AS (
  SELECT
    c.user_pseudo_id AS player,
    c.day_0,
    -- Collapses each user's journal to one row of booleans. D-N is activity on exactly day N,
    -- not activity on or after day N — the stricter of the two conventions.
    LOGICAL_OR(DATE_DIFF(j.active_day, c.day_0, DAY) = 1)  AS retained_d1,
    LOGICAL_OR(DATE_DIFF(j.active_day, c.day_0, DAY) = 3) AS retained_d3,
    LOGICAL_OR(DATE_DIFF(j.active_day, c.day_0, DAY) = 7)  AS retained_d7,
    LOGICAL_OR(DATE_DIFF(j.active_day, c.day_0, DAY) = 14) AS retained_d14,
    LOGICAL_OR(DATE_DIFF(j.active_day, c.day_0, DAY) = 30) AS retained_d30
  FROM day_0_table AS c
  -- Inner join to day_0_table restricts to in-window installers. Pre-window users have no first_open
  -- in the export, so they drop out here. That exclusion is the left-censoring limitation itself,
  -- not a filter chosen for convenience.
  JOIN user_journal AS j
    ON c.user_pseudo_id = j.user_pseudo_id
  GROUP BY player, c.day_0
)
  
-- Eligibility cutoffs. The export ends 2018-10-03, so a user must have installed at least N days
-- before that to have had the chance to return on day N. Denominators therefore shrink as N grows;
-- without the cutoffs, later points would be diluted by users who could never have qualified.
SELECT
  COUNTIF(day_0 <= DATE '2018-10-02')                    AS d1_eligible,
  COUNTIF(day_0 <= DATE '2018-10-02' AND retained_d1)    AS d1_retained,
  ROUND(100 * COUNTIF(day_0 <= DATE '2018-10-02' AND retained_d1)
            / COUNTIF(day_0 <= DATE '2018-10-02'), 2)    AS d1_pct,
  
  COUNTIF(day_0 <= DATE '2018-09-30')                    AS d3_eligible,
  COUNTIF(day_0 <= DATE '2018-09-30' AND retained_d3)    AS d3_retained,
  ROUND(100 * COUNTIF(day_0 <= DATE '2018-09-30' AND retained_d3)
            / COUNTIF(day_0 <= DATE '2018-09-30'), 2)    AS d3_pct,

  COUNTIF(day_0 <= DATE '2018-09-26')                    AS d7_eligible,
  COUNTIF(day_0 <= DATE '2018-09-26' AND retained_d7)    AS d7_retained,
  ROUND(100 * COUNTIF(day_0 <= DATE '2018-09-26' AND retained_d7)
            / COUNTIF(day_0 <= DATE '2018-09-26'), 2)    AS d7_pct,

  COUNTIF(day_0 <= DATE '2018-09-19')                    AS d14_eligible,
  COUNTIF(day_0 <= DATE '2018-09-19' AND retained_d14)    AS d14_retained,
  ROUND(100 * COUNTIF(day_0 <= DATE '2018-09-19' AND retained_d14)
            / COUNTIF(day_0 <= DATE '2018-09-19'), 2)    AS d14_pct,

  COUNTIF(day_0 <= DATE '2018-09-03')                    AS d30_eligible,
  COUNTIF(day_0 <= DATE '2018-09-03' AND retained_d30)   AS d30_retained,
  ROUND(100 * COUNTIF(day_0 <= DATE '2018-09-03' AND retained_d30)
            / COUNTIF(day_0 <= DATE '2018-09-03'), 2)    AS d30_pct
FROM player_flags;
