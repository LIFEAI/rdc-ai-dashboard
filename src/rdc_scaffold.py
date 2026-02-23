"""
rdc_scaffold.py — Build the RDC2 folder tree
Creates the standard 149-directory structure across all companies.

CLI:  python rdc_scaffold.py "C:/RDC2" [--dry-run]
"""
import os
import argparse
from pathlib import Path

STANDARD_SUBS = [
    "01-Corp-Legal",
    "02-Business-Dev",
    "03-Decks-Investor",
    "04-Marketing",
    "05-Research-Articles",
    "06-Projects",
    "07-Resumes-BIOs",
    "08-Vendors-Partners",
    "_archive",
]

COMPANIES = {
    "00 - _AI-Training":        [],
    "01 - RDC":                 STANDARD_SUBS + ["09-Platform-Models", "10-Website-Social"],
    "02 - The-Place-Fund":      STANDARD_SUBS + ["09-LP-Returns", "10-Dataroom"],
    "03 - Future-Places-SAAS":  STANDARD_SUBS + ["09-SaaS-Platform", "10-Dataroom"],
    "04 - Living-Building-Systems": STANDARD_SUBS + ["09-Engineering", "10-Dataroom"],
    "05 - Life-AI":             STANDARD_SUBS + ["09-AI-Exports", "10-Agents-Workflows"],
    "06 - Regen-Consulting":    STANDARD_SUBS,
    "07 - Division-Six":        STANDARD_SUBS,
    "08 - Demeter":             STANDARD_SUBS,
    "09 - SPIG":                STANDARD_SUBS,
    "10 - Regenity":            STANDARD_SUBS,
    "11 - Datarooms-Shared":    ["_archive"],
    "12 - FBI":                 STANDARD_SUBS,
    "13 - SSA":                 STANDARD_SUBS,
    "90 - Dave-IP":             STANDARD_SUBS,
    "97 - Uploads":             [],
    "98 - Code":                [
        "01-RDC-Dashboard",
        "02-Archive-Tools",
        "03-AI-Tools",
        "04-VB-Outlook",
        "05-VB-PowerPoint",
        "06-VB-Word",
        "07-Utilities",
        "_archive",
    ],
    "99 - Office-Tools":        ["_archive"],
}

README = """RDC2 File Naming Convention
============================
Format:  CompanyCode_Purpose_Type_VX.XX.ext

Company codes: RDC, TPF, FP, LBS, LifeAI, RC, D6, DEM, SPIG, REG
Types:         Deck, Exec_Sum, One_Pager, Overview, BizPlan, NDA, PPM
Training tag:  CompanyCode_Purpose_TRAIN_VX.XX.ext  (syncs to 00-AI-Training)
Archive:       Older versions auto-move to _archive/ via rdc_archive.py
"""


def build(root: str, dry_run: bool = False, log=print):
    root = Path(root)
    created = 0
    for company, subs in COMPANIES.items():
        co_path = root / company
        if not dry_run:
            co_path.mkdir(parents=True, exist_ok=True)
        else:
            log(f"  [DRY] mkdir {co_path}")
        created += 1
        for sub in subs:
            sub_path = co_path / sub
            if not dry_run:
                sub_path.mkdir(exist_ok=True)
            else:
                log(f"  [DRY] mkdir {sub_path}")
            created += 1
        # Drop README in company root
        readme_path = co_path / "_README.txt"
        if not dry_run and not readme_path.exists():
            readme_path.write_text(README, encoding="utf-8")
    log(f"\nScaffold complete: {created} directories {'(dry run)' if dry_run else 'created'}.")
    return created


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="RDC2 Scaffold Builder")
    parser.add_argument("root", help="Target root folder (e.g. C:/RDC2)")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    build(args.root, dry_run=args.dry_run)
