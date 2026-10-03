SELECT 
    member_id,
    COUNT(*) AS transaction_count,
    CAST(MIN(transaction_datetime) AS DATE) AS first_purchase_date,
    CAST(MAX(transaction_datetime) AS DATE) AS last_purchase_date,
    ROUND((CAST(MAX(transaction_datetime) AS DATE) - CAST(MIN(transaction_datetime) AS DATE)) / (COUNT(*) - 1.0), 2) AS avg_days_between_purchases

FROM transactions
GROUP BY member_id
HAVING COUNT(*) > 1
LIMIT 20;


-- Step 2: Distribution of average days between purchases (all members)
WITH member_gaps AS (
    SELECT
        member_id,
        (CAST(MAX(transaction_datetime) AS DATE) - CAST(MIN(transaction_datetime) AS DATE))
            / (COUNT(*) - 1.0) AS avg_days_between_purchases
    FROM transactions
    GROUP BY member_id
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS member_count,
    ROUND(CAST(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY avg_days_between_purchases) AS NUMERIC), 1) AS p50_days,
    ROUND(CAST(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_days_between_purchases) AS NUMERIC), 1) AS p75_days,
    ROUND(CAST(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY avg_days_between_purchases) AS NUMERIC), 1) AS p90_days
FROM member_gaps;


-- what is churn?? Definition??
-- Step A: Each purchase and the next purchase date (one member)
SELECT
    member_id,
    CAST(transaction_datetime AS DATE) AS purchase_date,
    LEAD(CAST(transaction_datetime AS DATE))
        OVER (PARTITION BY member_id ORDER BY transaction_datetime ASC) AS next_purchase_date
FROM transactions
WHERE member_id = 'M00005'
ORDER BY transaction_datetime ASC;


-- Step B: Days away and whether the member came back (one member)
WITH purchases AS (
    SELECT
        member_id,
        CAST(transaction_datetime AS DATE) AS purchase_date,
        LEAD(CAST(transaction_datetime AS DATE))
            OVER (PARTITION BY member_id ORDER BY transaction_datetime ASC) AS next_purchase_date
    FROM transactions
)
SELECT
    member_id,
    purchase_date,
    next_purchase_date,
    CASE
        WHEN next_purchase_date IS NULL THEN DATE '2026-06-28' - purchase_date
        ELSE next_purchase_date - purchase_date
    END AS days_away,
    CASE
        WHEN next_purchase_date IS NULL THEN 0
        ELSE 1
    END AS came_back
FROM purchases
WHERE member_id = 'M00005'
ORDER BY purchase_date ASC;

-- Step C: Return rate by length of absence (all members)
WITH purchases AS (
    SELECT
        member_id,
        CAST(transaction_datetime AS DATE) AS purchase_date,
        LEAD(CAST(transaction_datetime AS DATE))
            OVER (PARTITION BY member_id ORDER BY transaction_datetime ASC) AS next_purchase_date
    FROM transactions
),
absences AS (
    SELECT
        member_id,
        CASE
            WHEN next_purchase_date IS NULL THEN DATE '2026-06-28' - purchase_date
            ELSE next_purchase_date - purchase_date
        END AS days_away,
        CASE
            WHEN next_purchase_date IS NULL THEN 0
            ELSE 1
        END AS came_back
    FROM purchases
)
SELECT 14 AS threshold_days, COUNT(*) AS absence_count, SUM(came_back) AS returned_count,
       ROUND(SUM(came_back) * 100.0 / COUNT(*), 1) AS return_rate_pct
FROM absences WHERE days_away >= 14
UNION ALL
SELECT 28, COUNT(*), SUM(came_back), ROUND(SUM(came_back) * 100.0 / COUNT(*), 1)
FROM absences WHERE days_away >= 28
UNION ALL
SELECT 42, COUNT(*), SUM(came_back), ROUND(SUM(came_back) * 100.0 / COUNT(*), 1)
FROM absences WHERE days_away >= 42
UNION ALL
SELECT 56, COUNT(*), SUM(came_back), ROUND(SUM(came_back) * 100.0 / COUNT(*), 1)
FROM absences WHERE days_away >= 56
UNION ALL
SELECT 84, COUNT(*), SUM(came_back), ROUND(SUM(came_back) * 100.0 / COUNT(*), 1)
FROM absences WHERE days_away >= 84
ORDER BY threshold_days ASC;