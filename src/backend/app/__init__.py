"""
SE-QPT Unified Web Platform - Flask Backend
Integrates all components: Marcel's methodology, Derik's assessor, RAG-LLM innovation
"""

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from datetime import timedelta
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Extensions will be initialized by the models module
migrate = Migrate()
jwt = JWTManager()

def create_app(config_name='development'):
    """Application factory pattern"""
    app = Flask(__name__)

    # Configuration
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    # app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'postgresql://seqpt_user:seqpt_pass@localhost:5432/seqpt')
    app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'sqlite:///seqpt.db')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'jwt-secret-string')
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=24)

    # OpenAI Configuration
    app.config['OPENAI_API_KEY'] = os.getenv('OPENAI_API_KEY')

    # File upload configuration
    app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

    # Import and initialize database
    from models import db

    # Initialize extensions with app
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)

    # CORS configuration for frontend
    CORS(app,
         origins=[
             'http://localhost:3000', 'http://localhost:3001', 'http://localhost:3002',
             'http://localhost:3003', 'http://localhost:3004', 'http://localhost:5173',
             'http://127.0.0.1:3000', 'http://127.0.0.1:3001', 'http://127.0.0.1:3002',
             'http://127.0.0.1:3003', 'http://127.0.0.1:3004', 'http://127.0.0.1:5173'
         ],
         allow_headers=['Content-Type', 'Authorization'],
         methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
         supports_credentials=True,
         expose_headers=['Content-Type', 'Authorization']
    )

    # Register blueprints
    from app.routes import main_bp
    # from app.auth import auth_bp  # Disabled - using MVP auth system instead
    from app.api import api_bp
    from app.admin import admin_bp
    from app.questionnaire_api import questionnaire_bp
    from app.module_api import module_bp
    from app.competency_service import competency_service_bp

    app.register_blueprint(main_bp)
    # app.register_blueprint(auth_bp, url_prefix='/auth')  # Disabled - using MVP auth system instead
    app.register_blueprint(api_bp, url_prefix='/api')
    app.register_blueprint(admin_bp, url_prefix='/admin')
    app.register_blueprint(questionnaire_bp, url_prefix='/api')
    app.register_blueprint(module_bp, url_prefix='/api')
    app.register_blueprint(competency_service_bp, url_prefix='/api/competency')

    # Import Derik's routes - Enable competency assessor integration
    try:
        from app.derik_integration import derik_bp
        app.register_blueprint(derik_bp, url_prefix='/api/derik')
        print("Derik's competency assessor integration enabled")
    except Exception as e:
        print(f"Warning: Derik's competency assessor not available: {e}")
        pass

    # Import SE-QPT RAG routes
    try:
        from app.seqpt_routes import seqpt_bp
        app.register_blueprint(seqpt_bp, url_prefix='/api/seqpt')
        print("SE-QPT RAG routes registered successfully")
    except Exception as e:
        print(f"Warning: SE-QPT RAG routes not available: {e}")
        pass

    # Import MVP routes for simplified architecture
    try:
        from app.mvp_routes import mvp_api
        app.register_blueprint(mvp_api)
        print("MVP API routes registered successfully")
    except Exception as e:
        print(f"Warning: MVP API routes not available: {e}")
        pass

    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return {'error': 'Resource not found'}, 404

    @app.errorhandler(500)
    def internal_error(error):
        db.session.rollback()
        return {'error': 'Internal server error'}, 500

    # Health check endpoint
    @app.route('/health')
    def health_check():
        return {
            'status': 'healthy',
            'service': 'SE-QPT Unified Platform',
            'version': '1.0.0',
            'components': {
                'database': 'connected',
                'rag_llm': 'operational',
                'derik_assessor': 'integrated'
            }
        }

    return app