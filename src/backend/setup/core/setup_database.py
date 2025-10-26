#!/usr/bin/env python3
"""
Database Setup Script for SE-QPT Platform
Creates PostgreSQL database and initializes tables with sample data
"""

import os
import sys
import subprocess
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

def check_postgresql():
    """Check if PostgreSQL is installed and accessible"""
    try:
        result = subprocess.run(['psql', '--version'], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✓ PostgreSQL found: {result.stdout.strip()}")
            return True
        else:
            print("✗ PostgreSQL not found in PATH")
            return False
    except FileNotFoundError:
        print("✗ PostgreSQL not installed or not in PATH")
        return False

def create_database():
    """Create SE-QPT database and user"""
    try:
        # Connect to PostgreSQL default database
        conn = psycopg2.connect(
            host='localhost',
            port=5432,
            user='postgres',  # Default superuser
            database='postgres'
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()

        # Check if database exists
        cursor.execute("SELECT 1 FROM pg_catalog.pg_database WHERE datname = 'seqpt'")
        exists = cursor.fetchone()

        if not exists:
            print("Creating SE-QPT database...")
            cursor.execute("CREATE DATABASE seqpt")
            print("✓ Database 'seqpt' created")
        else:
            print("✓ Database 'seqpt' already exists")

        # Check if user exists
        cursor.execute("SELECT 1 FROM pg_roles WHERE rolname = 'seqpt_user'")
        user_exists = cursor.fetchone()

        if not user_exists:
            print("Creating SE-QPT user...")
            cursor.execute("CREATE USER seqpt_user WITH PASSWORD 'seqpt_pass'")
            print("✓ User 'seqpt_user' created")
        else:
            print("✓ User 'seqpt_user' already exists")

        # Grant privileges
        cursor.execute("GRANT ALL PRIVILEGES ON DATABASE seqpt TO seqpt_user")
        print("✓ Privileges granted to seqpt_user")

        cursor.close()
        conn.close()
        return True

    except psycopg2.Error as e:
        print(f"✗ Database creation failed: {e}")
        return False
    except Exception as e:
        print(f"✗ Unexpected error: {e}")
        return False

def setup_environment():
    """Set up environment variables"""
    env_vars = {
        'DATABASE_URL': 'postgresql://seqpt_user:seqpt_pass@localhost:5432/seqpt',
        'SECRET_KEY': 'dev-secret-key-change-in-production',
        'JWT_SECRET_KEY': 'jwt-secret-string',
        'FLASK_APP': 'run.py',
        'FLASK_ENV': 'development'
    }

    # Check if .env file exists
    env_file = os.path.join(os.path.dirname(__file__), '..', '..', '.env')

    if os.path.exists(env_file):
        print("✓ .env file already exists")
    else:
        print("Creating .env file...")
        with open(env_file, 'w') as f:
            for key, value in env_vars.items():
                f.write(f"{key}={value}\n")
        print("✓ .env file created")

def run_migrations():
    """Run Flask-Migrate to create tables"""
    try:
        os.chdir(os.path.dirname(__file__))

        # Initialize Flask-Migrate (if not already done)
        result = subprocess.run(['python', '-m', 'flask', 'db', 'init'],
                              capture_output=True, text=True)
        if result.returncode == 0:
            print("✓ Flask-Migrate initialized")
        else:
            print("✓ Flask-Migrate already initialized")

        # Create initial migration
        result = subprocess.run(['python', '-m', 'flask', 'db', 'migrate', '-m', 'Initial migration'],
                              capture_output=True, text=True)
        if result.returncode == 0:
            print("✓ Initial migration created")
        else:
            print(f"Migration creation: {result.stderr}")

        # Apply migrations
        result = subprocess.run(['python', '-m', 'flask', 'db', 'upgrade'],
                              capture_output=True, text=True)
        if result.returncode == 0:
            print("✓ Migrations applied successfully")
            return True
        else:
            print(f"✗ Migration failed: {result.stderr}")
            return False

    except Exception as e:
        print(f"✗ Migration error: {e}")
        return False

def initialize_data():
    """Initialize database with ALL required data using master script"""
    try:
        os.chdir(os.path.dirname(__file__))

        print("\n" + "=" * 50)
        print("IMPORTANT: Data Initialization")
        print("=" * 50)
        print("\nSE-QPT requires critical matrix data to function.")
        print("This includes:")
        print("  - Process-Competency Matrix (GLOBAL)")
        print("  - Role-Process Matrix for Org 1 (TEMPLATE)")
        print("\nWe will now run the master initialization script.")
        print("This is REQUIRED - without it, the system will not work!")

        response = input("\nRun master data initialization now? (yes/no): ")
        if response.lower() != 'yes':
            print("\n[WARNING] Skipping data initialization!")
            print("You must run this manually later:")
            print("  cd src/backend")
            print("  python initialize_all_data.py")
            return False

        # Run the master initialization script
        result = subprocess.run(['python', 'initialize_all_data.py'],
                              capture_output=True, text=True)
        if result.returncode == 0:
            print("\n✓ Data initialization completed successfully")
            if result.stdout:
                # Print last 30 lines to show summary
                lines = result.stdout.strip().split('\n')
                print('\n'.join(lines[-30:]))
            return True
        else:
            print(f"\n✗ Data initialization failed!")
            if result.stderr:
                print("Error output:")
                print(result.stderr)
            if result.stdout:
                print("Standard output:")
                print(result.stdout)
            return False
    except Exception as e:
        print(f"✗ Data initialization error: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Main setup process"""
    print("SE-QPT Database Setup")
    print("=" * 50)

    # Check prerequisites
    if not check_postgresql():
        print("\nPlease install PostgreSQL and ensure it's in your PATH")
        print("Download from: https://www.postgresql.org/download/")
        return False

    # Setup environment
    setup_environment()

    # Create database
    if not create_database():
        return False

    # Run migrations
    if not run_migrations():
        return False

    # Initialize data
    if not initialize_data():
        return False

    print("\n" + "=" * 50)
    print("✓ SE-QPT Database setup completed successfully!")
    print("\nDatabase connection details:")
    print("  Host: localhost")
    print("  Port: 5432")
    print("  Database: seqpt")
    print("  Username: seqpt_user")
    print("  Password: seqpt_pass")
    print("\nYou can now start the backend server with:")
    print("  cd src/backend")
    print("  python run.py")

    return True

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)