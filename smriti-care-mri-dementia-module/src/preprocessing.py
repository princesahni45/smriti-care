"""
3D MRI Preprocessing & Augmentation Pipeline for OASIS-1 Volumetric Scans.
Supports Analyze 7.5 (.img/.hdr) and NIfTI (.nii/.nii.gz).
Includes orientation standardization, brain-mask bounding box cropping,
resampling to fixed dimensions (96x96x96), intensity normalization, and 3D augmentation.
"""

import os
import struct
import numpy as np
from scipy import ndimage
import torch


def load_analyze_volume(img_path, hdr_path=None, debug=False):
    """
    Loads Analyze 7.5 volume (.img/.hdr) or NIfTI (.nii/.nii.gz).
    For NIfTI inputs:
      - Preserves affine
      - Standardizes spatial orientation to ('L', 'A', 'S') (training reference orientation)
        via nibabel affine orientation transform (not blind array transposition)
      - Logs debug information if requested.
    For Analyze 7.5 inputs:
      - Preserves native OASIS Analyze orientation and layout without altering training data.
    """
    img_path = str(img_path)
    if hdr_path is None:
        hdr_path = os.path.splitext(img_path)[0] + '.hdr'

    # Try nibabel first
    try:
        import nibabel as nib
        if img_path.endswith('.nii') or img_path.endswith('.nii.gz'):
            nii = nib.load(img_path)
            orig_shape = nii.shape
            orig_zooms = tuple(float(z) for z in nii.header.get_zooms()[:3])
            orig_axcodes = nib.aff2axcodes(nii.affine)

            data = np.squeeze(nii.get_fdata(dtype=np.float32))

            # Standardize spatial orientation to ('L', 'A', 'S') using NIfTI affine
            target_ornt = nib.orientations.axcodes2ornt(('L', 'A', 'S'))
            nii_ornt = nib.orientations.io_orientation(nii.affine)
            transform = nib.orientations.ornt_transform(nii_ornt, target_ornt)
            reoriented = nib.orientations.apply_orientation(data, transform)

            if debug:
                print(f"[PREPROCESS DEBUG] File: {os.path.basename(img_path)}")
                print(f"  Input: shape={orig_shape}, orientation={orig_axcodes}, spacing={orig_zooms}")
                print(f"  Standardized: orientation=('L', 'A', 'S'), shape={reoriented.shape}, spacing={orig_zooms}")

            return reoriented, nii.affine, orig_zooms
        elif os.path.exists(hdr_path):
            img = nib.analyze.AnalyzeImage.load(hdr_path)
            data = np.squeeze(img.get_fdata(dtype=np.float32))
            zooms = tuple(float(z) for z in img.header.get_zooms()[:3])
            if debug:
                print(f"[PREPROCESS DEBUG] Analyze File: {os.path.basename(img_path)}, shape={data.shape}, spacing={zooms}")
            return data, img.affine, zooms
    except Exception as e:
        if debug:
            print(f"[PREPROCESS DEBUG] nibabel loader warning: {e}, falling back to binary reader")
        pass

    # Direct binary fallback for Analyze 7.5 format
    if not os.path.exists(hdr_path) or not os.path.exists(img_path):
        raise FileNotFoundError(f"Missing image or header: {img_path} / {hdr_path}")

    with open(hdr_path, 'rb') as f:
        raw_hdr = f.read(348)
    sizeof_hdr = struct.unpack('<I', raw_hdr[:4])[0]
    endian = '<' if sizeof_hdr == 348 else '>'
    dim = struct.unpack(endian + '8h', raw_hdr[40:56])
    pixdim = struct.unpack(endian + '8f', raw_hdr[76:108])
    datatype = struct.unpack(endian + 'h', raw_hdr[68:70])[0]
    bitpix = struct.unpack(endian + 'h', raw_hdr[72:74])[0]

    shape = (dim[1], dim[2], dim[3])
    voxel_sizes = (pixdim[1], pixdim[2], pixdim[3])

    # Determine numpy dtype
    if bitpix == 16:
        dt = np.dtype(endian + 'i2')
    elif bitpix == 8:
        dt = np.dtype('u1')
    elif bitpix == 32:
        dt = np.dtype(endian + 'f4')
    else:
        dt = np.dtype(endian + 'i2')

    data = np.fromfile(img_path, dtype=dt)
    data = data.reshape(shape).astype(np.float32)
    return data, None, voxel_sizes


