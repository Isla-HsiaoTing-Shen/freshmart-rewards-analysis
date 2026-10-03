-- Step A: Number of members who became churned each month
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
        purchase_date,
        CASE
            WHEN next_purchase_date IS NULL THEN DATE '2026-06-28' - purchase_date
            ELSE next_purchase_date - purchase_date
        END AS days_away
    FROM purchases
),
churn_events AS (
    SELECT
        member_id,
        purchase_date + 56 AS churn_date
    FROM absences
    WHERE days_away >= 56
)
SELECT
    CAST(DATE_TRUNC('month', churn_date) AS DATE) AS churn_month,
    COUNT(*) AS churned_member_count
FROM churn_events
GROUP BY CAST(DATE_TRUNC('month', churn_date) AS DATE)
ORDER BY churn_month ASC;

-- Step B: Monthly churn rate
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
        purchase_date,
        CASE
            WHEN next_purchase_date IS NULL THEN DATE '2026-06-28' - purchase_date
            ELSE next_purchase_date - purchase_date
        END AS days_away
    FROM purchases
),
churn_events AS (
    SELECT
        member_id,
        purchase_date + 56 AS churn_date
    FROM absences
    WHERE days_away >= 56
),
monthly_churn AS (
    SELECT
        CAST(DATE_TRUNC('month', churn_date) AS DATE) AS month,
        COUNT(*) AS churned_member_count
    FROM churn_events
    GROUP BY CAST(DATE_TRUNC('month', churn_date) AS DATE)
),
monthly_active AS (
    SELECT
        CAST(DATE_TRUNC('month', transaction_datetime) AS DATE) AS month,
        COUNT(DISTINCT member_id) AS active_member_count
    FROM transactions
    GROUP BY CAST(DATE_TRUNC('month', transaction_datetime) AS DATE)
),
combined AS (
    SELECT
        a.month,
        LAG(a.active_member_count) OVER (ORDER BY a.month ASC) AS previous_month_active_count,
        c.churned_member_count
    FROM monthly_active AS a
    LEFT JOIN monthly_churn AS c
        ON a.month = c.month
)
SELECT
    month,
    previous_month_active_count,
    churned_member_count,
    ROUND(churned_member_count * 100.0 / previous_month_active_count, 2) AS churn_rate_pct
FROM combined
WHERE month >= DATE '2025-04-01'
ORDER BY month ASC;