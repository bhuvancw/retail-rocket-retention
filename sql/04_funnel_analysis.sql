-- ============================================================
-- 04_funnel_analysis.sql
-- PURPOSE: Measure where users drop off in the purchase funnel.
-- view → addtocart → transaction
--
-- WHY: The funnel tells us WHERE the product is broken.
-- "Low conversion" is not actionable. Knowing that 93% of
-- viewers never add to cart IS actionable — fix discoverability.
-- ============================================================

-- BUSINESS QUESTION 3:
-- What is the overall funnel conversion at each step?

select distinct event_type from events;

SELECT
    count(distinct case when event_type = 'view'
        then user_id end) as step1_viewers,
    count(distinct case when event_type = 'addtocart'
        then user_id end) as step2_carted,
    count(distinct case when event_type = 'transaction'
        then user_id end) as step3_purchased,
    round(100.0 *
        count(distinct case when event_type = 'addtocart'
                then user_id end) / 
        count(distinct case when event_type = 'view'
                then user_id end), 1) as view_to_cart_pct,
    round(100.0 *
        count(distinct case when event_type = 'transaction'
                then user_id end) /
        nullif(count(distinct case when event_type = 'addtocart'
                then user_id end), 0), 1) as cart_to_buy_pct,
    round(100.0 *
        count(distinct case when event_type = 'transaction'
                then user_id end) / 
        count(distinct case when event_type = 'view'
                then user_id end),1) as overall_conv_pct
from events;

-- BUSINESS QUESTION 4:
-- Which item categories have the highest cart-to-purchase rate?

with category_events as (
    SELECT
        e.user_id,
        e.event_type,
        p.value as category_id
    from events e
    left join item_props p 
        on e.item_id = p.itemid 
        and p.property = 'categoryid'
    where p.value is not null
),
category_funnel as (
    SELECT
        category_id,
        count(distinct case when event_type = 'view'
                then user_id end) as viewers,
        count(distinct case when event_type = 'addtocart    '
                then user_id end) as carted,
        count(distinct case when event_type = 'transaction'
                then user_id end) as purchasers
    from category_events
    group by category_id
    having viewers > 200
)

SELECT
    category_id,
    viewers,
    carted,
    purchasers,
    round(100.0 * carted / nullif(viewers, 0), 1) as view_to_cart_pct,
    round(100.0 * purchasers / nullif(carted, 0), 1) as cart_to_buy_pct,
    round(100.0 * purchasers / nullif(viewers, 0), 1) as overall_conv_pct
from category_funnel
order by cart_to_buy_pct desc
limit 15;

-- BUSINESS QUESTION 5:
-- Does conversion vary by day of week?

SELECT
    day_of_week,
    count(distinct case when event_type = 'view'
            then user_id end) as viewers,
    count(distinct case when event_type = 'transaction'
            then user_id end) as purchasers,
    round(100.0 * 
        count(distinct case when event_type = 'transaction'
                then user_id end) / 
        nullif(count(distinct case when event_type = 'view'
                        then user_id end), 0), 2) as conversion_pct
from events
group by day_of_week
order by conversion_pct desc;

-- BUSINESS QUESTION 6:
-- What hour of day drives the most transactions?

SELECT
    hour,
    sum(case when event_type = 'transaction' then 1 end) as transactions,
    sum(case when event_type = 'view' then 1 end) as views,
    round(100.0 * 
        sum(case when event_type = 'transaction' then 1 end) / 
        nullif(sum (case when event_type = 'view' then 1 end), 0), 2) as hourly_conv_pct
from events
group by hour
order by hour;
    
