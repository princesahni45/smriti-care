"""
Cognitive Game Recommendation API
=================================
FastAPI web service serving the Random Forest cognitive game recommendation model.

NON-DIAGNOSTIC NOTICE:
This API is strictly an assistive tool for matching users to engaging cognitive exercises.
It DOES NOT evaluate, diagnose, or stage dementia or any neurological pathology.
"""

import os
import sys

# Ensure this file's directory is in sys.path regardless of where the command is executed
current_dir = os.path.dirname(os.path.abspath(__file__))
if current_dir not in sys.path:
    sys.path.insert(0, current_dir)

from typing import Dict, List, Optional
from fastapi import FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from recommender import (
    CognitiveRecommender,
    get_recommender,
    DISCLAIMER_TEXT,
    GAME_METADATA
)

app = FastAPI(
    title="Cognitive Game Recommendation API",
    description=(
        "Machine Learning recommendation service powered by Random Forest. "
        "Accepts patient cognitive subscores and recommends the optimal cognitive game "
        "(Memory Match, Word Recall, or Find the Different Object) to support brain fitness.\n\n"
        "**STRICT DISCLAIMER**: This system does NOT diagnose dementia, Alzheimer's, or any medical condition."
    ),
    version="1.0.0"
)

# Enable CORS for web and mobile frontends (React / Flutter)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Pydantic Schemas
class PatientCognitiveScores(BaseModel):
    patient_id: Optional[str] = Field(default=None, description="Optional anonymous patient / session identifier")
    visual_memory: float = Field(
        ..., ge=0.0, le=100.0,
        description="Visual memory & pair retention score (0-100)",
        example=42.5
    )
    verbal_memory: float = Field(
        ..., ge=0.0, le=100.0,
        description="Word recall & delayed recognition score (0-100)",
        example=78.0
    )
    executive_function: float = Field(
        ..., ge=0.0, le=100.0,
        description="Categorization, abstract reasoning, and problem solving score (0-100)",
        example=65.0
    )
    attention_focus: float = Field(
        default=60.0, ge=0.0, le=100.0,
        description="Concentration & sustained visual focus score (0-100)",
        example=58.0
    )
    processing_speed: float = Field(
        default=60.0, ge=0.0, le=100.0,
        description="Reaction pace & visual scanning speed score (0-100)",
        example=55.0
    )


class BatchPatientScoresRequest(BaseModel):
    patients: List[PatientCognitiveScores] = Field(
        ...,
        description="List of patient cognitive profiles to evaluate in batch"
    )


class DifficultyRecommendation(BaseModel):
    tier: str
    label: str
    specific_level_detail: str
    rationale: str


class RecommendationResponse(BaseModel):
    patient_id: Optional[str]
    recommended_game_id: str
    recommended_game_title: str
    recommended_game_subtitle: str
    game_description: str
    target_cognitive_domain: str
    confidence_score: float
    probabilities: Dict[str, float]
    recommended_difficulty: DifficultyRecommendation
    clinical_rationale: str
    input_scores_evaluated: Dict[str, float]
    disclaimer: str
    is_prototype: bool


@app.get("/", tags=["General"])
def root_status():
    """Returns service overview, non-diagnostic disclaimer, and status."""
    return {
        "status": "healthy",
        "service": "Cognitive Game Random Forest Recommendation API",
        "version": "1.0.0",
        "supported_games": list(GAME_METADATA.keys()),
        "disclaimer": DISCLAIMER_TEXT,
        "note": "Synthetic prototype model. Does not diagnose dementia.",
        "documentation": "/docs"
    }


@app.get("/health", tags=["General"])
def health_check():
    """Health check probe."""
    return {"status": "ok"}


@app.get("/games", tags=["Games Catalog"])
def get_supported_games():
    """
    Returns the catalog of existing cognitive games supported for recommendation.
    No new games are introduced; recommendations are selected from this catalog.
    """
    return {
        "count": len(GAME_METADATA),
        "games": GAME_METADATA,
        "disclaimer": DISCLAIMER_TEXT
    }


@app.post("/recommend", response_model=RecommendationResponse, tags=["Recommendation"])
def recommend_game(scores: PatientCognitiveScores):
    """
    Accepts patient cognitive scores and returns the recommended game using the Random Forest classifier.
    
    Includes:
    - Best matching existing game
    - Confidence and probability distribution across all 3 games
    - Recommended difficulty level tailored to the patient
    - Plain-language clinical rationale
    - Non-diagnostic medical disclaimer
    """
    try:
        recommender = get_recommender()
        input_dict = {
            "visual_memory": scores.visual_memory,
            "verbal_memory": scores.verbal_memory,
            "executive_function": scores.executive_function,
            "attention_focus": scores.attention_focus,
            "processing_speed": scores.processing_speed,
        }
        result = recommender.predict(input_dict)
        result["patient_id"] = scores.patient_id
        return result
    except FileNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Inference error: {str(e)}"
        )


@app.post("/recommend/batch", response_model=List[RecommendationResponse], tags=["Recommendation"])
def recommend_game_batch(batch: BatchPatientScoresRequest):
    """Accepts multiple patient profiles and returns game recommendations for each."""
    try:
        recommender = get_recommender()
        results = []
        for profile in batch.patients:
            input_dict = {
                "visual_memory": profile.visual_memory,
                "verbal_memory": profile.verbal_memory,
                "executive_function": profile.executive_function,
                "attention_focus": profile.attention_focus,
                "processing_speed": profile.processing_speed,
            }
            res = recommender.predict(input_dict)
            res["patient_id"] = profile.patient_id
            results.append(res)
        return results
    except FileNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Batch inference error: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api:app", host="127.0.0.1", port=8000, reload=True, app_dir=current_dir)
