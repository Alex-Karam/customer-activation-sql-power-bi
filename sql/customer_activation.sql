-- Customer Activation and Feature Adoption | MySQL / Power BI portfolio project
-- Fictional financial-services meanings applied to 365 Data Science student observations.
-- Course data and the PBIX are not distributed with this script.
-- Source tables must already exist in db_course_conversions.
-- Run ordered blocks and inspect controls using docs/reproduce.md and docs/validation.md.
-- Creates/replaces reporting views in customer_activation_case, leaving source rows unchanged.
-- Step 9 is the original all-date course benchmark, not a report KPI.
-- The original SQL statements below are preserved, with only this header and blank-line cleanup.

-- Step 1: Check the connection and source tables.
SELECT
    VERSION() AS mysql_version,
    t.TABLE_SCHEMA AS database_name,
    t.TABLE_NAME AS table_name
FROM information_schema.TABLES AS t
WHERE t.TABLE_SCHEMA = 'db_course_conversions'
  AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_NAME;

###################################################

-- Step 2: Count rows in each source table.
SELECT 'student_info' AS table_name, COUNT(*) AS row_count
FROM db_course_conversions.student_info

UNION ALL

SELECT 'student_engagement', COUNT(*)
FROM db_course_conversions.student_engagement

UNION ALL

SELECT 'student_purchases', COUNT(*)
FROM db_course_conversions.student_purchases;

###################################################

-- Step 3: Inspect column types, NULL settings and keys.
SELECT
    TABLE_NAME AS table_name,
    COLUMN_NAME AS column_name,
    COLUMN_TYPE AS column_type,
    IS_NULLABLE AS allows_null,
    COLUMN_KEY AS column_key
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'db_course_conversions'
  AND TABLE_NAME IN (
      'student_info',
      'student_engagement',
      'student_purchases'
  )
ORDER BY TABLE_NAME, ORDINAL_POSITION;

###################################################

-- Step 4: Check observed date ranges and missing dates.
SELECT
    'student_info' AS table_name,
    MIN(date_registered) AS first_date,
    MAX(date_registered) AS last_date,
    SUM(date_registered IS NULL) AS missing_dates
FROM db_course_conversions.student_info

UNION ALL

SELECT
    'student_engagement',
    MIN(date_watched),
    MAX(date_watched),
    SUM(date_watched IS NULL)
FROM db_course_conversions.student_engagement

UNION ALL

SELECT
    'student_purchases',
    MIN(date_purchased),
    MAX(date_purchased),
    SUM(date_purchased IS NULL)
FROM db_course_conversions.student_purchases;

###################################################

-- Step 5: Check event records against registered students.
SELECT
    'student_engagement' AS table_name,
    SUM(e.student_id IS NULL) AS missing_student_ids,
    SUM(e.student_id IS NOT NULL
        AND i.student_id IS NULL) AS unmatched_student_ids
FROM db_course_conversions.student_engagement AS e
LEFT JOIN db_course_conversions.student_info AS i
    ON e.student_id = i.student_id

UNION ALL

SELECT
    'student_purchases',
    SUM(p.student_id IS NULL),
    SUM(p.student_id IS NOT NULL
        AND i.student_id IS NULL)
FROM db_course_conversions.student_purchases AS p
LEFT JOIN db_course_conversions.student_info AS i
    ON p.student_id = i.student_id;

###################################################

-- Step 6: Find events dated before registration.
SELECT
    'student_engagement' AS table_name,
    SUM(e.date_watched < i.date_registered)
        AS event_rows_before_registration
FROM db_course_conversions.student_engagement AS e
JOIN db_course_conversions.student_info AS i
    ON e.student_id = i.student_id

UNION ALL

SELECT
    'student_purchases',
    SUM(p.date_purchased < i.date_registered)
FROM db_course_conversions.student_purchases AS p
JOIN db_course_conversions.student_info AS i
    ON p.student_id = i.student_id;

###################################################

