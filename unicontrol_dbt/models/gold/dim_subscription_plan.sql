{{ config(
    materialized = 'view',
    schema = 'gold',
    tags = ['gold', 'dimension']
) }}

with base as (
  select plan,
         billing_cycle,
         amount_dkk,
         min(_month) as valid_from_raw,
         last_day(max(_month)) as valid_to_raw,
         currency,
         row_number() over (partition by plan, billing_cycle order by min(_month)) as rn
  from {{ ref('fact_erp_subscription_invoice') }}
  where valid_subscription_invoice = true
  group by plan, billing_cycle, amount_dkk, currency
),

with_dates as (
  select plan,
         billing_cycle,
         amount_dkk,
         currency,
         case when rn = 1 then date '2020-01-01'
              else valid_from_raw
              end as valid_from,
         case when rn = max(rn) over (partition by plan, billing_cycle) then date '2099-12-31'
              else valid_to_raw
              end as valid_to
  from base
)

select 
       {{ dbt_utils.generate_surrogate_key(['plan','billing_cycle', 'valid_from','amount_dkk']) }} as subscription_plan_key,
       plan,
       billing_cycle,
       amount_dkk,
       currency,
       valid_from,
       valid_to,
       case when billing_cycle = 'monthly' then 1
            when billing_cycle = 'quarterly' then 3
            when billing_cycle = 'yearly' then 12
            else 0
            end as billing_cycle_number
from with_dates
order by plan asc
