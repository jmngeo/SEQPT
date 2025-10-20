from flask import Blueprint, request, jsonify
from app import db
from app.models import RoleCluster, Competency, CompetencyIndicator, RoleProcessMatrix, IsoProcesses, ProcessCompetencyMatrix, RoleCompetencyMatrix, Organization, AppUser, UserCompetencySurveyResults, UserRoleCluster, UserCompetencySurveyFeedback, UserSurveyType, UnknownRoleProcessMatrix, UnknownRoleCompetencyMatrix, AdminUser, NewSurveyUser
import openai
from openai import AzureOpenAI
from openai import AzureOpenAI
from pydantic import BaseModel, Field
import os
import logging
from sqlalchemy.exc import SQLAlchemyError, IntegrityError
from sqlalchemy import or_, and_
from sqlalchemy import text
from sqlalchemy import func
from app.rank_competency_indicators_llm import process_user_tasks_and_competencies
from datetime import datetime
from flask import jsonify
import json
from app.generate_survey_feedback import generate_feedback_with_llm
from collections import defaultdict
from app.llm_process_identification_pipeline import create_pipeline
from app.most_similar_role import find_most_similar_role_cluster
import numpy as np
from flask_bcrypt import Bcrypt

main = Blueprint('main', __name__)
bcrypt = Bcrypt()




@main.route('/')
def index():
    return "Welcome to the Survey App"

@main.route('/roles', methods=['GET'])
def get_roles():
    roles = RoleCluster.query.filter(
        and_(RoleCluster.id != 40004, RoleCluster.id != 70007)
    ).all()
    roles_list = [{"id": role.id, "name": role.role_cluster_name, "description": role.role_cluster_description} for role in roles]
    return jsonify(roles_list)


##Adding competency and competency indicators CRUD operations 
# Competency CRUD

@main.route('/competencies', methods=['POST'])
def create_competency():
    data = request.json
    competency = Competency(
        competency_area=data['competency_area'],
        competency_name=data['competency_name'],
        description=data['description'],
        why_it_matters=data['why_it_matters']
    )
    db.session.add(competency)
    db.session.commit()
    return jsonify({'message': 'Competency created successfully!'}), 201


@main.route('/competencies', methods=['GET'])
def get_competencies():
    competencies = Competency.query.all()
    return jsonify([{
        'id': c.id,
        'competency_area': c.competency_area,
        'competency_name': c.competency_name,
        'description': c.description,
        'why_it_matters': c.why_it_matters
    } for c in competencies])


@main.route('/competencies/<int:id>', methods=['PUT'])
def update_competency(id):
    data = request.json
    competency = Competency.query.get(id)
    if not competency:
        return jsonify({'message': 'Competency not found'}), 404

    competency.competency_area = data['competency_area']
    competency.competency_name = data['competency_name']
    competency.description = data['description']
    competency.why_it_matters = data['why_it_matters']
    db.session.commit()
    return jsonify({'message': 'Competency updated successfully!'})


@main.route('/competencies/<int:id>', methods=['DELETE'])
def delete_competency(id):
    competency = Competency.query.get(id)
    if not competency:
        return jsonify({'message': 'Competency not found'}), 404

    db.session.delete(competency)
    db.session.commit()
    return jsonify({'message': 'Competency deleted successfully!'})

@main.route('/iso_processes', methods=['GET'])
def get_iso_processes():
    processes = IsoProcesses.query.all()
    return jsonify([{
        'id': p.id,
        'name': p.name,
        'description': p.description,
        'life_cycle_process_id': p.life_cycle_process_id
    } for p in processes])
    
# CompetencyIndicator CRUD

@main.route('/competency_indicators', methods=['POST'])
def create_competency_indicator():
    data = request.json
    indicator = CompetencyIndicator(
        competency_id=data['competency_id'],
        level=data['level'],
        indicator_en=data['indicator_en'],
        indicator_de=data['indicator_de']
    )
    db.session.add(indicator)
    db.session.commit()
    return jsonify({'message': 'Competency Indicator created successfully!'}), 201



@main.route('/competency_indicators/<int:competency_id>', methods=['GET'])
def get_competency_indicators(competency_id):
    indicators = CompetencyIndicator.query.filter_by(competency_id=competency_id).all()
    return jsonify([{
        'id': i.id,
        'level': i.level,
        'indicator_en': i.indicator_en,
        'indicator_de': i.indicator_de
    } for i in indicators])



@main.route('/competency_indicators/<int:id>', methods=['PUT'])
def update_competency_indicator(id):
    data = request.json
    indicator = CompetencyIndicator.query.get(id)
    if not indicator:
        return jsonify({'message': 'Competency Indicator not found'}), 404

    indicator.level = data['level']
    indicator.indicator_en = data['indicator_en']
    indicator.indicator_de = data['indicator_de']
    db.session.commit()
    return jsonify({'message': 'Competency Indicator updated successfully!'})



@main.route('/competency_indicators/<int:id>', methods=['DELETE'])
def delete_competency_indicator(id):
    indicator = CompetencyIndicator.query.get(id)
    if not indicator:
        return jsonify({'message': 'Competency Indicator not found'}), 404

    db.session.delete(indicator)
    db.session.commit()
    return jsonify({'message': 'Competency Indicator deleted successfully!'})