-- Step 7: Count repeated student/date groups.
SELECT
    'student_engagement' AS table_name,
    COUNT(*) AS repeated_groups,
    COALESCE(SUM(event_count - 1), 0) AS additional_rows
FROM (
    SELECT student_id, date_watched, COUNT(*) AS event_count
    FROM db_course_conversions.student_engagement
    GROUP BY student_id, date_watched
    HAVING COUNT(*) > 1
) AS e

UNION ALL

SELECT
    'student_purchases',
    COUNT(*),
    COALESCE(SUM(event_count - 1), 0)
FROM (
    SELECT student_id, date_purchased, COUNT(*) AS event_count
    FROM db_course_conversions.student_purchases
    GROUP BY student_id, date_purchased
    HAVING COUNT(*) > 1
) AS p;

###################################################

-- Step 8: Count purchase records within and after the cutoff.
SELECT
    COUNT(*) AS total_purchase_rows,
    SUM(date_purchased <= '2022-10-30') AS rows_through_cutoff,
    SUM(date_purchased > '2022-10-30') AS rows_after_cutoff
FROM db_course_conversions.student_purchases;

###################################################

-- Step 9: Reproduce the original course conversion rate.
WITH first_watch AS (
    SELECT student_id, MIN(date_watched) AS first_watch_date
    FROM db_course_conversions.student_engagement
    GROUP BY student_id
),
first_purchase AS (
    SELECT student_id, MIN(date_purchased) AS first_purchase_date
    FROM db_course_conversions.student_purchases
    GROUP BY student_id
)
SELECT
    COUNT(*) AS eligible_students,
    COUNT(p.first_purchase_date) AS purchasers,
    ROUND(
        100.0 * COUNT(p.first_purchase_date) / COUNT(*), 2
    ) AS conversion_rate_pct
FROM first_watch AS w
LEFT JOIN first_purchase AS p
    ON w.student_id = p.student_id
WHERE p.first_purchase_date IS NULL
   OR p.first_purchase_date >= w.first_watch_date;

###################################################

-- Step 10: Create the case-study reporting database.
CREATE DATABASE IF NOT EXISTS customer_activation_case;

###################################################

-- Verify that the database exists.
SELECT SCHEMA_NAME AS database_name
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'customer_activation_case';

###################################################

-- Step 11: Present registrations as customer accounts.
CREATE OR REPLACE VIEW customer_activation_case.v_customers AS
SELECT
    student_id AS customer_id,
    date_registered AS account_created_date
FROM db_course_conversions.student_info;

###################################################

-- Preview 10 customers.
SELECT *
FROM customer_activation_case.v_customers
ORDER BY customer_id
LIMIT 10;

###################################################

-- Step 12: Present engagement records as funding activity.
CREATE OR REPLACE VIEW customer_activation_case.v_funding_activity AS
SELECT
    student_id AS customer_id,
    date_watched AS funding_activity_date
FROM db_course_conversions.student_engagement;

###################################################

-- Preview 10 funding records.
SELECT *
FROM customer_activation_case.v_funding_activity
ORDER BY customer_id, funding_activity_date
LIMIT 10;

###################################################

-- Step 13: Present purchases as Interest-activation events.
CREATE OR REPLACE VIEW customer_activation_case.v_interest_events AS
SELECT
    purchase_id AS interest_event_id,
    student_id AS customer_id,
    date_purchased AS interest_activated_date
FROM db_course_conversions.student_purchases;

###################################################

-- Preview 10 Interest-event records.
SELECT *
FROM customer_activation_case.v_interest_events
ORDER BY customer_id, interest_activated_date, interest_event_id
LIMIT 10;

###################################################

