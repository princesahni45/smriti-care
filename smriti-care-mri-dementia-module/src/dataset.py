"""
PyTorch Dataset and Subject-Level Stratified Data Loaders for OASIS-1.
Guarantees:
- Zero data leakage: strict subject-level splitting (no subject in multiple splits)
- Class-weighted Cross-Entropy support computed strictly from the train split
- Optional WeightedRandomSampler for class balance
"""

import os
import csv
import numpy as np
import torch
from torch.utils.data import Dataset, DataLoader, WeightedRandomSampler
from sklearn.model_selection import train_test_split

from src.preprocessing import preprocess_mri
from src.data_validation import verify_split_leakage


class MRIVolumeDataset(Dataset):
    """
    PyTorch Dataset for 3D Brain MRI volumes.
    Loads and caches standardized 3D volumes (96x96x96) in data/processed/.
    Applies on-the-fly 3D augmentation during training.
    """
    def __init__(self, records, target_shape=(96, 96, 96), normalize="zscore", is_train=False, cache_dir="data/processed"):
        self.records = records
        self.target_shape = target_shape
        self.normalize = normalize
        self.is_train = is_train
        self.cache_dir = cache_dir
        if self.cache_dir:
            os.makedirs(self.cache_dir, exist_ok=True)

    def __len__(self):
        return len(self.records)

    def __getitem__(self, idx):
        row = self.records[idx]
        sess_id = row['session_id']
        label = int(row['label'])

        cache_file = os.path.join(self.cache_dir, f"{sess_id}_96.pt") if self.cache_dir else None

        if cache_file and os.path.exists(cache_file):
            tensor = torch.load(cache_file, weights_only=True)
        else:
            # Preprocess base volume without augmentation first
            tensor = preprocess_mri(
                row['mri_path'],
                hdr_path=row.get('hdr_path', None),
                target_shape=self.target_shape,
                normalize=self.normalize,
                is_train=False
            )
            if cache_file:
                torch.save(tensor, cache_file)

        # Apply data augmentation on training split
        if self.is_train:
            from src.preprocessing import augment_3d_volume
            vol_np = tensor.squeeze().numpy()
            vol_aug = augment_3d_volume(vol_np)
            tensor = torch.from_numpy(vol_aug.astype(np.float32)).unsqueeze(0)

        return {
            'image': tensor,
            'label': torch.tensor(label, dtype=torch.long),
            'subject_id': row['subject_id'],
            'session_id': row['session_id'],
            'cdr': row['cdr']
        }


def create_subject_splits(csv_path="data/metadata/mri_dataset.csv",
                          train_ratio=0.70, val_ratio=0.15, test_ratio=0.15,
                          random_seed=42):
    """
    Performs subject-level stratified splitting.
    Computes class weights from train split ONLY.
    """
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = list(csv.DictReader(f))

    # Keep only clinically labeled subjects for supervised training
    labeled_records = [r for r in reader if int(r['label']) >= 0]
    
    # Subject-level grouping
    subj_to_record = {}
    for r in labeled_records:
        subj = r['subject_id']
        if subj not in subj_to_record:
            subj_to_record[subj] = r

    subjects = list(subj_to_record.keys())
    labels = [int(subj_to_record[s]['label']) for s in subjects]

    # Stratified split: Train vs Temp (Val + Test)
    val_test_ratio = val_ratio + test_ratio
    train_subjs, temp_subjs, train_labels, temp_labels = train_test_split(
        subjects, labels,
        test_size=val_test_ratio,
        stratify=labels,
        random_state=random_seed
    )

    # Stratified split: Val vs Test (50/50 of temp)
    val_share = val_ratio / val_test_ratio
    # If temp_labels has minority class with only 1 sample, fallback to random split for temp
    try:
        val_subjs, test_subjs, _, _ = train_test_split(
            temp_subjs, temp_labels,
            test_size=(1.0 - val_share),
            stratify=temp_labels,
            random_state=random_seed
        )
    except ValueError:
        val_subjs, test_subjs = train_test_split(
            temp_subjs,
            test_size=(1.0 - val_share),
            random_state=random_seed
        )

    # Explicit Zero-Leakage Verification
    verify_split_leakage(train_subjs, val_subjs, test_subjs)

    # Assign records to splits
    train_records = [subj_to_record[s] for s in train_subjs]
    val_records = [subj_to_record[s] for s in val_subjs]
    test_records = [subj_to_record[s] for s in test_subjs]

    # Compute class weights strictly from the train split
    num_classes = 3
    train_label_counts = {c: 0 for c in range(num_classes)}
    for r in train_records:
        train_label_counts[int(r['label'])] += 1

    total_train = len(train_records)
    class_weights = []
    for c in range(num_classes):
        cnt = train_label_counts[c]
        if cnt > 0:
            # Inverse frequency: N / (num_classes * count)
            w = total_train / (num_classes * cnt)
        else:
            w = 1.0
        class_weights.append(w)
    class_weights_tensor = torch.tensor(class_weights, dtype=torch.float32)

    split_info = {
        'train_subjs': train_subjs,
        'val_subjs': val_subjs,
        'test_subjs': test_subjs,
        'train_counts': train_label_counts,
        'class_weights': class_weights
    }

    return train_records, val_records, test_records, class_weights_tensor, split_info


def get_data_loaders(config):
    """
    Constructs PyTorch DataLoaders for train, val, and test splits.
    """
    csv_path = config['paths']['dataset_csv']
    target_shape = tuple(config['preprocessing']['target_shape'])
    normalize = config['preprocessing']['normalize']
    batch_size = config['training']['batch_size']
    use_sampler = config['training'].get('use_weighted_sampler', True)

    train_recs, val_recs, test_recs, class_weights, split_info = create_subject_splits(
        csv_path=csv_path,
        train_ratio=config['split']['train_ratio'],
        val_ratio=config['split']['val_ratio'],
        test_ratio=config['split']['test_ratio'],
        random_seed=config['split']['random_seed']
    )

    train_dataset = MRIVolumeDataset(train_recs, target_shape=target_shape, normalize=normalize, is_train=True)
    val_dataset = MRIVolumeDataset(val_recs, target_shape=target_shape, normalize=normalize, is_train=False)
    test_dataset = MRIVolumeDataset(test_recs, target_shape=target_shape, normalize=normalize, is_train=False)

    if use_sampler:
        # Sample weights for train dataset
        sample_weights = [class_weights[int(r['label'])].item() for r in train_recs]
        sampler = WeightedRandomSampler(weights=sample_weights, num_samples=len(train_recs), replacement=True)
        train_loader = DataLoader(train_dataset, batch_size=batch_size, sampler=sampler, num_workers=0)
    else:
        train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True, num_workers=0)

    val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False, num_workers=0)
    test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False, num_workers=0)

    return train_loader, val_loader, test_loader, class_weights, split_info