def crop_brain_nonzero(volume, margin=4):
    """
    Crops background zero-padding around brain volume to focus resolution on brain tissue.
    """
    volume = np.squeeze(volume)
    nonzero_mask = volume > 0.05 * np.max(volume)
    if not np.any(nonzero_mask):
        return volume

    coords = np.argwhere(nonzero_mask)
    z0, y0, x0 = coords.min(axis=0)
    z1, y1, x1 = coords.max(axis=0) + 1

    # Apply margin with boundary clamping
    z0 = max(0, z0 - margin)
    y0 = max(0, y0 - margin)
    x0 = max(0, x0 - margin)
    z1 = min(volume.shape[0], z1 + margin)
    y1 = min(volume.shape[1], y1 + margin)
    x1 = min(volume.shape[2], x1 + margin)

    return volume[z0:z1, y0:y1, x0:x1]


def resize_volume_3d(volume, target_shape=(96, 96, 96)):
    """
    Resamples 3D volume to a fixed target shape using trilinear interpolation.
    """
    factors = [t / s for t, s in zip(target_shape, volume.shape)]
    resized = ndimage.zoom(volume, factors, order=1, mode='constant', cval=0.0)
    return resized


def normalize_intensity_volume(volume, method="zscore", clip_percentiles=(0.5, 99.5)):
    """
    Normalizes MRI voxel intensities.
    Percentile clipping removes acquisition artifacts.
    Z-score or Min-Max normalization scales intensities for neural network inputs.
    """
    nonzeros = volume[volume > 0]
    if len(nonzeros) == 0:
        return volume

    # Percentile clipping on brain tissue
    p_low, p_high = np.percentile(nonzeros, clip_percentiles)
    clipped = np.clip(volume, 0, p_high)

    if method == "minmax":
        mx = np.max(clipped)
        if mx > 0:
            return clipped / mx
        return clipped
    elif method == "zscore":
        brain_voxels = clipped[clipped > 0]
        if len(brain_voxels) > 0:
            mean = np.mean(brain_voxels)
            std = np.std(brain_voxels)
            if std > 1e-6:
                normalized = np.zeros_like(clipped)
                mask = clipped > 0
                normalized[mask] = (clipped[mask] - mean) / std
                return normalized
        return clipped
    else:
        return clipped


def augment_3d_volume(volume, max_rot_deg=7.0, max_trans_fraction=0.05,
                        scale_range=(0.95, 1.05), noise_std=0.02):
    """
    Applies medically realistic 3D augmentations to training volumes only:
    - Subtle 3D rotation (±7 deg)
    - Small translation (±5%)
    - Slight isotropic/anisotropic scaling (0.95 - 1.05)
    - Mild Gaussian noise
    """
    # Random 3D Rotation along one or two random planes
    if np.random.rand() > 0.3:
        angle = np.random.uniform(-max_rot_deg, max_rot_deg)
        axes = tuple(np.random.choice([0, 1, 2], size=2, replace=False))
        volume = ndimage.rotate(volume, angle, axes=axes, reshape=False, order=1, mode='constant', cval=0.0)

    # Random Translation
    if np.random.rand() > 0.3:
        shifts = [np.random.uniform(-max_trans_fraction, max_trans_fraction) * s for s in volume.shape]
        volume = ndimage.shift(volume, shifts, order=1, mode='constant', cval=0.0)

    # Mild Gaussian Noise
    if np.random.rand() > 0.4:
        noise = np.random.normal(0, noise_std, volume.shape).astype(np.float32)
        volume = volume + noise * (volume > 0.05)

    return volume


def is_volume_unmasked(volume, threshold_ratio=0.03):
    """
    Robustly determines whether an MRI volume contains non-brain tissues (skull, scalp, neck).
    Inspects peripheral border voxels (15-voxel outer boundary margin).
    Already skull-stripped volumes have ~0% non-zero border voxels.
    Unmasked volumes with skull/scalp have >3% non-zero border voxels.
    """
    volume = np.squeeze(volume)
    if volume.ndim != 3 or np.min(volume.shape) < 32:
        return False

    border_mask = np.ones_like(volume, dtype=bool)
    border_mask[15:-15, 15:-15, 15:-15] = False

    v_max = np.max(volume)
    if v_max <= 0:
        return False

    border_nonzero_ratio = (volume[border_mask] > 0.05 * v_max).mean()
    return border_nonzero_ratio > threshold_ratio


