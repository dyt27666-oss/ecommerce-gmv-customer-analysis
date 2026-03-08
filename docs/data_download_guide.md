# Data Download Guide

## Dataset Source

Dataset name:

`Brazilian E-Commerce Public Dataset by Olist`

Download source:

Kaggle

## Download Steps

1. Open Kaggle in your browser.
2. Search for `Brazilian E-Commerce Public Dataset by Olist`.
3. Download the dataset archive to your local computer.
4. Extract the archive to a temporary folder.

## Keep Only the Required Files

This project only uses the following six CSV files:

- `olist_orders_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_customers_dataset.csv`
- `olist_products_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_order_payments_dataset.csv`

Files outside this list are not required for the current project scope.

## Target Local Folder

Place the six CSV files into:

```text
data/raw/
```

Windows 11 example:

```text
C:\Users\25855\Desktop\E-commerce data analysis\ecommerce-gmv-customer-analysis\data\raw
```

## Expected File Layout

```text
ecommerce-gmv-customer-analysis/
|-- data/
|   `-- raw/
|       |-- olist_orders_dataset.csv
|       |-- olist_order_items_dataset.csv
|       |-- olist_customers_dataset.csv
|       |-- olist_products_dataset.csv
|       |-- olist_order_reviews_dataset.csv
|       `-- olist_order_payments_dataset.csv
```

## Validation Before Import

Before loading data into MySQL, check the following:

- File names are exactly correct
- File extension is `.csv`
- Files are stored directly under `data/raw/`
- Files can be opened normally
- Encoding problems are not visible in headers

Run the validation script:

```powershell
py src/validate_raw_data.py
```

## Notes

- Do not rename the required CSV files.
- Do not place nested folders inside `data/raw/`.
- If the script reports missing files, recheck file names first.
- If the script reports read errors, re-extract the Kaggle archive and validate again.
