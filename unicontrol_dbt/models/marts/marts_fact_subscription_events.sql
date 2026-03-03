{{ config(
    materialized = 'view',
    schema = 'marts',
    tags = ['marts', 'fact']
) }}

select e.* except(attributes_plan, attributes_billing_cycle),
       attributes_plan as plan,
       attributes_billing_cycle as billing_cycle,
       c.customer_key,
       d.distributor_id
from {{ ref('fact_billing_subscription_events') }} e
left join {{ ref('marts_dim_vin')}} v
on e.vin = v.vin
left join {{ ref('marts_dim_customer')}} c
on v.customer_key = c.customer_key
left join {{ ref('marts_dim_distributor')}} d
on v.distributor_id = d.distributor_id