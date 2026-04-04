-- ============================================================
-- 01_setup.sql
-- PURPOSE: Explore raw data before writing any analysis.
-- ============================================================

-- Q: How many total events exist?
select
    count(*) as total_events
from events;

-- Q: What event types exist and what % of total is each?
SELECT
    event_type,
    count(*) as event_count,
    round(count(*) * 100/ sum(count(*)) over(),2) as pct_of_total
from events
group by event_type
order by event_count;

-- Q: What is the full date range of this dataset?

SELECT
    min(event_time) as earliest,
    max(event_time) as latest,
    CAST(julianday(max(event_time))
         - julianday(min(event_time)) as int) as total_days
from events;

-- Q: How many unique users and items?

SELECT
    count(distinct user_id) as unique_users,
    count(distinct item_id) as unique_items
from events;

-- Q: How many distinct users performed each event type?
SELECT
    event_type,
    count(distinct user_id) as unique_user
from events
group by event_type;

-- Q: What does one user's full journey look like?
SELECT
    event_time,
    event_type,
    item_id
from events
where user_id = (
    select
        user_id
    from events
    group by user_id
    order by count(*)
    limit 1
)
order by event_time;









