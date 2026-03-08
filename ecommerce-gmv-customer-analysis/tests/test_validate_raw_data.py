import unittest
from pathlib import Path

from src.validate_raw_data import REQUIRED_FILES, build_file_status


class ValidateRawDataTests(unittest.TestCase):
    def test_required_files_count_is_six(self) -> None:
        self.assertEqual(len(REQUIRED_FILES), 6)

    def test_build_file_status_for_missing_file(self) -> None:
        file_path = Path("C:/mock/raw/olist_orders_dataset.csv")

        result = build_file_status(file_path)

        self.assertEqual(result["file_name"], "olist_orders_dataset.csv")
        self.assertEqual(result["status"], "missing")
        self.assertIsNone(result["row_count"])
        self.assertIsNone(result["column_count"])


if __name__ == "__main__":
    unittest.main()
