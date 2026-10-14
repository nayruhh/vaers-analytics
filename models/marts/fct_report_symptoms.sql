-- One row per report x symptom. The 5 symptom columns are stacked into one column;
-- DISTINCT removes repeats caused by a report spanning several rows.
with stg as (

    select vaers_id, symptom_1, symptom_2, symptom_3, symptom_4, symptom_5
    from {{ ref('stg_vaers') }}

),

stacked as (

    select vaers_id, symptom_1 as symptom from stg
    union all select vaers_id, symptom_2 from stg
    union all select vaers_id, symptom_3 from stg
    union all select vaers_id, symptom_4 from stg
    union all select vaers_id, symptom_5 from stg

)

select distinct
    md5(vaers_id || '|' || symptom)  as report_symptom_id,
    vaers_id,
    symptom
from stacked
where symptom is not null