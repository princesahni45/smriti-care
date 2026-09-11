"""
Synthetic Cognitive Patient Data Generator
=========================================
NOTE: THIS IS SYNTHETIC PROTOTYPE DATA GENERATED FOR DEMONSTRATION,
DEVELOPMENT, AND ALGORITHM PROTOTYPING ONLY.
IT DOES NOT CONTAIN REAL PATIENT DATA AND MUST NOT BE USED FOR
MEDICAL DIAGNOSIS OR STAGING OF DEMENTIA.
"""

import os
import numpy as np

# Use basic standard libraries or pandas if available
GAMES = [
    {
        "id": "memory-match",
        "title": "Memory Match",
        "primary_domain": "visual_memory",
        "description": "Visual pair matching practicing visual memory and concentration."
    },
    {
        "id": "word-recall",
        "title": "Word Recall & Delayed Memory",
        "primary_domain": "verbal_memory",
        "description": "Word recognition, immediate and delayed verbal recall."
    },
    {
        "id": "different-object",
        "title": "Find the Different Object",
        "primary_domain": "executive_function",
        "description": "Category odd-one-out, categorical reasoning, and visual discrimination."
    }
]

FEATURE_COLUMNS = [
    "visual_memory",
    "verbal_memory",
    "executive_function",
    "attention_focus",
    "processing_speed"
]


def generate_synthetic_patient_records(n_samples: int = 1500, random_state: int = 42):
    """
    Generates realistic, clearly labeled synthetic prototype patient cognitive scores (0-100).
    Assigns target recommendations based on primary cognitive reinforcement opportunity:
      - Relative weakness in visual memory -> memory-match
      - Relative weakness in verbal memory / word recall -> word-recall
      - Relative weakness in categorization / executive function -> different-object
    Introduces realistic clinical variance/noise.
    """
    np.random.seed(random_state)
    records = []

    for i in range(n_samples):
        patient_id = f"SYN-PAT-{i+1001:04d}"

        # Baseline cognitive capacity (heterogeneous distribution representing elderly cohorts)
        baseline = np.random.normal(loc=65.0, scale=14.0)

        # Domain specific scores with correlated variation around baseline
        # Clip strictly between 10 and 100
        visual_memory = float(np.clip(np.random.normal(loc=baseline, scale=12.0), 10.0, 100.0))
        verbal_memory = float(np.clip(np.random.normal(loc=baseline, scale=12.0), 10.0, 100.0))
        executive_func = float(np.clip(np.random.normal(loc=baseline, scale=12.0), 10.0, 100.0))
        attention = float(np.clip(np.random.normal(loc=baseline, scale=10.0), 10.0, 100.0))
        speed = float(np.clip(np.random.normal(loc=baseline, scale=10.0), 10.0, 100.0))

        # Intentionally inject specific relative challenge profiles across clusters
        cluster_assignment = i % 3
        if cluster_assignment == 0:
            # Cluster 0: Needs Visual Memory support
            visual_memory = float(np.clip(visual_memory - np.random.uniform(8.0, 20.0), 10.0, 100.0))
        elif cluster_assignment == 1:
            # Cluster 1: Needs Verbal Memory support
            verbal_memory = float(np.clip(verbal_memory - np.random.uniform(8.0, 20.0), 10.0, 100.0))
        else:
            # Cluster 2: Needs Executive Function support
            executive_func = float(np.clip(executive_func - np.random.uniform(8.0, 20.0), 10.0, 100.0))

        # Determine target game label using primary reinforcement opportunity
        # Weighted domain deficiency with slight stochastic noise
        score_dict = {
            "memory-match": visual_memory * 1.0 + attention * 0.15 + np.random.normal(0, 3.0),
            "word-recall": verbal_memory * 1.0 + attention * 0.15 + np.random.normal(0, 3.0),
            "different-object": executive_func * 1.0 + speed * 0.15 + np.random.normal(0, 3.0)
        }

        # The game corresponding to the lowest subscore receives primary recommendation
        recommended_game = min(score_dict, key=score_dict.get)

        records.append({
            "patient_id": patient_id,
            "visual_memory": round(visual_memory, 2),
            "verbal_memory": round(verbal_memory, 2),
            "executive_function": round(executive_func, 2),
            "attention_focus": round(attention, 2),
            "processing_speed": round(speed, 2),
            "recommended_game": recommended_game,
            "is_synthetic_prototype": True,
            "generation_timestamp": "2026-09-10T00:00:00Z"
        })

    return records


def save_synthetic_data(output_dir: str = "data") -> str:
    """Generates and saves the synthetic dataset to CSV with metadata notice."""
    import csv

    os.makedirs(output_dir, exist_ok=True)
    csv_path = os.path.join(output_dir, "synthetic_patient_cognitive_data.csv")
    readme_path = os.path.join(output_dir, "PROTOTYPE_DATA_NOTICE.md")

    records = generate_synthetic_patient_records(n_samples=1500)
    fieldnames = list(records[0].keys())

    with open(csv_path, mode="w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(records)

    notice_content = """# Prototype Data Notice & Disclaimer

**IMPORTANT NOTICE**: 
The dataset contained in `synthetic_patient_cognitive_data.csv` is **100% synthetic prototype data** created strictly for algorithmic modeling, software prototyping, and system testing.

- **NO REAL PATIENT DATA**: No real patient or protected health information (PHI) is present.
- **NON-DIAGNOSTIC**: This dataset and the resulting recommendation models **DO NOT DIAGNOSE DEMENTIA**, Alzheimer's disease, or any neurological pathology.
- **PURPOSE**: Used exclusively to train game recommendation classifiers matching users to cognitive exercises (`memory-match`, `word-recall`, `different-object`).
"""
    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(notice_content)

    print(f"[OK] Generated {len(records)} synthetic records saved to {csv_path}")
    counts = {}
    for r in records:
        counts[r["recommended_game"]] = counts.get(r["recommended_game"], 0) + 1
    print(f"[OK] Class distribution: {counts}")
    return csv_path


if __name__ == "__main__":
    save_synthetic_data()
