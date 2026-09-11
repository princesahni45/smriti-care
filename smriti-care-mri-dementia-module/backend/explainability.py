"""
3D Grad-CAM (Gradient-Weighted Class Activation Mapping) for Volumetric Brain MRI.
Hooks activations and gradients from the final 3D convolutional stage,
computes 3D volumetric saliency, and renders multi-planar slice overlays
(Sagittal, Coronal, Axial) with medical disclaimers.
"""

import os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import torch
import torch.nn.functional as F
from scipy.ndimage import zoom

try:
    from utils import GRADCAM_DISCLAIMER, LABEL_HEADER, CLASS_NAMES_3CLASS
except ImportError:
    from src.utils import GRADCAM_DISCLAIMER, LABEL_HEADER, CLASS_NAMES_3CLASS


class GradCAM3D:
    def __init__(self, model, target_layer):
        self.model = model
        self.target_layer = target_layer
        self.gradients = None
        self.activations = None
        self._register_hooks()

    def _register_hooks(self):
        def forward_hook(module, input, output):
            self.activations = output.detach()

        def backward_hook(module, grad_input, grad_output):
            self.gradients = grad_output[0].detach()

        self.target_layer.register_forward_hook(forward_hook)
        self.target_layer.register_full_backward_hook(backward_hook)

    def generate_heatmap(self, input_tensor, target_class=None):
        """
        Generates normalized 3D Grad-CAM heatmap for input_tensor (1, 1, D, H, W).
        Returns numpy array of shape (D, H, W) normalized to [0, 1].
        """
        self.model.eval()
        self.model.zero_grad()

        # Forward pass
        output = self.model(input_tensor)
        if target_class is None:
            target_class = torch.argmax(output, dim=1).item()

        # Backward pass on target class logit
        one_hot = torch.zeros_like(output)
        one_hot[0, target_class] = 1.0
        output.backward(gradient=one_hot, retain_graph=True)

        # Gradients: (1, C, d, h, w) -> Global Average Pool over spatial dimensions (d, h, w)
        weights = torch.mean(self.gradients, dim=(2, 3, 4), keepdim=True)

        # Weighted combination of activation maps
        cam = torch.sum(weights * self.activations, dim=1, keepdim=True)
        cam = F.relu(cam)  # ReLU to keep only features that positively influence target class

        # Interpolate 3D CAM up to input volume shape
        d, h, w = input_tensor.shape[2:]
        cam = F.interpolate(cam, size=(d, h, w), mode='trilinear', align_corners=False)
        cam = cam.squeeze().cpu().numpy()

        # Normalize to [0, 1]
        mx = np.max(cam)
        mn = np.min(cam)
        if mx - mn > 1e-8:
            cam = (cam - mn) / (mx - mn)
        else:
            cam = np.zeros_like(cam)

        return cam, target_class


def render_and_save_gradcam(mri_tensor, cam_3d, session_id, pred_class, confidence,
                           clinical_cdr="N/A", save_dir="reports/gradcam"):
    """
    Renders 3-plane (Sagittal, Coronal, Axial) MRI slices with 3D Grad-CAM overlay.
    """
    os.makedirs(save_dir, exist_ok=True)
    mri_vol = mri_tensor.squeeze().cpu().numpy()

    # Normalize MRI slice for background display
    p99 = np.percentile(mri_vol, 99.5)
    if p99 > 0:
        display_mri = np.clip(mri_vol / p99, 0, 1)
    else:
        display_mri = mri_vol

    d, h, w = mri_vol.shape
    s_idx = d // 2  # Sagittal slice
    c_idx = h // 2  # Coronal slice
    a_idx = w // 2  # Axial slice

    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    planes = [
        ("Sagittal View", display_mri[s_idx, :, :], cam_3d[s_idx, :, :]),
        ("Coronal View", display_mri[:, c_idx, :], cam_3d[:, c_idx, :]),
        ("Axial View", display_mri[:, :, a_idx], cam_3d[:, :, a_idx])
    ]

    for ax, (title, mri_slice, cam_slice) in zip(axes, planes):
        ax.imshow(mri_slice, cmap='gray', origin='lower')
        # Overlay heatmap with alpha transparency
        masked_cam = np.ma.masked_where(cam_slice < 0.15, cam_slice)
        im = ax.imshow(masked_cam, cmap='jet', alpha=0.5, origin='lower', vmin=0, vmax=1)
        ax.set_title(title, fontsize=12, fontweight='bold')
        ax.axis('off')

    pred_name = CLASS_NAMES_3CLASS.get(pred_class, f"Class {pred_class}")
    fig.suptitle(
        f"{LABEL_HEADER}\n"
        f"Subject/Session: {session_id} | Predicted: {pred_name} (Conf: {confidence*100:.1f}%) | Clinical CDR: {clinical_cdr}\n"
        f"[{GRADCAM_DISCLAIMER}]",
        fontsize=11, color='#1e293b'
    )

    save_path = os.path.join(save_dir, f"{session_id}_gradcam.png")
    plt.tight_layout()
    plt.savefig(save_path, dpi=150, bbox_inches='tight')
    plt.close()
    print(f"[SAVED] Grad-CAM visualization: {save_path}")
    return save_path
