{{ config(
    materialized = 'table',
    schema = 'silver',
    partition_by = { 'field' : '_month',
                     'data_type' : 'date',
                     'granularity' : 'month'}   
) }}

select * except(_loaded_at_utc, attributes),
trim(attributes.billing_cycle) as attributes_billing_cycle,
trim(attributes.plan) as attributes_plan,
_loaded_at_utc as bronze_loaded_at_utc,
current_timestamp() as loaded_at_utc
from {{ ref('billing_subscription_event_practice_1') }}
