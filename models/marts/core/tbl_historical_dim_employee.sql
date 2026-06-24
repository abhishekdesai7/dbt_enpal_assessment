{{ config(materialized='table') }}

with employee_history as (

    select
        employee_id,
        employee_name,
        employee_email,
        modified_timestamp,
        lead(modified_timestamp) over (partition by employee_id order by modified_timestamp) as next_effective_start_date,
        source_system_code
    from {{ ref('vw_stg_pipedrive_user') }}

)

select
    employee_id,
    employee_name,
    employee_email,
    modified_timestamp as effective_start_date,
    coalesce(next_effective_start_date - interval '1 day', cast('2199-01-01' as date)) as effective_end_date,
    case
        when next_effective_start_date is null then true
        else false
    end as employee_is_active,
    source_system_code,
    current_timestamp as load_timestamp
from employee_history

-- UNION employee data from other source systems
-- Considering creating a new surrogate key if there's overlap between IDs and systems