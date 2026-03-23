/*
  What this file does:
  This file takes raw, messy donation data directly from ActBlue and cleans it up. 
  It adds helpful context to each donation, such as identifying the specific client, 
  standardizing all timestamps to Eastern Time, and labeling whether a donation was 
  "New", "Existing", or "One-time". It also uses our helper functions (like 
  `likely_source_type`) to guess where the donation came from if that info is missing, 
  and applies "finance exclusions" to filter out specific transactions if needed.

  How it fits into the directory:
  This is a "pre-core" or intermediate step. It prepares ActBlue-specific data so 
  that it's perfectly formatted and ready to be merged into our final, master 
  donations table (`core__donations`) later on. If we had other platforms 
  (like NGP or ActionKit), they would have their own similar "pre-core" files.
*/

{{
    config(
        dist='wdl_transaction_id',
        sort=['wdl_transaction_id'],

    )
}}


WITH
    donations AS (
        SELECT * FROM {{ ref('int_actblue__02__donations') }}
    ),

    codes AS (
        SELECT * FROM {{ source('auxiliary', 'actblue_entities_to_client_code') }}
    ),

    sources AS (
        SELECT
            wdl_client_code,
            refcode,
            form_name,
            type AS source_type
        FROM {{ source('auxiliary', 'auxiliary__source_categories_merged') }}
    ),

    finance_exclusions AS (
        SELECT
            wdl_client_code,
            exclude_from_digital,
            order_number
        FROM {{ source('auxiliary', 'auxiliary__finance_exclusions') }}
        WHERE exclude_from_digital IS TRUE
    )

SELECT
    COALESCE(codes.wdl_client_code, 'ZZZ') AS wdl_client_code,
    'actblue-'||LOWER(COALESCE(codes.wdl_client_code, 'ZZZ'))||'-'||donations.lineitem_id as wdl_transaction_id,

    donations.lineitem_id,
    donations.committee_name,
    donations.order_number,
    donations.utc_created_at,
    {{ normalize_timestamp('donations.utc_created_at', 'UTC', 'US/Eastern') }} AS et_created_at,
    EXTRACT(YEAR from donations.et_created_at) AS et_created_year,
    EXTRACT(MONTH from donations.et_created_at) AS et_created_month,
    CAST(
        DATE_TRUNC('month', donations.et_created_at) AS DATE
    ) AS et_created_month_trunc,
    donations.utc_modified_at,
    {{ normalize_timestamp('donations.utc_modified_at', 'UTC', 'US/Eastern') }} AS et_modified_at,
    donations.entity_id,
    donations.amount,
    donations.post_refund_amount,

    donations.first_name,
    donations.last_name,
    donations.email,
    donations.phone,
    donations.address,
    donations.city,
    donations.state,
    donations.zip,
    donations.country,

    CAST(donations.is_recurring AS BOOLEAN) AS is_recurring,
    donations.utc_recurring_started_at,
    donations.recurring_gift_seq,
    donations.recurring_period,
    donations.is_recurring_cancelled,
    donations.utc_recurring_cancelled_at,
    {{ normalize_timestamp('donations.utc_recurring_cancelled_at', 'UTC', 'US/Eastern') }} AS et_recurring_cancelled_at,
    CASE
        WHEN donations.is_recurring = 1 AND donations.recurring_gift_seq = 0 THEN 'New'
        WHEN donations.is_recurring = 1 THEN 'Existing'
        WHEN donations.is_recurring = 0 THEN 'One-time'
        ELSE NULL
    END AS recurring_type,

    donations.is_refunded,
    donations.utc_refunded_at,
    {{ normalize_timestamp('donations.utc_refunded_at', 'UTC', 'US/Eastern') }} AS et_refunded_at,

    COALESCE(finance_exclusions.exclude_from_digital, FALSE) AS is_finance_exclusion,
    CASE WHEN finance_exclusions.order_number IS NOT NULL THEN 'Finance'
            ELSE sources.source_type
        END AS source_type,
    CASE WHEN finance_exclusions.order_number IS NOT NULL THEN 'Finance'
            ELSE {{ likely_source_type('sources.source_type', 'donations.refcode', 'donations.form_name') }}
        END AS likely_source_type,
    donations.refcode,
    donations.refcode2,
    donations.form_name,
    donations.form_managing_entity_committee_name,
    donations.form_managing_entity_name,
    donations.ab_test_name,
    donations.ab_test_variation
FROM donations
LEFT JOIN codes USING (entity_id)
LEFT JOIN finance_exclusions USING (wdl_client_code, order_number)
LEFT JOIN sources ON (
    codes.wdl_client_code = sources.wdl_client_code
    AND COALESCE(donations.refcode, '') = COALESCE(sources.refcode, '')
    AND COALESCE(donations.form_name, '') = COALESCE(sources.form_name, '')
)
