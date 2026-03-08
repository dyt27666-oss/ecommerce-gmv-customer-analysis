"""
Validate required raw CSV files under data/raw.

Windows 11 + Anaconda example:
    py src/validate_raw_data.py
"""

from __future__ import annotations

import logging
from pathlib import Path
from typing import Any, Dict, List

try:
    import pandas as pd
except ImportError:  # pragma: no cover - handled at runtime
    pd = None


PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"

# Windows 11 example path:
# RAW_DATA_DIR = Path(r"C:\Users\25855\Desktop\E-commerce data analysis\ecommerce-gmv-customer-analysis\data\raw")

REQUIRED_FILES: List[str] = [
    "olist_orders_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_customers_dataset.csv",
    "olist_products_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_order_payments_dataset.csv",
]


def configure_logging() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)s | %(message)s"
    )


def ensure_dependencies() -> None:
    if pd is None:
        raise ImportError(
            "Missing required package: pandas. "
            "Install dependencies with: py -m pip install -r requirements.txt"
        )


def build_file_status(file_path: Path) -> Dict[str, Any]:
    result: Dict[str, Any] = {
        "file_name": file_path.name,
        "status": "missing",
        "row_count": None,
        "column_count": None,
        "columns": [],
        "file_path": str(file_path),
    }

    if not file_path.exists():
        return result

    try:
        dataframe = pd.read_csv(file_path)
        result["status"] = "ok"
        result["row_count"] = int(len(dataframe))
        result["column_count"] = int(len(dataframe.columns))
        result["columns"] = dataframe.columns.tolist()
    except Exception as exc:  # pragma: no cover - depends on local files
        result["status"] = f"read_error: {exc}"

    return result


def validate_raw_files(raw_dir: Path) -> List[Dict[str, Any]]:
    return [build_file_status(raw_dir / file_name) for file_name in REQUIRED_FILES]


def print_validation_report(results: List[Dict[str, Any]]) -> None:
    print("=" * 100)
    print("RAW DATA VALIDATION REPORT")
    print("=" * 100)

    for item in results:
        print(f"File Name     : {item['file_name']}")
        print(f"Status        : {item['status']}")
        print(f"Rows          : {item['row_count']}")
        print(f"Columns       : {item['column_count']}")
        print(f"Column Names  : {item['columns']}")
        print(f"File Path     : {item['file_path']}")
        print("-" * 100)


def main() -> None:
    configure_logging()
    ensure_dependencies()

    logging.info("Starting raw data validation")
    logging.info("Raw data directory: %s", RAW_DATA_DIR)

    if not RAW_DATA_DIR.exists():
        raise FileNotFoundError(f"Raw data directory does not exist: {RAW_DATA_DIR}")

    results = validate_raw_files(RAW_DATA_DIR)
    print_validation_report(results)

    ok_count = sum(1 for item in results if item["status"] == "ok")
    missing_count = sum(1 for item in results if item["status"] == "missing")
    error_count = len(results) - ok_count - missing_count

    logging.info("Validation summary | ok=%s | missing=%s | error=%s", ok_count, missing_count, error_count)

    if missing_count > 0 or error_count > 0:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
