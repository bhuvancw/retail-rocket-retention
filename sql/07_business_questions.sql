-- ============================================================
-- 07_business_questions.sql
-- PURPOSE: Advanced analytical questions using window functions.
-- These are the queries that demonstrate FAANG-level SQL depth.
-- ============================================================

-- BUSINESS QUESTION 11:
-- How many events does it take before a user makes
-- their first purchase? (Time-to-conversion)

with events_ordered as (
    SELECT
        user_id,
        event_type,
        row_number() over(partition by user_id order by event_time) as event_rank
    from events
),
first_purchase as (
    SELECT  
        user_id,
        min(event_rank) as events_before_purchase
    from events_ordered
    where event_type = 'transaction'
    group by user_id 
 )
 SELECT
    case
        when events_before_purchase = 1 then '1st event'
        when events_before_purchase between 2 and 5 then '2-5 events'
        when events_before_purchase between 6 and 20 then '6-20 events'
        when events_before_purchase between 21 and 50 then '21-50 events'
        else '50+ events'
    end as touchpoint_before_purchase,
    count(*) as buyers,
    round(100.0 * count(*) / 
            sum(count(*)) over(), 1)  as pct_of_all_buyers
from first_purchase
group by touchpoint_before_purchase
order by min(events_before_purchase);

-- BUSINESS QUESTION 12:
-- How quickly do users decide to buy after adding to cart?

with cart_to_buy as ( 
    SELECT
        user_id,
        item_id,
        event_time as cart_time,
        lead(event_time) over(partition by user_id, item_id order by event_time) as next_time,
        lead(event_type) over(partition by user_id, item_id order by event_time) as next_event
    from events
    where event_type = 'addtocart'
)
SELECT
    CASE
        when (julianday(next_time) - julianday(cart_time)) * 24 < 1 then 'Under 1 hour'
        when (julianday(next_time) - julianday(cart_time)) * 24 < 24 then '1-24 hours'
        when (julianday(next_time) - julianday(cart_time)) * 24 < 72 then '1-3 days'
        else 'Over 3 days'
    end as time_to_purchase,
    count(*) as conversions
from cart_to_buy
where next_time = 'transaction'
group by time_to_purchase
order by min((julianday(next_time) - julianday(cart_time)) * 24);

-- BUSINESS QUESTION 13:
-- What is the repeat purchase rate?

with purchase_counts as (
    SELECT  
        user_id,
        count(distinct transaction_id) as num_purchases
    from events 
    where event_type = 'transaction'
        and transaction_id is not NULL
    group by user_id
)
SELECT
    CASE
        when num_purchases = 1 then 'One-time buyer'
        when num_purchases = 2 then 'Bought twice'
        when num_purchases >= 3 then 'Loyal (3+)'
    end as buyer_type,
    count(*) as users,
    round(100.0 * count(*) /
        sum(count(*)) over(), 1) as pct_of_buyers
from purchase_counts
group by buyer_type
order by min(num_purchases);

-- BUSINESS QUESTION 14:
-- Month-over-month growth in users and transactions
-- using LAG() window function

with monthly as (
    SELECT
        strftime('%Y-%m', event_time) as month,
        count(distinct user_id) as total_users,
        count(distinct case when event_type = 'transaction'
                then user_id end) as buyers,
        count(case when event_type = 'transaction'
                then 1 end) as transactions
    from events
    group by month
)
SELECT
    month,
    total_users,
    buyers,
    transactions,
    lag(total_users) over(order by month) as prev_users,
    lag(transactions) over(order by month) as prev_transactions,
    round(100.0 * (total_users - 
        lag(total_users) over(order by month)) /
        nullif(lag(total_users) over(order by month), 0), 1) as user_growth_pct,
    round(100.0 * (transactions - 
        lag(transactions) over(order by month)) /
        nullif(lag(transactions) over(order by month), 0), 1) as txn_growth_pct
from monthly
order by month;

-- BUSINESS QUESTION 15:
-- 7-day rolling average of daily transactions
-- (Spot trends without daily noise)

with daily_txns as (
    SELECT
        date(event_time) as txn_date,
        count(*) as daily_transactions
    from events
    where event_type = 'transaction'
    group by txn_date
)
SELECT
    txn_date,
    daily_transactions,
    round(avg(daily_transactions) over(order by txn_date rows between 6 preceding and current row), 1) as rolling_7day_avg
from daily_txns
order by txn_date;

