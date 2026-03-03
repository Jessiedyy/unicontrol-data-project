{{ config(
    materialized = 'view',
    schema = 'gold',
    tags = ['gold', 'dimension']
) }}

select dealer_id as distributor_id,
       name as distributor_name,
       created_at,
       partner_since,
       updated_at,
       status as distributor_status,
       region,
       country,
       _snapshot_month as snapshot_month,
       *
       except(bronze_loaded_at_utc, _loaded_at_utc, _source, dealer_id, name, 
       created_at, partner_since, updated_at, status, region, country, 
       _snapshot_month)
from {{ ref('silver_crm_distributor_info_practice_1') }}
where _snapshot_month = 
(select max(_snapshot_month) from {{ ref('silver_crm_distributor_info_practice_1') }})