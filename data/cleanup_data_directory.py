#!/usr/bin/env python3
"""
SE-QPT Data Directory Cleanup Script
Safe reorganization and archiving of data files with rollback capability

Usage:
    python cleanup_data_directory.py --dry-run    # Preview changes
    python cleanup_data_directory.py --execute    # Execute cleanup
    python cleanup_data_directory.py --rollback   # Undo last cleanup

Author: SE-QPT Team
Date: 2025-10-26
"""

import os
import sys
import json
import shutil
import argparse
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Tuple

# Project root
PROJECT_ROOT = Path(__file__).parent.parent
DATA_DIR = Path(__file__).parent

# Backup directory for rollback
BACKUP_DIR = DATA_DIR / '.cleanup_backup'
MANIFEST_FILE = BACKUP_DIR / 'cleanup_manifest.json'


class DataDirectoryCleanup:
    """Safe cleanup and reorganization of data directory"""

    def __init__(self, dry_run: bool = True):
        self.dry_run = dry_run
        self.operations: List[Dict] = []
        self.backup_created = False

    def log(self, message: str, level: str = "INFO"):
        """Log a message"""
        prefix = {
            "INFO": "[INFO]",
            "WARN": "[WARNING]",
            "ERROR": "[ERROR]",
            "OK": "[OK]",
            "DRY": "[DRY-RUN]"
        }
        print(f"{prefix.get(level, '[INFO]')} {message}")

    def create_backup_manifest(self):
        """Create backup directory and manifest"""
        if self.dry_run:
            self.log("Would create backup manifest", "DRY")
            return

        BACKUP_DIR.mkdir(exist_ok=True)

        manifest = {
            'timestamp': datetime.now().isoformat(),
            'operations': self.operations,
            'project_root': str(PROJECT_ROOT),
            'data_dir': str(DATA_DIR)
        }

        with open(MANIFEST_FILE, 'w') as f:
            json.dump(manifest, f, indent=2)

        self.backup_created = True
        self.log(f"Backup manifest created: {MANIFEST_FILE}", "OK")

    def archive_file(self, source: Path, archive_subdir: str) -> bool:
        """
        Archive a file to archive subdirectory

        Args:
            source: Source file path (relative to DATA_DIR)
            archive_subdir: Subdirectory in archive/ (e.g., 'old_questionnaires')

        Returns:
            bool: Success status
        """
        source_path = DATA_DIR / source
        dest_path = DATA_DIR / 'archive' / archive_subdir / source_path.name

        if not source_path.exists():
            self.log(f"Source file does not exist: {source}", "WARN")
            return False

        operation = {
            'action': 'move',
            'source': str(source),
            'destination': str(Path('archive') / archive_subdir / source_path.name),
            'timestamp': datetime.now().isoformat()
        }

        if self.dry_run:
            self.log(f"Would move: {source} -> archive/{archive_subdir}/", "DRY")
            self.operations.append(operation)
            return True

        # Create destination directory
        dest_path.parent.mkdir(parents=True, exist_ok=True)

        # Move file
        shutil.move(str(source_path), str(dest_path))
        self.operations.append(operation)
        self.log(f"Moved: {source} -> {dest_path.relative_to(DATA_DIR)}", "OK")

        return True

    def delete_file(self, file_path: Path) -> bool:
        """
        Delete a file (with backup)

        Args:
            file_path: File path relative to DATA_DIR

        Returns:
            bool: Success status
        """
        full_path = DATA_DIR / file_path

        if not full_path.exists():
            self.log(f"File does not exist: {file_path}", "WARN")
            return False

        operation = {
            'action': 'delete',
            'source': str(file_path),
            'backup_content': None,
            'timestamp': datetime.now().isoformat()
        }

        if self.dry_run:
            self.log(f"Would delete: {file_path}", "DRY")
            self.operations.append(operation)
            return True

        # Backup content before delete
        if full_path.stat().st_size < 10 * 1024 * 1024:  # Only backup if < 10MB
            with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
                try:
                    operation['backup_content'] = f.read()
                except:
                    operation['backup_content'] = None

        # Delete
        full_path.unlink()
        self.operations.append(operation)
        self.log(f"Deleted: {file_path}", "OK")

        return True

    def validate_critical_files(self) -> bool:
        """
        Validate that critical runtime files still exist

        Returns:
            bool: True if all critical files exist
        """
        critical_files = [
            'processed/archetype_competency_matrix.json',
            'source/templates/learning_objectives_guidelines.json',
            'processed/se_foundation_data.json',
            'processed/standard_learning_objectives.json',
            'rag_vectordb/chroma.sqlite3'
        ]

        all_exist = True
        for file in critical_files:
            file_path = DATA_DIR / file
            if not file_path.exists():
                self.log(f"CRITICAL FILE MISSING: {file}", "ERROR")
                all_exist = False
            else:
                self.log(f"Critical file verified: {file}", "OK")

        return all_exist

    def perform_cleanup(self):
        """Perform the cleanup operations"""
        self.log("=" * 80)
        self.log("SE-QPT DATA DIRECTORY CLEANUP")
        self.log("=" * 80)

        if self.dry_run:
            self.log("DRY RUN MODE - No changes will be made", "DRY")
        else:
            self.log("EXECUTE MODE - Changes will be made", "WARN")

        # Step 1: Create archive directories
        archive_dirs = ['old_questionnaires', 'phase1_development', 'corrected_versions']
        for dir_name in archive_dirs:
            dir_path = DATA_DIR / 'archive' / dir_name
            if self.dry_run:
                self.log(f"Would create directory: archive/{dir_name}", "DRY")
            else:
                dir_path.mkdir(parents=True, exist_ok=True)
                self.log(f"Created directory: archive/{dir_name}", "OK")

        # Step 2: Archive old questionnaire backups
        self.log("\nArchiving old questionnaire backups...")
        old_questionnaires = [
            'source/questionnaires/phase1/archetype_selection_backup_old.json',
            'source/questionnaires/phase1/maturity_assessment_backup_old.json'
        ]

        for file in old_questionnaires:
            file_path = Path(file)
            if (DATA_DIR / file_path).exists():
                self.log(f"File already moved to archive: {file}", "INFO")
            else:
                self.log(f"File not found (may already be archived): {file}", "INFO")

        # Step 3: Validate critical files
        self.log("\nValidating critical runtime files...")
        if not self.validate_critical_files():
            self.log("CRITICAL FILES MISSING - ABORTING CLEANUP", "ERROR")
            return False

        # Step 4: Create backup manifest
        if not self.dry_run:
            self.create_backup_manifest()

        # Step 5: Summary
        self.log("\n" + "=" * 80)
        self.log("CLEANUP SUMMARY")
        self.log("=" * 80)
        self.log(f"Total operations: {len(self.operations)}")

        if self.dry_run:
            self.log("\nThis was a DRY RUN. No changes were made.", "DRY")
            self.log("Run with --execute to apply changes.", "INFO")
        else:
            self.log("\nCleanup completed successfully!", "OK")
            if self.backup_created:
                self.log(f"Backup manifest saved: {MANIFEST_FILE}", "OK")
                self.log("To rollback, run: python cleanup_data_directory.py --rollback", "INFO")

        return True

    def rollback(self):
        """Rollback last cleanup operation"""
        if not MANIFEST_FILE.exists():
            self.log("No backup manifest found. Nothing to rollback.", "ERROR")
            return False

        with open(MANIFEST_FILE, 'r') as f:
            manifest = json.load(f)

        self.log("=" * 80)
        self.log("ROLLBACK CLEANUP")
        self.log("=" * 80)
        self.log(f"Backup from: {manifest['timestamp']}")
        self.log(f"Operations to reverse: {len(manifest['operations'])}")

        # Reverse operations in reverse order
        for op in reversed(manifest['operations']):
            if op['action'] == 'move':
                # Move back
                source = DATA_DIR / op['destination']
                dest = DATA_DIR / op['source']

                if source.exists():
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    shutil.move(str(source), str(dest))
                    self.log(f"Restored: {op['source']}", "OK")
                else:
                    self.log(f"Source file missing, cannot restore: {op['destination']}", "WARN")

            elif op['action'] == 'delete':
                # Restore from backup content
                if op['backup_content']:
                    dest = DATA_DIR / op['source']
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    with open(dest, 'w', encoding='utf-8') as f:
                        f.write(op['backup_content'])
                    self.log(f"Restored: {op['source']}", "OK")
                else:
                    self.log(f"No backup content for: {op['source']}", "WARN")

        # Remove backup manifest
        MANIFEST_FILE.unlink()
        self.log("\nRollback completed!", "OK")

        return True


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='SE-QPT Data Directory Cleanup Script',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Preview changes without executing them (default)'
    )

    parser.add_argument(
        '--execute',
        action='store_true',
        help='Execute the cleanup operations'
    )

    parser.add_argument(
        '--rollback',
        action='store_true',
        help='Rollback the last cleanup operation'
    )

    args = parser.parse_args()

    # Default to dry-run if no mode specified
    if not (args.execute or args.rollback):
        args.dry_run = True

    if args.rollback:
        cleanup = DataDirectoryCleanup(dry_run=False)
        cleanup.rollback()
    else:
        cleanup = DataDirectoryCleanup(dry_run=not args.execute)
        cleanup.perform_cleanup()


if __name__ == '__main__':
    main()
