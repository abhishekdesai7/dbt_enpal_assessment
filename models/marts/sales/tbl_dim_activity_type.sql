{{ config(materialized='table') }}

select
    activity_type_id,
    activity_type_name,
    activity_type_code,
    is_active
from {{ ref('vw_stg_pipedrive_activity_type') }}