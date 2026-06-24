{{ config(materialized='view') }}

select
    cast(activity_id as int) as activity_id,
    cast(deal_id as int) as deal_id,
    cast(assigned_to_user as int) as assigned_to_user,
    trim(type) as activity_type,
    cast(done as boolean) as is_done,
    cast(due_to as timestamp) as due_date,
    'Pipedrive' as source_system_code
from {{ source('pipedrive_raw', 'activity') }}
