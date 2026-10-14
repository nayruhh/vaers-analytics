-- One row per calendar day, Dec 2020 (vaccine rollout) to Dec 2021.
with days as (

    select
        dateadd(day, row_number() over (order by seq4()) - 1, '2020-12-01'::date) as date_day
    from table(generator(rowcount => 396))

)

select
    date_day,
    year(date_day)                          as year,
    quarter(date_day)                       as quarter,
    'Q' || quarter(date_day)                as quarter_name,
    month(date_day)                         as month_number,
    monthname(date_day)                     as month_name,      -- Jan, Feb...
    to_char(date_day, 'YYYY-MM')            as year_month,      -- 2021-01
    date_trunc('month', date_day)           as month_start,
    date_trunc('week', date_day)            as week_start,
    dayofweekiso(date_day)                  as weekday_number,  -- 1 = Monday
    dayname(date_day)                       as weekday_name,    -- Mon, Tue...
    dayofweekiso(date_day) in (6, 7)        as is_weekend
from days