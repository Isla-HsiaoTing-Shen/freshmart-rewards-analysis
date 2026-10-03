-- =====================================================================
-- FreshMart Rewards Analysis
-- 03_data_exploration.sql
-- Purpose : First look at the data - what each table contains,
--           how big it is, and basic data quality checks.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Preview each table (first 10 rows)
-- ---------------------------------------------------------------------
SELECT * FROM stores       LIMIT 10;
SELECT * FROM members      LIMIT 10;
SELECT * FROM products     LIMIT 10;
SELECT * FROM transactions LIMIT 10;
SELECT * FROM offers       LIMIT 10;
SELECT * FROM offer_sends  LIMIT 10;
-- Observations:
--   * Every transaction has points_earned -> the data only contains member transactions
--     (limitation: no non-member sales to compare against).
--   * products: brand_tier = Essentials / Own Brand / National Brand / Premium.
--     regular_price - unit_cost = margin per product (at full price).
--   * offers: min_spend is the threshold to qualify, not what the customer spent.


-- ---------------------------------------------------------------------
-- 2. Time range of the data
-- ---------------------------------------------------------------------
-- Overall first and last transaction
SELECT
    MIN(transaction_datetime) AS first_transaction,
    MAX(transaction_datetime) AS last_transaction
FROM transactions;

-- First and last transaction for each member
SELECT
    member_id,
    MIN(transaction_datetime) AS first_transaction,
    MAX(transaction_datetime) AS last_transaction
FROM transactions
GROUP BY member_id
LIMIT 10;

-- Member join dates
SELECT
    MIN(join_date) AS first_join_date,
    MAX(join_date) AS last_join_date
FROM members;


-- ---------------------------------------------------------------------
-- 3. Counts by category
-- ---------------------------------------------------------------------
-- Stores by state
SELECT
    state,
    COUNT(*) AS store_count
FROM stores
GROUP BY state
ORDER BY store_count DESC;

-- Transactions by channel, with % share
SELECT
    channel,
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM transactions
GROUP BY channel
ORDER BY transaction_count DESC;

-- Products by category
SELECT
    category,
    COUNT(*) AS product_count
FROM products
GROUP BY category
ORDER BY product_count DESC;

-- Offers by type
SELECT
    offer_type,
    COUNT(*) AS offer_count
FROM offers
GROUP BY offer_type
ORDER BY offer_count DESC;


-- ---------------------------------------------------------------------
-- 4. Offer sends
-- ---------------------------------------------------------------------
-- How many members received each offer
SELECT
    offer_id,
    COUNT(*) AS member_count
FROM offer_sends
GROUP BY offer_id
ORDER BY member_count DESC;

-- Total sends vs. unique offers vs. unique members
SELECT
    COUNT(*)                  AS total_sends,
    COUNT(DISTINCT offer_id)  AS unique_offers,
    COUNT(DISTINCT member_id) AS unique_members
FROM offer_sends;

-- Activation rate and redemption rate (out of all sends)
SELECT
    COUNT(*)                                     AS total_sent,
    SUM(activated)                               AS total_activated,
    ROUND(SUM(activated) * 100.0 / COUNT(*), 2)  AS activation_rate_pct,
    ROUND(SUM(redeemed)  * 100.0 / COUNT(*), 2)  AS redemption_rate_pct
FROM offer_sends;

-- Offer funnel: sent -> activated -> redeemed
SELECT
    COUNT(*)       AS sent,
    SUM(activated) AS activated,
    SUM(redeemed)  AS redeemed,
    ROUND(SUM(redeemed) * 100.0 / SUM(activated), 1) AS redeemed_of_activated_pct
FROM offer_sends;


-- ---------------------------------------------------------------------
-- 5. Data quality: missing values
-- ---------------------------------------------------------------------
-- member_id is NOT NULL by design -> should return 0 rows
SELECT *
FROM offer_sends
WHERE member_id IS NULL;

-- activated_datetime is empty when an offer was not activated
-- (this number + total_activated should equal total_sent)
SELECT COUNT(*) AS not_activated_count
FROM offer_sends
WHERE activated_datetime IS NULL;