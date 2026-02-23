{{ config(
    materialized = 'table',
    schema = 'silver',
    partition_by = { 'field' : '_month',
                     'data_type' : 'date',
                     'granularity' : 'month'}
) }}

with base as (select * except(loaded_at_utc), 
loaded_at_utc as bronze_loaded_at_utc, 
current_timestamp() as loaded_at_utc
from {{ ref('distributor_api_sell_out_practice_1') }} )

select base.* except(raw, customer, dealer, product, country_name, country_code),
trim(raw.notes)as raw_notes,
trim(raw.discount_pct) as raw_discount_pct,
trim(raw.dealer_payload_version) as raw_dealer_payload_version,
trim(raw.source_system) as raw_source_system,
trim(customer.contact.phone) as customer_contact_phone,
trim(customer.contact.email) as customer_contact_email,
trim(customer.country_code) as customer_country_code,
trim(customer.customer_name) as customer_customer_name,
coalesce(trim(customer.vat), 'not available') as customer_vat,
trim(customer.customer_external_id) as customer_customer_external_id,
coalesce(dim_country.country_name, trim(dealer.country)) as dealer_country
dealer.onboard_date as dealer_onboard_date,
trim(dealer.dealer_name) as dealer_dealer_name,
trim(dealer.region) as dealer_region,
trim(dealer.dealer_id) as dealer_dealer_id,
product.list_price_dkk as product_list_price_dkk,
trim(product.currency) as product_currency,
trim(product.product_type) as product_product_type
from base
left join {{ ref('dim_country') }} 
on base.dealer_country = dim_country.country_code



