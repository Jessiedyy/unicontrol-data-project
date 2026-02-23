{{ config(
    materialized = 'view',
    schema = 'gold',
    tags = ['gold', 'fact']
) }}

select 
  {{ dbt_utils.generate_surrogate_key(['event_id']) }} as subscription_event_key,
  a.event_id as subscription_event_id,
  b.subscription_key,
  a.* except(event_id,subscription_id,bronze_loaded_at_utc, loaded_at_utc, _source)
from {{ ref('silver_subscription_event_practice_1') }} a
left join {{ ref('dim_billing_subscription_terms') }} b
on a.subscription_id = b.subscription_id