-- ============================================================
-- 02_cohort_assignment.sql
-- PURPOSE: Tag every user with the month they first appeared.
-- This is the FOUNDATION of all retention analysis.
--
-- WHY COHORTS: Comparing a May user's retention to a September
-- user's retention without cohort grouping is meaningless —
-- the Sep user has had less time to be "retained". Cohorts
-- put users on equal footing.
-- ============================================================

-- Step 1: Preview — each user's first event
SELECT
    user_id,
    min(event_time) as first_event_time,
    date(min(event_time)) as first_date,
    strftime('%Y-%m', min(event_time)) as cohort_month
from events
group by user_id
limit 10;

-- Step 2: Create permanent cohort table
-- We CREATE TABLE so all future queries JOIN to this
-- instead of recalculating MIN(event_time) every time
DROP TABLE IF EXISTS user_cohorts;

CREATE TABLE user_cohorts AS
WITH first_seen AS (
    SELECT
        user_id,
        DATE(MIN(event_time))               AS first_date,
        strftime('%Y-%m', MIN(event_time))  AS cohort_month
    FROM events
    GROUP BY user_id
)
SELECT user_id, first_date, cohort_month
FROM first_seen;

-- Step 3: How large is each cohort?
SELECT
    cohort_month,
    COUNT(DISTINCT user_id) AS cohort_size
FROM user_cohorts
GROUP BY cohort_month
ORDER BY cohort_month;



