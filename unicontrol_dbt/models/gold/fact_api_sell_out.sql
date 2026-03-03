{{ config(
    materialized = 'view',
    schema = 'gold',
    tags = ['gold', 'fact']
) }}

with base as (
  select
    {{ dbt_utils.generate_surrogate_key(['order_id']) }} as order_key,
    dealer_dealer_id as distributor_id,
    row_number() over (partition by customer_customer_external_id, dealer_dealer_id order by contract_date) as distributor_number,
    * except(bronze_loaded_at_utc, loaded_at_utc, _source, dealer_dealer_id)
  from {{ ref('silver_sell_out_practice_1') }}
),

-- 每个 (customer, dealer) 的最大 row_number = 该 dealer 的合同数
with_stats as (
  select
    *,
    max(distributor_number) over (partition by customer_customer_external_id, distributor_id) as max_rn_per_dealer
  from base
),

-- 每个 customer 取 row_number 最大的那个 dealer 作为 primary_distributor
with_primary as (
  select
    *,
    first_value(distributor_id) over (
      partition by customer_customer_external_id
      order by max_rn_per_dealer desc, contract_date desc
    ) as primary_distributor_id
  from with_stats
)

select
  * except(distributor_id, max_rn_per_dealer, primary_distributor_id),
  primary_distributor_id as distributor_id
from with_primary
