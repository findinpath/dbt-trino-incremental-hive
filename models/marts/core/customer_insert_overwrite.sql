{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'insert_overwrite',
        unique_key = 'customer_id',
        properties={
          "format": "'ORC'",
          "partitioned_by": "ARRAY['customer_id']",
        })
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
