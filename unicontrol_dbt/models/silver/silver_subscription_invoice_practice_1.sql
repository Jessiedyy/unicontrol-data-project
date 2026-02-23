{{ config(
    materialized = 'table',
    schema = 'silver',
    partition_by = { 'field' : '_month',
                     'data_type' : 'date',
                     'granularity' : 'month'}
) }}

with base as (
    select * except(_loaded_at_utc),
_loaded_at_utc as bronze_loaded_at_utc,
current_timestamp() as loaded_at_utc
from {{ ref('erp_subscription_invoice_practice_1') }} 
)

select *, 
  case when amount_check = 'incorrect amount' 
       or period_check = 'invalid period' then False
       else True
       end as valid_subscription_invoice
from
(select *,
 case 
    when amount_dkk !=0 and amount_dkk != 3290 and amount_dkk !=2990 
      and amount_dkk !=8490 and amount_dkk != 29990 then 'incorrect amount'
    else 'correct amount' 
  end as amount_check,
  case when period_start >= period_end then 'invalid period'
       else 'valid period' 
  end as period_check
 from base)