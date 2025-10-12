import os
from pathlib import Path

class DevelopmentConfig:
    """Development configuration aligned with Derik's competency assessor"""
    
    # Base directories
    BASE_DIR = Path(__file__).parent.parent.parent
    DATA_DIR = BASE_DIR / "data"
    SOURCE_DIR = DATA_DIR / "source"
    
    # Database configuration (same as Derik's setup)
    DATABASE_URL = os.getenv('DATABASE_URL', 'postgresql://seqpt_user:seqpt_pass@localhost:5432/seqpt')
    SQLALCHEMY_DATABASE_URI = DATABASE_URL
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = True  # For development debugging
    
    # LangChain and OpenAI configuration (identical to Derik's setup)
    OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
    LANGCHAIN_MODEL = "gpt-4o-mini"  # Same model as Derik
    EMBEDDING_MODEL = "text-embedding-ada-002"  # Same model as Derik
    
    # RAG configuration
    VECTOR_DB_PATH = DATA_DIR / "processed" / "vector_db"
    LEARNING_OBJECTIVES_TEMPLATES = SOURCE_DIR / "templates"
    
    # Input sources configuration
    EXCEL_SOURCE_FILE = SOURCE_DIR / "excel" / "Qualifizierungsmodule_Qualifizierungspläne_v4_enUS.xlsx"
    QUESTIONNAIRES_DIR = SOURCE_DIR / "questionnaires"
    THESIS_FILES_DIR = SOURCE_DIR / "thesis_files"
    
    # Application settings
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    DEBUG = True
    TESTING = False
    
    # CORS settings for frontend integration
    CORS_ORIGINS = ["http://localhost:3000", "http://127.0.0.1:3000"]
    
    # File upload settings
    MAX_CONTENT_LENGTH = 50 * 1024 * 1024  # 50MB max file size
    UPLOAD_FOLDER = DATA_DIR / "uploads"
    
    # Validation thresholds
    RAG_QUALITY_THRESHOLD = 0.85  # SMART criteria threshold for generated objectives
    COMPETENCY_GAP_THRESHOLD = 1.0  # Minimum gap to include in planning
    
    # Integration settings
    DERIK_INTEGRATION_ENABLED = True
    COMPETENCY_COUNT = 16  # Same as Derik's system
    ROLE_COUNT = 14  # SE role clusters
    ARCHETYPE_COUNT = 6  # Qualification archetypes

class ProductionConfig(DevelopmentConfig):
    """Production configuration"""
    DEBUG = False
    TESTING = False
    SQLALCHEMY_ECHO = False
    SECRET_KEY = os.getenv('SECRET_KEY')  # Must be set in production
    
class TestingConfig(DevelopmentConfig):
    """Testing configuration"""
    TESTING = True
    DATABASE_URL = 'postgresql://seqpt_user:seqpt_pass@localhost:5432/seqpt'
    SQLALCHEMY_DATABASE_URI = DATABASE_URL

# Configuration dictionary
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}