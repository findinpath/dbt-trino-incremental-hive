{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append')
}}

with customers as (

    select * from {{ ref('stg_customer') }}

)

select
       first_name,
       last_name,
       email,
       customer_id
from customers
