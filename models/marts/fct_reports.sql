with stg as (

    select * from {{ ref('stg_vaers') }}

),

-- Collapse to one row per report.
reports as (

    select
        vaers_id,

        any_value(received_date)              as received_date,
        any_value(vaccination_date)           as vaccination_date,
        any_value(onset_date)                 as onset_date,
        any_value(death_date)                 as death_date,
        any_value(days_to_onset)              as days_to_onset_raw,

        any_value(state_code)                 as state_code_raw,
        any_value(age_years)                  as age_years_raw,
        any_value(sex)                        as sex,

        boolor_agg(is_death)                  as is_death,
        boolor_agg(is_life_threatening)       as is_life_threatening,
        boolor_agg(is_hospitalized)           as is_hospitalized,
        boolor_agg(is_prolonged_stay)         as is_prolonged_stay,
        boolor_agg(is_disabled)               as is_disabled,
        boolor_agg(is_birth_defect)           as is_birth_defect,
        boolor_agg(had_er_visit)              as had_er_visit,
        boolor_agg(had_office_visit)          as had_office_visit,
        max(hospital_days)                    as hospital_days,
        any_value(recovery_status)            as recovery_status,

        count(distinct vaccine_manufacturer)  as manufacturer_count,
        max(vaccine_manufacturer)             as single_manufacturer,
        any_value(administered_by)            as administered_by,
        any_value(symptom_text)               as symptom_text

    from stg
    group by vaers_id

),

states as (

    select state_code from {{ ref('dim_state') }}

),

final as (

    select
        -- primary key
        r.vaers_id,

        -- foreign keys to dimensions
        r.received_date,                                          -- -> dim_date
        coalesce(s.state_code, 'UNK')         as state_code,      -- -> dim_state
        case
            when r.age_years_raw is null or r.age_years_raw not between 0 and 120 then 'Unknown'
            when r.age_years_raw < 12  then '0-11'
            when r.age_years_raw < 18  then '12-17'
            when r.age_years_raw < 30  then '18-29'
            when r.age_years_raw < 40  then '30-39'
            when r.age_years_raw < 50  then '40-49'
            when r.age_years_raw < 65  then '50-64'
            when r.age_years_raw < 75  then '65-74'
            else '75+'
        end                                   as age_group,       -- -> dim_age_group
        case
            when r.manufacturer_count > 1                  then 'Multiple'
            when r.single_manufacturer = 'PFIZER-BIONTECH' then 'Pfizer-BioNTech'
            when r.single_manufacturer = 'MODERNA'         then 'Moderna'
            when r.single_manufacturer = 'JANSSEN'         then 'Janssen (J&J)'
            else 'Unknown'
        end                                   as manufacturer,    -- -> dim_manufacturer

        -- other dates
        r.vaccination_date,
        r.onset_date,
        r.death_date,

        -- patient
        case when r.age_years_raw between 0 and 120
             then r.age_years_raw end         as age_years,
        r.sex,

        -- measures and flags
        case when r.days_to_onset_raw between 0 and 365
             then r.days_to_onset_raw end     as days_to_onset,
        r.is_death,
        r.is_life_threatening,
        r.is_hospitalized,
        r.is_prolonged_stay,
        r.is_disabled,
        r.is_birth_defect,
        (r.is_death or r.is_life_threatening or r.is_hospitalized
         or r.is_prolonged_stay or r.is_disabled or r.is_birth_defect)
                                              as is_serious,
        r.had_er_visit,
        r.had_office_visit,
        r.hospital_days,
        r.recovery_status,
        r.administered_by,
        r.symptom_text

    from reports r
    left join states s
        on r.state_code_raw = s.state_code

)

select * from final