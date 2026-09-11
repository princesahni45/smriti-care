"""
Random Forest Cognitive Game Recommendation Model Trainer
=========================================================
Trains a multi-class Random Forest model to recommend cognitive games
based on synthetic patient cognitive domain scores.

STRICT MEDICAL DISCLAIMER:
This model is designed solely to recommend brain exercises/games for cognitive stimulation.
It DOES NOT diagnose dementia, Alzheimer's disease, or any neurological condition.
"""

import os
import json
import csv
import joblib
import numpy as np
from datetime import datetime
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score

from data_generator import (
    FEATURE_COLUMNS,
    GAMES,
    generate_synthetic_patient_records,
    save_synthetic_data
)

MODEL_DIR = "models"
MODEL_PATH = os.path.join(MODEL_DIR, "recommender_rf.joblib")
METRICS_PATH = os.path.join(MODEL_DIR, "model_metrics.json")


def load_or_generate_dataset(data_path: str = "data/synthetic_patient_cognitive_data.csv"):
    """Loads existing CSV or generates a new synthetic prototype dataset if missing."""
    if not os.path.exists(data_path):
        print("[INFO] Dataset not found. Generating synthetic prototype data...")
        save_synthetic_data(os.path.dirname(data_path) or "data")

    records = []
    with open(data_path, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            records.append(row)

    X = []
    y = []
    for r in records:
        X.append([float(r[col]) for col in FEATURE_COLUMNS])
        y.append(r["recommended_game"])

    return np.array(X), np.array(y), records


def train_and_evaluate_model():
    """Trains the Random Forest recommender and saves serialized artifacts."""
    os.makedirs(MODEL_DIR, exist_ok=True)

    print("=" * 60)
    print("Training Cognitive Game Recommendation Random Forest Model")
    print("=" * 60)

    X, y, records = load_or_generate_dataset()
    classes = sorted(list(set(y)))
    print(f"Total synthetic prototype samples: {len(X)}")
    print(f"Features: {FEATURE_COLUMNS}")
    print(f"Target classes (Existing Games): {classes}")

    # Train-test split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )

    # Train Random Forest Classifier
    rf = RandomForestClassifier(
        n_estimators=120,
        max_depth=12,
        min_samples_split=4,
        min_samples_leaf=2,
        class_weight="balanced",
        random_state=42,
        n_jobs=-1
    )

    rf.fit(X_train, y_train)

    # 5-fold Cross-Validation
    cv_scores = cross_val_score(rf, X, y, cv=5, scoring="accuracy")
    print(f"\n5-Fold Cross-Validation Accuracy: {cv_scores.mean():.4f} (+/- {cv_scores.std():.4f})")

    # Evaluation on holdout test set
    y_pred = rf.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    report = classification_report(y_test, y_pred, output_dict=True)
    conf_mat = confusion_matrix(y_test, y_pred, labels=classes).tolist()

    print(f"Holdout Test Accuracy: {acc * 100:.2f}%\n")
    print("Detailed Classification Report:")
    print(classification_report(y_test, y_pred))

    # Feature importances
    importances = {col: round(float(imp), 4) for col, imp in zip(FEATURE_COLUMNS, rf.feature_importances_)}
    sorted_importances = dict(sorted(importances.items(), key=lambda item: item[1], reverse=True))
    print("Feature Importances:")
    for feat, imp in sorted_importances.items():
        print(f"  - {feat:20s}: {imp:.4f}")

    # Save model artifact bundle
    model_bundle = {
        "model": rf,
        "feature_columns": FEATURE_COLUMNS,
        "target_classes": classes,
        "games_catalog": GAMES,
        "metadata": {
            "model_type": "RandomForestClassifier",
            "trained_at": datetime.utcnow().isoformat() + "Z",
            "accuracy": round(float(acc), 4),
            "cv_accuracy_mean": round(float(cv_scores.mean()), 4),
            "feature_importances": sorted_importances,
            "is_synthetic_prototype": True,
            "disclaimer": (
                "Prototype cognitive activity recommendation model. "
                "DOES NOT DIAGNOSE DEMENTIA, Alzheimer's, or any medical disorder. "
                "Intended solely for recommending games to support brain fitness."
            )
        }
    }

    joblib.dump(model_bundle, MODEL_PATH)
    print(f"\n[OK] Model artifact successfully saved to: {MODEL_PATH}")

    # Save metrics JSON
    metrics_data = {
        "accuracy": float(acc),
        "cv_accuracy_mean": float(cv_scores.mean()),
        "cv_accuracy_std": float(cv_scores.std()),
        "classification_report": report,
        "confusion_matrix": {
            "classes": classes,
            "matrix": conf_mat
        },
        "feature_importances": sorted_importances
    }
    with open(METRICS_PATH, "w", encoding="utf-8") as f:
        json.dump(metrics_data, f, indent=2)
    print(f"[OK] Metrics saved to: {METRICS_PATH}")

    return model_bundle, metrics_data


if __name__ == "__main__":
    train_and_evaluate_model()
