{{ config(materialized='view') }}

with ranked_activities as (

    select
        *,
        row_number() over (partition by activity_id order by due_date asc) as rn
    from {{ ref('vw_stg_pipedrive_activity') }}

)

select
    activity_id,
    deal_id,
    assigned_to_user,
    activity_type,
    is_done,
    due_date,
    source_system_code
from ranked_activities
where rn = 1