{{ config(materialized='view') }}

select
    cast(id as int) as activity_type_id,
    trim(name) as activity_type_name,
    cast(active as boolean) as is_active,
    trim(type) as activity_type_code,
    'Pipedrive' as source_system_code
from {{ source('pipedrive_raw', 'activity_types') }}
