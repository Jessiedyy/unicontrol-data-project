{{ config(
    materialized = 'view',
    schema = 'marts',
    tags = ['marts', 'fact']
) }}

select i.*,
       c.customer_key,
       d.distributor_id,
       p.subscription_plan_key
from {{ ref('fact_erp_subscription_invoice') }} i
left join {{ ref('marts_dim_vin')}} v
on i.vin = v.vin
left join {{ ref('marts_dim_customer')}} c
on v.customer_key = c.customer_key
left join {{ ref('marts_dim_distributor')}} d
on v.distributor_id = d.distributor_id
left join {{ ref('marts_dim_subscription_plan')}} p
on i.plan = p.plan
  and i.amount_dkk = p.amount_dkk
where valid_subscription_invoice = true