-- Step 14: Build the customer summary at the common cutoff.
CREATE OR REPLACE VIEW customer_activation_case.v_customer_events AS
WITH first_funding AS (
    SELECT
        customer_id,
        MIN(funding_activity_date) AS first_funding_date
    FROM customer_activation_case.v_funding_activity
    WHERE funding_activity_date <= '2022-10-30'
    GROUP BY customer_id
),
first_interest AS (
    SELECT
        customer_id,
        MIN(interest_activated_date) AS first_interest_date
    FROM customer_activation_case.v_interest_events
    WHERE interest_activated_date <= '2022-10-30'
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.account_created_date,
    CAST('2022-10-30' AS DATE) AS analysis_cutoff_date,
    f.first_funding_date,
    i.first_interest_date
FROM customer_activation_case.v_customers AS c
LEFT JOIN first_funding AS f
    ON c.customer_id = f.customer_id
LEFT JOIN first_interest AS i
    ON c.customer_id = i.customer_id
WHERE c.account_created_date <= '2022-10-30';

###################################################

-- Preview 10 customer summaries.
SELECT *
FROM customer_activation_case.v_customer_events
ORDER BY customer_id
LIMIT 10;

###################################################

-- Step 15: Validate the one-row-per-customer summary.
SELECT
    COUNT(*) AS customer_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(first_funding_date) AS funded_customers,
    COUNT(first_interest_date) AS interest_customers
FROM customer_activation_case.v_customer_events;

###################################################

-- Step 16: Classify each customer's observed activation path.
CREATE OR REPLACE VIEW customer_activation_case.v_customer_paths AS
SELECT
    e.*,
    CASE
        WHEN first_funding_date IS NULL
             AND first_interest_date IS NULL
            THEN 'No funding or Interest'
        WHEN first_funding_date IS NULL
            THEN 'Interest without observed funding'
        WHEN first_interest_date IS NULL
            THEN 'Funding without Interest'
        WHEN first_interest_date < first_funding_date
            THEN 'Interest before funding'
        WHEN first_interest_date = first_funding_date
            THEN 'Interest on funding date'
        ELSE 'Interest after funding'
    END AS activation_path
FROM customer_activation_case.v_customer_events AS e;

###################################################

-- Count customers in each activation path.
SELECT
    activation_path,
    COUNT(*) AS customers
FROM customer_activation_case.v_customer_paths
GROUP BY activation_path
ORDER BY customers DESC;

###################################################

-- Step 17: Add cohort month and elapsed calendar days.
CREATE OR REPLACE VIEW customer_activation_case.v_customer_timing AS
SELECT
    p.*,
    CAST(DATE_FORMAT(account_created_date, '%Y-%m-01') AS DATE)
        AS signup_cohort_month,
    DATEDIFF(first_funding_date, account_created_date)
        AS days_to_first_funding,
    CASE
        WHEN first_interest_date >= first_funding_date
            THEN DATEDIFF(first_interest_date, first_funding_date)
        ELSE NULL
    END AS days_funding_to_interest
FROM customer_activation_case.v_customer_paths AS p;

###################################################

-- Preview the timing calculations.
SELECT
    customer_id,
    signup_cohort_month,
    days_to_first_funding,
    days_funding_to_interest,
    activation_path
FROM customer_activation_case.v_customer_timing
ORDER BY customer_id
LIMIT 10;

###################################################

-- Step 18: Add available follow-up time.
CREATE OR REPLACE VIEW customer_activation_case.v_customer_metrics AS
SELECT
    t.*,
    DATEDIFF(analysis_cutoff_date, account_created_date)
        AS signup_followup_days,
    DATEDIFF(analysis_cutoff_date, first_funding_date)
        AS funding_followup_days
FROM customer_activation_case.v_customer_timing AS t;

###################################################

-- Inspect the newest signups.
SELECT
    customer_id,
    account_created_date,
    signup_followup_days,
    funding_followup_days
FROM customer_activation_case.v_customer_metrics
ORDER BY account_created_date DESC, customer_id
LIMIT 10;

###################################################

-- Step 19: Compare signup-to-funding conversion windows.
WITH conversion_windows AS (
    SELECT 1 AS window_days
    UNION ALL SELECT 7
    UNION ALL SELECT 30
),
conversion_counts AS (
    SELECT
        w.window_days,
        SUM(m.signup_followup_days >= w.window_days)
            AS eligible_customers,
        SUM(
            CASE
                WHEN m.signup_followup_days >= w.window_days
                     AND m.days_to_first_funding
                         BETWEEN 0 AND w.window_days
                    THEN 1
                ELSE 0
            END
        ) AS converted_customers
    FROM customer_activation_case.v_customer_metrics AS m
    CROSS JOIN conversion_windows AS w
    GROUP BY w.window_days
)
SELECT
    window_days,
    eligible_customers,
    converted_customers,
    ROUND(
        100.0 * converted_customers
        / NULLIF(eligible_customers, 0), 2
    ) AS conversion_rate_pct
FROM conversion_counts
ORDER BY window_days;

###################################################

-- Step 20: Compare funding-to-Interest conversion windows.
WITH conversion_windows AS (
    SELECT 1 AS window_days
    UNION ALL SELECT 7
    UNION ALL SELECT 30
),
conversion_counts AS (
    SELECT
        w.window_days,
        SUM(m.funding_followup_days >= w.window_days)
            AS eligible_customers,
        SUM(
            CASE
                WHEN m.funding_followup_days >= w.window_days
                     AND m.days_funding_to_interest
                         BETWEEN 0 AND w.window_days
                    THEN 1
                ELSE 0
            END
        ) AS converted_customers
    FROM customer_activation_case.v_customer_metrics AS m
    CROSS JOIN conversion_windows AS w
    WHERE m.first_funding_date IS NOT NULL
      AND (
          m.first_interest_date IS NULL
          OR m.first_interest_date >= m.first_funding_date
      )
    GROUP BY w.window_days
)
SELECT
    window_days,
    eligible_customers,
    converted_customers,
    ROUND(
        100.0 * converted_customers
        / NULLIF(eligible_customers, 0), 2
    ) AS conversion_rate_pct
FROM conversion_counts
ORDER BY window_days;

###################################################

-- Step 21: Compare signup cohorts at the same 30-day horizon.
WITH cohort_counts AS (
    SELECT
        signup_cohort_month,
        COUNT(*) AS cohort_customers,
        SUM(signup_followup_days >= 30) AS eligible_customers,
        SUM(
            CASE
                WHEN signup_followup_days >= 30
                     AND days_to_first_funding BETWEEN 0 AND 30
                    THEN 1
                ELSE 0
            END
        ) AS funded_within_30d
    FROM customer_activation_case.v_customer_metrics
    GROUP BY signup_cohort_month
)
SELECT
    signup_cohort_month,
    cohort_customers,
    eligible_customers,
    funded_within_30d,
    ROUND(
        100.0 * funded_within_30d
        / NULLIF(eligible_customers, 0), 2
    ) AS funding_conversion_30d_pct
FROM cohort_counts
ORDER BY signup_cohort_month;

###################################################

-- Step 22: Compare funding-to-Interest conversion by signup cohort.
WITH cohort_counts AS (
    SELECT
        signup_cohort_month,
        COUNT(*) AS cohort_customers,
        SUM(
            CASE
                WHEN funding_followup_days >= 30
                     AND (
                         first_interest_date IS NULL
                         OR first_interest_date >= first_funding_date
                     )
                    THEN 1
                ELSE 0
            END
        ) AS eligible_customers,
        SUM(
            CASE
                WHEN funding_followup_days >= 30
                     AND days_funding_to_interest BETWEEN 0 AND 30
                    THEN 1
                ELSE 0
            END
        ) AS interest_within_30d
    FROM customer_activation_case.v_customer_metrics
    GROUP BY signup_cohort_month
)
SELECT
    signup_cohort_month,
    cohort_customers,
    eligible_customers,
    interest_within_30d,
    ROUND(
        100.0 * interest_within_30d
        / NULLIF(eligible_customers, 0), 2
    ) AS interest_conversion_30d_pct
FROM cohort_counts
ORDER BY signup_cohort_month;

###################################################

-- Step 23: Summarise waiting times among funded customers.
WITH ranked_delays AS (
    SELECT
        days_to_first_funding AS delay_days,
        ROW_NUMBER() OVER (
            ORDER BY days_to_first_funding, customer_id
        ) AS delay_rank,
        COUNT(*) OVER () AS sample_size
    FROM customer_activation_case.v_customer_metrics
    WHERE days_to_first_funding IS NOT NULL
)
SELECT
    COUNT(*) AS funded_customers,
    ROUND(AVG(delay_days), 2) AS mean_days,
    ROUND(AVG(
        CASE
            WHEN delay_rank IN (
                FLOOR((sample_size + 1) / 2),
                FLOOR((sample_size + 2) / 2)
            )
            THEN delay_days
        END
    ), 2) AS median_days,
    MAX(
        CASE WHEN delay_rank = CEIL(0.90 * sample_size)
             THEN delay_days END
    ) AS p90_days,
    MAX(delay_days) AS maximum_days,
    ROUND(
        100.0 * SUM(delay_days = 0) / COUNT(*), 2
    ) AS same_day_pct
FROM ranked_delays;

###################################################

-- Step 24: Summarise observed funding-to-Interest waiting times.
WITH ranked_delays AS (
    SELECT
        days_funding_to_interest AS delay_days,
        ROW_NUMBER() OVER (
            ORDER BY days_funding_to_interest, customer_id
        ) AS delay_rank,
        COUNT(*) OVER () AS sample_size
    FROM customer_activation_case.v_customer_metrics
    WHERE days_funding_to_interest IS NOT NULL
)
SELECT
    COUNT(*) AS activated_customers,
    ROUND(AVG(delay_days), 2) AS mean_days,
    ROUND(AVG(
        CASE
            WHEN delay_rank IN (
                FLOOR((sample_size + 1) / 2),
                FLOOR((sample_size + 2) / 2)
            )
            THEN delay_days
        END
    ), 2) AS median_days,
    MAX(
        CASE WHEN delay_rank = CEIL(0.90 * sample_size)
             THEN delay_days END
    ) AS p90_days,
    MAX(delay_days) AS maximum_days,
    ROUND(
        100.0 * SUM(delay_days = 0) / COUNT(*), 2
    ) AS same_day_pct
FROM ranked_delays;

###################################################

-- Step 25: Inspect the waiting-time distributions.
WITH delays AS (
    SELECT
        'Signup to funding' AS metric,
        days_to_first_funding AS delay_days
    FROM customer_activation_case.v_customer_metrics
    WHERE days_to_first_funding IS NOT NULL

    UNION ALL

    SELECT
        'Funding to Interest',
        days_funding_to_interest
    FROM customer_activation_case.v_customer_metrics
    WHERE days_funding_to_interest IS NOT NULL
),
delay_bands AS (
    SELECT
        metric,
        delay_days,
        CASE
            WHEN delay_days = 0 THEN '0 days'
            WHEN delay_days <= 7 THEN '1-7 days'
            WHEN delay_days <= 30 THEN '8-30 days'
            WHEN delay_days <= 90 THEN '31-90 days'
            ELSE '91+ days'
        END AS delay_band
    FROM delays
)
SELECT
    metric,
    delay_band,
    COUNT(*) AS customers,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (PARTITION BY metric), 2
    ) AS share_pct
