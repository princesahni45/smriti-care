"""
Cognitive Game Recommendation Engine
====================================
Loads the trained Random Forest model and provides recommendation predictions,
confidence distributions, difficulty tier suggestions, and rationales.

NON-DIAGNOSTIC NOTICE:
This recommender is exclusively an exercise/game selection assistant.
It DOES NOT evaluate, diagnose, or stage dementia or any neurological pathology.
"""

import os
import joblib
import numpy as np
from typing import Dict, Any, List, Optional

DISCLAIMER_TEXT = (
    "DISCLAIMER: This system is a cognitive engagement & activity recommendation prototype for "
    "selecting brain fitness exercises. It is NOT a diagnostic tool and DOES NOT diagnose dementia, "
    "Alzheimer's, or any medical condition. It does not replace professional clinical evaluation."
)

DEFAULT_MODEL_PATH = os.path.join(
    os.path.dirname(__file__), "models", "recommender_rf.joblib"
)

GAME_METADATA = {
    "memory-match": {
        "title": "Memory Match",
        "subtitle": "Visual Pair Matching",
        "primary_domain": "visual_memory",
        "description": "Match pairs of familiar, everyday pictures to gently practice visual memory and concentration.",
        "levels": {
            "easy": "Level 1 (2 pairs) - Gentle start",
            "medium": "Level 2 (4 pairs) - Standard engagement",
            "hard": "Level 3 (6 pairs) - Full challenge"
        }
    },
    "word-recall": {
        "title": "Word Recall & Delayed Memory",
        "subtitle": "Word Recognition & Recall",
        "primary_domain": "verbal_memory",
        "description": "Read everyday words, enjoy a gentle distraction activity, and recall words later.",
        "levels": {
            "easy": "Easy (5 words, extended time) - Relaxed verbal exercise",
            "medium": "Medium (5 words, standard time) - Balanced recall",
            "hard": "Hard (7 words, shorter time) - High retention challenge"
        }
    },
    "different-object": {
        "title": "Find the Different Object",
        "subtitle": "Category Odd-One-Out",
        "primary_domain": "executive_function",
        "description": "Spot the object that belongs to a different category than all others. Stress-free categorical reasoning.",
        "levels": {
            "easy": "Easy (6 items) - Obvious category distinctions",
            "medium": "Medium (8 items) - Moderate category discrimination",
            "hard": "Hard (10 items) - Fine-grained visual & category nuance"
        }
    }
}


