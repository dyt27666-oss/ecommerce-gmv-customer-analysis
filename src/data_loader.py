"""
Load Olist CSV files from data/raw into MySQL tables.

Run example on Windows 11:
    python src/data_loader.py
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING, Dict, List, Optional, Sequence, Set
from urllib.parse import quote_plus

try:
    import pandas as pd
except ImportError:  # pragma: no cover - handled at runtime
    pd = None

try:
    from sqlalchemy import create_engine, text
    from sqlalchemy.engine import Engine
    from sqlalchemy.exc import SQLAlchemyError
except ImportError:  # pragma: no cover - handled at runtime
    create_engine = None
    text = None
    Engine = object

    class SQLAlchemyError(Exception):
        """Fallback SQLAlchemy error type when dependency is missing."""


if TYPE_CHECKING:
    import pandas as pandas_module


# Database connection configuration.
# Replace the placeholder values with your local MySQL settings.
@dataclass(frozen=True)
class DatabaseConfig:
    host: str = "127.0.0.1"
    port: int = 3306
    user: str = "root"
    password: str = "101275"
    database: str = "ecommerce_gmv_customer_analysis"
    charset: str = "utf8mb4"


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"

# Windows 11 local path example:
# RAW_DATA_DIR = Path(r"C:\Users\25855\Desktop\E-commerce data analysis\ecommerce-gmv-customer-analysis\data\raw")

FILE_TABLE_MAPPING: Dict[str, str] = {
    "olist_orders_dataset.csv": "orders",
    "olist_order_items_dataset.csv": "order_items",
    "olist_customers_dataset.csv": "customers",
    "olist_products_dataset.csv": "products",
    "olist_order_reviews_dataset.csv": "reviews",
    "olist_order_payments_dataset.csv": "payments",
}

DATE_COLUMNS: Dict[str, Sequence[str]] = {
    "olist_orders_dataset.csv": [
        "order_purchase_timestamp",
        "order_approved_at",
        "order_delivered_carrier_date",
        "order_delivered_customer_date",
        "order_estimated_delivery_date",
    ],
    "olist_order_items_dataset.csv": [
        "shipping_limit_date",
    ],
    "olist_order_reviews_dataset.csv": [
        "review_creation_date",
        "review_answer_timestamp",
    ],
}

CHUNK_SIZE = 5000


def configure_logging() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(message)s"
    )


def build_connection_url(config: DatabaseConfig) -> str:
    encoded_password = quote_plus(config.password)
    return (
        f"mysql+pymysql://{config.user}:{encoded_password}"
        f"@{config.host}:{config.port}/{config.database}?charset={config.charset}"
    )


def create_db_engine(config: DatabaseConfig) -> Engine:
    ensure_dependencies()
    connection_url = build_connection_url(config)
    return create_engine(connection_url, pool_pre_ping=True, future=True)


def get_missing_files(
    raw_dir: Path,
    file_mapping: Dict[str, str],
    existing_files: Optional[Set[Path]] = None,
) -> List[Path]:
    if existing_files is None:
        existing_files = set(raw_dir.glob("*.csv"))

    missing_files: List[Path] = []
    for filename in file_mapping:
        file_path = raw_dir / filename
        if file_path not in existing_files:
            missing_files.append(file_path)
    return missing_files


def validate_raw_files(raw_dir: Path, file_mapping: Dict[str, str]) -> None:
    if not raw_dir.exists():
        raise FileNotFoundError(f"Raw data directory does not exist: {raw_dir}")

    missing_files = get_missing_files(raw_dir, file_mapping)
    if missing_files:
        missing_text = "\n".join(f"- {path}" for path in missing_files)
        raise FileNotFoundError(f"Missing CSV files:\n{missing_text}")


def ensure_dependencies() -> None:
    missing_packages: List[str] = []
    if pd is None:
        missing_packages.append("pandas")
    if create_engine is None or text is None:
        missing_packages.extend(["sqlalchemy", "pymysql"])

    if missing_packages:
        unique_packages = ", ".join(sorted(set(missing_packages)))
        raise ImportError(
            f"Missing required packages: {unique_packages}. "
            "Install dependencies with: py -m pip install -r requirements.txt"
        )


def normalize_datetime_columns(df: "pandas_module.DataFrame", columns: Sequence[str]) -> "pandas_module.DataFrame":
    for column in columns:
        if column in df.columns:
            df[column] = pd.to_datetime(df[column], errors="coerce")
    return df


def clean_dataframe(df: "pandas_module.DataFrame", csv_name: str) -> "pandas_module.DataFrame":
    df = df.copy()
    df.columns = [column.strip() for column in df.columns]
    df = df.where(pd.notnull(df), None)
    df = normalize_datetime_columns(df, DATE_COLUMNS.get(csv_name, []))
    return df


def truncate_table(engine: Engine, table_name: str) -> None:
    with engine.begin() as connection:
        connection.execute(text(f"TRUNCATE TABLE `{table_name}`"))


def load_single_csv(
    engine: Engine,
    csv_path: Path,
    table_name: str,
    chunksize: int = CHUNK_SIZE,
) -> int:
    ensure_dependencies()
    logging.info("Reading file: %s", csv_path)
    dataframe = pd.read_csv(csv_path)
    dataframe = clean_dataframe(dataframe, csv_path.name)

    logging.info("Importing %s rows into table `%s`", len(dataframe), table_name)
    dataframe.to_sql(
        name=table_name,
        con=engine,
        if_exists="append",
        index=False,
        chunksize=chunksize,
        method="multi",
    )
    return len(dataframe)


def load_all_csv_to_mysql(
    engine: Engine,
    raw_dir: Path,
    file_mapping: Dict[str, str],
    truncate_before_load: bool = False,
) -> None:
    total_rows = 0

    for csv_name, table_name in file_mapping.items():
        csv_path = raw_dir / csv_name

        if truncate_before_load:
            logging.info("Truncating table before import: `%s`", table_name)
            truncate_table(engine, table_name)

        imported_rows = load_single_csv(engine, csv_path, table_name)
        total_rows += imported_rows
        logging.info("Finished importing `%s` -> `%s` (%s rows)", csv_name, table_name, imported_rows)

    logging.info("All CSV files imported successfully. Total rows imported: %s", total_rows)


def test_database_connection(engine: Engine) -> None:
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))


def main() -> None:
    configure_logging()

    db_config = DatabaseConfig()
    raw_dir = RAW_DATA_DIR
    truncate_before_load = False

    logging.info("Starting CSV to MySQL import job")
    logging.info("Project root: %s", PROJECT_ROOT)
    logging.info("Raw data directory: %s", raw_dir)
    logging.info("Target database: %s@%s:%s/%s", db_config.user, db_config.host, db_config.port, db_config.database)

    try:
        ensure_dependencies()
        validate_raw_files(raw_dir, FILE_TABLE_MAPPING)
        engine = create_db_engine(db_config)
        test_database_connection(engine)
        logging.info("Database connection successful")

        load_all_csv_to_mysql(
            engine=engine,
            raw_dir=raw_dir,
            file_mapping=FILE_TABLE_MAPPING,
            truncate_before_load=truncate_before_load,
        )
    except FileNotFoundError as exc:
        logging.error("File validation failed: %s", exc)
        raise
    except pd.errors.EmptyDataError as exc:
        logging.error("CSV file is empty: %s", exc)
        raise
    except SQLAlchemyError as exc:
        logging.error("Database operation failed: %s", exc)
        raise
    except Exception as exc:
        logging.exception("Unexpected error during data import: %s", exc)
        raise
    finally:
        logging.info("Import job finished")


if __name__ == "__main__":
    main()
