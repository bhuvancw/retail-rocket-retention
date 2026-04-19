-- ============================================================
-- 06_power_users.sql
-- PURPOSE: Segment users by week-1 behaviour depth, then check
-- whether that predicts a future purchase.
--
-- WHY: This is the "aha moment" analysis. FAANG product teams
-- obsess over early behaviour because it predicts LTV. If we
-- find what high-retention users do in week 1, we can engineer
-- the product to nudge new users toward those behaviours.
-- ============================================================

create table if not exists user_segments AS
with week1_activity AS (
    SELECT
        e.user_id,
        count(*) as w1_total_events,
        count(distinct date(e.event_time)) as w1_active_days,
        count(distinct e.item_id) as w1_unique_items,
        count(case when e.event_type = 'addtocart'
                    then 1 end) as w1_cart_actions,
        count(case when e.event_type = 'transaction'
                    then 1 end) as w1_purchases,
        round(100.0 *
                nullif(count(distinct date(e.event_time)), 0), 1) as w1_events_per_day
    from events e
    join user_cohorts c on e.user_id = c.user_id
    where julianday(date(e.event_time)) - 
          julianday(c.first_date) between 0 and 7
    group by e.user_id
),
later_behaviour as (
    SELECT
        e.user_id,
        max(CASE
                when e.event_type = 'transaction'
                and julianday(date(e.event_time)) - 
                    julianday(c.first_date) > 7
                then 1 else 0
            end) as purchased_after_week1,
        count(CASE
                when julianday(date(e.event_time)) -
                     julianday(c.first_date) > 7
                then 1 end) as events_after_week1
    from events e
    join user_cohorts c on e.user_id = c.user_id
    group by e.user_id
)
SELECT
    w.user_id,
    w.w1_total_events,
    w.w1_active_days,
    w.w1_unique_items,
    w.w1_cart_actions,
    w.w1_purchases,
    w.w1_events_per_day,
    l.purchased_after_week1,
    l.events_after_week1,
    case
        when w.w1_purchases >= 2 then 'power-buyer'
        when w.w1_purchases = 1 then 'single_buyer'
        when w.w1_cart_actions >= 1 then 'cart_browser'
        when w.w1_unique_items >= 10 then 'heavy_viewer'
        else 'light_viewer'
    end as user_segment
from week1_activity w
join later_behaviour l on w.user_id = l.user_id;

-- BUSINESS QUESTION 9:
-- What future purchase rate does each week-1 segment achieve?

SELECT
    user_segment,
    count(*) as total_users,
    sum(purchased_after_week1) as later_buyers,
    round(100.0 * sum(purchased_after_week1) /
            count(*), 1) as future_purchase_rate_pct,
    round(avg(w1_total_events), 1) as avg_w1_events,
    round(avg(w1_active_days), 1) as avg_w1_active_days,
    round(avg(w1_unique_items), 1) as avg_items_viewed
from user_segments
group by user_segment
order by future_purchase_rate_pct desc;

-- BUSINESS QUESTION 10:
-- What is the minimum event threshold separating high vs low retention?

SELECT
    CASE
        when w1_total_events = 1 then '01 event'
        when w1_total_events between 2 and 4 then '02-04 events'
        when w1_total_events between 5 and 9 then '05-09 events'
        when w1_total_events between 10 and 19 then '10-19 events'
        else '20+ events'
    end as event_bucket,
    count(*) as users,
    round(100.0 * sum(purchased_after_week1) / 
            count(*), 1) as future_purchase_rate_pct
from user_segments 
group by event_bucket
order by min(w1_total_events);