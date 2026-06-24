{{ config(materialized='table') }}

with deal_stage_entries as (

    select
        d.deal_id,
        date_trunc('month', fst.entered_stage_at)::date as month,
        fst.stage_id

    from {{ ref('tbl_dim_deal') }} d

    left join {{ ref('tbl_fact_deal_stage_transition') }} fst
        on d.deal_id = fst.deal_id
    where fst.entered_stage_at is not null
),

funnel_counts as (

    select
        month,
        stage_id,
        count(distinct deal_id) as deals_count
    from deal_stage_entries
    group by 1,2

)

select
    fc.month,
    'deals_count' as kpi_name,
    ds.stage_name as funnel_step,
    fc.deals_count

from funnel_counts fc

left join {{ ref('tbl_dim_stage') }} ds
    on fc.stage_id = ds.stage_id