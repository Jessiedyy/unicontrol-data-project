{{ config(
    materialized = 'view',
    schema = 'marts',
    tags = ['marts', 'fact']
) }}

select t.*,
       c.customer_key,
       d.distributor_id
from {{ ref('fact_telemetry_machine_events') }} t
left join {{ ref('marts_dim_vin')}} v
on t.vin = v.vin
left join {{ ref('marts_dim_customer')}} c
on v.customer_key = c.customer_key
left join {{ ref('marts_dim_distributor')}} d
on v.distributor_id = d.distributor_id