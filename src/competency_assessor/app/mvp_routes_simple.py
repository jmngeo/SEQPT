"""
SE-QPT MVP API Routes - Simplified Version
Works with Derik's existing database structure
"""

from flask import Blueprint, request, jsonify, current_app, g
from flask_jwt_extended import jwt_required, create_access_token
from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
import hashlib
import time
import uuid
import jwt as pyjwt

from app import db
from app.models import Organization, AdminUser

# Create blueprint
mvp_api = Blueprint('mvp_api', __name__)

# Custom JWT verification decorator (bypasses Flask-JWT-Extended CSRF)
def verify_jwt_token(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')

        if not auth_header:
            return jsonify({'error': 'Authorization header missing'}), 401

        try:
            # Extract token from "Bearer <token>"
            token = auth_header.split(' ')[1] if ' ' in auth_header else auth_header

            # Decode and verify token using PyJWT
            payload = pyjwt.decode(
                token,
                current_app.config['JWT_SECRET_KEY'],
                algorithms=['HS256']
            )

            # Store payload in Flask's g object for access in the route
            g.jwt_payload = payload
            g.jwt_identity = int(payload.get('sub'))  # Convert back to int

            return f(*args, **kwargs)

        except pyjwt.ExpiredSignatureError:
            return jsonify({'error': 'Token has expired'}), 401
        except pyjwt.InvalidTokenError as e:
            return jsonify({'error': f'Invalid token: {str(e)}'}), 422
        except Exception as e:
            return jsonify({'error': f'Token verification failed: {str(e)}'}), 422

    return decorated_function

# =============================================================================
# AUTHENTICATION ENDPOINTS
# =============================================================================

@mvp_api.route('/mvp/auth/register-admin', methods=['POST'])
def register_admin():
    """Admin creates organization and becomes first admin user"""
    try:
        data = request.get_json()

        # Minimal required fields
        if not data.get('username') or not data.get('password') or not data.get('organization_name'):
            return jsonify({'error': 'username, password, and organization_name are required'}), 400

        # Check if username already exists
        if AdminUser.query.filter_by(username=data['username']).first():
            return jsonify({'error': 'Username already registered'}), 400

        # Generate organization code
        base = f"{data['organization_name']}_{int(time.time() * 1000)}"
        org_code = hashlib.sha256(base.encode()).hexdigest()[:16].upper()

        # Check uniqueness
        while Organization.query.filter_by(organization_public_key=org_code).first():
            base = f"{data['organization_name']}_{int(time.time() * 1000)}_{uuid.uuid4().hex[:4]}"
            org_code = hashlib.sha256(base.encode()).hexdigest()[:16].upper()

        # Create organization
        organization = Organization(
            organization_name=data['organization_name'],
            organization_public_key=org_code
        )
        db.session.add(organization)
        db.session.flush()

        # Create admin user
        admin_user = AdminUser(
            username=data['username'],
            password_hash=generate_password_hash(data['password'])
        )
        db.session.add(admin_user)
        db.session.commit()

        # Create access token manually without CSRF using PyJWT
        iat_timestamp = int(time.time())
        exp_timestamp = iat_timestamp + (15 * 60)  # 15 minutes = 900 seconds
        payload = {
            'fresh': False,
            'iat': iat_timestamp,
            'jti': str(uuid.uuid4()),
            'type': 'access',
            'sub': str(admin_user.id),  # Must be string for JWT standard
            'nbf': iat_timestamp,
            'exp': exp_timestamp,
            'organization_id': organization.id,
            'role': 'admin',
            'org_code': org_code
        }
        access_token = pyjwt.encode(payload, current_app.config['JWT_SECRET_KEY'], algorithm='HS256')

        return jsonify({
            'access_token': access_token,
            'user': {
                'id': admin_user.id,
                'username': admin_user.username,
                'role': 'admin',
                'first_name': admin_user.username,  # Use username as name since AdminUser has no name fields
                'last_name': ''
            },
            'organization': {
                'id': organization.id,
                'name': organization.organization_name,
                'code': org_code
            }
        }), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Admin registration error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'Registration failed: {str(e)}'}), 500


