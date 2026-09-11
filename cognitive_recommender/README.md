# Cognitive Game Recommendation Engine & API

A machine learning recommendation service powered by **Random Forest** that analyzes a patient's cognitive scores across key domains (visual memory, verbal memory, executive function, attention, and processing speed) and recommends the optimal game from your existing platform catalog.

> **CRITICAL MEDICAL DISCLAIMER**:  
> This system is strictly an assistive activity recommendation prototype for selecting brain fitness exercises. It **DOES NOT DIAGNOSE DEMENTIA**, Alzheimer's disease, or any medical condition. It does not replace clinical evaluation by a certified healthcare professional.

---

## 1. Supported Existing Games Catalog
The recommendation model strictly recommends among your **three existing cognitive games**:

1. **`memory-match`** (Visual Pair Matching)
   - **Target Domain**: Visual Memory & Visual Focus
   - **Exercise**: Match pairs of everyday pictures to gently practice visual memory and concentration.
   - **Adaptive Difficulties**: Level 1 (2 pairs) • Level 2 (4 pairs) • Level 3 (6 pairs)
2. **`word-recall`** (Word Recognition & Delayed Memory)
   - **Target Domain**: Verbal Memory & Delayed Recall
   - **Exercise**: Read everyday words, enjoy a gentle distraction activity, and recall words later.
   - **Adaptive Difficulties**: Easy (5 words) • Medium (5 words) • Hard (7 words)
3. **`different-object`** (Find the Different Object)
   - **Target Domain**: Executive Function & Categorization
   - **Exercise**: Spot the object that belongs to a different category than all others.
   - **Adaptive Difficulties**: Easy (6 items) • Medium (8 items) • Hard (10 items)

---

## 2. Synthetic Prototype Data Notice
Real patient cognitive assessment data is not used. The system includes a synthetic generator producing **1,500 clearly labeled prototype records**:
- Explicit marker: `is_synthetic_prototype: true`
- Documentation: `data/PROTOTYPE_DATA_NOTICE.md`
- Data features: Normalized scores from `0.0` to `100.0` across 5 cognitive subscales:
  - `visual_memory`
  - `verbal_memory`
  - `executive_function`
  - `attention_focus`
  - `processing_speed`

---

## 3. Machine Learning Architecture
- **Algorithm**: `sklearn.ensemble.RandomForestClassifier` (120 estimators, balanced class weights, depth-controlled to prevent overfitting).
- **Holdout Test Accuracy**: ~88.0%
- **5-Fold Cross-Validation**: ~88.7%
- **Interpretability**: Feature importances are balanced across key therapeutic domains (~29% visual memory, ~29% verbal memory, ~29% executive function).
- **Difficulty Mapping**:
  - Overall Mean $< 50.0 \rightarrow$ **Easy / Level 1** (gentle, stress-free engagement)
  - Overall Mean $50.0 - 74.9 \rightarrow$ **Medium / Level 2** (balanced stimulation)
  - Overall Mean $\ge 75.0 \rightarrow$ **Hard / Level 3** (full stimulation)

---

## 4. Running the Project

### Prerequisites
Make sure dependencies are installed (Python 3.11 recommended):
```bash
py -3.11 -m pip install scikit-learn fastapi uvicorn pydantic httpx
```

### Step 1: Train the Random Forest Model
```bash
cd C:\Users\91969\.gemini\antigravity\scratch\cognitive_recommender
py -3.11 train_model.py
```

### Step 2: Run Unit & API Verification Tests
```bash
py -3.11 test_recommender.py
```

### Step 3: Start the FastAPI Server
```bash
py -3.11 -m uvicorn api:app --host 127.0.0.1 --port 8000 --reload
```
Once started:
- Interactive OpenAPI Swagger documentation: **`http://127.0.0.1:8000/docs`**
- Alternative ReDoc documentation: **`http://127.0.0.1:8000/redoc`**

---

## 5. API Endpoints & Usage

### 1. Root & Health
`GET /`
```json
{
  "status": "healthy",
  "service": "Cognitive Game Random Forest Recommendation API",
  "version": "1.0.0",
  "supported_games": ["different-object", "memory-match", "word-recall"],
  "disclaimer": "DISCLAIMER: This system is a cognitive engagement & activity recommendation prototype... DOES NOT diagnose dementia..."
}
```

### 2. Get Games Catalog
`GET /games`
Returns the 3 existing games and their targeted cognitive skills and level breakdowns.

### 3. Recommend a Game
`POST /recommend`

#### Request Payload:
```json
{
  "patient_id": "PATIENT-101",
  "visual_memory": 35.0,
  "verbal_memory": 82.0,
  "executive_function": 78.0,
  "attention_focus": 60.0,
  "processing_speed": 65.0
}
```

#### Response:
```json
{
  "patient_id": "PATIENT-101",
  "recommended_game_id": "memory-match",
  "recommended_game_title": "Memory Match",
  "recommended_game_subtitle": "Visual Pair Matching",
  "game_description": "Match pairs of familiar, everyday pictures to gently practice visual memory and concentration.",
  "target_cognitive_domain": "visual_memory",
  "confidence_score": 0.8917,
  "probabilities": {
    "different-object": 0.05,
    "memory-match": 0.8917,
    "word-recall": 0.0583
  },
  "recommended_difficulty": {
    "tier": "medium",
    "label": "Medium / Level 2",
    "specific_level_detail": "Level 2 (4 pairs) - Standard engagement",
    "rationale": "Moderate overall domain performance. A balanced difficulty maintains confidence and stimulation."
  },
  "clinical_rationale": "Visual memory score (35.0/100) presents the primary cognitive opportunity. Memory Match is recommended to gently exercise visual pair association, pattern retention, and visual focus.",
  "disclaimer": "DISCLAIMER: This system is a cognitive engagement & activity recommendation prototype for selecting brain fitness exercises. It is NOT a diagnostic tool and DOES NOT diagnose dementia, Alzheimer's, or any medical condition. It does not replace professional clinical evaluation.",
  "is_prototype": true
}
```

### 4. Integration with Frontend (JavaScript / React)
```javascript
async function fetchRecommendedGame(patientScores) {
  const response = await fetch('http://127.0.0.1:8000/recommend', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(patientScores)
  });
  const data = await response.json();
  console.log('Recommended Game:', data.recommended_game_id);
  return data;
}
```
