{{ config(materialized='table') }}

select
    stage_id,
    stage_name,
    source_system_code
from {{ ref('vw_stg_pipedrive_stage') }}

-- UNION other stages for deals from other source systems e.g. Operations, Billing