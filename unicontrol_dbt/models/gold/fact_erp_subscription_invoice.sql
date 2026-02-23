{{ config(
    materialized = 'view',
    schema = 'gold',
    tags = ['gold', 'fact']
) }}

select 
  {{ dbt_utils.generate_surrogate_key(['invoice_id']) }} as invoice_key,
  b.subscription_key,
  a.* except(subscription_id,bronze_loaded_at_utc, loaded_at_utc, _source)   
from {{ ref('silver_subscription_invoice_practice_1') }} a
left join {{ ref('dim_billing_subscription_terms') }} b
on a.subscription_id = b.subscription_id