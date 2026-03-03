{{ config(
    materialized = 'view',
    schema = 'marts',
    tags = ['marts', 'kpi', 'mrr']
) }}

-- MRR：选定日期仍生效的订阅，其月订阅费之和
-- 粒度：每日 × 每张 active 发票，带维度便于 Power BI 按 plan/subscription 切片
-- Power BI：SUM(mrr_dkk)；按月/年看用该月/年最后一天的 MRR

with invoice_with_mrr as (
  -- 每张发票的「月订阅费」+ 维度列
  select inv.invoice_key,
         inv.subscription_key,
         inv.plan,
         inv.billing_cycle,
         inv.period_start,
         inv.period_end,
         inv.amount_dkk / nullif(
           case inv.billing_cycle
             when 'monthly' then 1
             when 'quarterly' then 3
             when 'yearly' then 12
             else 1
           end, 0
         ) as mrr_dkk
  from {{ ref('marts_fact_subscription_invoice') }} inv
),

min_max_dates as (
  select coalesce(min(period_start), date '2020-01-01') as min_date,
         current_date() as max_date
  from {{ ref('marts_fact_subscription_invoice') }}
),

date_spine as (
  select date_day as period_date
  from min_max_dates,
  unnest(
    generate_date_array(min_max_dates.min_date, min_max_dates.max_date, interval 1 day)
  ) as date_day
),

-- 不聚合：保留 (日期, 发票, 维度)，Power BI 里 SUM(mrr_dkk) 按筛选器聚合
mrr_expanded as (
  select d.period_date,
         i.invoice_key,
         i.subscription_key,
         i.plan,
         i.billing_cycle,
         i.mrr_dkk
  from date_spine d
  inner join invoice_with_mrr i
    on d.period_date between i.period_start and i.period_end
)

select *
from mrr_expanded
order by period_date, subscription_key, invoice_key
