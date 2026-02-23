{{ config(
    materialized = 'table',
    schema = 'bronze',
    partition_by = {'field' : '_month', 'data_type' : 'date', 'granularity' : 'month'}
) }}

select * except(month),
date(concat(cast(month as string), '-01')) as _month,
current_timestamp() as _loaded_at_utc,
'ext.subscription_invoices' as _source
from {{ source ('ext', 'subscription_invoices') }}