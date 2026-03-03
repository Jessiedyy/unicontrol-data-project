{{ config(
    materialized = 'view',
    schema = 'marts',
    tags = ['marts', 'dimension']
) }}


select
  v.vin,
  s.customer_key as customer_key,
  s.distributor_id as distributor_id
from {{ ref('dim_vin') }} v
left join {{ ref('marts_fact_sell_out') }} s on v.vin = s.vin
group by v.vin, s.customer_key, s.distributor_id