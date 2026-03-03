{{ config(
    materialized = 'view',
    schema = 'gold',
    tags = ['gold', 'dimension']
) }}

select 
      {{ dbt_utils.generate_surrogate_key(['product_product_type', 'product_list_price_dkk']) }} as product_type_key,
      product_product_type as product_type,
      product_list_price_dkk as list_price_dkk,
      product_currency as currency
 from {{ ref('fact_api_sell_out') }}
group by product_product_type, product_list_price_dkk, product_currency
order by product_product_type asc
