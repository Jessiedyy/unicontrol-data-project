{{ config(
    materialized = 'view',
    schema = 'marts',
    tags = ['marts', 'dimension']
)}}

select * 
from {{ ref('dim_crm_distributor_info') }}