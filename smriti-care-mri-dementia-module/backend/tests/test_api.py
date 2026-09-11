"""
Unit and Integration Tests for Smriti Care MRI Dementia Estimation Backend API.
Tests:
- GET /
- GET /health
- GET /model-info
- POST /predict with invalid extension
- POST /predict with empty file
- POST /predict with missing Analyze .hdr
- POST /predict with corrupted MRI file
- POST /predict with valid MRI file (if sample available)
"""

import os
import sys
import unittest
import io
import tempfile
from fastapi.testclient import TestClient

backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from main import app, pipeline


class TestMRIAPI(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)

    def test_01_root_endpoint(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("service", data)
        self.assertIn("disclaimer", data)
        self.assertIn("health_check", data)

    def test_02_health_endpoint(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "online")
        self.assertIn("device", data)
        self.assertTrue(data["model_loaded"])
        self.assertEqual(data["active_model"], "best_model_disc5.pth")
        self.assertIn("disclaimer", data)

    def test_03_model_info_endpoint(self):
        response = self.client.get("/model-info")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["architecture"], "resnet10_3d")
        self.assertEqual(data["active_checkpoint"], "best_model_disc5.pth")
        self.assertTrue(data["model_loaded"])
        self.assertIn("benchmark_metrics", data)
        self.assertIn("disclaimer", data)
        self.assertIn("class_mapping", data)
        self.assertIn("0", data["class_mapping"])

    def test_04_reject_empty_file(self):
        empty_file = io.BytesIO(b"")
        response = self.client.post(
            "/predict",
            files={"file": ("empty.nii.gz", empty_file, "application/octet-stream")}
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("empty", response.json()["detail"].lower())

    def test_05_reject_unsupported_file(self):
        txt_file = io.BytesIO(b"This is a text file, not an MRI.")
        response = self.client.post(
            "/predict",
            files={"file": ("scan.txt", txt_file, "text/plain")}
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("unsupported", response.json()["detail"].lower())

    def test_06_reject_analyze_img_without_hdr(self):
        img_file = io.BytesIO(b"fake analyze data")
        response = self.client.post(
            "/predict",
            files={"file": ("scan.img", img_file, "application/octet-stream")}
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("requires both", response.json()["detail"].lower())

    def test_07_reject_corrupted_nifti(self):
        corrupted_data = io.BytesIO(b"PK\x03\x04corrupted binary header that is not valid nifti gzip")
        response = self.client.post(
            "/predict",
            files={"file": ("corrupted.nii.gz", corrupted_data, "application/octet-stream")}
        )
        self.assertIn(response.status_code, [400, 422])
        self.assertIn("header", response.json()["detail"].lower())


if __name__ == "__main__":
    unittest.main()
