"""
PostgreSQL Database Backup Script
Creates timestamped backups of the competency_assessment database
"""
import subprocess
import os
from datetime import datetime
from pathlib import Path

# Configuration
DB_USER = "ma0349"
DB_PASSWORD = "MA0349_2025"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "competency_assessment"

# Backup directory
BACKUP_DIR = Path(__file__).parent.parent.parent / "backups"
BACKUP_DIR.mkdir(exist_ok=True)

def create_backup():
    """Create a timestamped backup of the database"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    # SQL format (human-readable, can be version controlled)
    sql_backup_file = BACKUP_DIR / f"competency_assessment_{timestamp}.sql"

    # Custom format (compressed, faster restore)
    dump_backup_file = BACKUP_DIR / f"competency_assessment_{timestamp}.dump"

    # Set password environment variable
    env = os.environ.copy()
    env['PGPASSWORD'] = DB_PASSWORD

    print(f"Creating SQL backup: {sql_backup_file}")
    try:
        subprocess.run([
            "pg_dump",
            "-U", DB_USER,
            "-h", DB_HOST,
            "-p", DB_PORT,
            "-d", DB_NAME,
            "-f", str(sql_backup_file)
        ], env=env, check=True, capture_output=True, text=True)
        print(f"[SUCCESS] SQL backup created: {sql_backup_file}")
        print(f"Size: {sql_backup_file.stat().st_size / 1024:.2f} KB")
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] SQL backup failed: {e.stderr}")
        return False

    print(f"\nCreating compressed backup: {dump_backup_file}")
    try:
        subprocess.run([
            "pg_dump",
            "-U", DB_USER,
            "-h", DB_HOST,
            "-p", DB_PORT,
            "-Fc",  # Custom format (compressed)
            "-d", DB_NAME,
            "-f", str(dump_backup_file)
        ], env=env, check=True, capture_output=True, text=True)
        print(f"[SUCCESS] Compressed backup created: {dump_backup_file}")
        print(f"Size: {dump_backup_file.stat().st_size / 1024:.2f} KB")
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Compressed backup failed: {e.stderr}")
        return False

    # List all backups
    print("\nAll backups in directory:")
    backups = sorted(BACKUP_DIR.glob("competency_assessment_*"))
    for backup in backups:
        size_kb = backup.stat().st_size / 1024
        print(f"  {backup.name} ({size_kb:.2f} KB)")

    return True

def list_backups():
    """List all available backups"""
    backups = sorted(BACKUP_DIR.glob("competency_assessment_*"))
    if not backups:
        print("No backups found.")
        return []

    print("Available backups:")
    for i, backup in enumerate(backups, 1):
        size_kb = backup.stat().st_size / 1024
        mtime = datetime.fromtimestamp(backup.stat().st_mtime)
        print(f"  {i}. {backup.name}")
        print(f"     Size: {size_kb:.2f} KB | Modified: {mtime}")

    return backups

def restore_backup(backup_file):
    """Restore from a backup file"""
    backup_path = Path(backup_file)

    if not backup_path.exists():
        print(f"[ERROR] Backup file not found: {backup_file}")
        return False

    env = os.environ.copy()
    env['PGPASSWORD'] = DB_PASSWORD

    print(f"[WARNING] This will overwrite the current database!")
    print(f"Restoring from: {backup_path.name}")

    # Determine backup format
    if backup_path.suffix == '.sql':
        print("Detected SQL format backup")
        try:
            subprocess.run([
                "psql",
                "-U", DB_USER,
                "-h", DB_HOST,
                "-p", DB_PORT,
                "-d", DB_NAME,
                "-f", str(backup_path)
            ], env=env, check=True, capture_output=True, text=True)
            print("[SUCCESS] Database restored from SQL backup")
        except subprocess.CalledProcessError as e:
            print(f"[ERROR] Restore failed: {e.stderr}")
            return False

    elif backup_path.suffix == '.dump':
        print("Detected custom format backup")
        try:
            subprocess.run([
                "pg_restore",
                "-U", DB_USER,
                "-h", DB_HOST,
                "-p", DB_PORT,
                "-d", DB_NAME,
                "-c",  # Clean (drop) database objects before recreating
                str(backup_path)
            ], env=env, check=True, capture_output=True, text=True)
            print("[SUCCESS] Database restored from compressed backup")
        except subprocess.CalledProcessError as e:
            print(f"[ERROR] Restore failed: {e.stderr}")
            return False

    return True

if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        command = sys.argv[1]

        if command == "backup":
            create_backup()

        elif command == "list":
            list_backups()

        elif command == "restore":
            if len(sys.argv) < 3:
                print("Usage: python backup_database.py restore <backup_file>")
                list_backups()
            else:
                backup_file = sys.argv[2]
                # If it's just a filename, look in BACKUP_DIR
                if not os.path.isabs(backup_file):
                    backup_file = BACKUP_DIR / backup_file
                restore_backup(backup_file)

        else:
            print(f"Unknown command: {command}")
            print("Usage: python backup_database.py [backup|list|restore]")

    else:
        # Default: create backup
        create_backup()
