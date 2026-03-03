{{ config(
    materialized = 'view',
    schema = 'gold',
    tags = ['gold', 'dimension']
) }}

with fact as (
  select * from {{ ref('fact_api_sell_out') }}
),

-- 对每个 customer 的每个属性：在非 null 行中，取 contract_date 最新的那行的值
-- first_value(... ignore nulls) + order by contract_date desc = 取「最新日期且非 null」的值
with_best_values as (
  select
    customer_customer_external_id as customer_external_id,
    distributor_id,
    -- 各属性：取最新 contract_date 对应的非 null 值，全 null 则得 null
    first_value(upper(trim(customer_customer_name)) ignore nulls) over (
      partition by customer_customer_external_id order by contract_date desc
    ) as customer_name,
    first_value(customer_contact_phone ignore nulls) over (
      partition by customer_customer_external_id order by contract_date desc
    ) as contact_phone,
    first_value(trim(customer_contact_email) ignore nulls) over (
      partition by customer_customer_external_id order by contract_date desc
    ) as contact_email,
    first_value(trim(customer_vat) ignore nulls) over (
      partition by customer_customer_external_id order by contract_date desc
    ) as customer_vat,
    row_number() over (partition by customer_customer_external_id order by contract_date desc) as rn
  from fact
  where customer_customer_external_id is not null
),

-- 每个 customer 只保留一行
dedup as (
  select *
  from with_best_values
  where rn = 1
)

select
  {{ dbt_utils.generate_surrogate_key(['customer_external_id']) }} as customer_key,
  customer_external_id,
  customer_name,
  contact_phone,
  contact_email,
  customer_vat,
  d.distributor_id,
  d.region,
  d.country
from dedup
left join {{ ref('dim_crm_distributor_info') }} d
  on dedup.distributor_id = d.distributor_id
