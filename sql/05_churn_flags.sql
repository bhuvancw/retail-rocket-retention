-- ============================================================
-- 05_churn_flags.sql
-- PURPOSE: Label every user as churned or active.
--
-- CHURN DEFINITION (document this in every project):
-- A user is CHURNED if they have not appeared in the dataset
-- for more than 30 days before the data ends (2015-09-18).
-- So: last_active_date < 2015-08-19 = churned.
--
-- WHY DEFINE IT EXPLICITLY: Churn is not a column in the data.
-- It's an analytical decision. Documenting your definition is
-- what separates an analyst from someone who just runs queries.
-- ============================================================

create table if not exists churn_labels as 
with last_seen as (
    SELECT
        user_id,
        max(date(event_time)) as last_active_date,
        count(*) as total_events,
        count(distinct date(event_time)) as active_days
    from events
    group by user_id
),
purchase_history as
(
    select
        user_id,
        max(case when event_type = 'transaction' then 1 else 0 end) as ever_purchased,
        count(case when event_type = 'transaction' then 1 end) as total_purchases,
        max(case when event_type = 'addtocart' then 1 else 0 end) as ever_carted
    from events
    group by user_id
)
SELECT
    l.user_id,
    l.last_active_date,
    l.total_events,
    l.active_days,
    p.ever_purchased,
    p.total_purchases,
    p.ever_carted,
    cast(julianday('2015-09-18') - 
         julianday(l.last_active_date) as int) as days_since_active,
    case
        when CAST(julianday('2015-09-18')-julianday(l.last_active_date)
                  AS INT) <= 30
         AND p.ever_purchased = 1              THEN 'active_buyer'
        WHEN CAST(julianday('2015-09-18')-julianday(l.last_active_date)
                  AS INT) <= 30
         AND p.ever_purchased = 0              THEN 'active_browser'
        WHEN CAST(julianday('2015-09-18')-julianday(l.last_active_date)
                  AS INT) > 30
         AND p.ever_purchased = 1              THEN 'churned_buyer'
        WHEN CAST(julianday('2015-09-18')-julianday(l.last_active_date)
                  AS INT) > 30
         AND p.ever_carted = 1
         AND p.ever_purchased = 0             THEN 'churned_cart_abandoner'
        ELSE                                       'churned_viewer'
    END AS churn_label
FROM last_seen l
join purchase_history p
on l.user_id = p.user_id;


-- BUSINESS QUESTION 7:
-- How many users fall in each churn segment?

SELECT
    churn_label,
    count(*) as user_count,
    round(100.0 * count(*) / 
            sum(count(*)) over(), 1) as pct_of_all_users
from churn_labels
group by churn_label
order by user_count desc;

-- BUSINESS QUESTION 8:
-- Of cart abandoners, how long after carting did they go silent?
-- (This tells us the best re-engagement window)

SELECT
    case
        when days_since_active between 30 and 44 then '30-44 days'
        when days_since_active between 45 and 59 then '45-59 days'
        when days_since_active between 60 and 89 then '60-89 days'
        else '90+ days'
    end as inactivity_bucket,
    count(*) as user_count
from churn_labels
where churn_label = 'churned_cart_abandoner' 
group by inactivity_bucket
order by min(days_since_active);
