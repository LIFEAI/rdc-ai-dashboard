"""
rdc_archive.py — Version archive utility
Scans a folder tree, groups files by base-name + extension,
keeps the highest version, moves older versions to _archive/.

Naming convention supported:
    CompanyCode_Purpose_Type_V1.23.ext
    Project Name v1.2.ext
    project_name_v1.2.ext

CLI:  python rdc_archive.py "C:/RDC2" [--dry-run]
"""
import os
import re
import shutil
import argparse
from datetime import datetime
from pathlib import Path

SKIP_DIRS = {
    "_archive", ".tmp.driveupload", "$RECYCLE.BIN",
    ".git", "node_modules", "__pycache__", ".trash"
}
SKIP_PREFIXES = ("~$",)

# Matches:  basename [space or _] v  major . minor  [suffix] .ext
VERSION_RE = re.compile(
    r'^(.+?)[\s_]+[vV](\d+)\.(\d+)(.*?)(\.[^.]+)$'
)


def _parse_version(filename: str):
    m = VERSION_RE.match(filename)
    if not m:
        return None
    base, major, minor, suffix, ext = m.groups()
    return {
        "base": base.strip(),
        "major": int(major),
        "minor": int(minor),
        "suffix": suffix,
        "ext": ext.lower(),
        "sort_key": (int(major), int(minor)),
    }


def run_archive(root: str, dry_run: bool = False, log_callback=None):
    root = Path(root)
    log = log_callback or print
    moved = 0
    skipped = 0
    log(f"{'[DRY RUN] ' if dry_run else ''}Scanning: {root}\n")

    for dirpath, dirnames, filenames in os.walk(root):
        # Prune skip dirs in-place
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]

        groups = {}
        for fname in filenames:
            if any(fname.startswith(p) for p in SKIP_PREFIXES):
                continue
            info = _parse_version(fname)
            if not info:
                continue
            key = (info["base"].lower(), info["ext"])
            groups.setdefault(key, []).append((info["sort_key"], fname, info))

        for key, versions in groups.items():
            if len(versions) < 2:
                continue
            versions.sort(key=lambda x: x[0], reverse=True)
            latest = versions[0][1]
            older = [v[1] for v in versions[1:]]

            archive_dir = Path(dirpath) / "_archive"
            if not dry_run:
                archive_dir.mkdir(exist_ok=True)

            for old_file in older:
                src = Path(dirpath) / old_file
                dst = archive_dir / old_file
                log(f"  ARCHIVE: {old_file}  →  _archive/")
                if not dry_run:
                    shutil.move(str(src), str(dst))
                moved += 1

    # Write log file
    if not dry_run:
        log_path = root / "_archive_log.txt"
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(f"\n[{datetime.now():%Y-%m-%d %H:%M}] Archived {moved} files\n")

    log(f"\nDone. {moved} files archived, {skipped} skipped.")
    return moved


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="RDC Version Archiver")
    parser.add_argument("root", help="Root folder to scan")
    parser.add_argument("--dry-run", action="store_true", help="Preview only, no moves")
    args = parser.parse_args()
    run_archive(args.root, dry_run=args.dry_run)
