{{ config(materialized='table') }}

with transitions as (
    select
        deal_id,
        stage_id,
        change_time as entered_stage_at,
        lead(change_time) over (partition by deal_id order by change_time) as exited_stage_at
    from {{ ref('vw_int_deal_stage_transitions') }}
)

select
    deal_id,
    stage_id,
    entered_stage_at,
    exited_stage_at,
    (coalesce(exited_stage_at, current_timestamp)::date - entered_stage_at::date) as days_in_stage

from transitions