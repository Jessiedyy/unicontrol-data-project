{{ config(
    materialized = 'view',
    schema = 'gold',
    tags = ['gold', 'fact']
) }}

select 
  {{ dbt_utils.generate_surrogate_key(['order_id']) }} as order_key,
  dealer_dealer_id as distributor_id,
  * except(bronze_loaded_at_utc, loaded_at_utc, _source, dealer_dealer_id)
from {{ ref('silver_sell_out_practice_1') }}
