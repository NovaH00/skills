#!/usr/bin/env python3
"""Manage experiment run artifacts and lineage for LaTeX papers.

Tracks which experiment runs produced the figures and tables in the paper/ directory.
Records artifact checksums, source paths, git commits, and metadata in paper/runs.json
using only the Python standard library with zero external dependencies.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def calculate_sha256(file_path: Path) -> str:
    """Calculate the SHA256 checksum of a file."""
    hasher = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest()


def load_runs_manifest(manifest_path: Path) -> dict[str, Any]:
    """Load the runs.json manifest file."""
    if not manifest_path.exists():
        return {"runs": {}}

    content = manifest_path.read_text(encoding="utf-8")
    if not content.strip():
        return {"runs": {}}

    try:
        data = json.loads(content)
    except json.JSONDecodeError as e:
        print(f"Error parsing {manifest_path}: {e}", file=sys.stderr)
        return {"runs": {}}

    if not isinstance(data, dict):
        return {"runs": {}}
    if "runs" not in data or not isinstance(data["runs"], dict):
        data["runs"] = {}
    return data


def save_runs_manifest(manifest_path: Path, data: dict[str, Any]) -> None:
    """Save formatted data to runs.json."""
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def get_paper_root() -> Path:
    """Locate the paper directory from current working tree."""
    cwd = Path.cwd()
    if (cwd / "paper").is_dir():
        return cwd / "paper"
    if (cwd / "main.tex").is_file():
        return cwd
    # Default to ./paper
    return cwd / "paper"


def cmd_import(args: argparse.Namespace) -> int:
    """Import figures or tables from an experiment run into the paper."""
    paper_dir = Path(args.paper_dir).resolve() if args.paper_dir else get_paper_root().resolve()
    manifest_path = paper_dir / "runs.json"

    source_dir = Path(args.source).resolve()
    if not source_dir.exists():
        print(f"Error: Source directory does not exist: {source_dir}", file=sys.stderr)
        return 1

    dest_folder = paper_dir / args.category
    dest_folder.mkdir(parents=True, exist_ok=True)

    manifest = load_runs_manifest(manifest_path)
    run_entry = manifest["runs"].setdefault(args.run_id, {
        "description": args.notes or "",
        "source_dir": str(source_dir),
        "imported_at": datetime.now(timezone.utc).isoformat(),
        "git_commit": args.commit or "",
        "artifacts": [],
    })

    if args.notes:
        run_entry["description"] = args.notes
    if args.commit:
        run_entry["git_commit"] = args.commit

    imported_files: list[str] = []
    for file_pattern in args.files:
        matches = list(source_dir.glob(file_pattern)) if any(char in file_pattern for char in "*?[]") else [source_dir / file_pattern]
        
        for src_file in matches:
            if not src_file.is_file():
                print(f"Warning: File not found: {src_file}", file=sys.stderr)
                continue

            target_filename = src_file.name
            target_path = dest_folder / target_filename
            shutil.copy2(src_file, target_path)

            checksum = calculate_sha256(target_path)
            rel_dest_path = f"{args.category}/{target_filename}"

            # Update artifact list in run entry
            existing = [item for item in run_entry["artifacts"] if item.get("path") == rel_dest_path]
            if existing:
                existing[0]["sha256"] = checksum
                existing[0]["source_file"] = str(src_file)
                existing[0]["updated_at"] = datetime.now(timezone.utc).isoformat()
            else:
                run_entry["artifacts"].append({
                    "path": rel_dest_path,
                    "source_file": str(src_file),
                    "sha256": checksum,
                    "imported_at": datetime.now(timezone.utc).isoformat(),
                })
            imported_files.append(rel_dest_path)

    save_runs_manifest(manifest_path, manifest)
    print(f"Successfully recorded run '{args.run_id}' with {len(imported_files)} artifact(s) in {manifest_path.name}:")
    for f in imported_files:
        print(f"  - {f}")
    return 0


def cmd_list(args: argparse.Namespace) -> int:
    """List all registered runs and their mapped artifacts."""
    paper_dir = Path(args.paper_dir).resolve() if args.paper_dir else get_paper_root().resolve()
    manifest_path = paper_dir / "runs.json"

    if not manifest_path.exists():
        print(f"No runs manifest found at {manifest_path}")
        return 0

    manifest = load_runs_manifest(manifest_path)
    runs = manifest.get("runs", {})
    if not runs:
        print("No runs recorded yet.")
        return 0

    print(f"Experiment Runs in {manifest_path.relative_to(Path.cwd()) if manifest_path.is_relative_to(Path.cwd()) else manifest_path}:")
    print("=" * 70)
    for run_id, info in runs.items():
        desc = info.get("description", "No description")
        commit = info.get("git_commit", "N/A")
        artifacts = info.get("artifacts", [])
        print(f"\nRun ID: {run_id}")
        print(f"  Description: {desc}")
        print(f"  Commit:      {commit}")
        print(f"  Source Dir:  {info.get('source_dir', 'Unknown')}")
        print(f"  Artifacts ({len(artifacts)}):")
        for art in artifacts:
            print(f"    - {art.get('path')} (sha256: {art.get('sha256', '')[:8]}...)")
    print("=" * 70)
    return 0


def cmd_verify(args: argparse.Namespace) -> int:
    """Verify that all paper figures and tables match recorded runs."""
    paper_dir = Path(args.paper_dir).resolve() if args.paper_dir else get_paper_root().resolve()
    manifest_path = paper_dir / "runs.json"

    if not manifest_path.exists():
        print(f"Error: Manifest not found: {manifest_path}", file=sys.stderr)
        return 1

    manifest = load_runs_manifest(manifest_path)
    registered_artifacts: dict[str, str] = {}
    for run_id, run_data in manifest.get("runs", {}).items():
        for art in run_data.get("artifacts", []):
            registered_artifacts[art.get("path")] = art.get("sha256")

    has_issues = False

    # Check files on disk
    for category in ["figures", "tables"]:
        cat_dir = paper_dir / category
        if not cat_dir.is_dir():
            continue
        for file_path in cat_dir.glob("**/*"):
            if file_path.is_file() and not file_path.name.startswith("."):
                rel_path = f"{category}/{file_path.relative_to(cat_dir)}"
                if rel_path not in registered_artifacts:
                    print(f"[UNTRACKED] {rel_path}: file exists on disk but has no run recorded in runs.json")
                    has_issues = True
                else:
                    curr_hash = calculate_sha256(file_path)
                    expected_hash = registered_artifacts[rel_path]
                    if curr_hash != expected_hash:
                        print(f"[MODIFIED]  {rel_path}: current hash ({curr_hash[:8]}) does not match manifest ({expected_hash[:8]})")
                        has_issues = True
                    else:
                        if args.verbose:
                            print(f"[OK]        {rel_path}: matches recorded hash")

    # Check missing files
    for rel_path in registered_artifacts:
        target_path = paper_dir / rel_path
        if not target_path.exists():
            print(f"[MISSING]   {rel_path}: recorded in runs.json but missing from disk")
            has_issues = True

    if not has_issues:
        print("Provenance verification passed: all artifacts match recorded runs cleanly.")
        return 0
    else:
        print("\nProvenance verification warnings found above.", file=sys.stderr)
        return 1


def main() -> None:
    parser = argparse.ArgumentParser(description="Manage experiment run artifacts for LaTeX papers.")
    parser.add_argument("--paper-dir", help="Path to the paper root directory (default: ./paper)")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # import
    p_import = subparsers.add_parser("import", help="Import artifacts from an experiment run")
    p_import.add_argument("--run-id", required=True, help="Unique identifier for the experiment run")
    p_import.add_argument("--source", required=True, help="Directory containing experiment output")
    p_import.add_argument("--files", nargs="+", required=True, help="File names or glob patterns to copy")
    p_import.add_argument("--category", choices=["figures", "tables"], default="figures", help="Target subfolder")
    p_import.add_argument("--notes", help="Short description of this experiment run")
    p_import.add_argument("--commit", help="Git commit hash of the code used to generate the run")
    p_import.set_defaults(func=cmd_import)

    # list
    p_list = subparsers.add_parser("list", help="List registered runs and artifacts")
    p_list.set_defaults(func=cmd_list)

    # verify
    p_verify = subparsers.add_parser("verify", help="Verify artifacts against manifest checksums")
    p_verify.add_argument("-v", "--verbose", action="store_true", help="Print verified files")
    p_verify.set_defaults(func=cmd_verify)

    args = parser.parse_args()
    sys.exit(args.func(args))


if __name__ == "__main__":
    main()
