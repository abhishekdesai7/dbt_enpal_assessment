{{ config(materialized='view') }}

select
    cast(id as int) as employee_id,
    trim(name) as employee_name,
    lower(trim(email)) as employee_email,
    cast(modified as timestamp) as modified_timestamp,
    'Pipedrive' as source_system_code
from {{ source('pipedrive_raw', 'users') }}