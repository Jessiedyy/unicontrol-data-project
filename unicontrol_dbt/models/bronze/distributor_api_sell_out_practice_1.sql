-- 全量 load，按 month 分区，加 _month / _loaded_at_utc / _source

{{ config(
    materialized = 'table',
    schema = 'bronze',
    partition_by = {'field' : '_month', 'data_type' : 'date', 'granularity' : 'month'}
) }}                 

select * except(month),
date(concat(cast(month as string), '-01')) as _month,
current_timestamp() as loaded_at_utc,
'ext.sell_out' as _source
from {{ source ('ext', 'sell_out') }}