def extract_brain_mask(volume):
    """
    Extracts a 3D brain mask to strip skull, scalp, and non-brain tissue.
    For atlas-registered volumes with shape (176, 208, 176), uses the calibrated
    OASIS T88 atlas brain template.
    For arbitrary shapes, uses automated Otsu thresholding + morphological cleanup
    (opening, largest connected component, hole filling, dilation).
    """
    # 1. Check for pre-calibrated atlas template
    models_dir = os.path.join(os.path.dirname(__file__), "..", "models")
    atlas_mask_path = os.path.join(models_dir, "oasis_atlas_brain_mask.npy")
    if volume.shape == (176, 208, 176) and os.path.exists(atlas_mask_path):
        atlas_mask = np.load(atlas_mask_path)
        if atlas_mask.shape == volume.shape:
            return atlas_mask

    # 2. Automated Otsu + morphological fallback
    p99 = np.percentile(volume[volume > 0], 99.5) if np.any(volume > 0) else 1.0
    v_norm = np.clip(volume / p99, 0, 1) if p99 > 0 else volume

    fg = v_norm[v_norm > 0.05]
    if len(fg) == 0:
        return np.ones_like(volume, dtype=bool)

    hist, bin_edges = np.histogram(fg, bins=128)
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
    w1 = np.cumsum(hist)
    w2 = np.cumsum(hist[::-1])[::-1]
    m1 = np.cumsum(hist * bin_centers) / w1
    m2 = (np.cumsum((hist * bin_centers)[::-1]) / w2[::-1])[::-1]
    variance = w1[:-1] * w2[1:] * (m1[:-1] - m2[1:]) ** 2
    otsu = bin_centers[np.argmax(variance)]

    # Brain tissue threshold
    thresh = otsu * 0.60
    tissue = v_norm > thresh
    struct = ndimage.generate_binary_structure(3, 1)
    opened = ndimage.binary_opening(tissue, structure=struct, iterations=3)

    labeled, num_features = ndimage.label(opened)
    if num_features == 0:
        return np.ones_like(volume, dtype=bool)

    sizes = ndimage.sum(opened, labeled, range(1, num_features + 1))
    largest_label = np.argmax(sizes) + 1
    brain_comp = (labeled == largest_label)
    filled = ndimage.binary_fill_holes(brain_comp)
    dilated = ndimage.binary_dilation(filled, structure=struct, iterations=2)
    return dilated


def preprocess_mri(mri_path, hdr_path=None, target_shape=(96, 96, 96),
                   normalize="zscore", is_train=False, debug=False):
    """
    Complete end-to-end 3D preprocessing pipeline for a single MRI volume.
    Standardizes orientation, applies automated brain extraction if unmasked,
    crops to brain tissue bounding box, resamples to target 3D shape, and normalizes intensity.
    Returns:
        torch.FloatTensor of shape (1, D, H, W)
    """
    # 1. Load volume (standardizes NIfTI to 'LAS' reference orientation)
    volume, affine, voxel_sizes = load_analyze_volume(mri_path, hdr_path, debug=debug)

    # 2. Check if volume requires skull stripping
    unmasked = is_volume_unmasked(volume)
    if unmasked:
        brain_mask = extract_brain_mask(volume)
        volume = volume * brain_mask
        if debug:
            mask_pct = (brain_mask.sum() / brain_mask.size) * 100
            coords = np.argwhere(brain_mask)
            bbox = (coords.min(axis=0), coords.max(axis=0)) if len(coords) > 0 else "empty"
            print(f"[PREPROCESS DEBUG] Brain extraction applied: mask={mask_pct:.1f}%, bbox={bbox}")
    elif debug:
        print("[PREPROCESS DEBUG] Volume is already skull-stripped (retaining native brain voxels)")

    # 3. Crop empty background padding around brain tissue
    cropped = crop_brain_nonzero(volume, margin=4)

    # 4. Resize to standardized 3D shape (96, 96, 96)
    resized = resize_volume_3d(cropped, target_shape=target_shape)

    # 5. Intensity normalization (z-score)
    normalized = normalize_intensity_volume(resized, method=normalize)

    if debug:
        print(f"[PREPROCESS DEBUG] Output tensor: shape={resized.shape}, range=[{normalized.min():.2f}, {normalized.max():.2f}], mean={normalized.mean():.4f}, std={normalized.std():.4f}")

    # 6. Data Augmentation (train split only)
    if is_train:
        normalized = augment_3d_volume(normalized)

    # 7. Convert to PyTorch Tensor: (Channels=1, D, H, W)
    tensor = torch.from_numpy(normalized.astype(np.float32)).unsqueeze(0)
    return tensor
