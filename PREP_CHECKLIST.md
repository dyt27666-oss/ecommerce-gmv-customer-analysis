# Project Preparation Checklist

## Environment Setup

- [ ] Windows 11 is available and running normally
- [ ] Anaconda or Miniconda is installed
- [ ] Python environment is created for this project
- [ ] MySQL 8.x is installed and accessible locally
- [ ] VSCode or PyCharm is ready for project development
- [ ] Required Python packages are installed

Recommended command:

```powershell
py -m pip install -r requirements.txt
```

## Project Folder Setup

- [ ] Project folder `ecommerce-gmv-customer-analysis` exists locally
- [ ] `data/raw` folder exists
- [ ] `data/processed` folder exists
- [ ] `sql` folder exists
- [ ] `notebooks` folder exists
- [ ] `src` folder exists
- [ ] `dashboards` folder exists
- [ ] `docs` folder exists

## Dataset Download

- [ ] Download dataset: `Brazilian E-Commerce Public Dataset by Olist`
- [ ] Source: Kaggle
- [ ] Extract all files locally
- [ ] Keep only the required six CSV files for this project

Required files:

- [ ] `olist_orders_dataset.csv`
- [ ] `olist_order_items_dataset.csv`
- [ ] `olist_customers_dataset.csv`
- [ ] `olist_products_dataset.csv`
- [ ] `olist_order_reviews_dataset.csv`
- [ ] `olist_order_payments_dataset.csv`

## Raw Data Validation

- [ ] Place the six CSV files into `data/raw/`
- [ ] Run raw data validation script
- [ ] Confirm file existence
- [ ] Confirm row count and column count are readable
- [ ] Confirm file names match the project mapping

Recommended command:

```powershell
py src/validate_raw_data.py
```

## MySQL Database Preparation

- [ ] MySQL service is running
- [ ] Database connection information is confirmed
- [ ] Target database is created
- [ ] Database character set is `utf8mb4`
- [ ] Initialization SQL is executed
- [ ] Table creation SQL is executed before data import

Recommended execution order:

1. `sql/00_init_database.sql`
2. `sql/01_create_tables.sql`
3. `src/data_loader.py`
4. `sql/02_data_cleaning.sql`
5. `sql/03_core_metrics.sql`

## Final Readiness Check

- [ ] Raw data is available
- [ ] Database is initialized
- [ ] Tables are created
- [ ] Data import script is ready
- [ ] Validation script runs successfully
- [ ] SQL execution order is clear

If any item above is incomplete, stop before formal analysis.
