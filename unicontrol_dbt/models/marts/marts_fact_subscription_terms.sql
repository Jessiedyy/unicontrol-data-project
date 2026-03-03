{{ config(
    materialized = 'view',
    schema = 'marts',
    tags = ['marts', 'fact']
) }}

-- 每 subscription 只取一张发票的 amount，避免 join 导致行膨胀、PK 不唯一
with inv_one_per_sub as (
  select subscription_key, amount_dkk
  from {{ ref('marts_fact_subscription_invoice') }}
  qualify row_number() over (partition by subscription_key order by period_start) = 1
)
select t.*,
       i.amount_dkk as plan_amount_dkk,
       p.subscription_plan_key,
       c.customer_key,
       d.distributor_id
from {{ ref('dim_billing_subscription_terms') }} t
left join {{ ref('marts_dim_vin') }} v on t.vin = v.vin
left join {{ ref('marts_dim_customer') }} c on v.customer_key = c.customer_key
left join {{ ref('marts_dim_distributor') }} d on v.distributor_id = d.distributor_id
left join inv_one_per_sub i on t.subscription_key = i.subscription_key
left join {{ ref('marts_dim_subscription_plan') }} p
  on t.plan = p.plan
 and t.billing_cycle = p.billing_cycle
 and i.amount_dkk = p.amount_dkk


