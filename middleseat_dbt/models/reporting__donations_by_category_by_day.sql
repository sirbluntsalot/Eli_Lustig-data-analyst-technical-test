/*
  Model: reporting__donations_by_category_by_day
  
  Description:
  This reporting model serves as the primary data source for the Benito for President (BFP) 2028 Dashboard. 
  It aggregates granular donation records into a day-by-day, category-by-category view for longitudinal 
  campaign analysis.

  Larger Context:
  1. Base Layer: Pulls from `core__donations` (cleaned donation records).
  2. Enrichment: Joins with campaign seed files:
     - `seed_income_zip_data`: maps zip codes to household income brackets.
     - `seed_2024_election_states`: adds electoral category (Blue/Red/Swing) and 2024 winner.
     - `seed_primary_calendar`: associates each state with its 2028 primary election date.
  3. Output: Produces the daily 'Raised' metrics (dollars and counts) used to track momentum around 
     key dates like Super Tuesday.
*/


{{
    config(
        dist='wdl_client_code',
        sort=['wdl_client_code', 'likely_source_type']
    )
}}

WITH base AS (
    SELECT
        wdl_client_code,
        CAST(et_created_at AS DATE) AS et_created_date,
        COALESCE(likely_source_type, 'None') AS likely_source_type,
        form_managing_entity_committee_name,
        committee_name,
        COALESCE(recurring_type, 'None') AS recurring,
        post_refund_amount,
        wdl_transaction_id,
        state,
        zip
    FROM {{ ref('core__donations')}}
),

zip_income AS (
    SELECT * FROM {{ ref('seed_income_zip_data') }}
),

election_states AS (
    SELECT * FROM {{ ref('seed_2024_election_states') }}
),

primary_calendar AS (
    SELECT * FROM {{ ref('seed_primary_calendar') }}
)

SELECT
    b.wdl_client_code,
    b.et_created_date,
    b.likely_source_type,
    b.form_managing_entity_committee_name,
    b.committee_name,
    b.recurring,
    b.zip,
    b.state,
    i.income_bracket,
    es.Category AS electoral_category,
    es.Winner AS electoral_winner,
    pc.primary_date AS state_primary_date,
    SUM(b.post_refund_amount) AS dollars_raised,
    COUNT(DISTINCT b.wdl_transaction_id) AS number_of_donations
FROM base b
LEFT JOIN zip_income i 
    ON b.zip = i.zip
LEFT JOIN election_states es 
    ON b.state = es.Abbreviation
LEFT JOIN primary_calendar pc 
    ON es.State = pc.state_name
GROUP BY 
    b.wdl_client_code, 
    b.et_created_date, 
    b.likely_source_type, 
    b.form_managing_entity_committee_name, 
    b.committee_name, 
    b.recurring,
    b.zip,
    b.state,
    i.income_bracket,
    es.Category,
    es.Winner,
    pc.primary_date
ORDER BY 
    b.wdl_client_code, 
    b.et_created_date DESC, 
    b.likely_source_type
