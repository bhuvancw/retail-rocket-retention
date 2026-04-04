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