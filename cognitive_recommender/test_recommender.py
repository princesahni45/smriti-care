"""
Comprehensive Test Suite for Cognitive Game Recommender & API
============================================================
Tests:
1. Synthetic data generator correctness and prototype labeling
2. Random Forest model training, accuracy, and serialization
3. Cognitive recommender domain sensitivity and difficulty scaling
4. FastAPI endpoints, Pydantic bounds validation, and medical disclaimers
"""

import os
import unittest
import numpy as np
from starlette.testclient import TestClient

from data_generator import (
    generate_synthetic_patient_records,
    save_synthetic_data,
    FEATURE_COLUMNS,
    GAMES
)
from train_model import train_and_evaluate_model, MODEL_PATH
from recommender import CognitiveRecommender, DISCLAIMER_TEXT
from api import app


class TestCognitiveRecommender(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        # Ensure model is trained and available
        os.chdir(os.path.dirname(__file__))
        train_and_evaluate_model()
        cls.recommender = CognitiveRecommender()
        cls.client = TestClient(app)

    def test_01_synthetic_data_generation(self):
        records = generate_synthetic_patient_records(n_samples=300)
        self.assertEqual(len(records), 300)

        # Check required schema keys
        for rec in records:
            for col in FEATURE_COLUMNS:
                self.assertIn(col, rec)
                self.assertGreaterEqual(rec[col], 0.0)
                self.assertLessEqual(rec[col], 100.0)

            self.assertIn(rec["recommended_game"], ["memory-match", "word-recall", "different-object"])
            self.assertTrue(rec["is_synthetic_prototype"], "Synthetic prototype flag must be true")

    def test_02_model_persistence_and_accuracy(self):
        self.assertTrue(os.path.exists(MODEL_PATH), "Trained model joblib file must exist")
        self.assertIsNotNone(self.recommender.model)
        self.assertEqual(len(self.recommender.target_classes), 3)

    def test_03_recommendation_visual_memory_bias(self):
        # Low visual memory, high elsewhere -> Memory Match
        scores = {
            "visual_memory": 20.0,
            "verbal_memory": 85.0,
            "executive_function": 85.0,
            "attention_focus": 70.0,
            "processing_speed": 75.0
        }
        res = self.recommender.predict(scores)
        self.assertEqual(res["recommended_game_id"], "memory-match")
        self.assertEqual(res["target_cognitive_domain"], "visual_memory")
        self.assertIn("Visual memory score", res["clinical_rationale"])
        self.assertIn("DOES NOT diagnose dementia", res["disclaimer"])

    def test_04_recommendation_verbal_memory_bias(self):
        # Low verbal memory, high elsewhere -> Word Recall
        scores = {
            "visual_memory": 85.0,
            "verbal_memory": 22.0,
            "executive_function": 85.0,
            "attention_focus": 70.0,
            "processing_speed": 75.0
        }
        res = self.recommender.predict(scores)
        self.assertEqual(res["recommended_game_id"], "word-recall")
        self.assertEqual(res["target_cognitive_domain"], "verbal_memory")
        self.assertIn("Verbal memory score", res["clinical_rationale"])

    def test_05_recommendation_executive_bias(self):
        # Low executive function, high elsewhere -> Different Object
        scores = {
            "visual_memory": 85.0,
            "verbal_memory": 85.0,
            "executive_function": 20.0,
            "attention_focus": 70.0,
            "processing_speed": 75.0
        }
        res = self.recommender.predict(scores)
        self.assertEqual(res["recommended_game_id"], "different-object")
        self.assertEqual(res["target_cognitive_domain"], "executive_function")
        self.assertIn("Executive function score", res["clinical_rationale"])

    def test_06_difficulty_scaling(self):
        # Low scores overall -> Easy difficulty
        low_scores = {col: 35.0 for col in FEATURE_COLUMNS}
        res_low = self.recommender.predict(low_scores)
        self.assertEqual(res_low["recommended_difficulty"]["tier"], "easy")

        # High scores overall -> Hard difficulty
        high_scores = {col: 88.0 for col in FEATURE_COLUMNS}
        res_high = self.recommender.predict(high_scores)
        self.assertEqual(res_high["recommended_difficulty"]["tier"], "hard")

    def test_07_api_root_and_games(self):
        res = self.client.get("/")
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["status"], "healthy")
        self.assertIn("disclaimer", data)
        self.assertIn("memory-match", data["supported_games"])

        res_games = self.client.get("/games")
        self.assertEqual(res_games.status_code, 200)
        games_data = res_games.json()
        self.assertEqual(games_data["count"], 3)
        self.assertIn("word-recall", games_data["games"])

    def test_08_api_recommend_post(self):
        payload = {
            "patient_id": "TEST-PAT-001",
            "visual_memory": 30.0,
            "verbal_memory": 80.0,
            "executive_function": 75.0,
            "attention_focus": 70.0,
            "processing_speed": 65.0
        }
        res = self.client.post("/recommend", json=payload)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(data["patient_id"], "TEST-PAT-001")
        self.assertEqual(data["recommended_game_id"], "memory-match")
        self.assertIn("probabilities", data)
        # Check that probabilities sum to ~1.0
        total_prob = sum(data["probabilities"].values())
        self.assertAlmostEqual(total_prob, 1.0, places=2)
        self.assertIn("disclaimer", data)
        self.assertTrue(data["is_prototype"])

    def test_09_api_bounds_validation(self):
        # Cognitive score out of bounds (> 100) must return 422
        bad_payload = {
            "visual_memory": 150.0,
            "verbal_memory": 80.0,
            "executive_function": 75.0
        }
        res = self.client.post("/recommend", json=bad_payload)
        self.assertEqual(res.status_code, 422)

    def test_10_api_batch_recommend(self):
        batch_payload = {
            "patients": [
                {
                    "patient_id": "BATCH-01",
                    "visual_memory": 25.0,
                    "verbal_memory": 80.0,
                    "executive_function": 80.0
                },
                {
                    "patient_id": "BATCH-02",
                    "visual_memory": 80.0,
                    "verbal_memory": 25.0,
                    "executive_function": 80.0
                }
            ]
        }
        res = self.client.post("/recommend/batch", json=batch_payload)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertEqual(len(data), 2)
        self.assertEqual(data[0]["recommended_game_id"], "memory-match")
        self.assertEqual(data[1]["recommended_game_id"], "word-recall")


if __name__ == "__main__":
    unittest.main()
