{{ config(
    materialized='incremental',
    unique_key='deal_id',
    incremental_strategy='merge'
) }}

with dim_deal as (

    select *
    from {{ ref('tbl_dim_deal') }} d

    {% if is_incremental() %}
    where d.load_timestamp >
    (
        select coalesce(max(t.load_timestamp), '1900-01-01')
        from {{ this }} t
    )
    {% endif %}

),

current_employee as (

    select
        doh.deal_id,
        e.employee_id,
        e.employee_name,
        e.employee_email,
        row_number() over (partition by doh.deal_id order by doh.valid_from desc) as rn
    from {{ ref('vw_int_deal_employee_history') }} doh

    inner join {{ ref('tbl_historical_dim_employee') }} e
        on doh.assigned_employee_id = e.employee_id
        and e.employee_is_active = true
),

first_stage as (

    select
        deal_id,
        min(change_time) as first_stage_entry_date
    from {{ ref('vw_int_deal_stage_transitions') }}
    group by 1
),

latest_stage as (

    select
        deal_id,
        stage_id as latest_stage,
        change_time as latest_stage_entry_date,
        row_number() over (partition by deal_id order by change_time desc) as rn
    from {{ ref('vw_int_deal_stage_transitions') }}
)

select
    d.deal_id,
    d.deal_created_date,
    d.deal_closed_date,
    d.lost_reason,
    d.deal_status,

    ce.employee_id as current_employee_id,
    ce.employee_name as current_employee_name,
    ce.employee_email as current_employee_email,

    fs.first_stage_entry_date,
    ls.latest_stage,
    ls.latest_stage_entry_date,
    d.source_system_code,
    current_timestamp as load_timestamp

from dim_deal d

left join current_employee ce
    on d.deal_id = ce.deal_id
    and ce.rn = 1 --Eliminating multiple employee assignments

left join first_stage fs
    on d.deal_id = fs.deal_id

left join latest_stage ls
    on d.deal_id = ls.deal_id
    and ls.rn = 1 --Appending the most recent stage for the deal
