# Reproduction guide

[Overview](../README.md) · [SQL step guide](sql-guide.md) · [Model configuration](power-bi-model.md) · [Validation](validation.md)

## Availability and prerequisites

This release provides reviewable SQL/DAX and aggregate report outputs. **It is not a self-contained data release.** The course data and PBIX are excluded because source-data redistribution permission has not been established. Obtain authorised access to the 365 Data Science exercise source separately.

The project ran on **MySQL 8.0.46**, using MySQL Workbench, and Power BI Desktop with the MySQL Import connector. The script needs MySQL 8.0 features including CTEs and window functions. Version numbers describe the project environment, not a requirement to install that exact patch. Driver installation and a complete fresh-machine restore were not tested.

Required source database: `db_course_conversions`, with the three tables and fields in the [data dictionary](data-dictionary.md). The source used for the report contained 40,979 / 74,246 / 5,922 rows respectively. Its preserved dump has SHA-256:

```text
e0f482298f19c07f3aa53091c50660d6469965eb210bff4a7ce2da3a009ed529
```

That fingerprint identifies the original exercise input; it is not a download link. The original course dump may contain database-drop/recreation statements: inspect it before any local restoration, and use a separate development environment. The analytical script distributed here does not include that dump.

## 1. Run the SQL workflow

1. Confirm the source schema exists and use an account with SELECT access to the source, plus permission to create the reporting schema/views.
2. Open [sql/customer_activation.sql](../sql/customer_activation.sql) in MySQL Workbench. Run its ordered blocks from Step 1 onward, reviewing result grids. Statements are separated by the existing hash comment line.
3. Steps 10–27 create/recreate views in `customer_activation_case`. Re-running replaces views with the same names; choose an isolated reporting schema if those names already serve another purpose. Source observations are not modified.
4. Compare the quality, conversion, delay and repeat outputs with [validation.md](validation.md). Step 9 is the original all-date course reference, not the report KPI.
5. Confirm Step 30 gives 40,979 rows, 40,979 distinct IDs, zero invalid repeat rows and zero rows beyond the cutoff.

The final import view is `customer_activation_case.v_customer_repeat_metrics`. The cutoff is explicitly fixed to **2022-10-30** in the reporting SQL. Refreshing data does not move that date automatically.

## 2. Build the Power BI model

1. In Power BI Desktop, choose the MySQL database connector, your own server and database `customer_activation_case`, and **Import**. The tested local server was `localhost`; the username/password option in that UI was called **Basic**. Use your own credentials; none are included here.
2. Select only `v_customer_repeat_metrics`. Rename the Power Query query **Customers**. Apply the 13 field types in the dictionary. Preserve null dates and delays, then load the data.
3. Create the five calculated tables from [MODEL_MEASURES.dax](../power-bi/MODEL_MEASURES.dax), one definition at a time. Configure the active, single calendar relationship and sort settings in [power-bi-model.md](power-bi-model.md).
4. Create the eight snapshot measures, then Funnel Customers, then the delay measures, then the band measures, then the three repeat measures. Respect the home-table notes. Create the six conversion-window measures from [WINDOW_MEASURES.dax](../power-bi/WINDOW_MEASURES.dax). These files are individual definitions, not one DAX query to execute as a batch.
5. Build the three pages using the documented fields and visual-level filters. Import the supplied theme if using the same presentation style. Only the monthly cohort matrices should be restricted to the 30-day window; summaries retain 1/7/30.
6. Run the baseline, September and empty-sample checks in [validation.md](validation.md). Restore all cohort/path selections before saving and exporting.

The saved working model contains 24 distinct measures directly referenced by visuals. All have named documentation here, with two additional supporting measures. The documentation is transcribed from the project workflow; re-entering it into a fresh model was not independently executed as part of this release.

## 3. Refresh and export

With MySQL running and the reporting views available, Home → Refresh reloads the import through Power Query and updates dependent calculations/visuals. It does not change the source tables. Update private connection credentials through the application's data-source settings as needed.

The original workflow demonstrated refresh on the existing local setup. It does not establish automatic refresh in the Power BI service or a fresh-machine driver setup. Export the three report pages to PDF after restoring All selections, and inspect every page for clipping, missing labels and correct totals.

The included PDF/images are the previously reviewed output. Reviewing this repository or building a model diagram does not itself rerun SQL, execute DAX or test interactive behaviour.
