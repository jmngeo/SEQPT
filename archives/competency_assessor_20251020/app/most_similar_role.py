import numpy as np
from sqlalchemy import func
from sqlalchemy.orm import Session
from app import db
from app.models import RoleCompetencyMatrix

def find_most_similar_role_cluster(organization_id, user_scores):
    """
    Finds the most similar role cluster based on Euclidean, Manhattan, and Cosine distances.
    
    Parameters:
    - organization_id: int, the ID of the organization to filter the query.
    - new_role: np.array, the competency vector of the new role.

    Returns:
    - dict: contains the closest role cluster for each distance metric.
    """
    # Query the database for competency values grouped by role_cluster_id and competency_id
    results = (
        db.session.query(
            RoleCompetencyMatrix.role_cluster_id,
            RoleCompetencyMatrix.competency_id,
            func.sum(RoleCompetencyMatrix.role_competency_value).label('role_competency_value')
        )
        .filter(RoleCompetencyMatrix.organization_id == organization_id)
        .group_by(RoleCompetencyMatrix.competency_id, RoleCompetencyMatrix.role_cluster_id)
        .order_by(RoleCompetencyMatrix.role_cluster_id)
        .all()
    )

    # Organize the results into vectors for each role cluster
    role_clusters = {}
    for row in results:
        role_cluster_id = row.role_cluster_id
        competency_id = row.competency_id
        competency_value = row.role_competency_value

        if role_cluster_id not in role_clusters:
            role_clusters[role_cluster_id] = {}
        role_clusters[role_cluster_id][competency_id] = competency_value

    # Create competency vectors
    all_competency_ids = sorted(
        {row.competency_id for row in results}
    )  
    
    # Create a mapping of competency_id to score from user_scores
    user_scores_map = {entry['competency_id']: entry['score'] for entry in user_scores}

    # Build the new role vector using user_scores_map
    new_role_vector = np.array([user_scores_map.get(c_id, 0) for c_id in all_competency_ids])

    # Ensure consistent ordering of competencies
    existing_roles = {
        role_cluster: np.array([role_clusters[role_cluster].get(c_id, 0) for c_id in all_competency_ids])
        for role_cluster in role_clusters
    }

    # Define distance functions
    def euclidean_distance(vec1, vec2):
        return np.linalg.norm(vec1 - vec2)

    def manhattan_distance(vec1, vec2):
        return np.sum(np.abs(vec1 - vec2))

    def cosine_distance(vec1, vec2):
        dot_product = np.dot(vec1, vec2)
        magnitude1 = np.linalg.norm(vec1)
        magnitude2 = np.linalg.norm(vec2)
        return 1 - (dot_product / (magnitude1 * magnitude2))

    # Compute distances
    distances = {
        "euclidean": {},
        "manhattan": {},
        "cosine": {}
    }

    for role, vec in existing_roles.items():
        distances["euclidean"][role] = euclidean_distance(new_role_vector, vec)
        distances["manhattan"][role] = manhattan_distance(new_role_vector, vec)
        distances["cosine"][role] = cosine_distance(new_role_vector, vec)

    # # Find the closest roles
    # closest_roles = {
    #     metric: min(roles, key=roles.get)
    #     for metric, roles in distances.items()
    # }

    # Find all role clusters with the minimum similarity for each metric
    closest_roles = {
        metric: [
            role for role, distance in roles.items()
            if distance == min(roles.values())
        ]
        for metric, roles in distances.items()
    }


    # Log the results
    print(f"Distances by metric: {distances}")
    print(f"Closest roles: {closest_roles}")

    # Return the role cluster ID for the most similar role (based on Euclidean distance as primary)
    return closest_roles["euclidean"]

