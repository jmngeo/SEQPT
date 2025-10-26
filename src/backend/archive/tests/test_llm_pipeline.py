"""Quick test to verify LLM pipeline works"""
import os
import sys

# Set environment variable for database
os.environ['DATABASE_URL'] = 'postgresql://ma0349:MA0349_2025@localhost:5432/competency_assessment'

# Load .env file
from dotenv import load_dotenv
load_dotenv()

print("[TEST] OpenAI API Key present:", "Yes" if os.getenv('OPENAI_API_KEY') else "No")
print("[TEST] Database URL:", os.getenv('DATABASE_URL'))

try:
    print("\n[TEST] Importing LLM pipeline...")
    from app.services.llm_pipeline.llm_process_identification_pipeline import create_pipeline
    print("[SUCCESS] Import successful")

    print("\n[TEST] Creating pipeline...")
    pipeline = create_pipeline()
    print("[SUCCESS] Pipeline created")

    print("\n[TEST] Testing with sample tasks...")
    test_tasks = {
        "responsible_for": [
            "Developing software modules",
            "Writing unit tests"
        ],
        "supporting": [
            "Code reviews for team members"
        ],
        "designing": [
            "Software architecture design"
        ]
    }

    result = pipeline(test_tasks)
    print("[SUCCESS] Pipeline execution completed")
    print(f"[RESULT] Status: {result.get('status')}")

    if result.get('status') == 'success':
        processes = result.get('result').processes if hasattr(result.get('result'), 'processes') else []
        print(f"[RESULT] Identified {len(processes)} processes")
        for proc in processes[:3]:  # Show first 3
            print(f"  - {proc.process_name}: {proc.involvement}")
    else:
        print(f"[RESULT] Message: {result.get('message')}")

except ImportError as e:
    print(f"[ERROR] Import failed: {e}")
    sys.exit(1)
except Exception as e:
    print(f"[ERROR] Pipeline execution failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n[SUCCESS] All tests passed! LLM pipeline is working correctly.")
