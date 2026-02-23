{{ config(
    materialized = 'table',
    schema = 'silver',
    partition_by = { 'field' : '_month',
                     'data_type' : 'date',
                     'granularity' : 'month'}   
) }}

select * except(_loaded_at_utc),
_loaded_at_utc as bronze_loaded_at_utc,
current_timestamp() as loaded_at_utc
from {{ ref('billing_subscription_terms_practice_1') }}

