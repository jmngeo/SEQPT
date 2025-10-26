"""
PostgreSQL Database and User Rename Script
Safely renames the database and/or PostgreSQL user with backup
"""
import subprocess
import os
import sys
from pathlib import Path
from datetime import datetime

# Current credentials
CURRENT_DB_USER = "ma0349"
CURRENT_DB_PASSWORD = "MA0349_2025"
CURRENT_DB_NAME = "competency_assessment"
DB_HOST = "localhost"
DB_PORT = "5432"

# New credentials (user specified)
NEW_DB_USER = "seqpt_admin"
NEW_DB_PASSWORD = "SeQpt_2025"
NEW_DB_NAME = "seqpt_database"

def run_psql_command(command, user, password, database="postgres"):
    """Run a psql command"""
    env = os.environ.copy()
    env['PGPASSWORD'] = password

    try:
        result = subprocess.run([
            "psql",
            "-U", user,
            "-h", DB_HOST,
            "-p", DB_PORT,
            "-d", database,
            "-c", command
        ], env=env, check=True, capture_output=True, text=True)
        print(f"[SUCCESS] {result.stdout.strip()}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] {e.stderr}")
        return False

def create_backup():
    """Create backup before renaming"""
    print("\n" + "="*60)
    print("STEP 1: Creating backup before rename")
    print("="*60)

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = Path(__file__).parent.parent.parent / "backups"
    backup_dir.mkdir(exist_ok=True)

    backup_file = backup_dir / f"pre_rename_backup_{timestamp}.sql"

    env = os.environ.copy()
    env['PGPASSWORD'] = CURRENT_DB_PASSWORD

    print(f"Creating backup: {backup_file}")
    try:
        subprocess.run([
            "pg_dump",
            "-U", CURRENT_DB_USER,
            "-h", DB_HOST,
            "-p", DB_PORT,
            "-d", CURRENT_DB_NAME,
            "-f", str(backup_file)
        ], env=env, check=True, capture_output=True, text=True)
        print(f"[SUCCESS] Backup created: {backup_file}")
        return str(backup_file)
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Backup failed: {e.stderr}")
        return None

def create_new_user():
    """Create new PostgreSQL user"""
    print("\n" + "="*60)
    print("STEP 2: Creating new PostgreSQL user")
    print("="*60)

    # Use postgres superuser to create new user
    postgres_password = input("Enter postgres superuser password (or press Enter to skip): ").strip()
    if not postgres_password:
        postgres_password = "postgres"  # Try default

    print(f"Creating user: {NEW_DB_USER}")

    # Create user with password
    command = f"CREATE USER {NEW_DB_USER} WITH PASSWORD '{NEW_DB_PASSWORD}' CREATEDB;"
    if run_psql_command(command, "postgres", postgres_password):
        print(f"[SUCCESS] User {NEW_DB_USER} created")
        return True
    else:
        print("[WARNING] User creation failed - user might already exist")
        return False

def rename_database():
    """Rename the database"""
    print("\n" + "="*60)
    print("STEP 3: Renaming database")
    print("="*60)

    postgres_password = input("Enter postgres superuser password: ").strip()
    if not postgres_password:
        postgres_password = "postgres"

    # Disconnect all users from the database
    print(f"Disconnecting all users from {CURRENT_DB_NAME}...")
    disconnect_command = f"""
    SELECT pg_terminate_backend(pg_stat_activity.pid)
    FROM pg_stat_activity
    WHERE pg_stat_activity.datname = '{CURRENT_DB_NAME}'
    AND pid <> pg_backend_pid();
    """
    run_psql_command(disconnect_command, "postgres", postgres_password)

    # Rename database
    print(f"Renaming {CURRENT_DB_NAME} to {NEW_DB_NAME}...")
    rename_command = f"ALTER DATABASE {CURRENT_DB_NAME} RENAME TO {NEW_DB_NAME};"
    if run_psql_command(rename_command, "postgres", postgres_password):
        print(f"[SUCCESS] Database renamed to {NEW_DB_NAME}")
        return True
    else:
        print("[ERROR] Database rename failed")
        return False

def transfer_ownership():
    """Transfer database ownership to new user"""
    print("\n" + "="*60)
    print("STEP 4: Transferring ownership to new user")
    print("="*60)

    postgres_password = input("Enter postgres superuser password: ").strip()
    if not postgres_password:
        postgres_password = "postgres"

    # Grant all privileges
    print(f"Granting privileges to {NEW_DB_USER}...")
    commands = [
        f"ALTER DATABASE {NEW_DB_NAME} OWNER TO {NEW_DB_USER};",
        f"GRANT ALL PRIVILEGES ON DATABASE {NEW_DB_NAME} TO {NEW_DB_USER};",
    ]

    for command in commands:
        run_psql_command(command, "postgres", postgres_password)

    # Grant schema privileges
    print("Granting schema privileges...")
    env = os.environ.copy()
    env['PGPASSWORD'] = postgres_password

    schema_commands = f"""
    GRANT ALL PRIVILEGES ON SCHEMA public TO {NEW_DB_USER};
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO {NEW_DB_USER};
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO {NEW_DB_USER};
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO {NEW_DB_USER};
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO {NEW_DB_USER};
    """

    try:
        subprocess.run([
            "psql",
            "-U", "postgres",
            "-h", DB_HOST,
            "-p", DB_PORT,
            "-d", NEW_DB_NAME,
            "-c", schema_commands
        ], env=env, check=True, capture_output=True, text=True)
        print("[SUCCESS] Schema privileges granted")
    except subprocess.CalledProcessError as e:
        print(f"[WARNING] Schema privileges: {e.stderr}")

