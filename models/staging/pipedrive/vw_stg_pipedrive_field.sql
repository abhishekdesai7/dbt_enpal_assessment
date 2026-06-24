{{ config(materialized='view') }}

select
    cast(id as int) as field_id,
    field_key,
    trim(name) as field_name,
    field_value_options,
    'Pipedrive' as source_system_code
from {{ source('pipedrive_raw', 'fields') }}