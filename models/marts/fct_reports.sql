with stg as (

    select * from {{ ref('stg_vaers') }}

),

-- Collapse to one row per report. Report-level fields repeat on every row,
-- so ANY_VALUE is safe; outcome flags are TRUE if any row says TRUE.
reports as (

    select
        vaers_id,

        any_value(received_date)              as received_date,
        any_value(vaccination_date)           as vaccination_date,
        any_value(onset_date)                 as onset_date,
        any_value(death_date)                 as death_date,
        any_value(days_to_onset)              as days_to_onset_raw,

        any_value(state_code)                 as state_code,
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

final as (

    select
        vaers_id,

        -- dates
        received_date,
        date_trunc('month', received_date)   as received_month,
        vaccination_date,
        onset_date,
        death_date,
        -- keep only plausible onset gaps (0–365 days); typos become NULL
        case when days_to_onset_raw between 0 and 365
             then days_to_onset_raw end       as days_to_onset,

        -- patient
        state_code,
        case when age_years_raw between 0 and 120
             then age_years_raw end           as age_years,
        case
            when age_years_raw is null or age_years_raw not between 0 and 120 then 'Unknown'
            when age_years_raw < 12  then '0-11'
            when age_years_raw < 18  then '12-17'
            when age_years_raw < 30  then '18-29'
            when age_years_raw < 40  then '30-39'
            when age_years_raw < 50  then '40-49'
            when age_years_raw < 65  then '50-64'
            when age_years_raw < 75  then '65-74'
            else '75+'
        end                                   as age_group,
        sex,

        -- vaccine (one label per report)
        case
            when manufacturer_count > 1                       then 'Multiple'
            when single_manufacturer = 'PFIZER-BIONTECH'      then 'Pfizer-BioNTech'
            when single_manufacturer = 'MODERNA'              then 'Moderna'
            when single_manufacturer = 'JANSSEN'              then 'Janssen (J&J)'
            else 'Unknown'
        end                                   as manufacturer,
        administered_by,

        -- outcomes
        is_death,
        is_life_threatening,
        is_hospitalized,
        is_prolonged_stay,
        is_disabled,
        is_birth_defect,
        -- FDA definition of a "serious" VAERS report
        (is_death or is_life_threatening or is_hospitalized
         or is_prolonged_stay or is_disabled or is_birth_defect)
                                              as is_serious,
        had_er_visit,
        had_office_visit,
        hospital_days,
        recovery_status,

        symptom_text

    from reports

)

select * from final