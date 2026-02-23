"""
rdc_training_sync.py — AI Training Set Sync
Finds files tagged _TRAIN_ (or TRAIN), copies only the latest version
to 00 - _AI-Training/ in the RDC2 root, removes stale copies.

CLI:  python rdc_training_sync.py "C:/RDC2" [--dry-run]
"""
import os
import re
import shutil
import argparse
from datetime import datetime
from pathlib import Path

SKIP_DIRS = {
    "_archive", ".tmp.driveupload", "$RECYCLE.BIN",
    ".git", "node_modules", "__pycache__"
}
SKIP_PREFIXES = ("~$",)
TRAIN_DIR_NAME = "00 - _AI-Training"

TRAIN_RE = re.compile(
    r'^(.+?)[\s_]TRAIN[\s_][vV](\d+)\.(\d+)(.*?)(\.[^.]+)$',
    re.IGNORECASE
)


def _parse_train(filename: str):
    m = TRAIN_RE.match(filename)
    if not m:
        return None
    base, major, minor, suffix, ext = m.groups()
    return {
        "base": base.strip(),
        "major": int(major),
        "minor": int(minor),
        "ext": ext.lower(),
        "sort_key": (int(major), int(minor)),
    }


def run_sync(root: str, dry_run: bool = False, log_callback=None):
    root = Path(root)
    log = log_callback or print
    train_dir = root / TRAIN_DIR_NAME
    log(f"{'[DRY RUN] ' if dry_run else ''}Syncing training files → {train_dir}\n")

    if not dry_run:
        train_dir.mkdir(exist_ok=True)

    # Collect all _TRAIN_ files grouped by (base, ext)
    groups = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames
                       if d not in SKIP_DIRS and Path(dirpath) / d != train_dir]
        for fname in filenames:
            if any(fname.startswith(p) for p in SKIP_PREFIXES):
                continue
            info = _parse_train(fname)
            if not info:
                continue
            key = (info["base"].lower(), info["ext"])
            groups.setdefault(key, []).append((info["sort_key"], Path(dirpath) / fname, info))

    manifest_lines = []
    files_added = 0
    files_removed = 0

    # For each group, copy only the latest version
    for key, versions in groups.items():
        versions.sort(key=lambda x: x[0], reverse=True)
        sort_key, src_path, info = versions[0]
        dest_name = src_path.name
        dest_path = train_dir / dest_name

        if not dest_path.exists() or src_path.stat().st_mtime > dest_path.stat().st_mtime:
            log(f"  ADD: {dest_name}")
            if not dry_run:
                shutil.copy2(str(src_path), str(dest_path))
            files_added += 1

        manifest_lines.append(f"{dest_name}  ←  {src_path}")

        # Remove stale older versions from train_dir
        for _, old_path, old_info in versions[1:]:
            stale = train_dir / old_path.name
            if stale.exists():
                log(f"  REMOVE stale: {stale.name}")
                if not dry_run:
                    stale.unlink()
                files_removed += 1

    # Write manifest
    if not dry_run:
        manifest_path = train_dir / "_manifest.txt"
        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(f"RDC AI Training Manifest — {datetime.now():%Y-%m-%d %H:%M}\n")
            f.write(f"Files: {len(manifest_lines)}\n\n")
            f.write("\n".join(manifest_lines))

    log(f"\nDone. {files_added} added, {files_removed} stale removed.")
    return files_added, files_removed, manifest_lines


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="RDC Training Set Sync")
    parser.add_argument("root", help="RDC2 root folder")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    run_sync(args.root, dry_run=args.dry_run)