#Role Process Matrix CRUD
# Fetch roles and processes
@main.route('/roles_and_processes', methods=['GET'])
def get_roles_and_processes():
    """Fetch all roles and processes for the role-process matrix page."""
    try:
        roles = RoleCluster.query.all()
        processes = IsoProcesses.query.all()

        roles_list = [{"id": role.id, "name": role.role_cluster_name} for role in roles]
        processes_list = [{"id": process.id, "name": process.name} for process in processes]

        return jsonify({"roles": roles_list, "processes": processes_list})
    except Exception as e:
        logging.error(f"Error fetching roles and processes: {str(e)}")
        return jsonify({"error": "An error occurred while fetching roles and processes."}), 500


# Fetch role-process matrix data for a specific role and organization
@main.route('/role_process_matrix/<int:organization_id>/<int:role_cluster_id>', methods=['GET'])
def get_role_process_matrix(organization_id, role_cluster_id):
    """Fetch role-process matrix entries for a specific role and organization."""
    try:
        matrix_entries = RoleProcessMatrix.query.filter_by(role_cluster_id=role_cluster_id, organization_id=organization_id).all()
        matrix_data = [
            {
                'iso_process_id': entry.iso_process_id,
                'role_process_value': entry.role_process_value
            }
            for entry in matrix_entries
        ]
        return jsonify(matrix_data)
    except Exception as e:
        logging.error(f"Error fetching role-process matrix: {str(e)}")
        return jsonify({"error": "An error occurred while fetching the role-process matrix."}), 500



# Bulk update role-process matrix for a role and organization
@main.route('/role_process_matrix/bulk', methods=['PUT'])
def bulk_update_role_process_matrix():
    """Bulk update role-process matrix entries for a specific role and organization."""
    data = request.json
    role_cluster_id = data.get('role_cluster_id')
    organization_id = data.get('organization_id')
    matrix = data.get('matrix')  # Should be a dictionary of {iso_process_id: role_process_value}

    if role_cluster_id is None or organization_id is None or not isinstance(matrix, dict):
        return jsonify({"error": "organization_id, role_cluster_id, and matrix are required"}), 400

    try:
        # Iterate over the matrix and update each entry
        for iso_process_id, value in matrix.items():
            # Skip entries where the value is None (meaning the user did not set it)
            if value is None:
                continue

            # Log the iso_process_id and the value to debug
            logging.debug(f"Processing iso_process_id={iso_process_id}, value={value}")

            # Query to find if a record exists
            matrix_entry = RoleProcessMatrix.query.filter_by(
                role_cluster_id=role_cluster_id,
                iso_process_id=iso_process_id,
                organization_id=organization_id
            ).first()

            if matrix_entry:
                # Update existing entry
                logging.debug(f"Updating existing entry: organization_id={organization_id}, role_cluster_id={role_cluster_id}, iso_process_id={iso_process_id}, new_value={value}")
                matrix_entry.role_process_value = value
            else:
                # Insert new entry if a value is explicitly provided
                logging.debug(f"Inserting new entry: organization_id={organization_id}, role_cluster_id={role_cluster_id}, iso_process_id={iso_process_id}, value={value}")
                new_entry = RoleProcessMatrix(
                    organization_id=organization_id,
                    role_cluster_id=role_cluster_id,
                    iso_process_id=iso_process_id,
                    role_process_value=value
                )
                db.session.add(new_entry)

        # Ensure that all inserts/updates are flushed to the database before committing
        db.session.flush()
        db.session.commit()

        # After successful commit, call the stored procedure to update the role competency matrix with the organization_id
        db.session.execute(text('CALL update_role_competency_matrix(:org_id);'), {'org_id': organization_id})
        db.session.commit()

        logging.info("Role-Process matrix updated successfully and role-competency matrix recalculated.")
        return jsonify({"message": "Role-Process matrix updated successfully."})

    except SQLAlchemyError as e:
        logging.error(f"Error bulk updating role-process matrix: {str(e)}")
        db.session.rollback()  # Rollback in case of any error to maintain consistency
        return jsonify({"error": "An error occurred while updating the role-process matrix."}), 500

# CRUD for Process Competency Matrix
@main.route('/process_competency_matrix/<int:competency_id>', methods=['GET'])
def get_process_competency_matrix(competency_id):
    """Fetch process competency matrix data for a specific competency."""
    try:
        processes = IsoProcesses.query.all()
        matrix_entries = ProcessCompetencyMatrix.query.filter_by(competency_id=competency_id).all()

        # List of processes to return
        process_list = [{"id": process.id, "name": process.name} for process in processes]
        
        # Matrix entries to return
        matrix_data = [
            {
                'iso_process_id': entry.iso_process_id,
                'process_competency_value': entry.process_competency_value  # Updated field name
            }
            for entry in matrix_entries
        ]

        return jsonify({"processes": process_list, "matrix": matrix_data})
    except Exception as e:
        logging.error(f"Error fetching process-competency matrix: {str(e)}")
        return jsonify({"error": "An error occurred while fetching the process-competency matrix."}), 500


