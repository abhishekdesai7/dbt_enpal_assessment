{{ config(materialized='view') }}

with stages as (

    select
        deal_id,
        cast(new_value as int) as stage_id,
        change_time,
        lag(cast(new_value as int)) over (partition by deal_id order by change_time) as previous_stage_id
    from {{ ref('vw_stg_pipedrive_deal_changes') }}
    where changed_field_key = 'stage_id'

)

select
    deal_id,
    stage_id,
    change_time,
    previous_stage_id

from stages
where previous_stage_id is null
   or stage_id <> previous_stage_id