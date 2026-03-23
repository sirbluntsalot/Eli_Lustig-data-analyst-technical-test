# Project Overview (Benito for President)

This document provides a non-technical, high-level overview of the data pipeline built for the **Benito for President** campaign. It explains what each piece of code does in simple terms.
---

## Understanding dbt Concepts
Before diving into the specific files, here is a quick guide to the different terms you'll see in this project:
- **Models:** These are the actual data tables we create. In dbt, a "model" is just a set of instructions (a query) that takes raw data, cleans or transforms it, and saves it as a new table in our database.
- **Macros:** These are reusable helper functions. Instead of copying and pasting the same complex calculation or rule into ten different models, we write it once as a macro and let the models borrow it. 
- **Queries:** This is the underlying code language (SQL) we use to ask the database questions or give it instructions. Models and macros are written using queries.
- **Seeds:** These are small, static spreadsheets (like CSV files) containing helpful mapping data that doesn't change very often. We upload them directly into our database to help our models categorize things.

---

### `likely_source_type` (Type: Macro)
**What it does:** 
It acts like a detective to determine where a donation came from (e.g., Email, Ads, Texting, Website). It first looks for a clearly labeled source, but if none exists, it searches through the donation tracking codes or form names for specific keywords (like "em" for email or "ads" for ads) to make an educated guess.

**Why it matters:** 
Instead of copying and pasting these long categorization rules into every single table that records donations, we just store the rules here. Any table needing to know a donation's origin can simply call this one file, keeping our system clean and consistent.

### `get_precore_tables` (Type: Macro)
**What it does:**
This acts like an automated search engine for the database. Instead of a person manually listing out every data table they want to look at, they can give this tool a pattern or set of rules. It scans the database and instantly returns a list of all tables that match those rules.

**Why it matters:**
When we have multiple similar tables from different platforms (like separate tables for ActBlue donations, NGP donations, etc.), we need to gather them all to combine them. This function automates that gathering process, so we never have to manually update our code when a new data source table is added.

---

## Data Cleanup (Pre-Core Models)
*These tables take raw data from a single specific platform and clean it up before it gets merged into our main reporting tables.*

### `precore_actblue__donations` (Type: Model)
**What it does:**
This table takes raw, messy donation data specifically from ActBlue and cleans it up. It adds necessary context to each donation, like identifying the client, converting all times to Eastern Time, and determining if a recurring donation is "New" or "Existing". It also uses our `likely_source_type` macro to fill in missing source information.

**Why it matters:**
Different platforms provide data in very different formats. This is an essential "translate and clean" step. By formatting the ActBlue data perfectly here, we ensure it's ready to be effortlessly combined with other platforms later on in a safe, standardized way.

---

## Core Models (The Master Tables)
*These are the ultimate, combined tables that power our final reporting. They stack the pre-core tables together into one unified source of truth.*

### `core__donations` (Type: Model)
**What it does:**
This is the master list of all incoming money. It takes the cleaned data from all our individual platforms (like ActBlue and Shopify) and stacks them securely together into one massive, unified table. It also generates a `contribution_platform` column, which instantly tells a user if the specific dollar amount came from an ActBlue donation or a Shopify merchandise sale.

**Why it matters:**
Whenever we want to build a dashboard, calculate total revenue, or see trends across our entire fundraising operation, we use this table. We don't have to look at ActBlue and Shopify separately—this table gives us the complete, unified picture.

---

## Configuration and Documentation
*These files define rules, tests, and human-readable definitions for our models.*

### `_core_schema.yml` (Type: YAML Schema)
**What it does:**
This file acts as the dictionary and "quality control" for the final tables (like `core__donations`). It contains plain-English descriptions of what every important column means (like "amount" vs "post_refund_amount"). It also sets up automated tests, like ensuring every donation has a unique ID and isn't blank.

**Why it matters:**
This ensures anyone looking at our data—from engineers to campaign managers—can easily understand what the data represents without having to guess. It also acts as an automated safety net to catch dirty data before it reaches our dashboards.

---

## Static Data Directories (Seeds)
*Seeds are small, static files (usually CSVs) loaded directly into the database. They provide essential context—like mapping zip codes to income brackets—without having to hardcode these rules into our logic.*

### `seed_income_zip_data.csv` (Type: Seed)
**What it does & Why it matters:**
This file maps every single US zip code to a specific numeric income bracket (like "$50k-$100k"). By joining this with our donation data, we can instantly tell the relative income level of the donors contributing to the campaign without violating privacy. 

### `seed_2024_election_states.csv` (Type: Seed)
**What it does & Why it matters:**
This maps every US state to its 2024 Electoral College results (e.g., Red, Blue, Swing, and the exact winner). When joined with our donation data, it tells us exactly where our financial support leans politically on the electoral map.

### `seed_primary_calendar.csv` (Type: Seed)
**What it does & Why it matters:**
This acts as a timeline map linking each state to the date its 2028 primary election is held. Having this timeline in our database is incredibly vital because it allows us to analyze how recurring subscription signups and cancellations fluctuate around key election dates.

---

## Reporting Models
*These tables are specifically designed to feed cleanly into Dashboards (like Data Studio). They pre-group and summarize information to make visualizations fast and clear.*

### `reporting__donations_by_category_by_day` (Type: Model)
**What it does & Why it matters:**
This is the ultimate table used for top-level campaign dashboards. It takes the massive `core__donations` table and summarizes the total dollars raised and the number of donors *by day and by specific categories*. 
Recently, it was updated to seamlessly incorporate the three seed files above. This means you can immediately use this single table to answer complex questions—not just "how much did we raise on Tuesday," but "how much did we raise *on Tuesday, from Swing states, by middle-income donors, leading up to that state's primary.*"

