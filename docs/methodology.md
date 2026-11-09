# Methodology and metric definitions

[Repository overview](../README.md) · [SQL](../sql/customer_activation.sql) · [Validation](validation.md)

## Observations and fictional mapping

| Source event | Case-study meaning | Important limit |
|---|---|---|
| Student registration | Account creation | A fictional customer label |
| Lecture activity date | Funding activity date | No deposit amount, balance or transaction type exists |
| Purchase date | Interest activation date | No currency, product eligibility or actual financial feature is recorded |

The exercise assumes universal feature eligibility and complete tracking through **30 October 2022**. Registration and engagement observations end on that date; purchases continue through **28 August 2023**. A later maximum date does not prove continuous tracking or complete coverage. We deliberately use the common cutoff for all core analyses and exclude later purchases from the report.

## One row per customer

SQL Step 14 obtains each customer's minimum funding and Interest dates **separately**, restricting both event streams to the cutoff. These summaries are LEFT JOINed to registrations through the cutoff. Aggregating before joining avoids event-to-event multiplication; LEFT JOIN preserves customers with no funding or Interest events. The final view's grain is one registration/customer.

Step 16 creates six mutually exclusive activation paths. Interest on the funding date is reported separately from later Interest. Interest before funding and Interest without observed funding remain visible instead of being forced into an ordered funnel.

The first Interest date means the first observed Interest event for the customer. A customer whose first Interest precedes funding is excluded from sequential conversion even if another Interest event occurs later. It is not the first Interest event searched for after funding.

## Snapshot measures

All observations below are through the exercise cutoff; follow-up duration varies between customers.

| Measure | Numerator | Denominator |
|---|---|---|
| Funding Conversion % | Customers with first funding | All registrations |
| Interest Adoption % | Customers with first Interest | All registrations |
| Funding to Interest Conversion % | Customers with first Interest on/after first funding | Funded customers whose first Interest is absent or on/after funding |

Sequential eligibility is **20,778 − 523 = 20,255**; the sequential numerator is **1,128 same-date + 927 later = 2,055**. The 199 customers with Interest and no observed funding are included in overall Interest adoption, not in the sequential denominator or numerator. The funnel's **Eligible funded** stage is an eligibility adjustment, not a customer action or behavioural loss.

## Fixed-window conversion

For N in **1, 7, 30**, count conversion on elapsed calendar days **0 through N inclusive**. Day zero is the anchor date; a 1-day horizon includes days 0 and 1.

| Journey | Anchor | Eligible population | Converted population |
|---|---|---|---|
| Signup to funding | Account creation | At least N days from signup to cutoff | Eligible customers with first funding in days 0–N after signup |
| Funding to Interest | First funding | At least N days from first funding to cutoff, excluding earlier first Interest | Eligible customers with first Interest in days 0–N after first funding |

The numerator and denominator both require full follow-up, including for customers who converted early. This compares equally observed customers within each horizon. Different horizons can have different populations: comparing 1/7/30-day rates is not a cumulative conversion curve for one fixed cohort.

## Monthly signup cohorts

Group customers by the month of **account creation**. Both report matrices display a 30-day horizon. The Interest matrix groups by signup month but still anchors its follow-up at **first funding**. Its denominator is not every registered or every funded customer in that month.

October has zero eligible 30-day customers at the cutoff. Counts are zero and rates remain NULL/BLANK, not 0%. Cohort totals divide aggregated converted counts by aggregated eligible counts; they do not average monthly percentages. Descriptive cohort variation cannot identify the cause of a change.

## Waiting times and outliers

Signup-to-funding delays include observed funders. Funding-to-Interest delays include only observed first Interest on/after first funding. Absent events and excluded earlier Interest yield NULL/BLANK delays. Real zero-day observations are retained.

- Mean: sum of observed delays divided by the observed converter count.
- Median: middle observed delay after ordering; average the two middle values for an even sample.
- P90: the observed delay at rank **ceil(0.90 × n)**, ordered from smallest to largest. At least 90% of observed delays are at or below that value. Ties may mean more than 90%; this is not a standard-deviation interval or a normal-distribution assumption.
- Same-day share: observed zero-day conversions divided by observed converters.
- Bands: 0, 1–7, 8–30, 31–90 and 91+ days, inclusive and non-overlapping.

SQL uses ROW_NUMBER and COUNT window functions for the median and nearest-rank P90. DAX filters nonblank delays and uses TOPN/MAXX for the same P90 definition. Extra tied rows at the selected boundary do not change the boundary value. Same-day DAX comparisons use strict `== 0`, avoiding a loose comparison that can treat BLANK as zero.

Long delays are retained. Their presence raises the mean, but does not by itself establish that they are errors. These statistics describe **observed converters**, not every customer's eventual conversion time. Non-converters and incomplete follow-up are not modelled using survival analysis.

## Repeat activity

Step 26 creates distinct customer/funding-date pairs through the cutoff. Step 27 finds the minimum funding date **strictly later** than first funding. Same-date repeats are not separate return days.

For N in **7, 30**, eligible customers have first funding and at least N full days of follow-up from it. The numerator has a first later funding day within **1–N**. All funded Interest paths are eligible, including earlier Interest. This denominator therefore differs from sequential Interest eligibility.

This measures at least one later activity day, not daily retention, retained balances, recurring payment frequency or churn.

## NULL, zero and precision

SQL COUNT(column) excludes NULL and retains zero; COUNT(*) counts rows. Missing delays remain missing. DAX count measures return zero for valid windows with no qualifying rows; DIVIDE leaves rates undefined for zero denominators. Totals across multiple selected windows/journeys are intentionally blank where no unique selection exists.

Display counts as grouped integers, rates and mean/median as two decimals, P90/max as integer days. Only chart annotations use one decimal to fit; the count table preserves exact band counts. Date-only events establish the same calendar date, not ordering within a day.
