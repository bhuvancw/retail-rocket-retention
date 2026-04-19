-- ============================================================
-- 03_retention_matrix.sql
-- PURPOSE: For each cohort, how many users were still active
-- in month 1, 2, 3, 4 after joining?
--
-- READING THE OUTPUT:
-- month_number = 0  → the cohort's joining month (always 100%)
-- month_number = 1  → users still active the next month
-- month_number = 2  → users still active 2 months later
-- A sharp drop from 0→1 means users aren't forming a habit.
-- ============================================================

-- BUSINESS QUESTION 1:
-- What % of users return in month 1, 2, 3, 4?
with monthly_activity as 
(
    SELECT
        e.user_id,
        c.cohort_month,
        strftime('%Y-%m', e.event_time) as activity_month
    from events e 
    join user_cohorts c on e.user_id = c.user_id
),
month_offsets as (
    SELECT
        user_id,
        cohort_month,
        (cast(strftime('%Y', activity_month || '-01') as int) * 12 +
         cast(strftime('%m', activity_month || '-01') as int))
         -
         (CAST(strftime('%Y', cohort_month   || '-01') AS INT) * 12 +
         CAST(strftime('%m', cohort_month   || '-01') AS INT)) AS month_number
    FROM monthly_activity
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT user_id) AS cohort_size
    FROM user_cohorts GROUP BY cohort_month
),
retention_count as (
    SELECT
        cohort_month,
        month_number,
        count(distinct user_id) as retained_users
    from month_offsets
    where month_number between 0 and 4
    group by cohort_month, month_number
)
SELECT
    r.cohort_month,
    cs.cohort_size,
    r.month_number,
    r.retained_users,
    round(100.0* r.retained_users / cs.cohort_size, 1) as retention_pct
from retention_count r
join cohort_sizes cs on r.cohort_month = cs.cohort_month
order by r.cohort_month, r.month_number;

-- BUSINESS QUESTION 2:
-- Which cohort has the BEST month-2 retention?

with monthly_activity as 
(
    SELECT
        e.user_id,
        c.cohort_month,
        strftime('%Y-%m', e.event_time) as activity_month
    from events e 
    join user_cohorts c on e.user_id = c.user_id
),
month_offsets AS (
    SELECT user_id, cohort_month,
        (CAST(strftime('%Y', activity_month||'-01') AS INT)*12 +
         CAST(strftime('%m', activity_month||'-01') AS INT)) -
        (CAST(strftime('%Y', cohort_month  ||'-01') AS INT)*12 +
         CAST(strftime('%m', cohort_month  ||'-01') AS INT)) AS month_number
    FROM monthly_activity
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(DISTINCT user_id) AS cohort_size
    FROM user_cohorts GROUP BY cohort_month
)
SELECT
    m.cohort_month,
    cs.cohort_size,
    count(distinct m.user_id) as month2_users,
    round(100.0 * count(DISTINCT m.user_id)
        / cs.cohort_size, 1) as month2_retention_pct
from month_offsets m 
join cohort_sizes cs on m.cohort_month = cs.cohort_month
where m.month_number = 2
group by m.cohort_month
order by month2_retention_pct desc;
