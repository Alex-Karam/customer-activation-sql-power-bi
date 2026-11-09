# SQL review guide

[Overview](../README.md) · [Complete script](../sql/customer_activation.sql) · [Expected controls](validation.md)

The public script preserves the original ordered 30-step workflow. Its SQL statements are unchanged; a public context header has been added and unused trailing blank lines removed. The source database must already exist. It reads source tables, creates a reporting database if absent, and creates/replaces views in that reporting database. It does not update, delete or insert source observations.

| Steps | Purpose | What to review |
|---|---|---|
| 1–3 | Source table/version/schema inspection | Types, keys and nullability |
| 4–8 | Source quality and coverage | Missing dates/IDs, unmatched IDs, pre-signup events, repeated groups and purchase cutoff |
| 9 | Original course benchmark, all available dates | Separate historical reference, not a report KPI |
| 10–13 | Reporting schema and fictional aliases | Business labels retain the actual source provenance |
| 14–15 | First events through cutoff and customer summary | Separate MIN aggregations, LEFT JOINs and customer uniqueness |
| 16–18 | Paths, cohorts, delays and available follow-up | Earlier Interest remains visible; absent/excluded delays stay NULL |
| 19–20 | 1/7/30-day conversion | CROSS JOIN to windows; the same eligibility restriction for numerator and denominator |
| 21–22 | Monthly 30-day cohorts | Signup grouping with different conversion anchors; zero eligible yields NULL rate |
| 23–24 | Delay mean, median, P90, max and same-day share | ROW_NUMBER / COUNT OVER; nearest-rank P90; observed converters only |
| 25 | Delay-band counts and shares | Non-overlapping bands and per-journey denominators |
| 26–28 | Distinct activity days and repeat windows | Strictly later date; days 1–N; all funded paths included |
| 29 | Snapshot rates | COUNT(column) retains zero and excludes NULL; distinguish the three denominators |
| 30 | Final controls | One row/customer, valid repeat dates, no event dates after cutoff |

## Five useful inspection points

**Step 14:** explains why several event tables do not multiply customers. Each event stream is first grouped to one minimum date per customer, then joined to registrations. Customers without events survive the LEFT JOIN.

**Step 19:** a full-window denominator includes only customers observed for at least N days from signup. Even an early converter is excluded if that customer's full window is immature.

**Step 23:** both central order statistics are selected for an even sample; averaging them gives the median. P90 selects rank ceil(0.90 × n). No normality assumption is needed.

**Step 28:** repeat activity uses the first funding date as its anchor, a strictly later activity date and complete follow-up. It does not reuse the sequential Interest denominator.

**Step 30:** the grain and date rules are checked explicitly, rather than assuming that a successful query execution establishes correctness.

## Original course benchmark

Step 9 gives **20,255 eligible engaged students, 2,286 purchasers and 11.29%** using all available purchase dates. It reproduces the earlier course exercise, excluding first purchases before first engagement. It is not the 30 October financial-services snapshot or either fixed-window KPI. Main report analyses start from all registrations and use the common cutoff.

Preview SELECTs may return individual records when executed against a local source. No preview outputs or individual records are bundled here.
