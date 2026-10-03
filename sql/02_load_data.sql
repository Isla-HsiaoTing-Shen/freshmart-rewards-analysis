-- =====================================================================
-- FreshMart Rewards Analysis
-- 02_load_data.sql
-- Purpose : Load the 10 CSV files into the tables created by 01_create_tables.sql
-- =====================================================================

-- Stop immediately if any step fails
\set ON_ERROR_STOP on

-- ---------------------------------------------------------------------
-- 0. Empty all tables (so the script can be re-run without duplicates)
-- ---------------------------------------------------------------------
TRUNCATE experiment_assignment, experiments, points_ledger, offer_sends, offers,
         transaction_items, transactions, members, products, stores;

-- ---------------------------------------------------------------------
-- 1. Load data (parents first, because of foreign keys)
-- ---------------------------------------------------------------------
\echo 'Loading stores...'
\copy stores                FROM 'data/stores.csv'                WITH (FORMAT csv, HEADER true)
\echo 'Loading products...'
\copy products              FROM 'data/products.csv'              WITH (FORMAT csv, HEADER true)
\echo 'Loading members...'
\copy members               FROM 'data/members.csv'               WITH (FORMAT csv, HEADER true)
\echo 'Loading transactions (large file, please wait)...'
\copy transactions          FROM 'data/transactions.csv'          WITH (FORMAT csv, HEADER true)
\echo 'Loading transaction_items (largest file, about 1 minute)...'
\copy transaction_items     FROM 'data/transaction_items.csv'     WITH (FORMAT csv, HEADER true)
\echo 'Loading offers...'
\copy offers                FROM 'data/offers.csv'                WITH (FORMAT csv, HEADER true)
\echo 'Loading offer_sends...'
\copy offer_sends           FROM 'data/offer_sends.csv'           WITH (FORMAT csv, HEADER true)
\echo 'Loading points_ledger...'
\copy points_ledger         FROM 'data/points_ledger.csv'         WITH (FORMAT csv, HEADER true)
\echo 'Loading experiments...'
\copy experiments           FROM 'data/experiments.csv'           WITH (FORMAT csv, HEADER true)
\echo 'Loading experiment_assignment...'
\copy experiment_assignment FROM 'data/experiment_assignment.csv' WITH (FORMAT csv, HEADER true)

-- ---------------------------------------------------------------------
-- 2. Check: row count of every table
-- ---------------------------------------------------------------------
\echo 'Done! Row counts:'
SELECT 'stores'                AS table_name, COUNT(*) AS row_count FROM stores
UNION ALL SELECT 'products',              COUNT(*) FROM products
UNION ALL SELECT 'members',               COUNT(*) FROM members
UNION ALL SELECT 'transactions',          COUNT(*) FROM transactions
UNION ALL SELECT 'transaction_items',     COUNT(*) FROM transaction_items
UNION ALL SELECT 'offers',                COUNT(*) FROM offers
UNION ALL SELECT 'offer_sends',           COUNT(*) FROM offer_sends
UNION ALL SELECT 'points_ledger',         COUNT(*) FROM points_ledger
UNION ALL SELECT 'experiments',           COUNT(*) FROM experiments
UNION ALL SELECT 'experiment_assignment', COUNT(*) FROM experiment_assignment;