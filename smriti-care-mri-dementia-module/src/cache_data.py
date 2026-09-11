"""
Pre-cache all clinically labeled MRI scans into data/processed/
"""
import os
import sys
import csv
import torch

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.preprocessing import preprocess_mri
from src.utils import load_config


def cache_all_labeled():
    cfg = load_config('config.yaml')
    os.makedirs(cfg['paths']['processed_dir'], exist_ok=True)
    with open(cfg['paths']['dataset_csv'], 'r', encoding='utf-8') as f:
        records = [r for r in csv.DictReader(f) if int(r['label']) >= 0]

    print(f"Total labeled scans to verify/cache: {len(records)}")
    newly_cached = 0
    already_cached = 0

    for idx, r in enumerate(records, 1):
        sess = r['session_id']
        cache_file = os.path.join(cfg['paths']['processed_dir'], f"{sess}_96.pt")
        if os.path.exists(cache_file):
            already_cached += 1
        else:
            tensor = preprocess_mri(
                r['mri_path'],
                hdr_path=r.get('hdr_path'),
                target_shape=tuple(cfg['preprocessing']['target_shape']),
                normalize=cfg['preprocessing']['normalize'],
                is_train=False
            )
            torch.save(tensor, cache_file)
            newly_cached += 1
            print(f"  [{idx}/{len(records)}] Processed and cached: {sess}")

    print(f"Pre-caching complete! Already cached: {already_cached}, Newly cached: {newly_cached}, Total: {len(records)}")


if __name__ == '__main__':
    cache_all_labeled()
