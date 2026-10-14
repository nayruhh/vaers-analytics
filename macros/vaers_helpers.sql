-- Turns a text date into a real DATE, whether it is 01/31/2021 or 2021-01-31.
{% macro parse_date(col) %}
    coalesce(
        try_to_date(trim({{ col }}), 'MM/DD/YYYY'),
        try_to_date(trim({{ col }}), 'YYYY-MM-DD')
    )
{% endmacro %}

-- Turns VAERS 'Y' / blank flags into TRUE / FALSE.
{% macro yn_flag(col) %}
    coalesce(upper(trim({{ col }})) = 'Y', false)
{% endmacro %}

-- Treats placeholder text ('NONE MENTIONED', 'N/A', 'UNKNOWN'...) as empty.
{% macro clean_text(col) %}
    case
        when upper(trim({{ col }})) in ('', 'NONE', 'NONE MENTIONED', 'NONE REPORTED',
                                        'NONE KNOWN', 'N/A', 'NA', 'UNKNOWN', 'UNK', 'NO')
            then null
        else trim({{ col }})
    end
{% endmacro %}