# Run Sequence

## Local Execution Order

This document defines the recommended local execution sequence for the project.

## Step 1: Prepare Python Environment

Install project dependencies:

```powershell
py -m pip install -r requirements.txt
```

## Step 2: Download and Place Raw Data

1. Download `Brazilian E-Commerce Public Dataset by Olist` from Kaggle.
2. Extract the archive locally.
3. Keep only the required six CSV files.
4. Move the six CSV files into `data/raw/`.

## Step 3: Validate Raw Data

Run:

```powershell
py src/validate_raw_data.py
```

Expected result:

- All six files exist
- Each file can be read successfully
- Row count, column count, and column names are printed

## Step 4: Initialize MySQL Database

Run:

```sql
sql/00_init_database.sql
```

Expected result:

- Database `ecommerce_gmv_customer_analysis` is created
- Character set is `utf8mb4`

## Step 5: Create Tables

Run:

```sql
sql/01_create_tables.sql
```

Expected result:

- Six source tables are created in MySQL

## Step 6: Import Raw CSV Data

Open [data_loader.py](/Users/25855/Desktop/E-commerce%20data%20analysis/ecommerce-gmv-customer-analysis/src/data_loader.py) and confirm local MySQL connection settings first.

Run:

```powershell
py src/data_loader.py
```

Expected result:

- The six CSV files are imported into MySQL tables

## Step 7: Run Data Cleaning and Build Wide Table

Run:

```sql
sql/02_data_cleaning.sql
```

Expected result:

- Data quality checks are completed
- `order_level_dataset` is created

## Step 8: Run Core Metrics SQL

Run:

```sql
sql/03_core_metrics.sql
```

Expected result:

- Core operating metrics are available
- Monthly trend outputs are available
- User purchase, fulfillment, and category analysis outputs are available

## Step 9: Continue with Further Analysis

Suggested next tasks:

1. Build RFM analysis SQL
2. Export query results to Python or notebooks
3. Create visualizations
4. Summarize key findings in README and docs

## Recommended Full Order

1. `requirements.txt`
2. `docs/data_download_guide.md`
3. `PREP_CHECKLIST.md`
4. `src/validate_raw_data.py`
5. `sql/00_init_database.sql`
6. `sql/01_create_tables.sql`
7. `src/data_loader.py`
8. `sql/02_data_cleaning.sql`
9. `sql/03_core_metrics.sql`
