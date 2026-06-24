{{ config(materialized='view') }}

select
    cast(deal_id as int) as deal_id,
    cast(change_time as timestamp) as change_time,
    changed_field_key as changed_field_key,
    new_value as new_value,
    'Pipedrive' as source_system_code
from {{ source('pipedrive_raw', 'deal_changes') }}