FROM delay_bands
GROUP BY metric, delay_band
ORDER BY metric, MIN(delay_days);

###################################################

-- Step 26: Create distinct funding days through the cutoff.
CREATE OR REPLACE VIEW customer_activation_case.v_funding_days AS
SELECT DISTINCT
    customer_id,
    funding_activity_date AS funding_date
FROM customer_activation_case.v_funding_activity
WHERE funding_activity_date <= '2022-10-30';

###################################################

-- Verify activity-day and customer counts.
SELECT
    COUNT(*) AS funding_day_rows,
    COUNT(DISTINCT customer_id) AS funded_customers
FROM customer_activation_case.v_funding_days;

###################################################

-- Step 27: Add the first later funding date and its delay.
CREATE OR REPLACE VIEW customer_activation_case.v_customer_repeat_metrics AS
WITH first_repeat AS (
    SELECT
        m.customer_id,
        MIN(d.funding_date) AS first_repeat_funding_date
    FROM customer_activation_case.v_customer_metrics AS m
    JOIN customer_activation_case.v_funding_days AS d
        ON m.customer_id = d.customer_id
       AND d.funding_date > m.first_funding_date
    GROUP BY m.customer_id
)
SELECT
    m.*,
    r.first_repeat_funding_date,
    DATEDIFF(r.first_repeat_funding_date, m.first_funding_date)
        AS days_to_repeat_funding