# Bulk Update Process Competency Matrix Endpoint
@main.route('/process_competency_matrix/bulk', methods=['PUT'])
def bulk_update_process_competency_matrix():
    """Bulk update process-competency matrix entries for a specific competency."""
    data = request.json
    competency_id = data.get('competency_id')
    matrix = data.get('matrix')  # Should be a dictionary of {iso_process_id: process_competency_value}

    if competency_id is None or not isinstance(matrix, dict):
        return jsonify({"error": "competency_id and matrix are required"}), 400

    try:
        # Iterate over the matrix and update each entry
        for iso_process_id, value in matrix.items():
            # Skip if the value is -100 (indicating it's unset)
            if value == -100:
                continue

            matrix_entry = ProcessCompetencyMatrix.query.filter_by(competency_id=competency_id, iso_process_id=iso_process_id).first()

            if matrix_entry:
                # Update existing entry
                matrix_entry.process_competency_value = value
            else:
                # Insert new entry
                new_entry = ProcessCompetencyMatrix(
                    competency_id=competency_id,
                    iso_process_id=iso_process_id,
                    process_competency_value=value  # Updated field name
                )
                db.session.add(new_entry)

        db.session.commit()

        # After successful commit, call the stored procedure for all organizations
        organizations = Organization.query.all()
        for org in organizations:
            db.session.execute(
                text('CALL update_role_competency_matrix(:org_id);'), 
                {'org_id': org.id}
            )
        db.session.commit()

        logging.info("Process-Competency matrix updated successfully and role-competency matrix recalculated.")
        return jsonify({"message": "Process-Competency matrix updated successfully."})
    except SQLAlchemyError as e:
        logging.error(f"Error bulk updating process-competency matrix: {str(e)}")
        db.session.rollback()  # Rollback to maintain consistency in case of error
        return jsonify({"error": "An error occurred while updating the process-competency matrix."}), 500


# Fetch competencies for a specific role and organization
@main.route('/role_competency_matrix/<int:organization_id>/<int:role_cluster_id>', methods=['GET'])
def get_role_competency_matrix(organization_id, role_cluster_id):
    """Fetch role-competency matrix entries for a specific role and organization."""
    try:
        competencies = Competency.query.all()
        matrix_entries = RoleCompetencyMatrix.query.filter_by(role_cluster_id=role_cluster_id, organization_id=organization_id).all()

        competencies_list = [{"id": competency.id, "name": competency.competency_name} for competency in competencies]
        matrix_data = [
            {
                'competency_id': entry.competency_id,
                'role_competency_value': entry.role_competency_value
            }
            for entry in matrix_entries
        ]
        return jsonify({"competencies": competencies_list, "matrix": matrix_data})
    except Exception as e:
        logging.error(f"Error fetching role-competency matrix: {str(e)}")
        return jsonify({"error": "An error occurred while fetching the role-competency matrix."}), 500



# Create an organization
@main.route('/organization', methods=['POST'])
def create_organization():
    data = request.json
    organization_name = data.get('organization_name')
    organization_public_key = data.get('organization_public_key')

    if not organization_name or not organization_public_key:
        return jsonify({"error": "Organization name and key are required"}), 400

    # Check if the key already exists
    existing_organization = Organization.query.filter_by(organization_public_key=organization_public_key).first()
    if existing_organization:
        return jsonify({"error": "Organization key already exists"}), 400

    try:
        new_organization = Organization(
            organization_name=organization_name,
            organization_public_key=organization_public_key
        )
        db.session.add(new_organization)
        db.session.flush()  # Ensure the new_organization.id is generated

        # Execute the stored procedures using db.session.execute with text()
        try:
            db.session.execute(text("CALL insert_new_org_default_role_process_matrix(:org_id)"), {'org_id': new_organization.id})
            db.session.execute(text("CALL insert_new_org_default_role_competency_matrix(:org_id)"), {'org_id': new_organization.id})
        except Exception as proc_ex:
            db.session.rollback()
            print("Stored Procedure Error:", str(proc_ex))
            return jsonify({"error": "Error executing stored procedures: " + str(proc_ex)}), 500

        db.session.commit()

        return jsonify({"message": "Organization created successfully."}), 201

    except Exception as e:
        db.session.rollback()
        print("General Exception:", str(e))
        return jsonify({"error": str(e)}), 500


# Get all organizations
@main.route('/organizations', methods=['GET'])
def get_organizations():
    try:
        organizations = Organization.query.all()
        org_list = [{"id": org.id, "organization_name": org.organization_name, "organization_public_key": org.organization_public_key} for org in organizations]
        return jsonify(org_list), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# Delete an organization by ID
