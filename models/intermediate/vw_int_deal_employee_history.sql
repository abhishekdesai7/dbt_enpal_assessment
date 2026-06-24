{{ config(materialized='view') }}

select
    deal_id,
    cast(new_value as int) as assigned_employee_id,
    change_time as valid_from,
    lead(change_time) over ( partition by deal_id order by change_time) as valid_to
from {{ ref('vw_stg_pipedrive_deal_changes') }}
where changed_field_key = 'user_id'