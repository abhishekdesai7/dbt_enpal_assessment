{{ config(materialized='view') }}

select
    cast(stage_id as int) as stage_id,
    trim(stage_name) as stage_name,
    'Pipedrive' as source_system_code
from {{ source('pipedrive_raw', 'stages') }}