@main.route('/organization/<int:id>', methods=['DELETE'])
def delete_organization(id):
    try:
        organization = Organization.query.get(id)
        if not organization:
            return jsonify({"error": "Organization not found"}), 404

        db.session.delete(organization)
        db.session.commit()
        return jsonify({"message": "Organization deleted successfully."}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500
    
# Check if the organization key already exists
@main.route('/check_organization_key', methods=['POST'])
def check_organization_key():
    try:
        data = request.json
        organization_key = data.get('organization_public_key')

        if not organization_key:
            return jsonify({"error": "Organization key is required"}), 400

        # Query to check if organization key exists
        organization = Organization.query.filter_by(organization_public_key=organization_key).first()

        if organization:
            return jsonify({"exists": True}), 200
        else:
            return jsonify({"exists": False}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Get the organization ID for "Individual"
@main.route('/get_individual_organization_id', methods=['GET'])
def get_individual_organization_id():
    try:
        print("Ind id:")
        individual_org = Organization.query.filter_by(organization_name='Individual').first()
        print("Ind id:",individual_org)
        if individual_org:
            return jsonify({"id": individual_org.id}), 200
        else:
            return jsonify({"error": "Individual organization not found"}), 404
    except Exception as e:
        print(str(e))
        return jsonify({"error": str(e)}), 500

# Get organization by key
@main.route('/get_organization_by_key', methods=['POST'])
def get_organization_by_key():
    try:
        data = request.json
        organization_public_key = data.get('organization_public_key')

        if not organization_public_key:
            return jsonify({"error": "Organization key is required"}), 400

        organization = Organization.query.filter_by(organization_public_key=organization_public_key).first()
        if organization:
            return jsonify({"id": organization.id, "organization_name": organization.organization_name, "exists": True}), 200
        else:
            return jsonify({"exists": False}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


#User CRUD
@main.route('/create_user', methods=['POST'])
def create_user():
    try:
        data = request.json
        organization_id = data.get('organization_id')
        name = data.get('name')
        username = data.get('username')
        tasks_responsibilities = data.get('tasks_responsibilities')

        if not all([organization_id, name, username, tasks_responsibilities]):
            return jsonify({"error": "All fields are required"}), 400

        # Create a new user
        new_user = AppUser(
            organization_id=organization_id,
            name=name,
            username=username,
            tasks_responsibilities=tasks_responsibilities
        )
        db.session.add(new_user)
        db.session.commit()

        return jsonify({"message": "User created successfully"}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": str(e)}), 500

# Check if the username already exists for an organization
@main.route('/check_username', methods=['POST'])
def check_username():
    try:
        data = request.json
        organization_id = data.get('organization_id')
        username = data.get('username')

        if not organization_id or not username:
            return jsonify({"error": "organization_id and username are required"}), 400

        # Query to check if username exists for the given organization
        user_in_app_user = AppUser.query.filter_by(username=username).first()
        user_in_unknown_role_table = UnknownRoleProcessMatrix.query.filter_by(user_name=username).first()
        user_in_new_survey_user = NewSurveyUser.query.filter_by(username=username).first()
        if user_in_app_user or user_in_unknown_role_table or user_in_new_survey_user:
            return jsonify({"exists": True}), 200
        else:
            return jsonify({"exists": False}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# @main.route('/new_survey_user', methods=['POST'])
# def create_new_survey_user():
#     data = request.get_json()  # Get JSON data from request
#     username = data.get('username')

#     if not username:
#         return jsonify({"message": "Username is required."}), 400

#     new_user = NewSurveyUser(username=username)

#     try:
#         db.session.add(new_user)
#         db.session.commit()
#         return jsonify({"message": "User created successfully.", "username": username}), 201
#     except IntegrityError:
#         db.session.rollback()  # Rollback transaction on error
#         return jsonify({"message": "Username already exists. Please choose another."}), 400
#     except Exception as e:
#         return jsonify({"message": "An error occurred.", "error": str(e)}), 500

@main.route('/new_survey_user', methods=['POST'])
def create_new_survey_user():
    # No need to retrieve username from request data
    new_user = NewSurveyUser()  # Create without a username

    try:
        db.session.add(new_user)
        db.session.commit()
        # Refresh the object to get the username generated by the DB trigger
        db.session.refresh(new_user)
        return jsonify({
            "message": "User created successfully.",
            "username": new_user.username  # Return the generated username
        }), 201
    except IntegrityError:
        db.session.rollback()
        return jsonify({"message": "A user with this username already exists."}), 400
    except Exception as e:
        return jsonify({"message": "An error occurred.", "error": str(e)}), 500


# Fetch competencies for selected roles and organization
@main.route('/get_required_competencies_for_roles', methods=['POST'])
def get_required_competencies_for_roles():
    """Fetch distinct competencies and the maximum competency value for selected roles and organization."""
    data = request.json
    role_ids = data.get('role_ids')
    organization_id = data.get('organization_id')
    user_name = data.get('user_name')
    survey_type = data.get('survey_type')
    print("Role IDs:",role_ids)
    print("Organization IDs:",organization_id)
    print("Finding required competencies for survey type:", survey_type)
    if survey_type == 'known_roles':
        if role_ids is None or organization_id is None:
            return jsonify({"error": "role_ids and organization_id are required"}), 400

        try:
            # Query to get distinct competency IDs with maximum value for selected roles
            competencies = (
                db.session.query(
                    RoleCompetencyMatrix.competency_id,
                    func.max(RoleCompetencyMatrix.role_competency_value).label('max_value')
                )
                .filter(
                    RoleCompetencyMatrix.role_cluster_id.in_(role_ids),
                    RoleCompetencyMatrix.organization_id == organization_id
                )
                .group_by(RoleCompetencyMatrix.competency_id)
                .order_by(RoleCompetencyMatrix.competency_id)
                .all()
            )

            # Format the result as a list of dictionaries
            competencies_data = [
                {
                    'competency_id': competency.competency_id,
                    'max_value': competency.max_value
                }
                for competency in competencies
            ]

            return jsonify({"competencies": competencies_data}), 200

        except Exception as e:
            print(str(e))
            return jsonify({"error in known role competency fetching": str(e)}), 500
    elif survey_type == 'unknown_roles':
        if user_name is None or organization_id is None:
            return jsonify({"error": "user_name and organization_id are required"}), 400

        try:
            # Query to get competency IDs and their role competency values for unknown roles
            competencies = (
                db.session.query(
                    UnknownRoleCompetencyMatrix.competency_id,
                    UnknownRoleCompetencyMatrix.role_competency_value.label('max_value')
                )
                .filter(
                    UnknownRoleCompetencyMatrix.user_name == user_name,
                    UnknownRoleCompetencyMatrix.organization_id == organization_id
                )
                .order_by(UnknownRoleCompetencyMatrix.competency_id)
                .all()
            )

            # Format the result as a list of dictionaries
            competencies_data = [
                {
                    'competency_id': competency.competency_id,
                    'max_value': competency.max_value
                }
                for competency in competencies
            ]

            return jsonify({"competencies": competencies_data}), 200

        except Exception as e:
            print(str(e))
            return jsonify({"error": str(e)}), 500
    elif survey_type == "all_roles":
        print("Fetching competencies for all roles")
        if organization_id is None:
            return jsonify({"error": "organization_id are required"}), 400

        try:
            # Query to get distinct competency IDs with maximum value for selected roles
            competencies = (
                db.session.query(
                    RoleCompetencyMatrix.competency_id,
                    func.round(func.avg(RoleCompetencyMatrix.role_competency_value)).label('max_value')
                )
                .filter(
                    RoleCompetencyMatrix.organization_id == organization_id
                )
                .group_by(RoleCompetencyMatrix.competency_id)
                .order_by(RoleCompetencyMatrix.competency_id)
                .all()
            )

            # Format the result as a list of dictionaries
            competencies_data = [
                {
                    'competency_id': competency.competency_id,
                    'max_value': competency.max_value
                }
                for competency in competencies
            ]

            return jsonify({"competencies": competencies_data}), 200

        except Exception as e:
            print(str(e))
            return jsonify({"error in all roles competency fetching": str(e)}), 500
    else:
        return jsonify({"error": "Invalid survey_type provided"}), 400



@main.route('/get_competency_indicators_for_competency/<int:competency_id>', methods=['GET'])
def get_competency_indicators_for_competency(competency_id):
    """
    Fetch all indicators associated with the specified competency, grouped by level.
    """
    try:
        # Query to fetch indicators by competency ID
        indicators = CompetencyIndicator.query.filter_by(competency_id=competency_id).all()

        # Group indicators by their level
        indicators_by_level = {}
        for indicator in indicators:
            if indicator.level not in indicators_by_level:
                indicators_by_level[indicator.level] = []
            indicators_by_level[indicator.level].append({
                "indicator_en": indicator.indicator_en,
                "indicator_de": indicator.indicator_de
            })

        # Structure response with indicators grouped by level
        response_data = [
            {
                "level": level,
                "indicators": indicators
            }
            for level, indicators in indicators_by_level.items()
        ]

        return jsonify(response_data), 200

    except Exception as e:
        print(f"Error fetching competency indicators: {e}")
        return jsonify({"error": "An error occurred while fetching competency indicators"}), 500


@main.route('/submit_survey', methods=['POST'])
def submit_survey():
    data = request.get_json()
    try:
        # Extract the data from the incoming JSON request
        organization_id = data['organization_id']
        full_name = data['full_name']
        username = data['username']
        tasks_responsibilities = data['tasks_responsibilities']
        selected_roles = data['selected_roles']
        competency_scores = data['competency_scores']
        survey_type = data.get('survey_type', 'nothing_passed_from_front_end')  # Default to 'known_role' if not provided

        print("Selected Roles:", selected_roles)
        print("Survey Type:", survey_type)
        # updating survey completion in new_survey_user_table
        new_survey_user= NewSurveyUser.query.filter_by(username=username).first()
        if not new_survey_user:
            return jsonify({"message": "New Survey User entry not found."}), 404
        new_survey_user.survey_completion_status = True  # Mark survey as completed
        db.session.commit()
        # Check if the user already exists based on username
        user = AppUser.query.filter_by(username=username).first()

        if not user:
            # Create new user if they don't exist
            user = AppUser(
                organization_id=organization_id,
                name=full_name,
                username=username,
                tasks_responsibilities=json.dumps(tasks_responsibilities)
            )
            db.session.add(user)
            db.session.commit()  # Commit to generate user_id for new user

            # Create an entry in the UserSurveyType table for the new user
            user_survey_type_entry = UserSurveyType(
                user_id=user.id,
                survey_type=survey_type  # Use the survey_type passed from the front end
            )
            db.session.add(user_survey_type_entry)
            db.session.commit()
        # else:
        #     # Update user details if user exists (optional, commented out)
        #     # user.organization_id = organization_id
        #     # user.name = full_name
        #     # user.tasks_responsibilities = json.dumps(tasks_responsibilities)
        #     # db.session.commit()

        #     # Update or insert survey type for an existing user
        #     existing_survey_type = UserSurveyType.query.filter_by(user_id=user.id).first()
        #     if existing_survey_type:
        #         existing_survey_type.survey_type = survey_type  # Update survey type
        #         existing_survey_type.created_at = datetime.utcnow()  # Update timestamp
        #     else:
        #         new_survey_type_entry = UserSurveyType(
        #             user_id=user.id,
        #             survey_type=survey_type
        #         )
        #         db.session.add(new_survey_type_entry)
        #     db.session.commit()

        # Delete existing roles for the user if they exist
        UserRoleCluster.query.filter_by(user_id=user.id).delete()
        db.session.commit()  # Commit to ensure the deletion is successful

        # Insert new roles into user_role_cluster table
        for role in selected_roles:
            role_entry = UserRoleCluster(user_id=user.id, role_cluster_id=role['id'])
            db.session.add(role_entry)

        db.session.commit()  # Commit the new roles

        # Delete existing survey results for the user if they exist
        UserCompetencySurveyResults.query.filter_by(user_id=user.id).delete()
        db.session.commit()  # Commit to ensure the deletion is successful

        # Insert survey results into the user_se_competency_survey_results table
        for competency in competency_scores:
            survey = UserCompetencySurveyResults(
                user_id=user.id,
                organization_id=organization_id,
                competency_id=competency['competencyId'],
                score=competency['score']
            )
            db.session.add(survey)

        db.session.commit()  # Commit the survey results
        return jsonify({'message': 'Survey submitted successfully'}), 200

    except Exception as e:
        db.session.rollback()  # Rollback in case of an error
        return jsonify({'error': str(e)}), 500


# API endpoint to get competency results and generate feedback
@main.route('/get_user_competency_results', methods=['GET'])
def get_user_competency_results():
    username = request.args.get('username')
    organization_id = request.args.get('organization_id')
    survey_type = request.args.get('survey_type')
    print('Fetching competency result for survey type:',survey_type)
    try:
        # Step 1: Fetch user by username
        user = AppUser.query.filter_by(username=username).first()
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Step 2: Fetch competency survey results for radar chart
        user_competencies = UserCompetencySurveyResults.query.filter_by(
            user_id=user.id,
            organization_id=organization_id
        ).order_by(UserCompetencySurveyResults.competency_id).all()

        competencies = Competency.query.filter(
            Competency.id.in_([u.competency_id for u in user_competencies])
        ).order_by(Competency.id).all()

        competency_info_map = {comp.id: {'name': comp.competency_name, 'area': comp.competency_area} for comp in competencies}

        user_scores = [
            {
                'competency_id': u.competency_id,
                'score': u.score,
                'competency_name': competency_info_map[u.competency_id]['name'],
                'competency_area': competency_info_map[u.competency_id]['area']
            } 
            for u in user_competencies
        ]

        # Fetch required competency scores
        if survey_type == 'known_roles':
            user_roles = UserRoleCluster.query.filter_by(user_id=user.id).all()
            role_cluster_ids = [role.role_cluster_id for role in user_roles]
        ##if survey_type == 'known_roles':
            max_scores = db.session.query(
                RoleCompetencyMatrix.competency_id,
                db.func.max(RoleCompetencyMatrix.role_competency_value).label('max_score')
            ).filter(
                RoleCompetencyMatrix.organization_id == organization_id,
                RoleCompetencyMatrix.role_cluster_id.in_(role_cluster_ids)
            ).group_by(RoleCompetencyMatrix.competency_id).order_by(RoleCompetencyMatrix.competency_id).all()
        elif survey_type == 'unknown_roles':
            max_scores = db.session.query(
                UnknownRoleCompetencyMatrix.competency_id,
                UnknownRoleCompetencyMatrix.role_competency_value.label('max_score')
            ).filter(
                UnknownRoleCompetencyMatrix.organization_id == organization_id,
                UnknownRoleCompetencyMatrix.user_name == username
            )
        elif survey_type == 'all_roles':
            print("Calling finding most similar role function")
            most_similar_role_cluster = find_most_similar_role_cluster(organization_id,user_scores)
            print("Result of the calling function to find most similar role:",most_similar_role_cluster)
            max_scores = db.session.query(
                RoleCompetencyMatrix.competency_id,
                db.func.max(RoleCompetencyMatrix.role_competency_value).label('max_score')
            ).filter(
                RoleCompetencyMatrix.organization_id == organization_id,
                RoleCompetencyMatrix.role_cluster_id.in_(most_similar_role_cluster)
            ).group_by(RoleCompetencyMatrix.competency_id).order_by(RoleCompetencyMatrix.competency_id).all()
            for roleclusterid in most_similar_role_cluster:
                print("Adding most similar roles to user role cluster id table:",roleclusterid)
                role_entry = UserRoleCluster(user_id=user.id, role_cluster_id=roleclusterid)
                db.session.add(role_entry)


        max_scores_dict = [{'competency_id': m.competency_id, 'max_score': m.max_score} for m in max_scores]

        # Step 3: Check if feedback already exists in the database
        existing_feedbacks = UserCompetencySurveyFeedback.query.filter_by(
            user_id=user.id,
            organization_id=organization_id
        ).all()
        print("Max scores:",max_scores)
        # If feedback exists, use that; otherwise, generate new feedback
        if existing_feedbacks:
            feedback_list = [feedback.feedback for feedback in existing_feedbacks]
        else:
            # Step 4: Fetch competency results grouped by competency area using a stored procedure
            try:
                if survey_type == 'known_roles':
                    competency_results = db.session.execute(
                        text("""
                        SELECT competency_area, competency_name, user_recorded_level, user_recorded_level_competency_indicator,
                            user_required_level, user_required_level_competency_indicator
                        FROM public.get_competency_results(:username, :organization_id)
                        """),
                        {"username": username, "organization_id": organization_id}
                    ).fetchall()
                elif survey_type == 'unknown_roles':
                    competency_results = db.session.execute(
                        text("""
                        SELECT competency_area, competency_name, user_recorded_level, user_recorded_level_competency_indicator,
                            user_required_level, user_required_level_competency_indicator
                        FROM public.get_unknown_role_competency_results(:username, :organization_id)
                        """),
                        {"username": username, "organization_id": organization_id}
                    ).fetchall()
                
                elif survey_type == 'all_roles':
                    competency_results = db.session.execute(
                        text("""
                        SELECT competency_area, competency_name, user_recorded_level, user_recorded_level_competency_indicator,
                            user_required_level, user_required_level_competency_indicator
                        FROM public.get_competency_results(:username, :organization_id)
                        """),
                        {"username": username, "organization_id": organization_id}
                    ).fetchall()

            except SQLAlchemyError as e:
                db.session.rollback()
                return jsonify({"error": f"Database error: {str(e)}"}), 500

            # Step 5: Aggregate the results by competency area
            aggregated_results = defaultdict(list)
            for result in competency_results:
                competency_area, competency_name, user_level, user_indicator, required_level, required_indicator = result
                aggregated_results[competency_area].append({
                    "competency_name": competency_name,
                    "user_level": user_level,
                    "user_indicator": user_indicator,
                    "required_level": required_level,
                    "required_indicator": required_indicator
                })

            print('Aggregated result to send to LLM:',aggregated_results)
            # Step 6: Generate feedback using LLM for each competency area
            feedback_list = []
            try:
                for competency_area, competencies in aggregated_results.items():
                    feedback_json = generate_feedback_with_llm(competency_area, competencies)
                    feedback_list.append(feedback_json)

                # Save feedback to the database
                print(feedback_list)
                new_feedback = UserCompetencySurveyFeedback(
                    user_id=user.id,
                    organization_id=organization_id,
                    feedback=feedback_list
                )
                db.session.add(new_feedback)

                # Commit the changes after adding all feedbacks
                db.session.commit()

            except Exception as e:
                db.session.rollback()
                return jsonify({"error": f"Azure OpenAI API error: {str(e)}"}), 500
        if survey_type == 'all_roles':
            role_clusters = RoleCluster.query.filter(RoleCluster.id.in_(most_similar_role_cluster)).all()
            most_similar_role_clusters_details=[{
                'id': rc.id,
                'role_cluster_name': rc.role_cluster_name,
                'role_cluster_description': rc.role_cluster_description
            } for rc in role_clusters]
        # Step 7: Return user scores for the radar chart and feedback
        return jsonify({
            'user_scores': user_scores,
            'max_scores': max_scores_dict,
            'feedback_list': feedback_list,
            'most_similar_role': most_similar_role_clusters_details if survey_type == 'all_roles'  else []
        }), 200

    except SQLAlchemyError as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Get user competency results for multiple users
@main.route('/get_user_competency_results_admin', methods=['GET'])
def get_user_competency_results_admin():
    usernames = request.args.getlist('usernames')
    organization_id = request.args.get('organization_id')

    try:
        # Find users by usernames
        users = AppUser.query.filter(AppUser.username.in_(usernames), AppUser.organization_id == organization_id).all()
        if not users:
            return jsonify({'error': 'Users not found'}), 404

        user_ids = [user.id for user in users]

        # Get user survey results (competency scores), grouped and sorted by competency_id
        user_competencies = UserCompetencySurveyResults.query.filter(
            UserCompetencySurveyResults.user_id.in_(user_ids),
            UserCompetencySurveyResults.organization_id == organization_id
        ).with_entities(
            UserCompetencySurveyResults.competency_id,
            db.func.avg(UserCompetencySurveyResults.score).label('score')
        ).group_by(UserCompetencySurveyResults.competency_id).order_by(UserCompetencySurveyResults.competency_id).all()

        # Get competency names and areas
        competencies = Competency.query.filter(
            Competency.id.in_([u.competency_id for u in user_competencies])
        ).order_by(Competency.id).all()

        # Create a mapping of competency_id to competency_name and competency_area
        competency_info_map = {comp.id: {'name': comp.competency_name, 'area': comp.competency_area} for comp in competencies}

        # Format user scores
        user_scores = [
            {
                'competency_id': u.competency_id,
                'score': u.score,
                'competency_name': competency_info_map[u.competency_id]['name'],
                'competency_area': competency_info_map[u.competency_id]['area']
            } 
            for u in user_competencies
        ]

        # Get role cluster ids for the users
        user_roles = UserRoleCluster.query.filter(UserRoleCluster.user_id.in_(user_ids)).all()
        role_cluster_ids = [role.role_cluster_id for role in user_roles]
        if 40004 not in  role_cluster_ids:
            # Get maximum required scores for each competency, sorted by competency_id
            max_scores = db.session.query(
                RoleCompetencyMatrix.competency_id,
                db.func.max(RoleCompetencyMatrix.role_competency_value).label('max_score')
            ).filter(
                RoleCompetencyMatrix.organization_id == organization_id,
                RoleCompetencyMatrix.role_cluster_id.in_(role_cluster_ids)
            ).group_by(RoleCompetencyMatrix.competency_id).order_by(RoleCompetencyMatrix.competency_id).all()

        elif 40004 in role_cluster_ids:
            print("Fetching for admin view unknown role max values")
            max_scores = db.session.query(
                UnknownRoleCompetencyMatrix.competency_id,
                UnknownRoleCompetencyMatrix.role_competency_value.label('max_score')
            ).filter(
                UnknownRoleCompetencyMatrix.organization_id == organization_id,
                UnknownRoleCompetencyMatrix.user_name.in_(usernames)
            )


        # Format max scores
        max_scores_dict = [{'competency_id': m.competency_id, 'max_score': m.max_score} for m in max_scores]

        # Fetch feedback if only one user is selected
        feedback_list = []
        if len(usernames) == 1:
            user = users[0]
            feedback_query = UserCompetencySurveyFeedback.query.filter_by(
                user_id=user.id,
                organization_id=organization_id
            ).all()
            feedback_list = [feedback.feedback for feedback in feedback_query]

        return jsonify({
            'user_scores': user_scores,
            'max_scores': max_scores_dict,
            'feedback_list': feedback_list  # Include the feedback in the response
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


# Get all users for a specific organization
@main.route('/organization_users', methods=['GET'])
def get_organization_users():
    organization_id = request.args.get('organization_id')

    try:
        users = AppUser.query.filter_by(organization_id=organization_id).all()
        user_list = [{"id": user.id, "name": user.name, "username": user.username} for user in users]
        return jsonify(user_list), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    

#Route to find the ISO processes that the user performs
@main.route('/findProcesses', methods=['POST'])
def find_processes():
    data = request.get_json()
    pipeline = create_pipeline()

    if not data:
        return jsonify({"error": "No input provided"}), 400

    try:
        print("Data received from frontend:", data)

        # Extract username and organization_id from the input data
        username = data.get('username')
        organization_id = data.get('organizationId')
        if not username or not organization_id:
            return jsonify({"error": "Username or Organization ID missing"}), 400

        # Extract tasks from the nested structure
        tasks_responsibilities = data.get("tasks", {})  # Default to an empty dict if "tasks" key is missing

        # Extract individual task categories with appropriate defaults
        tasks_responsibilities = {
            "responsible_for": tasks_responsibilities.get("responsible_for", []),
            "supporting": tasks_responsibilities.get("supporting", []),
            "designing": tasks_responsibilities.get("designing", [])
        }
        print("Input to LLM:", tasks_responsibilities)
        # Run the pipeline with only tasks and responsibilities
        result = pipeline(tasks_responsibilities)
        # Handle invalid tasks case
        if result["status"] == "invalid_tasks":
            return jsonify({
                "status": "invalid_tasks",
                "message": result["message"]
            }), 400

        # Handle success case
        elif result["status"] == "success":
            # Fetch ISO Processes from the database
            iso_processes = IsoProcesses.query.with_entities(IsoProcesses.id, IsoProcesses.name).all()
            iso_process_map = {
                process.name.strip().lower(): process.id for process in iso_processes
            }

            # Prepare a map of process_name -> involvement from LLM result
            llm_process_map = {
                process.process_name.strip().lower(): process.involvement
                for process in result["result"].processes
            }
            print("LLM process maps")
            print(llm_process_map)
            # Prepare the data to insert into UnknownRoleProcessMatrix
            rows_to_insert = []

            for process in iso_processes:
                process_name = process.name.strip().lower()
                iso_process_id = process.id

                # Determine the involvement based on LLM output
                involvement = llm_process_map.get(process_name, "Not performing")

                # Determine role_process_value based on involvement
                if involvement == "Responsible":
                    role_process_value = 2
                elif involvement == "Supporting":
                    role_process_value = 1
                elif involvement == "Designing":
                    role_process_value = 3
                else:
                    role_process_value = 0

                # Add row to insert
                rows_to_insert.append(UnknownRoleProcessMatrix(
                    user_name=username,
                    iso_process_id=iso_process_id,
                    role_process_value=role_process_value,
                    organization_id=organization_id
                ))

            # Insert the rows into UnknownRoleProcessMatrix
            if rows_to_insert:
                db.session.bulk_save_objects(rows_to_insert)
                db.session.commit()

            #Update unknown role competency matrix
            # Call the procedure to update unknown_role_competency_matrix
            try:
                db.session.execute(
                    text(
                        "CALL update_unknown_role_competency_values(:username, :organization_id);"
                    ),
                    {"username": username, "organization_id": organization_id},
                )
                db.session.commit()  # Commit the transaction
            except Exception as db_error:
                print(f"Error while calling the stored procedure: {db_error}")
                db.session.rollback()
                return jsonify({"error": "Failed to update competency matrix"}), 500
            
            # Prepare the response for the frontend
            processes = [
                {
                    "process_name": process.process_name,
                    "involvement": process.involvement
                }
                for process in result["result"].processes
            ]
            return jsonify({
                "status": "success",
                "processes": processes
            }), 200

        # Fallback for unexpected statuses
        else:
            print("LLM pipeline failed", result)
            return jsonify({"error": "Unexpected result from pipeline"}), 500

    except Exception as e:
        print(f"Error processing tasks: {e}")
        db.session.rollback()  # Rollback in case of an error
        return jsonify({"error": str(e)}), 500

@main.route('/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return jsonify({"success": False, "message": "Missing username or password"}), 400

    try:
        # Query the AdminUser table
        user = AdminUser.query.filter_by(username=username).first()

        # Check if user exists and password is correct
        if user and bcrypt.check_password_hash(user.password_hash, password):
            return jsonify({"success": True, "message": "Login successful"}), 200
        else:
            return jsonify({"success": False, "message": "Invalid username or password"}), 401
    except Exception as e:
        print(f"Error during login: {e}")
        return jsonify({"success": False, "message": "An error occurred"}), 500
