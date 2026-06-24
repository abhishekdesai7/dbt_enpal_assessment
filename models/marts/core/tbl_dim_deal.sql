-- {{ config(materialized='table') }}
{{ config(
    materialized='incremental',
    unique_key='deal_id',
    incremental_strategy='merge'
) }}

with deal_changes as (

    select *
    from {{ ref('vw_stg_pipedrive_deal_changes') }}

    {% if is_incremental() %}
    where change_time >
    (
        select coalesce(max(load_timestamp), '1900-01-01')
        from {{ this }}
    )
    {% endif %}

),

first_add_time as (

    select
        cast(deal_id as int) as deal_id,
        cast(new_value as timestamp) as deal_created_date,
        source_system_code,
        row_number() over (
            partition by deal_id
            order by change_time
        ) as rn
    from deal_changes
    where changed_field_key = 'add_time'

),

first_lost_reason as (

    select
        cast(deal_id as int) as deal_id,
        cast(change_time as timestamp) as deal_closed_date,
        new_value as lost_reason,
        row_number() over (
            partition by deal_id
            order by change_time
        ) as rn
    from deal_changes
    where changed_field_key = 'lost_reason'

)

select
    a.deal_id,
    a.deal_created_date,
    l.deal_closed_date,
    l.lost_reason,

    case
        when l.lost_reason is not null then 'lost'
        else 'open_or_won' -- current date does not reliably differentiate between won and open deals
    end as deal_status,

    a.source_system_code,
    current_timestamp as load_timestamp

from first_add_time a

left join first_lost_reason l
    on a.deal_id = l.deal_id
    and l.rn = 1

where a.rn = 1