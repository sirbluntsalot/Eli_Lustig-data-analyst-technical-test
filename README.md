# 📊 Data Sources & Datasets

This repository contains several seed and master datasets used for electoral analysis and reporting. Below is a description of each file and its origin.

---

## 🗂️ Seed Files

These files provide foundational reference data used to build the larger dataset.

| File | Description | Source |
|------|-------------|--------|
| `seed_2024_election_states.csv` | State-level data from the 2024 U.S. election cycle | [Wikipedia](https://www.wikipedia.org) |
| `seed_income_zip_data.csv` | Income data broken down by ZIP code | [data.census.gov](https://data.census.gov) |
| `seed_primary_calendar.csv` | Hypothetical 2028 primary schedule based on historical primary patterns | Educated estimate |

---

## 📋 Master Dataset

| File | Description |
|------|-------------|
| `Master_Data_Report.csv` | Mock dataset powering the [Looker Studio](https://lookerstudio.google.com) dashboard. Consolidates seed data into a unified reporting layer. |

---

## ⚠️ Notes

- `seed_primary_calendar.csv` is **not** based on official 2028 primary dates — it is an informed projection extrapolated from historical primary scheduling patterns.
- `Master_Data_Report.csv` is a **mock dataset** intended for demonstration and dashboard development purposes only.
