{{ config(
    materialized = 'table',
    schema = 'bronze',
    partition_by = {'field' : '_snapshot_month', 
                    'data_type' : 'date',
                    'granularity' : 'month'}
) }}

select *  except(snapshot_month),
date(concat(cast(snapshot_month as string), '-01')) as _snapshot_month,
current_timestamp() as _loaded_at_utc,
'ext.distributors' as _source
from {{source ('ext', 'distributors')}}