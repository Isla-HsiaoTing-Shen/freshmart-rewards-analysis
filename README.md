# freshmart-rewards-analysis
Supermarket loyalty program analysis: member churn, offer effectiveness and A/B testing (SQL, Python, Power BI)

# FreshMart Rewards Analysis

> 🚧 **Work in progress** – this README is updated as the project develops.

Supermarket loyalty program analysis: member churn, offer effectiveness and A/B testing, using **SQL (PostgreSQL)**, **Python** and **Power BI**.

## Business Problem

FreshMart (a fictional Australian supermarket chain) has noticed that more loyalty members are becoming inactive.

**Main question:**
> Member churn is increasing. How can we identify members at risk of churning, and win them back with effective offers?

| Stage | Question |
|---|---|
| 1. Data exploration | What does the data look like? Can we trust it? |
| 2. Current state | How many active members? How serious is churn? |
| 3. Drivers | Which members are more likely to churn? |
| 4. Prediction | Who is likely to churn next? |
| 5. Action | Does a win-back offer work? Is it worth the cost? (A/B test) |
| 6. Reporting | Power BI dashboard for management |

## Data

The dataset is **simulated** and does not contain any real customer data. FreshMart is not affiliated with any real retailer.

| Item | Value |
|---|---|
| Period | 6 Jan 2025 – 28 Jun 2026 (77 weeks) |
| Members | 8,000 |
| Stores | 36 across 7 states |
| Products | 237 across 12 categories |
| Transactions | 475,177 |
| Transaction line items | 2,754,148 |
| Offers / offer sends | 116 / 270,447 |

10 tables in total. See [docs/data_dictionary.md](docs/data_dictionary.md) for every table and column.

**Known limitation:** the data only contains member transactions, so members cannot be compared with non-members.

## Project Structure

```
freshmart-rewards-analysis/
├── sql/
│   ├── 01_create_tables.sql      # Create 10 tables with primary and foreign keys
│   ├── 02_load_data.sql          # Load CSV files with psql \copy + row count check
│   ├── 03_data_exploration.sql   # First look at the data and quality checks
│   └── 04_churn_definition.sql   # Data-driven definition of churn
├── docs/
│   └── data_dictionary.md
└── README.md
```

## Progress So Far

### Step 1 – Database setup (`01`, `02`)
- Designed 10 tables with primary keys, foreign keys and suitable data types.
- Loaded about 4 million rows from 10 CSV files using a re-runnable `psql` script.
- Checked that the row count of every table matches the source files.

### Step 2 – Data exploration (`03`)
- Previewed every table and checked the date range and data volume.
- Counted transactions by channel, products by category and offers by type.
- Built an offer funnel: **sent → activated → redeemed**.
- Checked missing values. Empty values only appear where expected (e.g. `activated_datetime` is empty when an offer was not activated).

### Step 3 – Defining churn (`04`)
Supermarket membership is **non-contractual**: members never "cancel", they simply stop shopping. Churn therefore has to be defined from behaviour.

**3a. How often do members normally shop?**

Average days between purchases, across 7,970 members with 2+ purchases:

| Percentile | Days between purchases |
|---|---|
| 50th (median) | 7.0 |
| 75th | 8.9 |
| 90th | 11.1 |

→ Most members shop about once a week; 90% shop at least every 11 days.

**3b. After an absence, how many members come back?**

For every gap between purchases, I checked whether the member returned:

| Absent for at least | Came back |
|---|---|
| 2 weeks | 95.0% |
| 4 weeks | 80.2% |
| 6 weeks | 46.9% |
| 8 weeks | 16.9% |
| 12 weeks | 2.5% |

**Decision:**

| Status | Definition |
|---|---|
| **At risk** | No purchase for 4 weeks (28 days) |
| **Churned** | No purchase for 8 weeks (56 days) |

**Why:**
- After 2 weeks, 95% of members return – a short absence (e.g. a holiday) is normal.
- After 8 weeks, only 17% return – the shopping habit has most likely moved elsewhere.
- **Weeks 4–8 are the key window for win-back offers**: most members are still recoverable at 4 weeks, but very few are by 8 weeks.

**Limitation:** members who stopped shopping in the last weeks of the data may return after the data ends, so return rates for recent absences may be slightly understated.

## Key Decisions

| Decision | Reason |
|---|---|
| PostgreSQL instead of SQLite | Direct Power BI connection and more analytical functions |
| Money stored as `NUMERIC(10,2)` | Avoids rounding errors from `FLOAT` when summing many transactions |
| Yes/no flags stored as `0/1` | Rates can be calculated directly, e.g. `SUM(activated) / COUNT(*)` |
| Data loaded with a `psql` script | One script reloads all tables, so the database is reproducible |
| Churn = 8 weeks without a purchase | Supported by the return-rate analysis above |

## Next Steps
- Monthly active members and new members
- Monthly churn rate and trend
- Member loyalty (purchase frequency, spend, RFM segments)

## Tools
PostgreSQL 18 · VS Code · Git/GitHub · Python (planned) · Power BI (planned)