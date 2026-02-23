{{ config(
    materialized = 'view',
    schema = 'gold',
    tags = ['gold', 'dimension']
) }}

select 
  {{ dbt_utils.generate_surrogate_key(['subscription_id']) }} as subscription_key,
  * except(bronze_loaded_at_utc, loaded_at_utc, _source)
from {{ ref('silver_subscription_terms_practice_1') }}