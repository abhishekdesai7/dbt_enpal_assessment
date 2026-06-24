{{ config(materialized='table') }}
-- Full refresh as of today due to lack of reliable update timestamp

select
    a.activity_id,
    a.deal_id,
    d.deal_status,
    a.assigned_to_user as assigned_employee_id,
    e.employee_name as assigned_employee_name,
    e.employee_email as assigned_employee_email,
    a.activity_type,
    a.due_date,
    a.is_done,
    a.source_system_code,
    current_timestamp as load_timestamp
from {{ ref('vw_int_activity_deduplicated') }} a

left join {{ ref('tbl_dim_deal') }} d
    on a.deal_id = d.deal_id

left join {{ ref('tbl_historical_dim_employee') }} e
    on a.assigned_to_user = e.employee_id
    and a.due_date between effective_start_date and effective_end_date