@mvp_api.route('/mvp/auth/login', methods=['POST'])
def login():
    """Login for admin users"""
    try:
        data = request.get_json()

        if not data.get('username') or not data.get('password'):
            return jsonify({'error': 'Username and password required'}), 400

        user = AdminUser.query.filter_by(username=data['username']).first()

        if user and check_password_hash(user.password_hash, data['password']):
            # Create access token manually without CSRF using PyJWT (same as registration)
            iat_timestamp = int(time.time())
            exp_timestamp = iat_timestamp + (15 * 60)  # 15 minutes = 900 seconds
            payload = {
                'fresh': False,
                'iat': iat_timestamp,
                'jti': str(uuid.uuid4()),
                'type': 'access',
                'sub': str(user.id),  # Must be string for JWT standard
                'nbf': iat_timestamp,
                'exp': exp_timestamp,
                'role': 'admin'
            }
            access_token = pyjwt.encode(payload, current_app.config['JWT_SECRET_KEY'], algorithm='HS256')

            return jsonify({
                'access_token': access_token,
                'user': {
                    'id': user.id,
                    'username': user.username,
                    'role': 'admin',
                    'first_name': user.username,  # Use username as name since AdminUser has no name fields
                    'last_name': ''
                }
            }), 200

        return jsonify({'error': 'Invalid credentials'}), 401

    except Exception as e:
        current_app.logger.error(f"Login error: {str(e)}")
        return jsonify({'error': 'Login failed'}), 500


@mvp_api.route('/api/auth/me', methods=['GET'])
@verify_jwt_token
def get_current_user():
    """Get current authenticated user information"""
    try:
        # Get user ID from Flask's g object (set by our custom decorator)
        user_id = g.jwt_identity
        claims = g.jwt_payload

        # Get user from database
        admin_user = AdminUser.query.get(user_id)
        if not admin_user:
            return jsonify({'error': 'User not found'}), 404

        return jsonify({
            'user': {
                'id': admin_user.id,
                'username': admin_user.username,
                'role': claims.get('role', 'admin'),
                'first_name': admin_user.username,  # Use username as name since AdminUser has no name fields
                'last_name': ''
            }
        }), 200

    except Exception as e:
        current_app.logger.error(f"Get current user error: {str(e)}")
        return jsonify({'error': 'Failed to get user info'}), 500


@mvp_api.route('/api/organization/verify-code/<code>', methods=['GET'])
def verify_organization_code(code):
    """Verify if organization code is valid"""
    try:
        org = Organization.query.filter_by(organization_public_key=code).first()

        if org:
            return jsonify({
                'valid': True,
                'organization': {
                    'id': org.id,
                    'name': org.organization_name
                }
            }), 200

        return jsonify({'valid': False}), 404

    except Exception as e:
        current_app.logger.error(f"Code verification error: {str(e)}")
        return jsonify({'error': 'Verification failed'}), 500


@mvp_api.route('/mvp/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'ok', 'message': 'MVP API is running'}), 200


@mvp_api.route('/api/organization/dashboard', methods=['GET'])
@verify_jwt_token
def get_organization_dashboard():
    """Get organization dashboard data including organization code"""
    print("=== DASHBOARD ENDPOINT CALLED ===")
    try:
        # Get user ID and claims from Flask's g object (set by our custom decorator)
        user_id = g.jwt_identity
        claims = g.jwt_payload

        print(f'Dashboard accessed by user ID: {user_id}')
        current_app.logger.info(f'Dashboard accessed by user ID: {user_id}')

        print(f'JWT claims: {claims}')
        current_app.logger.info(f'JWT claims: {claims}')

        org_id = claims.get('organization_id')
        org_code = claims.get('org_code')

        # If org info not in claims, this is from login (not register)
        # For MVP: Find the most recent organization (assumes admin created it)
        if not org_id or not org_code:
            print(f'No org info in token for user {user_id}, looking up most recent organization')
            current_app.logger.info(f'No org info in token for user {user_id}, looking up most recent organization')

            # Get the most recently created organization (MVP workaround)
            organization = Organization.query.order_by(Organization.id.desc()).first()

            if not organization:
                return jsonify({'error': 'No organization found'}), 404
        else:
            organization = Organization.query.get(org_id)
        if not organization:
            return jsonify({'error': 'Organization not found'}), 404

        # Get user info
        admin_user = AdminUser.query.get(user_id)
        if not admin_user:
            return jsonify({'error': 'User not found'}), 404

        return jsonify({
            'organization': {
                'id': organization.id,
                'name': organization.organization_name,
                'organization_code': organization.organization_public_key
            },
            'user': {
                'id': admin_user.id,
                'username': admin_user.username,
                'firstName': '',  # AdminUser doesn't have first/last name fields
                'lastName': ''
            }
        }), 200
    except Exception as e:
        print(f'Dashboard error: {str(e)}')
        current_app.logger.error(f'Dashboard error: {str(e)}')
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'Failed to fetch dashboard data: {str(e)}'}), 500
