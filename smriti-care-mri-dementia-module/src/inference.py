"""
Standalone Inference Pipeline for AI-Assisted Brain MRI Dementia Severity Estimation.
Accepts .img/.hdr Analyze pairs or .nii/.nii.gz NIfTI files,
runs forward inference, calculates confidence and probability distribution,
evaluates low-confidence threshold, and optionally generates 3D Grad-CAM saliency.
"""

import os
import sys

# Ensure project root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import json
import numpy as np
import torch
import torch.nn.functional as F

from src.utils import (
    load_config, get_device, CLASS_NAMES_3CLASS,
    LABEL_HEADER, MEDICAL_DISCLAIMER, LOW_CONFIDENCE_WARNING
)
from src.preprocessing import preprocess_mri
from src.train import build_model
from src.explainability import GradCAM3D, render_and_save_gradcam


class MRIInferencePipeline:
    def __init__(self, config_path="config.yaml"):
        self.config = load_config(config_path)
        self.device, _ = get_device()
        self.models_dir = self.config['paths']['models_dir']
        self.target_shape = tuple(self.config['preprocessing']['target_shape'])
        self.normalize = self.config['preprocessing']['normalize']
        self.confidence_threshold = float(self.config['inference']['confidence_threshold'])

        # Load class mappings
        mapping_path = os.path.join(self.models_dir, "class_mapping.json")
        if os.path.exists(mapping_path):
            with open(mapping_path, "r", encoding="utf-8") as f:
                loaded = json.load(f)
                self.class_names = {int(k): v for k, v in loaded.items()}
        else:
            self.class_names = CLASS_NAMES_3CLASS

        # Load Model
        self.model = build_model(self.config)
        weights_path = os.path.join(self.models_dir, "best_model.pth")
        if os.path.exists(weights_path):
            self.model.load_state_dict(torch.load(weights_path, map_location=self.device))
        self.model.to(self.device)
        self.model.eval()

    def predict(self, mri_path, hdr_path=None, generate_gradcam=False, session_id="sample", debug=False):
        """
        Runs inference on given MRI scan.
        Returns dictionary formatted per project specification.
        """
        if not os.path.exists(mri_path):
            raise FileNotFoundError(f"MRI file not found: {mri_path}")

        # Check Analyze 7.5 pair requirement
        if mri_path.endswith('.img'):
            if hdr_path is None:
                hdr_path = os.path.splitext(mri_path)[0] + '.hdr'
            if not os.path.exists(hdr_path):
                raise FileNotFoundError(f"Analyze 7.5 .img requires matching .hdr file at: {hdr_path}")

        # Preprocess MRI Volume: (1, D, H, W)
        tensor = preprocess_mri(
            mri_path=mri_path,
            hdr_path=hdr_path,
            target_shape=self.target_shape,
            normalize=self.normalize,
            is_train=False,
            debug=debug
        )
        input_tensor = tensor.unsqueeze(0).to(self.device)  # (1, 1, D, H, W)

        # Forward Pass
        with torch.no_grad():
            logits = self.model(input_tensor)
            probs = F.softmax(logits, dim=1).squeeze().cpu().numpy()

        class_id = int(np.argmax(probs))
        confidence = float(probs[class_id])
        pred_label_name = self.class_names.get(class_id, f"Class {class_id}")

        probabilities_dict = {
            self.class_names[i]: round(float(probs[i]), 4)
            for i in range(len(probs))
        }

        # Handle Low-Confidence threshold
        is_low_confidence = confidence < self.confidence_threshold
        status_note = LOW_CONFIDENCE_WARNING if is_low_confidence else "Confidence above clinical threshold."

        result = {
            "label_header": LABEL_HEADER,
            "disclaimer": MEDICAL_DISCLAIMER,
            "prediction": pred_label_name,
            "class_id": class_id,
            "confidence": round(confidence, 4),
            "probabilities": probabilities_dict,
            "is_low_confidence": is_low_confidence,
            "clinical_note": status_note
        }

        # Optional 3D Grad-CAM generation
        if generate_gradcam:
            try:
                target_layer = self.model.get_target_layer_for_cam()
                gradcam = GradCAM3D(self.model, target_layer)
                cam_3d, _ = gradcam.generate_heatmap(input_tensor, target_class=class_id)
                cam_path = render_and_save_gradcam(
                    mri_tensor=tensor,
                    cam_3d=cam_3d,
                    session_id=session_id,
                    pred_class=class_id,
                    confidence=confidence,
                    save_dir=self.config['paths']['gradcam_dir']
                )
                result["gradcam_path"] = cam_path.replace('\\', '/')
            except Exception as e:
                result["gradcam_error"] = str(e)

        return result


def run_cli_inference(mri_path, hdr_path=None, generate_cam=True):
    pipeline = MRIInferencePipeline()
    res = pipeline.predict(mri_path, hdr_path=hdr_path, generate_gradcam=generate_cam)
    print(json.dumps(res, indent=2))
    return res


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        run_cli_inference(sys.argv[1])
    else:
        print("Usage: python inference.py <path_to_mri_file>")
