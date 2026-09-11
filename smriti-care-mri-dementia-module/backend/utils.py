"""
Utility functions for MRI Dementia Severity Estimation.
Includes configuration loading, device auto-detection, seed management,
and standardized medical disclaimers.
"""

import os
import random
import yaml
import numpy as np
try:
    import torch_loader
except ImportError:
    pass
import torch

MEDICAL_DISCLAIMER = (
    "This AI result is for research/educational assistance only and is not a medical diagnosis. "
    "This system provides AI-assisted estimation based on MRI patterns for research/educational purposes. "
    "It is not a medical diagnosis and should not replace evaluation by a qualified healthcare professional."
)

LABEL_HEADER = "AI-Assisted Dementia Severity Estimation"
LOW_CONFIDENCE_WARNING = "Low-confidence prediction — further clinical assessment recommended."
GRADCAM_DISCLAIMER = "Model attention visualization — not a clinical interpretation."

CLASS_NAMES_3CLASS = {
    0: "Normal",
    1: "Very Mild Dementia",
    2: "Dementia (Mild/Moderate)"
}


def load_config(config_path="config.yaml"):
    """Load configuration YAML file."""
    if not os.path.exists(config_path):
        # Look relative to parent or script
        alt_path = os.path.join(os.path.dirname(__file__), "..", config_path)
        if os.path.exists(alt_path):
            config_path = alt_path
        else:
            raise FileNotFoundError(f"Configuration file not found: {config_path}")
    with open(config_path, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)
    return config


def set_seed(seed=42):
    """Set random seeds for reproducibility."""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed(seed)
        torch.cuda.manual_seed_all(seed)
        torch.backends.cudnn.deterministic = True
        torch.backends.cudnn.benchmark = False


def get_device():
    """
    Detect optimal available computing device (CUDA with VRAM check or CPU).
    Returns (torch.device, str_description).
    """
    if torch.cuda.is_available():
        device = torch.device("cuda:0")
        device_name = torch.cuda.get_device_name(0)
        total_vram_gb = torch.cuda.get_device_properties(0).total_memory / (1024**3)
        info = f"CUDA Enabled: {device_name} (Total VRAM: {total_vram_gb:.2f} GB)"
        return device, info
    else:
        return torch.device("cpu"), "CPU Fallback (CUDA not available)"


def check_gpu_memory():
    """Print current allocated and reserved GPU memory in MB."""
    if torch.cuda.is_available():
        allocated = torch.cuda.memory_allocated(0) / (1024**2)
        reserved = torch.cuda.memory_reserved(0) / (1024**2)
        return f"VRAM Allocated: {allocated:.1f} MB | Reserved: {reserved:.1f} MB"
    return "CPU Mode (No VRAM)"
