# FreshMart Rewards – Synthetic Supermarket Loyalty Dataset

> **Disclaimer:** All data is simulated. FreshMart is a fictional Australian supermarket chain and is not affiliated with Coles, Woolworths or any real retailer. No real customer data is used.

This dataset supports a portfolio project on **member churn** and **offer effectiveness** in a supermarket loyalty program, including a **randomised A/B test** of a win-back offer.

## Overview

| Item | Value |
|---|---|
| Period | 6 Jan 2025 – 28 Jun 2026 (77 weeks) |
| Members | 8,000 |
| Stores | 36 across NSW, VIC, QLD, WA, SA, ACT, TAS |
| Products | 237 across 12 categories |
| Transactions | ~475,000 |
| Transaction line items | ~2.75 million |
| Currency | AUD |

**Program rules:** members earn 1 point per $1 spent (on the subtotal after promotional discounts). 2,000 points = $10 off. Members choose a redemption preference: *Automatic* ($10 off is applied at the next shop once they reach 2,000 points) or *Christmas Savings* (points are converted to dollars once a year, on 15 Nov).

## Entity relationships

```
stores ─┬─< members (home_store_id)
        └─< transactions (store_id)
members ─┬─< transactions ─< transaction_items >─ products
         ├─< offer_sends >─ offers
         ├─< points_ledger
         └─< experiment_assignment >─ experiments
experiments >─ offers (offer_id = the win-back offer)
```

## Tables

### `stores.csv`
| Column | Description |
|---|---|
| store_id | Primary key (S001…) |
| store_name | e.g. FreshMart Parramatta |
| suburb, state | Location |
| region_type | Metro / Regional |
| store_format | Large Format / Supermarket / Metro (small CBD store) |
| opened_date | Store opening date |

### `products.csv`
| Column | Description |
|---|---|
| product_id | Primary key (integer) |
| product_name, category, brand | Product details |
| brand_tier | Essentials / Own Brand / National Brand / Premium |
| regular_price | Shelf price (AUD) |
| unit_cost | Cost to FreshMart – use for margin analysis |

### `members.csv`
| Column | Description |
|---|---|
| member_id | Primary key (M00001…) |
| join_date | Date the member joined (some before 2025, ~20% during the period) |
| age_band, gender, state | Demographics |
| home_store_id | Member's usual store (FK → stores) |
| marketing_opt_in | 1 = can receive personalised offers |
| app_user | 1 = uses the mobile app |
| redemption_preference | Automatic / Christmas Savings |

### `transactions.csv`  (one row per shop)
| Column | Description |
|---|---|
| transaction_id | Primary key |
| member_id, store_id | FKs |
| transaction_datetime | Date and time of purchase |
| channel | In-store / Online - Delivery / Online - Pick Up |
| item_count | Total units |
| gross_amount | Value at regular prices |
| promo_discount | Discount from weekly promotions |
| subtotal | gross_amount − promo_discount (the basis for points) |
| rewards_dollars_redeemed | Dollars of points redeemed on this shop |
| amount_paid | subtotal − rewards_dollars_redeemed |
| points_earned | Base points (floor of subtotal) |

### `transaction_items.csv`  (one row per product per shop)
| Column | Description |
|---|---|
| transaction_id, product_id | Composite key |
| quantity | Units |
| unit_price | Price actually charged (after promo) |
| is_promo | 1 = product was on weekly promotion |

Line total = `quantity × unit_price`. Line margin = `quantity × (unit_price − products.unit_cost)`.

### `offers.csv`
| Column | Description |
|---|---|
| offer_id | Primary key |
| offer_name | Customer-facing description |
| campaign_type | Weekly Personalised / Win-back Experiment |
| offer_type | Spend & Get / Category Bonus / Points Multiplier |
| category | Qualifying category (Category Bonus only) |
| min_spend | Minimum subtotal to qualify |
| bonus_points | Fixed bonus (Spend & Get, Category Bonus) |
| points_multiplier | 2 or 3 (Points Multiplier: bonus = (multiplier − 1) × base points) |
| start_date, end_date | Offer window |

### `offer_sends.csv`  (one row per offer sent to a member)
| Column | Description |
|---|---|
| send_id | Primary key |
| offer_id, member_id | FKs |
| sent_datetime | When the offer was sent |
| activated, activated_datetime | Whether / when the member activated (boosted) the offer |
| redeemed | 1 = member made a qualifying purchase after activating |
| redeemed_transaction_id | The qualifying transaction |
| bonus_points_awarded | Bonus points credited |

Funnel: **sent → activated → redeemed**. Only opted-in members receive offers.

### `points_ledger.csv`
| Column | Description |
|---|---|
| ledger_id | Primary key |
| member_id | FK |
| event_datetime | When the points movement happened |
| event_type | OPENING_BALANCE / EARN / BONUS / REDEEM |
| points | Positive = credited, negative = redeemed |
| transaction_id, offer_id | Related records (where applicable) |
| description | Plain-English note |

Points balance (liability) at any date = running sum of `points`. 1 point ≈ $0.005.

### `experiments.csv`
Describes **EXP001 – Lapsing Member Win-back Offer**: hypothesis, eligibility rule, randomisation, dates, offer and metrics.

### `experiment_assignment.csv`
| Column | Description |
|---|---|
| experiment_id | FK → experiments |
| member_id | FK → members |
| group_name | Treatment (received the offer) / Control (no offer) |
| assigned_date | Randomisation date |

To measure the outcome, join to `transactions` and check whether each member shopped between `start_date` and `end_date`.

## Suggested definitions

- **Active member:** at least one transaction in the last 8 weeks.
- **Churned member:** no transaction for 8 consecutive weeks. (Define and justify your own – this is part of the analysis.)
- **For churn prediction:** build features from an observation window (e.g. Jan–Dec 2025) and the label from a later window (e.g. Jan–Feb 2026). Never let the label period leak into the features.

## Notes for GitHub

`transaction_items.csv` is ~60 MB. GitHub warns above 50 MB and blocks files above 100 MB. Options: use Git LFS, upload the data as a zipped release, or commit only `generate_data.py` and let readers regenerate the data (`python generate_data.py`, seeded for reproducibility).

## Reproduce

```bash
pip install numpy pandas
python generate_data.py
```
