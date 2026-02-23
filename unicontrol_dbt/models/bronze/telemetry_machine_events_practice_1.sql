{{ config(
    materialized = 'table',
    schema = 'bronze',
    partition_by = { 'field' : '_month', 
                     'data_type' : 'date',
                     'granularity' : 'month'}
) }}

select * ,
date(concat(left(cast(day as string), 7), '-01')) as _month,
current_timestamp() as _loaded_at_utc,
'ext.telemetry_machine' as _source
from {{ source('ext', 'telemetry_machine') }}