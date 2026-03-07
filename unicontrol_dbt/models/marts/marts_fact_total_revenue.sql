{{ config(
    materialized = 'view',
    schema = 'marts',
    tags = ['marts', 'fact', 'total revenue']
) }}

-- Total Revenue = Sell Out (设备销售) + Subscription (订阅收入)
-- By date, vin, customer, distributor, region, country
-- Power BI: SUM(revenue_dkk) with filters on revenue_date, vin, customer_key, distributor_id, region, country

-- Check NOT NULL IN PAID_AT AND CONTRACT_DATE FIRST
with

-- 1. Sell out: 设备销售，one row per order，revenue = 设备售价
sell_out_revenue as (
  select
    contract_date as revenue_date,
    vin,
    customer_key,
    distributor_id,
    product_list_price_dkk as revenue_dkk,
    'sell_out' as revenue_source
  from {{ ref('marts_fact_sell_out') }}
),

-- 2. Subscription: 订阅收入，每条发票一行，paid_at = 开票/付款时间，amount_dkk = 该笔金额
subscription_revenue as (
  select
    date(paid_at) as revenue_date,
    vin,
    customer_key,
    distributor_id,
    amount_dkk as revenue_dkk,
    'subscription' as revenue_source
  from {{ ref('marts_fact_subscription_invoice') }} 
)

select * from sell_out_revenue
union all
select * from subscription_revenue
order by revenue_date, vin, revenue_source
