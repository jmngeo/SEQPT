"""
Configuration Loader for Learning Objectives System
Loads and validates thresholds from config file

Created: 2025-11-08
Purpose: Enable threshold tuning without code changes
"""

import json
import os
from typing import Dict, Any
import logging

logger = logging.getLogger(__name__)

# Default configuration (fallback if file not found)
DEFAULT_CONFIG = {
    "validation_thresholds": {
        "critical_gap_threshold": 60,
        "significant_gap_threshold": 20,
        "critical_competency_count": 3,
        "inadequate_gap_percentage": 40
    },
    "priority_weights": {
        "gap_weight": 0.4,
        "role_weight": 0.3,
        "urgency_weight": 0.3
    },
    "algorithm_parameters": {
        "maturity_threshold": 3,
        "max_competency_level": 6,
        "valid_competency_levels": [0, 1, 2, 4, 6]
    },
    "caching": {
        "enabled": True,
        "ttl_hours": 24
    }
}

# Path to configuration file
# Supports both Docker deployment and local development
from pathlib import Path

def get_config_path():
    """
    Get path to configuration file.

    Path resolution order:
    1. Local to backend (Docker): src/backend/config/learning_objectives_config.json
    2. Project root (Local dev): config/learning_objectives_config.json
    """
    current_file = Path(__file__).resolve()
    # Navigate: services -> app -> backend
    backend_root = current_file.parent.parent.parent

    # Path 1: Docker path (config inside backend)
    docker_path = backend_root / 'config' / 'learning_objectives_config.json'
    if docker_path.exists():
        logger.debug(f"[Config] Using Docker path: {docker_path}")
        return str(docker_path)

    # Path 2: Local dev path (config at project root)
    project_root = backend_root.parent.parent  # backend -> src -> project_root
    dev_path = project_root / 'config' / 'learning_objectives_config.json'
    if dev_path.exists():
        logger.debug(f"[Config] Using dev path: {dev_path}")
        return str(dev_path)

    # Return Docker path as default (will show appropriate error if missing)
    logger.warning(f"[Config] No config file found, expected at: {docker_path} or {dev_path}")
    return str(docker_path)

CONFIG_PATH = get_config_path()


def load_config() -> Dict[str, Any]:
    """
    Load configuration from JSON file with fallback to defaults

    Returns:
        Configuration dictionary

    Raises:
        None - logs errors and returns defaults if config file invalid
    """
    if not os.path.exists(CONFIG_PATH):
        logger.warning(
            f"[Config] Configuration file not found at {CONFIG_PATH}. "
            f"Using default configuration."
        )
        return DEFAULT_CONFIG.copy()

    try:
        with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
            config = json.load(f)

        # Validate configuration structure
        validate_config(config)

        logger.info(f"[Config] Loaded configuration from {CONFIG_PATH}")
        return config

    except json.JSONDecodeError as e:
        logger.error(f"[Config] Invalid JSON in configuration file: {e}. Using defaults.")
        return DEFAULT_CONFIG.copy()

    except Exception as e:
        logger.error(f"[Config] Error loading configuration: {e}. Using defaults.")
        return DEFAULT_CONFIG.copy()


def validate_config(config: Dict[str, Any]) -> None:
    """
    Validate configuration structure and values

    Args:
        config: Configuration dictionary to validate

    Raises:
        ValueError: If configuration is invalid
    """
    # Check required sections
    required_sections = ['validation_thresholds', 'priority_weights', 'algorithm_parameters']
    for section in required_sections:
        if section not in config:
            raise ValueError(f"Missing required configuration section: {section}")

    # Validate validation thresholds (percentages 0-100)
    thresholds = config['validation_thresholds']
    for key in ['critical_gap_threshold', 'significant_gap_threshold', 'inadequate_gap_percentage']:
        if key not in thresholds:
            raise ValueError(f"Missing validation threshold: {key}")
        value = thresholds[key]
        if not (0 <= value <= 100):
            raise ValueError(f"Threshold {key} must be between 0 and 100, got {value}")

    # Validate priority weights (should sum to 1.0)
    weights = config['priority_weights']
    for key in ['gap_weight', 'role_weight', 'urgency_weight']:
        if key not in weights:
            raise ValueError(f"Missing priority weight: {key}")

    total_weight = weights['gap_weight'] + weights['role_weight'] + weights['urgency_weight']
    if abs(total_weight - 1.0) > 0.01:  # Allow small floating point error
        logger.warning(
            f"[Config] Priority weights sum to {total_weight:.2f}, expected 1.0. "
            f"Weights will be normalized."
        )


def get_validation_thresholds() -> Dict[str, float]:
    """Get validation thresholds from configuration"""
    config = load_config()
    return config['validation_thresholds']


def get_priority_weights() -> Dict[str, float]:
    """Get priority weights from configuration"""
    config = load_config()
    return config['priority_weights']


def get_algorithm_parameters() -> Dict[str, Any]:
    """Get algorithm parameters from configuration"""
    config = load_config()
    return config['algorithm_parameters']


def is_caching_enabled() -> bool:
    """Check if caching is enabled in configuration"""
    config = load_config()
    return config.get('caching', {}).get('enabled', True)


# =============================================================================
# EXPORT
# =============================================================================

__all__ = [
    'load_config',
    'get_validation_thresholds',
    'get_priority_weights',
    'get_algorithm_parameters',
    'is_caching_enabled'
]
