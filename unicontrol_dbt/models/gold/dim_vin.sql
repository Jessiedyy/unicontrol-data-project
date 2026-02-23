{{ config(
    materialized = 'view',
    schema = 'gold',
    tags = ['gold', 'dimension']
) }}

select distinct vin as vin 
from {{ref('silver_sell_out_practice_1') }}