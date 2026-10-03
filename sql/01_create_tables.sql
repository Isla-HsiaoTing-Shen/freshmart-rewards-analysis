-- =====================================================================
-- FreshMart Rewards Analysis
-- 01_create_tables.sql
-- Purpose : Create the 10 tables of the loyalty-program database
-- Database: PostgreSQL 18 (database name: freshmart)
-- Note    : Safe to re-run. Existing tables are dropped first.
-- =====================================================================
 
-- ---------------------------------------------------------------------
-- 0. Drop tables (children first, because of foreign keys)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS experiment_assignment;
DROP TABLE IF EXISTS experiments;
DROP TABLE IF EXISTS points_ledger;
DROP TABLE IF EXISTS offer_sends;
DROP TABLE IF EXISTS offers;
DROP TABLE IF EXISTS transaction_items;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS members;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS stores;

-- ---------------------------------------------------------------------
-- 1. Reference tables
-- ---------------------------------------------------------------------
CREATE TABLE stores (
    store_id        VARCHAR(4)    PRIMARY KEY,      -- e.g. S001
    store_name      VARCHAR(50)   NOT NULL,
    suburb          VARCHAR(50)   NOT NULL,
    state           VARCHAR(3)    NOT NULL,         -- NSW, VIC, QLD ...
    region_type     VARCHAR(10)   NOT NULL,         -- Metro / Regional
    store_format    VARCHAR(20)   NOT NULL,         -- Large Format / Supermarket / Metro
    opened_date     DATE
);
 
CREATE TABLE products (
    product_id      INTEGER       PRIMARY KEY,
    product_name    VARCHAR(100)  NOT NULL,
    category        VARCHAR(50)   NOT NULL,
    brand           VARCHAR(50)   NOT NULL,
    brand_tier      VARCHAR(20)   NOT NULL,         -- Essentials / Own Brand / National Brand / Premium
    regular_price   NUMERIC(10,2) NOT NULL,         -- money: NUMERIC, never FLOAT
    unit_cost       NUMERIC(10,2) NOT NULL
);
 
-- ---------------------------------------------------------------------
-- 2. Members
-- ---------------------------------------------------------------------
CREATE TABLE members (
    member_id             VARCHAR(6)   PRIMARY KEY,  -- e.g. M00001
    join_date             DATE         NOT NULL,
    age_band              VARCHAR(10),
    gender                VARCHAR(15),
    state                 VARCHAR(3),
    home_store_id         VARCHAR(4)   REFERENCES stores(store_id),
    marketing_opt_in      SMALLINT     NOT NULL,     -- 1 = yes, 0 = no
    app_user              SMALLINT     NOT NULL,     -- 1 = yes, 0 = no
    redemption_preference VARCHAR(20)                -- Automatic / Christmas Savings
);
 
-- ---------------------------------------------------------------------
-- 3. Sales
-- ---------------------------------------------------------------------
CREATE TABLE transactions (
    transaction_id           BIGINT        PRIMARY KEY,
    member_id                VARCHAR(6)    NOT NULL REFERENCES members(member_id),
    store_id                 VARCHAR(4)    NOT NULL REFERENCES stores(store_id),
    transaction_datetime     TIMESTAMP     NOT NULL,
    channel                  VARCHAR(20)   NOT NULL, -- In-store / Online - Delivery / Online - Pick Up
    item_count               INTEGER       NOT NULL,
    gross_amount             NUMERIC(10,2) NOT NULL, -- at regular prices
    promo_discount           NUMERIC(10,2) NOT NULL,
    subtotal                 NUMERIC(10,2) NOT NULL, -- gross_amount - promo_discount
    rewards_dollars_redeemed INTEGER       NOT NULL,
    amount_paid              NUMERIC(10,2) NOT NULL,
    points_earned            INTEGER       NOT NULL
);
 
CREATE TABLE transaction_items (
    transaction_id  BIGINT        NOT NULL REFERENCES transactions(transaction_id),
    product_id      INTEGER       NOT NULL REFERENCES products(product_id),
    quantity        INTEGER       NOT NULL,
    unit_price      NUMERIC(10,2) NOT NULL,         -- price actually charged
    is_promo        SMALLINT      NOT NULL,         -- 1 = on promotion
    PRIMARY KEY (transaction_id, product_id)        -- one row per product per shop
);
 
-- ---------------------------------------------------------------------
-- 4. Offers
-- ---------------------------------------------------------------------
CREATE TABLE offers (
    offer_id          VARCHAR(7)    PRIMARY KEY,    -- e.g. OFR0001
    offer_name        VARCHAR(100)  NOT NULL,
    campaign_type     VARCHAR(30)   NOT NULL,       -- Weekly Personalised / Win-back Experiment
    offer_type        VARCHAR(30)   NOT NULL,       -- Spend & Get / Category Bonus / Points Multiplier
    category          VARCHAR(50),                  -- only for Category Bonus
    min_spend         INTEGER,
    bonus_points      INTEGER,
    points_multiplier INTEGER,
    start_date        DATE          NOT NULL,
    end_date          DATE          NOT NULL
);
 
CREATE TABLE offer_sends (
    send_id                 INTEGER     PRIMARY KEY,
    offer_id                VARCHAR(7)  NOT NULL REFERENCES offers(offer_id),
    member_id               VARCHAR(6)  NOT NULL REFERENCES members(member_id),
    sent_datetime           TIMESTAMP   NOT NULL,
    activated               SMALLINT    NOT NULL,
    activated_datetime      TIMESTAMP,                -- NULL if not activated
    redeemed                SMALLINT    NOT NULL,
    redeemed_transaction_id BIGINT      REFERENCES transactions(transaction_id),
    bonus_points_awarded    INTEGER     NOT NULL
);
 
-- ---------------------------------------------------------------------
-- 5. Points
-- ---------------------------------------------------------------------
CREATE TABLE points_ledger (
    ledger_id       INTEGER      PRIMARY KEY,
    member_id       VARCHAR(6)   NOT NULL REFERENCES members(member_id),
    event_datetime  TIMESTAMP    NOT NULL,
    event_type      VARCHAR(20)  NOT NULL,          -- OPENING_BALANCE / EARN / BONUS / REDEEM
    points          INTEGER      NOT NULL,          -- negative = redeemed
    transaction_id  BIGINT       REFERENCES transactions(transaction_id),
    offer_id        VARCHAR(7)   REFERENCES offers(offer_id),
    description     VARCHAR(100)
);
 
-- ---------------------------------------------------------------------
-- 6. A/B test
-- ---------------------------------------------------------------------
CREATE TABLE experiments (
    experiment_id     VARCHAR(10)  PRIMARY KEY,
    experiment_name   VARCHAR(100) NOT NULL,
    hypothesis        TEXT,
    eligibility_rule  TEXT,
    randomisation     TEXT,
    offer_id          VARCHAR(7)   REFERENCES offers(offer_id),
    start_date        DATE         NOT NULL,
    end_date          DATE         NOT NULL,
    primary_metric    TEXT,
    secondary_metrics TEXT
);
 
CREATE TABLE experiment_assignment (
    experiment_id   VARCHAR(10)  NOT NULL REFERENCES experiments(experiment_id),
    member_id       VARCHAR(6)   NOT NULL REFERENCES members(member_id),
    group_name      VARCHAR(10)  NOT NULL,          -- Treatment / Control
    assigned_date   DATE         NOT NULL,
    PRIMARY KEY (experiment_id, member_id)
);
 
