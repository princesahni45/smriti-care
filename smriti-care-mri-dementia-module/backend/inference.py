"""
AI-Assisted Brain MRI Dementia Severity Estimation - Inference Pipeline
Active Model: 3D ResNet-10 (OASIS-1 Disc 1-5 Continuation Checkpoint: best_model_disc5.pth)

Clinical Class Mapping:
  0: Normal (CDR 0.0)
  1: Very Mild Dementia (CDR 0.5)
  2: Dementia (Mild/Moderate) (CDR >= 1.0)
"""

import os
import sys
import json
from pathlib import Path
# Ensure backend root is in sys.path
backend_dir = os.path.abspath(os.path.dirname(__file__))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

try:
    import torch_loader
except ImportError:
    pass

import numpy as np
import torch
import torch.nn.functional as F

from utils import (
    load_config, get_device, CLASS_NAMES_3CLASS,
    LABEL_HEADER, MEDICAL_DISCLAIMER, LOW_CONFIDENCE_WARNING
)
from preprocessing import preprocess_mri
from models.resnet3d import resnet10_3d
from explainability import GradCAM3D, render_and_save_gradcam

CLASS_KEY_MAPPING = {
    0: "normal",
    1: "very_mild",
    2: "dementia"
}


class MRIInferencePipeline:
    def __init__(self, config_path=None):
        if config_path is None:
            config_path = os.path.join(backend_dir, "config.yaml")
        self.config = load_config(config_path)
        self.device, self.device_info = get_device()

        # Locate models directory
        configured_models_dir = self.config.get("paths", {}).get("models_dir", "models")
        candidate_model_dirs = [
            os.path.join(backend_dir, configured_models_dir),
            os.path.abspath(configured_models_dir),
            os.path.join(backend_dir, "..", configured_models_dir),
            os.path.join(backend_dir, "..", "models")
        ]
        self.models_dir = None
        for cd in candidate_model_dirs:
            if os.path.exists(cd):
                self.models_dir = cd
                break
        if self.models_dir is None:
            self.models_dir = os.path.join(backend_dir, "models")

        self.target_shape = tuple(self.config["preprocessing"]["target_shape"])
        self.normalize = self.config["preprocessing"].get("normalize", "zscore")
        self.confidence_threshold = float(self.config["inference"].get("confidence_threshold", 0.60))

        # Class Names
        mapping_path = os.path.join(self.models_dir, "class_mapping.json")
        if os.path.exists(mapping_path):
            with open(mapping_path, "r", encoding="utf-8") as f:
                loaded = json.load(f)
                self.class_names = {int(k): v for k, v in loaded.items()}
        else:
            self.class_names = CLASS_NAMES_3CLASS

        # Checkpoint Resolution
        active_checkpoint_name = self.config.get("paths", {}).get("active_checkpoint", "best_model_disc5.pth")
        self.checkpoint_path = os.path.join(self.models_dir, active_checkpoint_name)
        if not os.path.exists(self.checkpoint_path):
            alt_path = os.path.join(backend_dir, "models", "best_model_disc5.pth")
            if os.path.exists(alt_path):
                self.checkpoint_path = alt_path

        self.model = None
        self.model_loaded = False
        self.model_load_error = None

        if os.path.exists(self.checkpoint_path):
            try:
                # Initialize ResNet-10 3D architecture
                model = resnet10_3d(
                    num_classes=self.config["model"]["num_classes"],
                    in_channels=self.config["model"]["in_channels"],
                    dropout=self.config["model"]["dropout"]
                )
                weights = torch.load(self.checkpoint_path, map_location=self.device)
                model.load_state_dict(weights)
                model.to(self.device)
                model.eval()
                self.model = model
                self.model_loaded = True
            except Exception as e:
                self.model_load_error = str(e)
                print(f"[MRIInferencePipeline] Error loading checkpoint: {e}")
        else:
            self.model_load_error = (
                f"Active checkpoint not found at {self.checkpoint_path}. "
                "Please place best_model_disc5.pth in backend/models/."
            )
            print(f"[MRIInferencePipeline] Warning: {self.model_load_error}")

    def is_ready(self):
        return self.model_loaded and self.model is not None

    def predict(self, mri_path, hdr_path=None, generate_gradcam=False, session_id="sample", debug=False):
        if not self.is_ready():
            raise RuntimeError(f"Model checkpoint is not loaded: {self.model_load_error}")

        if not os.path.exists(mri_path):
            raise FileNotFoundError(f"MRI file not found: {mri_path}")

        if str(mri_path).lower().endswith(".img"):
            if hdr_path is None:
                hdr_path = os.path.splitext(mri_path)[0] + ".hdr"
            if not os.path.exists(hdr_path):
                raise FileNotFoundError(f"Analyze 7.5 .img requires matching .hdr file at: {hdr_path}")

        # Step 1: Preprocess MRI volume
        tensor = preprocess_mri(
            mri_path=mri_path,
            hdr_path=hdr_path,
            target_shape=self.target_shape,
            normalize=self.normalize,
            is_train=False,
            debug=debug
        )
        input_tensor = tensor.unsqueeze(0).to(self.device)

        # Step 2: Forward Pass
        with torch.no_grad():
            logits = self.model(input_tensor)
            probs = F.softmax(logits, dim=1).squeeze().cpu().numpy()

        class_id = int(np.argmax(probs))
        confidence = float(probs[class_id])
        pred_label_name = self.class_names.get(class_id, f"Class {class_id}")

        # Standardized probabilities dictionary
        probabilities = {
            CLASS_KEY_MAPPING.get(i, f"class_{i}"): round(float(probs[i]), 4)
            for i in range(len(probs))
        }

        display_probabilities = {
            self.class_names.get(i, f"Class {i}"): round(float(probs[i]), 4)
            for i in range(len(probs))
        }

        # Step 3: Confidence threshold check
        is_low_confidence = confidence < self.confidence_threshold
        status_note = LOW_CONFIDENCE_WARNING if is_low_confidence else "Confidence meets threshold."

        result = {
            "label_header": LABEL_HEADER,
            "disclaimer": MEDICAL_DISCLAIMER,
            "prediction": pred_label_name,
            "class_id": class_id,
            "confidence": round(confidence, 4),
            "probabilities": probabilities,
            "display_probabilities": display_probabilities,
            "is_low_confidence": is_low_confidence,
            "clinical_note": status_note,
            "model_info": {
                "architecture": "resnet10_3d",
                "active_checkpoint": os.path.basename(self.checkpoint_path),
                "input_shape": list(self.target_shape),
                "device": self.device_info
            }
        }

        # Step 4: Optional 3D Grad-CAM attention visualization
        if generate_gradcam:
            try:
                gradcam_dir = os.path.join(backend_dir, self.config["paths"].get("gradcam_dir", "reports/gradcam"))
                os.makedirs(gradcam_dir, exist_ok=True)
                target_layer = self.model.get_target_layer_for_cam()
                gradcam = GradCAM3D(self.model, target_layer)
                cam_3d, _ = gradcam.generate_heatmap(input_tensor, target_class=class_id)
                cam_path = render_and_save_gradcam(
                    mri_tensor=tensor,
                    cam_3d=cam_3d,
                    session_id=session_id,
                    pred_class=class_id,
                    confidence=confidence,
                    save_dir=gradcam_dir
                )
                result["gradcam_path"] = cam_path.replace("\\", "/")
                result["gradcam_disclaimer"] = "Model Attention Visualization — Not a Clinical Interpretation"
            except Exception as e:
                result["gradcam_error"] = str(e)

        return result
