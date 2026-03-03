{{ config(
    materialized = 'table',
    schema = 'silver',
    partition_by = { 'field' : '_month',
                     'data_type' : 'date',
                     'granularity' : 'month'}   
) }}

select * except(_loaded_at_utc, payload,vin,project_id),
json_value(payload_raw, '$.job_type') as payload_job_type,
json_value(payload_raw, '$.product_type') as payload_product_type,
json_value(payload_raw, '$.duration_min') as payload_duration_min,
json_value(payload_raw, '$.offset_type') as payload_offset_type,
json_value(payload_raw, '$.method') as payload_method,
json_value(payload_raw, '$.point_type') as payload_point_type,
_loaded_at_utc as bronze_loaded_at_utc,
current_timestamp() as loaded_at_utc,
coalesce(vin, 'not available') as vin,
coalesce(project_id, 'not available') as project_id
from {{ ref('telemetry_machine_events_practice_1') }}
