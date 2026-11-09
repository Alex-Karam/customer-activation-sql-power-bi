# Validation record and expected controls

[Overview](../README.md) · [SQL](../sql/customer_activation.sql) · [Metric definitions](methodology.md)

These are aggregate controls from the local analysis and report checks completed on **5 November 2026**. They are included for reconciliation, not as freshly generated raw query exports. Documentation packaging on 9 November did not execute SQL or DAX against a live database/model.

## Source audit

| Source table | Rows | First observed date | Last observed date | Missing dates |
|---|---:|---|---|---:|
| student_info | 40,979 | 2021-12-01 | 2022-10-30 | 0 |
| student_engagement | 74,246 | 2021-12-01 | 2022-10-30 | 0 |
| student_purchases | 5,922 | 2021-12-01 | 2023-08-28 | 0 |

Both event tables have zero missing/unmatched student IDs and zero event rows dated before registration. Engagement has zero repeated student/date groups. Purchases have 18 repeated groups and 18 additional rows; these are retained rather than declared errors. Purchase rows through cutoff: **3,937**; later rows: **1,985**; total: **5,922**.

## Grain and paths

| Control | Expected |
|---|---:|
| Final customer rows | 40,979 |
| Distinct customer IDs | 40,979 |
| Funded customers | 20,778 |
| Overall Interest customers | 2,777 |
| Invalid repeat rows | 0 |
| Rows with account/event dates after cutoff | 0 |
| Distinct customer/funding-day rows through cutoff | 74,246 |

| Activation path | Customers |
|---|---:|
| No funding or Interest | 20,002 |
| Funding without Interest | 18,200 |
| Interest on funding date | 1,128 |
| Interest after funding | 927 |
| Interest before funding | 523 |
| Interest without observed funding | 199 |
| **Total** | **40,979** |

## Snapshot and window reconciliation

| Snapshot metric | Denominator | Converted | Rate |
|---|---:|---:|---:|
| Signup to funding | 40,979 | 20,778 | 50.70% |
| Funding to Interest | 20,255 | 2,055 | 10.15% |
| Overall Interest adoption | 40,979 | 2,777 | 6.78% |

| Journey | Window days | Eligible | Converted | Rate |
|---|---:|---:|---:|---:|
| Signup to funding | 1 | 40,840 | 18,225 | 44.63% |
| Signup to funding | 7 | 39,968 | 18,816 | 47.08% |
| Signup to funding | 30 | 36,944 | 17,517 | 47.42% |
| Funding to Interest | 1 | 20,179 | 1,344 | 6.66% |
| Funding to Interest | 7 | 19,626 | 1,718 | 8.75% |
| Funding to Interest | 30 | 17,579 | 1,768 | 10.06% |

## Thirty-day monthly cohorts

Each row is a **signup** cohort. Funding-to-Interest follow-up is anchored at first funding, even though grouping is by signup month.

| Signup month | Eligible signups | Funded | Funding % | Eligible funded | Interest | Interest % |
|---|---:|---:|---:|---:|---:|---:|
| 2021-12 | 3,582 | 1,597 | 44.58% | 1,636 | 139 | 8.50% |
| 2022-01 | 3,370 | 1,758 | 52.17% | 1,749 | 234 | 13.38% |
| 2022-02 | 3,227 | 1,550 | 48.03% | 1,582 | 162 | 10.24% |
| 2022-03 | 3,711 | 1,758 | 47.37% | 1,763 | 205 | 11.63% |
| 2022-04 | 3,292 | 1,474 | 44.78% | 1,513 | 161 | 10.64% |
| 2022-05 | 3,059 | 1,454 | 47.53% | 1,448 | 175 | 12.09% |
| 2022-06 | 4,237 | 1,827 | 43.12% | 1,880 | 154 | 8.19% |
| 2022-07 | 3,386 | 1,598 | 47.19% | 1,589 | 210 | 13.22% |
| 2022-08 | 5,588 | 2,617 | 46.83% | 2,609 | 155 | 5.94% |
| 2022-09 | 3,492 | 1,884 | 53.95% | 1,810 | 173 | 9.56% |
| 2022-10 | 0 | 0 | unavailable | 0 | 0 | unavailable |
| **Total** | **36,944** | **17,517** | **47.42%** | **17,579** | **1,768** | **10.06%** |

## Delay distributions

| Journey | Converters | Mean days | Median days | P90 days | Maximum days | Same-day share |
|---|---:|---:|---:|---:|---:|---:|
| Signup to funding | 20,778 | 3.90 | 0.00 | 3 | 313 | 82.88% |
| Funding to Interest | 2,055 | 8.23 | 0.00 | 18 | 302 | 54.89% |

| Delay band | Signup to funding | Funding to Interest |
|---|---:|---:|
| 0 days | 17,220 | 1,128 |
| 1–7 days | 2,192 | 619 |
| 8–30 days | 664 | 157 |
| 31–90 days | 439 | 99 |
| 91+ days | 263 | 52 |
| **Total** | **20,778** | **2,055** |

| Repeat horizon | Eligible funded | Returned | Repeat rate |
|---|---:|---:|---:|
| 7 days | 20,143 | 5,931 | 29.44% |
| 30 days | 18,066 | 6,261 | 34.66% |

## Interactive checks performed in Power BI

- **September signup cohort:** 3,492 total, 1,908 funded (54.64%), 223 overall Interest (6.39%), 1,875 eligible funded and 180 sequential Interest (9.60%). Page 3 band totals reconcile to 1,908 and 180. Funding bands: 1,656 / 157 / 71 / 24 / 0; Interest bands: 113 / 51 / 15 / 1 / 0.
- **September + Funding without Interest:** total/funded/eligible 1,695; Interest/sequential counts zero; Interest rates 0.00%.
- **September + Interest without observed funding:** total/Interest 10; funded/eligible/sequential zero; adoption 100%; sequential rate blank because its denominator is zero.
- **Page 3 empty converter sample:** filtering to Interest without observed funding (199 customers before cohort filtering) gives zero converter/band/repeat counts and blank undefined statistics/rates.
- **Refresh:** Home → Refresh on the existing local MySQL connection preserved baseline Page 1 controls. All cohort/path selections were restored before the reviewed export.

The PDF cannot demonstrate live interactions; those controls were checked in Desktop before export.

## Output and documentation review

All three PDF pages were rendered and visually inspected. Titles, monthly rows, disclosure/cutoff notes and all ten distribution annotations fit. Numeric controls match the saved analysis; chart annotations use one decimal while statistics tables retain their stated precision. Three included PNGs are rendered copies of the reviewed PDF pages.

The saved PBIX report-definition metadata references 24 distinct measures directly from visuals; all have named definitions in the DAX documentation. The helper tables and two additional supporting measures are also documented. This checks documentation coverage, not equality of transcriptions to every binary-model expression or execution in a newly built report.

Not tested: a complete fresh-machine source restore/driver installation, a fresh execution of the public documentation as a new model, hosted automatic refresh, or financial-product behaviour. The deferred interview walkthrough is not counted as an oral assessment.
