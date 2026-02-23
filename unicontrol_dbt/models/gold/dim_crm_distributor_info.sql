{{ config(
    materialized = 'view',
    schema = 'gold',
    tags = ['gold', 'dimension']
) }}

select *
except(bronze_loaded_at_utc, _loaded_at_utc, _source, dealer_id),
dealer_id as distributor_id
from {{ ref('silver_crm_distributor_info_practice_1') }}
where _snapshot_month = 
(select max(_snapshot_month) from {{ ref('silver_crm_distributor_info_practice_1') }})