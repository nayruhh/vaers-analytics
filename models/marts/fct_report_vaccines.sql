-- One row per report x vaccine dose listed on the report.
with stg as (

    select * from {{ ref('stg_vaers') }}

),

doses as (

    select distinct
        vaers_id,
        case vaccine_manufacturer
            when 'PFIZER-BIONTECH' then 'Pfizer-BioNTech'
            when 'MODERNA'         then 'Moderna'
            when 'JANSSEN'         then 'Janssen (J&J)'
            else 'Unknown'
        end                         as manufacturer,
        dose_series,
        vaccine_lot,
        vaccine_route,
        vaccine_site
    from stg

)

select
    md5(vaers_id || '|' || manufacturer || '|' || dose_series || '|'
        || coalesce(vaccine_lot, '') || '|' || coalesce(vaccine_route, '') || '|'
        || coalesce(vaccine_site, ''))   as report_vaccine_id,
    *
from doses