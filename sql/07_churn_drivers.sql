-- Step A: Churn rate by state
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
        CASE
            WHEN DATE '2026-06-28' - last_purchase_date <= 28 THEN 'Active'
            WHEN DATE '2026-06-28' - last_purchase_date <= 56 THEN 'At risk'
            ELSE 'Churned'
        END AS member_status
    FROM member_last_purchase
)
SELECT
    m.state,
    COUNT(*) AS member_count,
    SUM(CASE WHEN s.member_status = 'Churned' THEN 1 ELSE 0 END) AS churned_count,
    ROUND(SUM(CASE WHEN s.member_status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_pct
FROM member_status AS s
JOIN members AS m
    ON s.member_id = m.member_id
GROUP BY m.state
ORDER BY churn_pct DESC;

-- Step B: Churn rate by home store
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
        CASE
            WHEN DATE '2026-06-28' - last_purchase_date <= 28 THEN 'Active'
            WHEN DATE '2026-06-28' - last_purchase_date <= 56 THEN 'At risk'
            ELSE 'Churned'
        END AS member_status
    FROM member_last_purchase
)
SELECT
    st.store_id,
    st.store_name,
    st.state,
    COUNT(*) AS member_count,
    SUM(CASE WHEN s.member_status = 'Churned' THEN 1 ELSE 0 END) AS churned_count,
    ROUND(SUM(CASE WHEN s.member_status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_pct
FROM member_status AS s
JOIN members AS m
    ON s.member_id = m.member_id
JOIN stores AS st
    ON m.home_store_id = st.store_id
GROUP BY st.store_id, st.store_name, st.state
ORDER BY churn_pct DESC;

-- Step C: Monthly churn rate - Brisbane North stores vs all other stores
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
member_group AS (
    SELECT
        member_id,
        CASE
            WHEN home_store_id IN ('S020', 'S021', 'S022') THEN 'Brisbane North (3 stores)'
            ELSE 'All other stores'
        END AS store_group
    FROM members
),
monthly_churn AS (
    SELECT
        g.store_group,
        CAST(DATE_TRUNC('month', c.churn_date) AS DATE) AS month,
        COUNT(*) AS churned_member_count
    FROM churn_events AS c
    JOIN member_group AS g
        ON c.member_id = g.member_id
    GROUP BY g.store_group, CAST(DATE_TRUNC('month', c.churn_date) AS DATE)
),
monthly_active AS (
    SELECT
        g.store_group,
        CAST(DATE_TRUNC('month', t.transaction_datetime) AS DATE) AS month,
        COUNT(DISTINCT t.member_id) AS active_member_count
    FROM transactions AS t
    JOIN member_group AS g
        ON t.member_id = g.member_id
    GROUP BY g.store_group, CAST(DATE_TRUNC('month', t.transaction_datetime) AS DATE)
),
combined AS (
    SELECT
        a.store_group,
        a.month,
        LAG(a.active_member_count) OVER (PARTITION BY a.store_group ORDER BY a.month ASC) AS previous_month_active_count,
        c.churned_member_count
    FROM monthly_active AS a
    LEFT JOIN monthly_churn AS c
        ON a.store_group = c.store_group
       AND a.month = c.month
)
SELECT
    store_group,
    month,
    previous_month_active_count,
    churned_member_count,
    ROUND(churned_member_count * 100.0 / previous_month_active_count, 2) AS churn_rate_pct
FROM combined
WHERE month >= DATE '2025-04-01'
ORDER BY store_group, month ASC;


-- Step D1: Churn rate by marketing opt-in
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
        CASE
            WHEN DATE '2026-06-28' - last_purchase_date <= 28 THEN 'Active'
            WHEN DATE '2026-06-28' - last_purchase_date <= 56 THEN 'At risk'
            ELSE 'Churned'
        END AS member_status
    FROM member_last_purchase
)
SELECT
    m.marketing_opt_in,
    COUNT(*) AS member_count,
    SUM(CASE WHEN s.member_status = 'Churned' THEN 1 ELSE 0 END) AS churned_count,
    ROUND(SUM(CASE WHEN s.member_status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_pct
FROM member_status AS s
JOIN members AS m
    ON s.member_id = m.member_id
GROUP BY m.marketing_opt_in
ORDER BY churn_pct DESC;


-- Step D2: Churn rate by app usage
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
        CASE
            WHEN DATE '2026-06-28' - last_purchase_date <= 28 THEN 'Active'
            WHEN DATE '2026-06-28' - last_purchase_date <= 56 THEN 'At risk'
            ELSE 'Churned'
        END AS member_status
    FROM member_last_purchase
)
SELECT
    m.app_user,
    COUNT(*) AS member_count,
    SUM(CASE WHEN s.member_status = 'Churned' THEN 1 ELSE 0 END) AS churned_count,
    ROUND(SUM(CASE WHEN s.member_status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_pct
FROM member_status AS s
JOIN members AS m
    ON s.member_id = m.member_id
GROUP BY m.app_user
ORDER BY churn_pct DESC;


-- Step D3: Churn rate by age band
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
        CASE
            WHEN DATE '2026-06-28' - last_purchase_date <= 28 THEN 'Active'
            WHEN DATE '2026-06-28' - last_purchase_date <= 56 THEN 'At risk'
            ELSE 'Churned'
        END AS member_status
    FROM member_last_purchase
)
SELECT
    m.age_band,
    COUNT(*) AS member_count,
    SUM(CASE WHEN s.member_status = 'Churned' THEN 1 ELSE 0 END) AS churned_count,
    ROUND(SUM(CASE WHEN s.member_status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_pct
FROM member_status AS s
JOIN members AS m
    ON s.member_id = m.member_id
GROUP BY m.age_band
ORDER BY m.age_band ASC;



-- Step D4: Churn rate by redemption preference
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
        CASE
            WHEN DATE '2026-06-28' - last_purchase_date <= 28 THEN 'Active'
            WHEN DATE '2026-06-28' - last_purchase_date <= 56 THEN 'At risk'
            ELSE 'Churned'
        END AS member_status
    FROM member_last_purchase
)
SELECT
    m.redemption_preference,
    COUNT(*) AS member_count,
    SUM(CASE WHEN s.member_status = 'Churned' THEN 1 ELSE 0 END) AS churned_count,
    ROUND(SUM(CASE WHEN s.member_status = 'Churned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS churn_pct
FROM member_status AS s
JOIN members AS m
    ON s.member_id = m.member_id
GROUP BY m.redemption_preference
ORDER BY churn_pct DESC;