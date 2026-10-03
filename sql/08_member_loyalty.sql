-- Step A: Shopping behaviour summary for each member (preview)
WITH transaction_summary AS (
    SELECT
        member_id,
        COUNT(*) AS transaction_count,
        ROUND(AVG(subtotal), 2) AS avg_basket_value,
        ROUND(SUM(CASE WHEN channel <> 'In-store' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS online_pct
    FROM transactions
    GROUP BY member_id
),
promo_summary AS (
    SELECT
        t.member_id,
        ROUND(SUM(CASE WHEN i.is_promo = 1 THEN i.quantity ELSE 0 END) * 100.0 / SUM(i.quantity), 1) AS promo_item_pct
    FROM transaction_items AS i
    JOIN transactions AS t
        ON i.transaction_id = t.transaction_id
    GROUP BY t.member_id
),
offer_summary AS (
    SELECT
        member_id,
        COUNT(*) AS offers_received,
        ROUND(SUM(activated) * 100.0 / COUNT(*), 1) AS offer_activation_pct
    FROM offer_sends
    GROUP BY member_id
)
SELECT
    m.member_id,
    m.join_date,
    ts.transaction_count,
    ts.avg_basket_value,
    ts.online_pct,
    ps.promo_item_pct,
    os.offers_received,
    os.offer_activation_pct
FROM members AS m
JOIN transaction_summary AS ts
    ON m.member_id = ts.member_id
JOIN promo_summary AS ps
    ON m.member_id = ps.member_id
LEFT JOIN offer_summary AS os
    ON m.member_id = os.member_id
LIMIT 20;

-- Step B: Shopping behaviour by member status
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
),
transaction_summary AS (
    SELECT
        member_id,
        ROUND(AVG(subtotal), 2) AS avg_basket_value,
        ROUND(SUM(CASE WHEN channel <> 'In-store' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS online_pct
    FROM transactions
    GROUP BY member_id
),
promo_summary AS (
    SELECT
        t.member_id,
        ROUND(SUM(CASE WHEN i.is_promo = 1 THEN i.quantity ELSE 0 END) * 100.0 / SUM(i.quantity), 1) AS promo_item_pct
    FROM transaction_items AS i
    JOIN transactions AS t
        ON i.transaction_id = t.transaction_id
    GROUP BY t.member_id
),
offer_summary AS (
    SELECT
        member_id,
        ROUND(SUM(activated) * 100.0 / COUNT(*), 1) AS offer_activation_pct
    FROM offer_sends
    GROUP BY member_id
)
SELECT
    s.member_status,
    COUNT(*)                               AS member_count,
    ROUND(AVG(ts.avg_basket_value), 2)     AS avg_basket_value,
    ROUND(AVG(ts.online_pct), 1)           AS avg_online_pct,
    ROUND(AVG(ps.promo_item_pct), 1)       AS avg_promo_item_pct,
    ROUND(AVG(os.offer_activation_pct), 1) AS avg_offer_activation_pct
FROM member_status AS s
JOIN transaction_summary AS ts
    ON s.member_id = ts.member_id
JOIN promo_summary AS ps
    ON s.member_id = ps.member_id
LEFT JOIN offer_summary AS os
    ON s.member_id = os.member_id
GROUP BY s.member_status
ORDER BY s.member_status ASC;

-- Step B2: Offer activation rate, counting only offers sent before the member's last purchase
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
        last_purchase_date,
        CASE
            WHEN DATE '2026-06-28' - last_purchase_date <= 28 THEN 'Active'
            WHEN DATE '2026-06-28' - last_purchase_date <= 56 THEN 'At risk'
            ELSE 'Churned'
        END AS member_status
    FROM member_last_purchase
),
offer_summary AS (
    SELECT
        o.member_id,
        COUNT(*) AS offers_received,
        ROUND(SUM(o.activated) * 100.0 / COUNT(*), 1) AS offer_activation_pct
    FROM offer_sends AS o
    JOIN member_status AS s
        ON o.member_id = s.member_id
    WHERE CAST(o.sent_datetime AS DATE) <= s.last_purchase_date
    GROUP BY o.member_id
)
SELECT
    s.member_status,
    COUNT(os.member_id)                    AS members_with_offers,
    ROUND(AVG(os.offer_activation_pct), 1) AS avg_offer_activation_pct
FROM member_status AS s
LEFT JOIN offer_summary AS os
    ON s.member_id = os.member_id
GROUP BY s.member_status
ORDER BY s.member_status ASC;


-- Step C1: RFM values and scores for each member
WITH rfm_values AS (
    SELECT
        member_id,
        DATE '2026-06-28' - CAST(MAX(transaction_datetime) AS DATE) AS recency_days,
        SUM(CASE WHEN transaction_datetime >= DATE '2025-06-29' THEN 1 ELSE 0 END) AS frequency_12m,
        SUM(CASE WHEN transaction_datetime >= DATE '2025-06-29' THEN subtotal ELSE 0 END) AS monetary_12m
    FROM transactions
    GROUP BY member_id
),
rfm_scores AS (
    SELECT
        member_id,
        recency_days,
        frequency_12m,
        monetary_12m,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency_12m ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary_12m ASC)  AS m_score
    FROM rfm_values
)
SELECT *
FROM rfm_scores
ORDER BY member_id
LIMIT 20;


-- Step C2: RFM segments summary
WITH rfm_values AS (
    SELECT
        member_id,
        DATE '2026-06-28' - CAST(MAX(transaction_datetime) AS DATE) AS recency_days,
        SUM(CASE WHEN transaction_datetime >= DATE '2025-06-29' THEN 1 ELSE 0 END) AS frequency_12m,
        SUM(CASE WHEN transaction_datetime >= DATE '2025-06-29' THEN subtotal ELSE 0 END) AS monetary_12m
    FROM transactions
    GROUP BY member_id
),
rfm_scores AS (
    SELECT
        member_id,
        recency_days,
        frequency_12m,
        monetary_12m,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency_12m ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary_12m ASC)  AS m_score
    FROM rfm_values
),
rfm_segments AS (
    SELECT
        *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New or occasional'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
            WHEN r_score <= 2 AND f_score >= 4 THEN 'At risk - high value'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost - low value'
            ELSE 'Needs attention'
        END AS rfm_segment
    FROM rfm_scores
)
SELECT
    rfm_segment,
    COUNT(*) AS member_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS member_pct,
    ROUND(AVG(recency_days), 0)  AS avg_recency_days,
    ROUND(AVG(frequency_12m), 1) AS avg_frequency_12m,
    ROUND(AVG(monetary_12m), 0)  AS avg_monetary_12m,
    ROUND(SUM(monetary_12m) * 100.0 / SUM(SUM(monetary_12m)) OVER (), 1) AS revenue_pct
FROM rfm_segments
GROUP BY rfm_segment
ORDER BY avg_monetary_12m DESC;