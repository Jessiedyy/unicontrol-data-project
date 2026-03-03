{{ config(
    materialized = 'view',
    schema = 'marts',
    tags = ['marts', 'fact']
) }}

select order_key,
       order_id,
       contract_date,
       activate_date,
       occurred_at,
       vin,
       c.customer_key as customer_key,
       d.distributor_id as distributor_id,
       product_type_key,
       product_type,
       product_list_price_dkk,
       product_currency as currency,
       order_type,
       _month,
       raw_notes as notes,
       raw_discount_pct as discount_pct,
       raw_dealer_payload_version as distributor_payload_version,
       raw_source_system as source_system
 from {{ ref('fact_api_sell_out') }} s
 left join {{ ref('dim_customer') }} c
 on s.customer_customer_external_id = c.customer_external_id
 left join {{ ref('dim_crm_distributor_info') }} d
 on s.distributor_id = d.distributor_id
 left join {{ ref('marts_dim_product_type') }} p
   on s.product_product_type = p.product_type
  and s.product_list_price_dkk = p.list_price_dkk
