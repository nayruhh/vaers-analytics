with source as (

    select * from {{ source('vaers_raw', 'vaers_jan_nov_2021') }}

),

cleaned as (

    select
        -- keys
        md5(_source_file || '-' || _source_row)          as vaers_row_id,
        try_to_number(trim(vaers_id))                     as vaers_id,

        -- dates
        {{ parse_date('recvdate') }}                      as received_date,
        {{ parse_date('vax_date') }}                      as vaccination_date,
        {{ parse_date('onset_date') }}                    as onset_date,
        {{ parse_date('datedied') }}                      as death_date,
        {{ parse_date('todays_date') }}                   as form_completed_date,
        try_to_number(trim(numdays))                      as days_to_onset,

        -- patient
        upper(trim(state))                                as state_code,
        try_to_decimal(trim(age_yrs), 5, 2)               as age_years,
        case upper(trim(sex))
            when 'F' then 'Female'
            when 'M' then 'Male'
            else 'Unknown'
        end                                               as sex,

        -- outcomes (TRUE / FALSE)
        {{ yn_flag('died') }}                             as is_death,
        {{ yn_flag('l_threat') }}                         as is_life_threatening,
        {{ yn_flag('hospital') }}                         as is_hospitalized,
        {{ yn_flag('x_stay') }}                           as is_prolonged_stay,
        {{ yn_flag('disable') }}                          as is_disabled,
        {{ yn_flag('birth_defect') }}                     as is_birth_defect,
        {{ yn_flag('er_visit') }} or {{ yn_flag('er_ed_visit') }}
                                                          as had_er_visit,   -- old + new form field combined
        {{ yn_flag('ofc_visit') }}                        as had_office_visit,
        try_to_number(trim(hospdays))                     as hospital_days,
        case upper(trim(recovd))
            when 'Y' then 'Recovered'
            when 'N' then 'Not recovered'
            else 'Unknown'
        end                                               as recovery_status,

        -- vaccine
        upper(trim(vax_type))                             as vaccine_type,
        replace(upper(trim(vax_manu)), '\\', '-')         as vaccine_manufacturer,   -- PFIZER\BIONTECH -> PFIZER-BIONTECH
        upper(trim(vax_lot))                              as vaccine_lot,
        case
            when upper(trim(vax_dose_series)) in ('UNK', '') or vax_dose_series is null then 'Unknown'
            else upper(trim(vax_dose_series))
        end                                               as dose_series,
        upper(trim(vax_route))                            as vaccine_route,
        upper(trim(vax_site))                             as vaccine_site,
        upper(trim(v_adminby))                            as administered_by,

        -- symptoms (MedDRA terms)
        trim(symptom1)                                    as symptom_1,
        trim(symptom2)                                    as symptom_2,
        trim(symptom3)                                    as symptom_3,
        trim(symptom4)                                    as symptom_4,
        trim(symptom5)                                    as symptom_5,

        -- free text (placeholders like 'NONE MENTIONED' become NULL)
        trim(symptom_text)                                as symptom_text,
        {{ clean_text('lab_data') }}                      as lab_data,
        {{ clean_text('other_meds') }}                    as other_meds,
        {{ clean_text('cur_ill') }}                       as current_illness,
        {{ clean_text('history') }}                       as medical_history,
        {{ clean_text('allergies') }}                     as allergies,

        -- lineage
        _source_file,
        _source_row,
        _loaded_at

    from source

)

select * from cleaned