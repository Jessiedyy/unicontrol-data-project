{{ config(
    materialized = 'view',
    schema =  'gold',
    tags = ['gold', 'fact']
) }}

select 
  event_id as machine_event_id,
  * except(payload_raw, bronze_loaded_at_utc, loaded_at_utc, _source, event_id)
from {{ ref('silver_telemetry_machine_events_practice_1') }}
