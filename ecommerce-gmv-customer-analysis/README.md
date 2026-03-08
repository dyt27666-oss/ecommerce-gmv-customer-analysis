# ecommerce-gmv-customer-analysis

## Project Background

This project is an end-to-end e-commerce data analysis case based on the Olist Brazilian E-commerce Dataset. The goal is to build a GitHub-ready analytics project covering data import, SQL-based data cleaning, core business KPI analysis, customer segmentation, fulfillment evaluation, and Python visualization.

This project focuses on the following business questions:

- How does GMV change over time?
- What are the order and buyer trends?
- Which customer groups create the highest value?
- How does fulfillment performance affect review scores?
- What actions can improve business growth and customer experience?

## Dataset

This project uses the following six tables from the Olist Brazilian E-commerce Dataset:

- `olist_orders_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_customers_dataset.csv`
- `olist_products_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_order_payments_dataset.csv`

Recommended local path:

```text
data/raw/
```

## Methodology

The project is organized into the following analytical stages:

1. Import raw CSV files into MySQL.
2. Perform SQL-based data cleaning and data quality checks.
3. Build core business KPIs:
   - GMV
   - Orders
   - Buyers
   - AOV
   - Repeat Rate
4. Construct an RFM model to segment customers.
5. Analyze fulfillment performance and review score relationships.
6. Use Python for result extraction, charting, and storytelling.
7. Summarize business insights and recommendations in project documents.

## Key Findings

- Delivered-order GMV reached `13.22M`, with `96,478` orders and `93,358` buyers; overall AOV was `137.04`.
- Monthly GMV growth was mainly driven by buyer and order expansion, while AOV remained relatively stable.
- Repeat Rate was only `3.00%`, showing that the business still relied heavily on one-time buyers.
- Top GMV categories included `beleza_saude`, `relogios_presentes`, and `cama_mesa_banho`, indicating strong category concentration.
- Late delivery rate was `8.11%`; late orders had an average review score of `2.57`, versus `4.29` for on-time orders.
- RFM segmentation showed that `At Risk` and `New Customers` were the dominant user groups, while `High Value` users accounted for only about `1%`.

## Business Recommendations

- Improve second-purchase conversion for new buyers, since user acquisition is strong but repeat purchase remains weak.
- Prioritize reactivation of `At Risk` users because they represent a large share of the current customer base and revenue pool.
- Reduce late deliveries first, as fulfillment delays have a direct negative impact on customer ratings.
- Focus category operations on core revenue-driving segments while building repeat-purchase strategies around high-frequency categories.

## Project Structure

```text
ecommerce-gmv-customer-analysis/
|-- README.md
|-- requirements.txt
|-- .gitignore
|-- data_dictionary.json
|-- data/
|   |-- raw/
|   `-- processed/
|-- sql/
|-- notebooks/
|-- src/
|-- dashboards/
`-- docs/
```

## Run Environment

- OS: Windows 11
- Python: Anaconda
- Database: MySQL
- IDE: VSCode / PyCharm

## Next Steps

1. Put the six Olist CSV files into `data/raw/`
2. Create MySQL database and tables
3. Execute SQL scripts in sequence
4. Run Python analysis and visualization scripts
5. Export charts and complete business summary
