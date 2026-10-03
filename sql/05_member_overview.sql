-- Q1: New members per month (2025 onwards)
WITH member_join_month AS (
    SELECT
        member_id,
        CAST(DATE_TRUNC('month', join_date) AS DATE) AS join_month
    FROM members
    WHERE join_date >= DATE '2025-01-01'
)
SELECT
    join_month,
    COUNT(*) AS new_member_count
FROM member_join_month
GROUP BY join_month
ORDER BY join_month ASC;


-- Q2: Monthly active members (at least one purchase in the month)
WITH monthly_transactions AS (
    SELECT
        member_id,
        CAST(DATE_TRUNC('month', transaction_datetime) AS DATE) AS transaction_month
    FROM transactions
)
SELECT
    transaction_month,
    COUNT(DISTINCT member_id) AS active_member_count,
    COUNT(*)                  AS transaction_count
FROM monthly_transactions
GROUP BY transaction_month
ORDER BY transaction_month ASC;


-- Q3: Member status at the end of the data (2026-06-28)
WITH member_last_purchase AS (
    SELECT
        member_id,
        CAST(MAX(transaction_datetime) AS DATE) AS last_purchase_date
    FROM transactions
    GROUP BY member_id
),
member_status AS (
    SELECT
        member_id,
        DATE '2026-06-28' - last_purchase_date AS days_since_last_purchase,
        CASE
            WHEN DATE '2026-06-28' - last_purchase_date <= 28 THEN 'Active'
            WHEN DATE '2026-06-28' - last_purchase_date <= 56 THEN 'At risk'
            ELSE 'Churned'
        END AS member_status
    FROM member_last_purchase
)
SELECT
    member_status,
    COUNT(*) AS member_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM member_status
GROUP BY member_status
ORDER BY member_count DESC;