class CognitiveRecommender:
    def __init__(self, model_path: str = DEFAULT_MODEL_PATH):
        self.model_path = model_path
        self.model = None
        self.feature_columns = []
        self.target_classes = []
        self.metadata = {}
        self._load_model()

    def _load_model(self):
        if not os.path.exists(self.model_path):
            raise FileNotFoundError(
                f"Model file not found at '{self.model_path}'. "
                f"Please run train_model.py first."
            )
        bundle = joblib.load(self.model_path)
        self.model = bundle["model"]
        self.feature_columns = bundle.get("feature_columns", [
            "visual_memory", "verbal_memory", "executive_function", "attention_focus", "processing_speed"
        ])
        self.target_classes = bundle.get("target_classes", list(self.model.classes_))
        self.metadata = bundle.get("metadata", {})

    def _recommend_difficulty(self, average_score: float) -> Dict[str, str]:
        """Maps overall cognitive capacity to gentle, stress-free difficulty tiers."""
        if average_score >= 75.0:
            tier = "hard"
            label = "Hard / Level 3"
            note = "Patient shows strong overall domain performance. An advanced difficulty provides healthy stimulation."
        elif average_score >= 50.0:
            tier = "medium"
            label = "Medium / Level 2"
            note = "Moderate overall domain performance. A balanced difficulty maintains confidence and stimulation."
        else:
            tier = "easy"
            label = "Easy / Level 1"
            note = "Scores indicate a gentle, low-friction pace is recommended for maximum comfort and encouragement."

        return {
            "tier": tier,
            "label": label,
            "guidance": note
        }

    def _generate_rationale(
        self,
        scores: Dict[str, float],
        recommended_game_id: str,
        confidence: float
    ) -> str:
        """Generates a human-interpretable rationale for why this game was chosen."""
        vm = scores.get("visual_memory", 50.0)
        vbm = scores.get("verbal_memory", 50.0)
        ef = scores.get("executive_function", 50.0)

        domain_scores = {
            "visual_memory": vm,
            "verbal_memory": vbm,
            "executive_function": ef
        }

        min_domain = min(domain_scores, key=domain_scores.get)
        min_val = domain_scores[min_domain]

        if recommended_game_id == "memory-match":
            reason = (
                f"Visual memory score ({vm:.1f}/100) presents the primary cognitive opportunity. "
                f"Memory Match is recommended to gently exercise visual pair association, pattern retention, and visual focus."
            )
        elif recommended_game_id == "word-recall":
            reason = (
                f"Verbal memory score ({vbm:.1f}/100) represents the primary area benefiting from reinforcement. "
                f"Word Recall is recommended to promote verbal rehearsal, immediate recognition, and delayed recall without pressure."
            )
        elif recommended_game_id == "different-object":
            reason = (
                f"Executive function score ({ef:.1f}/100) is the lowest relative domain. "
                f"Find the Different Object is recommended to stimulate category identification, abstract reasoning, and visual scanning."
            )
        else:
            reason = f"Recommended based on multi-domain Random Forest profile match ({confidence * 100:.1f}% model confidence)."

        return reason

    def predict(self, scores: Dict[str, float]) -> Dict[str, Any]:
        """
        Runs recommendation inference for a patient cognitive score dictionary.
        Returns game recommendation, probability breakdown, difficulty guidance, and medical disclaimer.
        """
        # Build input vector in expected order
        features_vector = []
        for col in self.feature_columns:
            val = float(scores.get(col, 50.0))
            # Bound check strictly between 0 and 100
            val = max(0.0, min(100.0, val))
            features_vector.append(val)

        X = np.array([features_vector])

        # Prediction and probabilities
        pred_label = self.model.predict(X)[0]
        probabilities = self.model.predict_proba(X)[0]

        # Class probabilities mapping
        prob_dict = {}
        for cls_name, prob in zip(self.model.classes_, probabilities):
            prob_dict[cls_name] = round(float(prob), 4)

        confidence = float(np.max(probabilities))
        avg_score = float(np.mean(features_vector))
        difficulty_info = self._recommend_difficulty(avg_score)
        rationale = self._generate_rationale(scores, pred_label, confidence)

        game_meta = GAME_METADATA.get(pred_label, {
            "title": pred_label,
            "subtitle": "",
            "primary_domain": "",
            "description": "",
            "levels": {}
        })

        recommended_level_detail = game_meta.get("levels", {}).get(
            difficulty_info["tier"], difficulty_info["label"]
        )

        return {
            "recommended_game_id": pred_label,
            "recommended_game_title": game_meta["title"],
            "recommended_game_subtitle": game_meta["subtitle"],
            "game_description": game_meta["description"],
            "target_cognitive_domain": game_meta["primary_domain"],
            "confidence_score": round(confidence, 4),
            "probabilities": prob_dict,
            "recommended_difficulty": {
                "tier": difficulty_info["tier"],
                "label": difficulty_info["label"],
                "specific_level_detail": recommended_level_detail,
                "rationale": difficulty_info["guidance"]
            },
            "clinical_rationale": rationale,
            "input_scores_evaluated": {col: scores.get(col, 50.0) for col in self.feature_columns},
            "disclaimer": DISCLAIMER_TEXT,
            "is_prototype": True
        }


# Singleton instance for quick reuse
_recommender_instance = None

def get_recommender(model_path: str = DEFAULT_MODEL_PATH) -> CognitiveRecommender:
    global _recommender_instance
    if _recommender_instance is None:
        _recommender_instance = CognitiveRecommender(model_path=model_path)
    return _recommender_instance