FROM customer_activation_case.v_customer_metrics AS m
LEFT JOIN first_repeat AS r
    ON m.customer_id = r.customer_id;

###################################################

-- Preview repeat activity among funded customers.
SELECT
    customer_id,
    first_funding_date,
    first_repeat_funding_date,
    days_to_repeat_funding
FROM customer_activation_case.v_customer_repeat_metrics
WHERE first_funding_date IS NOT NULL
ORDER BY customer_id
LIMIT 10;

###################################################

-- Step 28: Measure repeat funding on a later day.
WITH repeat_windows AS (
    SELECT 7 AS window_days
    UNION ALL SELECT 30
),
repeat_counts AS (
    SELECT
        w.window_days,
        SUM(m.funding_followup_days >= w.window_days)
            AS eligible_customers,
        SUM(
            CASE
                WHEN m.funding_followup_days >= w.window_days
                     AND m.days_to_repeat_funding
                         BETWEEN 1 AND w.window_days
                    THEN 1
                ELSE 0
            END
        ) AS returning_customers
    FROM customer_activation_case.v_customer_repeat_metrics AS m
    CROSS JOIN repeat_windows AS w
    WHERE m.first_funding_date IS NOT NULL
    GROUP BY w.window_days
)
SELECT
    window_days,
    eligible_customers,
    returning_customers,
    ROUND(
        100.0 * returning_customers
        / NULLIF(eligible_customers, 0), 2
    ) AS repeat_funding_rate_pct
