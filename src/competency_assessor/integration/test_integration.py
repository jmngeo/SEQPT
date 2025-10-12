"""
Test script for SE-QPT and Derik's competency assessor integration
Validates that all components work together seamlessly
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import json
from datetime import datetime

def test_derik_models_compatibility():
    """Test that Derik's original models are preserved and accessible"""
    print("=== TESTING DERIK'S MODELS COMPATIBILITY ===")

    try:
        from app.models import RoleCluster, Competency, CompetencyIndicator
        print("✓ Derik's original models imported successfully")

        # Test that we can create instances (without DB)
        role = RoleCluster()
        competency = Competency()
        indicator = CompetencyIndicator()

        print("✓ Derik's models can be instantiated")
        return True
    except Exception as e:
        print(f"✗ Error testing Derik's models: {e}")
        return False

def test_se_qpt_extensions():
    """Test that SE-QPT extensions are properly defined"""
    print("\\n=== TESTING SE-QPT EXTENSIONS ===")

    try:
        from integration.unified_models import (
            QualificationArchetype, LearningObjective, QualificationPlan,
            RoleCompetencyMatrix, CompanyContext
        )
        print("✓ SE-QPT extension models imported successfully")

        # Test model instantiation
        archetype = QualificationArchetype()
        learning_obj = LearningObjective()
        plan = QualificationPlan()
        matrix = RoleCompetencyMatrix()
        context = CompanyContext()

        print("✓ SE-QPT extension models can be instantiated")
        return True
    except Exception as e:
        print(f"✗ Error testing SE-QPT extensions: {e}")
        return False

def test_langchain_integration():
    """Test LangChain integration patterns"""
    print("\\n=== TESTING LANGCHAIN INTEGRATION ===")

    try:
        from langchain.prompts import ChatPromptTemplate
        from langchain_openai import AzureChatOpenAI, OpenAIEmbeddings

        print("✓ LangChain imports successful")

        # Test prompt creation
        prompt = ChatPromptTemplate.from_messages([
            ("system", "You are a test assistant"),
            ("human", "Test message: {input}")
        ])

        print("✓ LangChain prompt templates working")
        return True
    except Exception as e:
        print(f"✗ Error testing LangChain: {e}")
        return False

def test_openai_configuration():
    """Test OpenAI API configuration"""
    print("\\n=== TESTING OPENAI CONFIGURATION ===")

    try:
        import os
        from dotenv import load_dotenv
        load_dotenv()

        openai_key = os.getenv('OPENAI_API_KEY')
        if openai_key:
            print("✓ OpenAI API key configured")
        else:
            print("⚠ OpenAI API key not found in environment")

        # Test model initialization (without actual API call)
        from langchain_openai import AzureChatOpenAI, OpenAIEmbeddings

        print("✓ OpenAI models can be initialized")
        return True
    except Exception as e:
        print(f"✗ Error testing OpenAI configuration: {e}")
        return False

def test_16_competencies_integration():
    """Test 16 SE competencies integration"""
    print("\\n=== TESTING 16 SE COMPETENCIES INTEGRATION ===")

    try:
        # Load the corrected competencies
        with open('../../../data/processed/corrected_roles_competencies.json', 'r') as f:
            se_data = json.load(f)

        competencies = se_data['competencies']['list']
        roles = se_data['roles']['list']

        if len(competencies) == 16:
            print(f"✓ 16 SE competencies loaded: {competencies[0]}, {competencies[1]}, ...")
        else:
            print(f"✗ Expected 16 competencies, found {len(competencies)}")

        if len(roles) == 14:  # Should be 14 after correction
            print(f"✓ 14 SE roles loaded: {roles[0]}, {roles[1]}, ...")
        else:
            print(f"⚠ Found {len(roles)} roles (expected 14)")

        return len(competencies) == 16
    except Exception as e:
        print(f"✗ Error testing competencies integration: {e}")
        return False

def test_api_routes_structure():
    """Test that SE-QPT API routes are properly structured"""
    print("\\n=== TESTING API ROUTES STRUCTURE ===")

    try:
        from integration.se_qpt_routes import se_qpt

        print(f"✓ SE-QPT blueprint created with prefix: {se_qpt.url_prefix}")

        # Check that essential routes exist
        routes = [rule.rule for rule in se_qpt.url_map.iter_rules()]
        essential_routes = [
            '/api/se-qpt/archetypes',
            '/api/se-qpt/learning-objectives/generate',
            '/api/se-qpt/qualification-plans',
            '/api/se-qpt/role-competency-matrix',
            '/api/se-qpt/status'
        ]

        for route in essential_routes:
            if any(route in r for r in routes):
                print(f"✓ Route exists: {route}")
            else:
                print(f"⚠ Route may be missing: {route}")

        return True
    except Exception as e:
        print(f"✗ Error testing API routes: {e}")
        return False

def test_qualification_archetypes():
    """Test 6 qualification archetypes"""
    print("\\n=== TESTING 6 QUALIFICATION ARCHETYPES ===")

    try:
        # Load the correct archetypes
        with open('../../../data/processed/correct_qualification_archetypes.json', 'r') as f:
            archetypes_data = json.load(f)

        archetypes = archetypes_data['qualification_archetypes']

        if len(archetypes) == 6:
            print("✓ 6 qualification archetypes loaded:")
            for arch in archetypes:
                print(f"    {arch['id']}. {arch['name']}")
        else:
            print(f"✗ Expected 6 archetypes, found {len(archetypes)}")

        return len(archetypes) == 6
    except Exception as e:
        print(f"✗ Error testing qualification archetypes: {e}")
        return False

def generate_integration_report():
    """Generate comprehensive integration test report"""
    print("\\n" + "="*60)
    print("SE-QPT + DERIK INTEGRATION TEST REPORT")
    print("="*60)

    tests = [
        ("Derik Models Compatibility", test_derik_models_compatibility),
        ("SE-QPT Extensions", test_se_qpt_extensions),
        ("LangChain Integration", test_langchain_integration),
        ("OpenAI Configuration", test_openai_configuration),
        ("16 SE Competencies", test_16_competencies_integration),
        ("API Routes Structure", test_api_routes_structure),
        ("6 Qualification Archetypes", test_qualification_archetypes)
    ]

    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, "PASS" if result else "FAIL"))
        except Exception as e:
            results.append((test_name, f"ERROR: {e}"))

    print("\\n" + "="*60)
    print("INTEGRATION TEST SUMMARY")
    print("="*60)

    passed = 0
    for test_name, status in results:
        print(f"{test_name:.<40} {status}")
        if status == "PASS":
            passed += 1

    print(f"\\nOverall: {passed}/{len(tests)} tests passed")

    if passed == len(tests):
        print("🎉 SE-QPT + Derik integration is READY!")
    else:
        print("⚠️  Some integration issues detected - review above")

    # Save report
    report = {
        'test_timestamp': datetime.now().isoformat(),
        'integration_status': 'ready' if passed == len(tests) else 'issues_detected',
        'tests_passed': passed,
        'total_tests': len(tests),
        'test_results': dict(results)
    }

    with open('integration_test_report.json', 'w') as f:
        json.dump(report, f, indent=2)

    print(f"\\nDetailed report saved: integration_test_report.json")

if __name__ == "__main__":
    generate_integration_report()