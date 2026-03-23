/* 
  What this file does: 
  This is a reusable helper function (a macro) that determines where a donation came from 
  (e.g., Email, Ads, Texting). It first checks if the source is already provided in 
  a source column. If that's empty, it acts like a detective and searches for specific 
  keywords (like 'em' for Email or 'ads' for Ads) hidden inside the donation's tracking 
  code or the name of the donation form.

  How it fits into the directory: 
  Instead of copying and pasting this long set of categorization rules into every table 
  that records donations, we store them once here. Other reports and tables across 
  our reporting system can simply call this single file whenever they need to know a 
  donation's origin, keeping our logic consistent and easy to update.
*/

{% macro likely_source_type(source_type, refcode=none, form_name=none) -%}
{% set search_fields = [refcode, form_name] %}

    CASE 
        WHEN {{ source_type }} IS NOT NULL THEN {{ source_type }}

        {% for field in search_fields %}
            WHEN LEFT(lower(replace( {{ field }},'_','-')), 2) = 'em' THEN 'Email'
            WHEN LEFT(lower(replace( {{ field }},'_','-')), 3) = 'ads' THEN 'Ads'
            WHEN lower(replace( {{ field }},'_','-')) ilike '%p2p%' AND lower(replace( {{ field }},'_','-')) ilike '%-rental-%' THEN 'Texting - P2P Rental'
            WHEN lower(replace( {{ field }},'_','-')) ilike '%p2p%' THEN 'Texting - Owned P2P'
            WHEN lower(replace( {{ field }},'_','-')) ilike '%sms%' AND NOT lower(replace( {{ field }},'_','-')) ilike '%p2p%' THEN 'Texting - Broadcast'
            WHEN lower(replace( {{ field }},'_','-')) ilike 'social' THEN 'Social'
            WHEN lower(replace( {{ field }},'_','-')) ilike '%web%' THEN 'Website'
        {% endfor %}
        
        WHEN lower({{ form_name }}) = 'actblue express donor dashboard contribution' THEN 'ActBlue Donor Dashboard'
        ELSE NULL
        END

{%- endmacro %}