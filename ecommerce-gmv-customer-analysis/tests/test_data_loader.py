import unittest
from pathlib import Path

from src.data_loader import DatabaseConfig, build_connection_url, get_missing_files


class DataLoaderHelperTests(unittest.TestCase):
    def test_build_connection_url_encodes_special_characters(self) -> None:
        config = DatabaseConfig(
            host="127.0.0.1",
            port=3306,
            user="root",
            password="pa@ss:word",
            database="olist_project"
        )

        url = build_connection_url(config)

        self.assertIn("mysql+pymysql://root:pa%40ss%3Aword@127.0.0.1:3306/olist_project", url)
        self.assertTrue(url.endswith("?charset=utf8mb4"))

    def test_get_missing_files_returns_only_absent_files(self) -> None:
        raw_dir = Path("C:/mock/raw")
        file_mapping = {
            "olist_orders_dataset.csv": "orders",
            "olist_customers_dataset.csv": "customers"
        }
        existing_files = {raw_dir / "olist_orders_dataset.csv"}

        missing_files = get_missing_files(raw_dir, file_mapping, existing_files)

        self.assertEqual(missing_files, [raw_dir / "olist_customers_dataset.csv"])


if __name__ == "__main__":
    unittest.main()