def update_env_file():
    """Update .env file with new credentials"""
    print("\n" + "="*60)
    print("STEP 5: Updating .env file")
    print("="*60)

    env_file = Path(__file__).parent.parent.parent / ".env"

    if not env_file.exists():
        print("[ERROR] .env file not found")
        return False

    # Read current .env
    with open(env_file, 'r') as f:
        content = f.read()

    # Create backup
    backup_env = env_file.parent / f".env.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    with open(backup_env, 'w') as f:
        f.write(content)
    print(f"[SUCCESS] .env backed up to {backup_env.name}")

    # Update DATABASE_URL
    old_url = f"postgresql://{CURRENT_DB_USER}:{CURRENT_DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{CURRENT_DB_NAME}"
    new_url = f"postgresql://{NEW_DB_USER}:{NEW_DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{NEW_DB_NAME}"

    updated_content = content.replace(old_url, new_url)

    with open(env_file, 'w') as f:
        f.write(updated_content)

    print(f"[SUCCESS] .env updated")
    print(f"Old: {old_url}")
    print(f"New: {new_url}")
    return True

def update_claude_md():
    """Update CLAUDE.md file with new credentials"""
    print("\n" + "="*60)
    print("STEP 6: Updating CLAUDE.md documentation")
    print("="*60)

    claude_md = Path.home() / ".claude" / "CLAUDE.md"

    if not claude_md.exists():
        print("[WARNING] CLAUDE.md file not found - skipping")
        return False

    # Read current CLAUDE.md
    with open(claude_md, 'r', encoding='utf-8') as f:
        content = f.read()

    # Create backup
    backup_claude = claude_md.parent / f"CLAUDE.md.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    with open(backup_claude, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"[SUCCESS] CLAUDE.md backed up to {backup_claude.name}")

    # Update all credential references
    old_url = f"postgresql://{CURRENT_DB_USER}:{CURRENT_DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{CURRENT_DB_NAME}"
    new_url = f"postgresql://{NEW_DB_USER}:{NEW_DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{NEW_DB_NAME}"

    # Replace DATABASE_URL
    updated_content = content.replace(old_url, new_url)

    # Replace individual credential mentions
    updated_content = updated_content.replace(
        f"**PostgreSQL** database: `{CURRENT_DB_NAME}`",
        f"**PostgreSQL** database: `{NEW_DB_NAME}`"
    )
    updated_content = updated_content.replace(
        f"**Actual credentials**: `{CURRENT_DB_USER}:{CURRENT_DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{CURRENT_DB_NAME}`",
        f"**Actual credentials**: `{NEW_DB_USER}:{NEW_DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{NEW_DB_NAME}`"
    )
    updated_content = updated_content.replace(
        f"DATABASE_URL={old_url}",
        f"DATABASE_URL={new_url}"
    )

    with open(claude_md, 'w', encoding='utf-8') as f:
        f.write(updated_content)

    print(f"[SUCCESS] CLAUDE.md updated")
    print(f"Updated database name: {CURRENT_DB_NAME} -> {NEW_DB_NAME}")
    print(f"Updated username: {CURRENT_DB_USER} -> {NEW_DB_USER}")
    return True

def main():
    print("="*60)
    print("PostgreSQL Database & User Rename Tool")
    print("="*60)
    print(f"\nCurrent configuration:")
    print(f"  Database: {CURRENT_DB_NAME}")
    print(f"  User:     {CURRENT_DB_USER}")
    print(f"\nNew configuration:")
    print(f"  Database: {NEW_DB_NAME}")
    print(f"  User:     {NEW_DB_USER}")
    print("\n" + "="*60)

    # Ask for confirmation
    print("\nWARNING: This will:")
    print("1. Create a backup of your current database")
    print("2. Create a new PostgreSQL user")
    print("3. Rename the database")
    print("4. Transfer ownership to the new user")
    print("5. Update your .env file")
    print("6. Update your CLAUDE.md documentation file")
    print("\nYou will need the postgres superuser password.\n")

    response = input("Continue? (yes/no): ").strip().lower()
    if response not in ['yes', 'y']:
        print("Aborted.")
        return

    # Execute steps
    backup_file = create_backup()
    if not backup_file:
        print("\n[ERROR] Backup failed. Aborting.")
        return

    if create_new_user():
        print("[INFO] New user created successfully")
    else:
        print("[INFO] Continuing with existing user")

    if not rename_database():
        print("\n[ERROR] Database rename failed. Aborting.")
        return

    transfer_ownership()

    env_updated = update_env_file()
    claude_updated = update_claude_md()

    if env_updated:
        print("\n" + "="*60)
        print("RENAME COMPLETE!")
        print("="*60)
        print("\nFiles updated:")
        print(f"  [OK] .env file")
        if claude_updated:
            print(f"  [OK] CLAUDE.md file")
        else:
            print(f"  [SKIP] CLAUDE.md file (not found or error)")
        print("\nNext steps:")
        print("1. Restart your Flask server")
        print("2. Test the connection")
        print(f"3. (Optional) Update utility scripts with hardcoded credentials")
        print(f"\nBackup location: {backup_file}")
        print("\nNOTE: Some utility scripts in src/backend/ have hardcoded")
        print("      credentials. See DATABASE_RENAME_CHECKLIST.md for details.")
    else:
        print("\n[ERROR] .env update failed")

if __name__ == "__main__":
    main()
