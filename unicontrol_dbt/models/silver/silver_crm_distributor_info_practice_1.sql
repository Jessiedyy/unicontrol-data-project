/*
  Silver: CRM Distributor Info monthly snapshot
  PK: dealer_id + _snapshot_month
*/
{{ config(
    materialized = 'table',
    schema = 'silver',
    partition_by = {'field' : '_snapshot_month', 
                    'data_type' : 'date',
                    'granularity' : 'month' }
) }}

/*
  Remove Nulls and Duplicates in PK (dealer_id + _snapshot_month)
  Trim unwanted spaces in all string columns
*/
with base as (
  select
    b.* except(_loaded_at_utc),
    b._loaded_at_utc as bronze_loaded_at_utc,
    current_timestamp() as _loaded_at_utc,
    row_number() over (
      partition by b.dealer_id, b._snapshot_month
      order by b.updated_at desc nulls last, b.created_at desc nulls last, b._loaded_at_utc desc nulls last
    ) as _row_number
  from {{ ref('crm_distributor_info_practice_1') }} b
)

select
  * except(vat_number, partner_tier, status, dealer_id, name, region, country, currency, _source,
    primary_contact, billing_address, _row_number, country_code, country_name),
  coalesce(trim(vat_number), 'not available') as vat_number,
  trim(partner_tier) as partner_tier,
  trim(status) as status,
  trim(dealer_id) as dealer_id,
  trim(name) as name,
  trim(region) as region,
  coalesce(dim.country_name, trim(base.country)) as country,
  trim(currency) as currency,
  trim(_source) as _source,
  coalesce(trim(primary_contact.name), 'not available') as primary_contact_name,
  coalesce(trim(primary_contact.email), 'not available') as primary_contact_email,
  coalesce(trim(primary_contact.phone), 'not available') as primary_contact_phone,
  trim(billing_address.city) as billing_address_city,
  coalesce(dim_billing.country_name, trim(billing_address.country_code)) as billing_address_country_code,
  coalesce(trim(billing_address.line1), 'not available') as billing_address_line1,
  coalesce(billing_address.postal_code, 0) as billing_address_postal_code
from base
left join {{ ref('dim_country') }} dim on upper(trim(base.country)) = dim.country_code
left join {{ ref('dim_country') }} dim_billing on upper(trim(billing_address.country_code)) = dim_billing.country_code
where base._row_number = 1