FROM repeat_counts
ORDER BY window_days;

###################################################

-- Step 29: Calculate snapshot conversion rates.
WITH customer_counts AS (
    SELECT
        COUNT(*) AS registered_customers,
        COUNT(first_funding_date) AS funded_customers,
        COUNT(first_interest_date) AS interest_customers,
        COUNT(days_funding_to_interest) AS sequential_activations,
        COALESCE(SUM(
            first_interest_date < first_funding_date
        ), 0) AS earlier_interest_customers
    FROM customer_activation_case.v_customer_metrics
),
funnel_metrics AS (
    SELECT
        'Signup to funding' AS metric,
        registered_customers AS denominator_customers,
        funded_customers AS converted_customers
    FROM customer_counts

    UNION ALL

    SELECT
        'Funding to Interest',
        funded_customers - earlier_interest_customers,
        sequential_activations
    FROM customer_counts

    UNION ALL

    SELECT
        'Overall Interest adoption',
        registered_customers,
        interest_customers
    FROM customer_counts
)
SELECT
    metric,
    denominator_customers,
    converted_customers,
    ROUND(
        100.0 * converted_customers
        / NULLIF(denominator_customers, 0), 2
    ) AS rate_pct
FROM funnel_metrics;

###################################################

-- Step 30: Check customer uniqueness, repeat dates and cutoff.
SELECT
    COUNT(*) AS customer_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(
        CASE
            WHEN first_repeat_funding_date IS NOT NULL
                 AND (
                     first_funding_date IS NULL
                     OR first_repeat_funding_date <= first_funding_date
                 )
                THEN 1
            ELSE 0
        END
    ) AS invalid_repeat_rows,
    SUM(
        CASE
            WHEN account_created_date > analysis_cutoff_date
                 OR first_funding_date > analysis_cutoff_date
                 OR first_interest_date > analysis_cutoff_date
                 OR first_repeat_funding_date > analysis_cutoff_date
                THEN 1
            ELSE 0
        END
    ) AS rows_after_cutoff
FROM customer_activation_case.v_customer_repeat_metrics;

###################################################
