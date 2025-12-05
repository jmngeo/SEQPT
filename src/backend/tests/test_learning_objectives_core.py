"""
Unit Tests for Learning Objectives Core Generator
=================================================

Tests for Algorithms 1-3:
1. calculate_combined_targets()
2. validate_mastery_requirements()
3. detect_gaps()

Date: 2025-11-25
Status: Week 1 Implementation
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from app.services.learning_objectives_core import (
    calculate_combined_targets,
    validate_mastery_requirements,
    detect_gaps,
    process_competency_with_roles,
    process_competency_organizational,
    get_archetype_target_level,
    check_if_org_has_roles,
    get_role_competency_requirement,
    calculate_median,
    calculate_mean,
    calculate_variance,
    determine_training_method
)


# =============================================================================
# TEST ALGORITHM 1: calculate_combined_targets()
# =============================================================================

class TestCalculateCombinedTargets:
    """Test suite for calculate_combined_targets()"""

    def test_basic_single_strategy(self):
        """Test with single non-TTT strategy"""

        # Mock StrategyArchetype
        mock_archetype = Mock()
        mock_archetype.competency_1_target = 2
        mock_archetype.competency_2_target = 2
        # ... set all 16 competencies to 2 for simplicity
        for i in range(1, 17):
            setattr(mock_archetype, f'competency_{i}_target', 2)

        strategies = [
            {'strategy_id': 1, 'strategy_name': 'Common basic understanding'}
        ]

        with patch('app.services.learning_objectives_core.StrategyArchetype') as mock_sa:
            mock_sa.query.filter_by.return_value.first.return_value = mock_archetype

            result = calculate_combined_targets(strategies)

            assert result['ttt_selected'] is False
            assert result['ttt_targets'] is None
            assert result['main_targets'][1] == 2
            assert len(result['main_targets']) == 16

    def test_ttt_strategy_separation(self):
        """Test TTT is correctly separated from main targets"""

        # Mock archetypes
        mock_archetype_1 = Mock()
        for i in range(1, 17):
            setattr(mock_archetype_1, f'competency_{i}_target', 2)

        strategies = [
            {'strategy_id': 1, 'strategy_name': 'Common basic understanding'},
            {'strategy_id': 6, 'strategy_name': 'Train the Trainer'}
        ]

        with patch('app.services.learning_objectives_core.StrategyArchetype') as mock_sa:
            mock_sa.query.filter_by.return_value.first.return_value = mock_archetype_1

            result = calculate_combined_targets(strategies)

            assert result['ttt_selected'] is True
            assert result['ttt_targets'] is not None
            assert result['ttt_targets'][1] == 6  # All level 6 for TTT
            assert result['main_targets'][1] == 2  # Main targets from non-TTT
            assert result['ttt_strategy']['strategy_name'] == 'Train the Trainer'

    def test_multiple_strategies_take_higher(self):
        """Test that HIGHER target is taken when multiple strategies"""

        # Mock archetypes with different levels
        mock_archetype_1 = Mock()
        for i in range(1, 17):
            setattr(mock_archetype_1, f'competency_{i}_target', 2)

        mock_archetype_2 = Mock()
        for i in range(1, 17):
            setattr(mock_archetype_2, f'competency_{i}_target', 4)

        strategies = [
            {'strategy_id': 1, 'strategy_name': 'Common basic understanding'},
            {'strategy_id': 2, 'strategy_name': 'Continuous support'}
        ]

        def archetype_side_effect(strategy_id):
            mock = Mock()
            if strategy_id == 1:
                mock.first.return_value = mock_archetype_1
            else:
                mock.first.return_value = mock_archetype_2
            return mock

        with patch('app.services.learning_objectives_core.StrategyArchetype') as mock_sa:
            mock_sa.query.filter_by.side_effect = archetype_side_effect

            result = calculate_combined_targets(strategies)

            # Should take higher target (4)
            assert result['main_targets'][1] == 4

    def test_only_ttt_selected(self):
        """Test edge case: Only TTT selected (no regular training)"""

        strategies = [
            {'strategy_id': 6, 'strategy_name': 'Train the Trainer'}
        ]

        result = calculate_combined_targets(strategies)

        assert result['ttt_selected'] is True
        assert result['ttt_targets'][1] == 6
        assert result['main_targets'][1] == 0  # No regular training

    def test_no_strategies_raises_error(self):
        """Test that no strategies raises ValueError"""

        with pytest.raises(ValueError, match="No strategies selected"):
            calculate_combined_targets([])

    def test_ttt_case_variations(self):
        """Test TTT detection with various naming variations"""

        test_cases = [
            'Train the Trainer',
            'train the trainer',
            'Train the SE-Trainer',
            'TRAIN THE TRAINER'
        ]

        for ttt_name in test_cases:
            strategies = [{'strategy_id': 6, 'strategy_name': ttt_name}]
            result = calculate_combined_targets(strategies)
            assert result['ttt_selected'] is True, f"Failed to detect: {ttt_name}"


# =============================================================================
# TEST ALGORITHM 2: validate_mastery_requirements()
# =============================================================================

class TestValidateMasteryRequirements:
    """Test suite for validate_mastery_requirements()"""

    def test_low_maturity_no_validation(self):
        """Test low maturity org returns OK"""

        with patch('app.services.learning_objectives_core.check_if_org_has_roles') as mock_check:
            mock_check.return_value = False

            result = validate_mastery_requirements(30, [], {})

            assert result['status'] == 'OK'
            assert result['severity'] == 'NONE'
            assert 'low maturity' in result['message'].lower()

    def test_all_requirements_met(self):
        """Test when all role requirements can be met"""

        # Mock role with requirement = 4
        mock_role = Mock()
        mock_role.id = 1
        mock_role.role_name = 'Systems Engineer'

        # Mock competency
        mock_comp = Mock()
        mock_comp.competency_name = 'Requirements Engineering'

        # Strategy provides level 4
        main_targets = {i: 4 for i in range(1, 17)}

        with patch('app.services.learning_objectives_core.check_if_org_has_roles') as mock_check, \
             patch('app.services.learning_objectives_core.OrganizationRole') as mock_or, \
             patch('app.services.learning_objectives_core.get_role_competency_requirement') as mock_req, \
             patch('app.services.learning_objectives_core.Competency') as mock_c:

            mock_check.return_value = True
            mock_or.query.filter_by.return_value.all.return_value = [mock_role]
            mock_req.return_value = 4  # Role requires level 4
            mock_c.query.get.return_value = mock_comp

            result = validate_mastery_requirements(28, [], main_targets)

            assert result['status'] == 'OK'
            assert result['severity'] == 'NONE'

    def test_level_6_required_no_ttt_high_severity(self):
        """Test HIGH severity when Level 6 required but TTT not selected"""

        mock_role = Mock()
        mock_role.id = 1
        mock_role.role_name = 'Senior Systems Engineer'

        mock_comp = Mock()
        mock_comp.competency_name = 'Systems Thinking'

        # Strategy provides level 4, role requires 6
        main_targets = {i: 4 for i in range(1, 17)}

        strategies = [
            {'strategy_id': 1, 'strategy_name': 'Continuous support'}
            # No TTT
        ]

        with patch('app.services.learning_objectives_core.check_if_org_has_roles') as mock_check, \
             patch('app.services.learning_objectives_core.OrganizationRole') as mock_or, \
             patch('app.services.learning_objectives_core.get_role_competency_requirement') as mock_req, \
             patch('app.services.learning_objectives_core.Competency') as mock_c:

            mock_check.return_value = True
            mock_or.query.filter_by.return_value.all.return_value = [mock_role]

            # First competency requires level 6, others 4
            def req_side_effect(role_id, comp_id):
                return 6 if comp_id == 1 else 4
            mock_req.side_effect = req_side_effect

            mock_c.query.get.return_value = mock_comp

            result = validate_mastery_requirements(28, strategies, main_targets)

            assert result['status'] == 'INADEQUATE'
            assert result['severity'] == 'HIGH'
            assert 'Train the Trainer' in result['message']
            assert len(result['affected']) > 0

            # Check recommendations
            recs = [r['action'] for r in result['recommendations']]
            assert 'add_ttt_strategy' in recs

    def test_level_6_required_with_ttt_ok(self):
        """Test OK when Level 6 required and TTT selected"""

        mock_role = Mock()
        mock_role.id = 1
        mock_role.role_name = 'Senior Systems Engineer'

        # Strategy provides level 4, but TTT selected (provides 6)
        main_targets = {i: 4 for i in range(1, 17)}

        strategies = [
            {'strategy_id': 1, 'strategy_name': 'Continuous support'},
            {'strategy_id': 6, 'strategy_name': 'Train the Trainer'}
        ]

        with patch('app.services.learning_objectives_core.check_if_org_has_roles') as mock_check, \
             patch('app.services.learning_objectives_core.OrganizationRole') as mock_or, \
             patch('app.services.learning_objectives_core.get_role_competency_requirement') as mock_req:

            mock_check.return_value = True
            mock_or.query.filter_by.return_value.all.return_value = [mock_role]
            mock_req.return_value = 4  # All requirements can be met by main strategies

            result = validate_mastery_requirements(28, strategies, main_targets)

            # Should be OK because TTT is selected (even if not needed)
            assert result['status'] == 'OK'


# =============================================================================
# TEST ALGORITHM 3: detect_gaps()
# =============================================================================

class TestDetectGaps:
    """Test suite for detect_gaps()"""

    def test_basic_gap_detection_organizational(self):
        """Test basic gap detection for low maturity org"""

        # Mock user scores: some at 0, some at 2
        mock_scores = [0, 0, 2, 2, 4]

        main_targets = {1: 4, 2: 4}  # Target level 4 for comps 1 and 2
        for i in range(3, 17):
            main_targets[i] = 0  # No targets for others

        mock_comp = Mock()
        mock_comp.competency_name = 'Systems Thinking'

        with patch('app.services.learning_objectives_core.check_if_org_has_roles') as mock_check, \
             patch('app.services.learning_objectives_core.get_all_user_scores_for_competency') as mock_scores_fn, \
             patch('app.services.learning_objectives_core.Competency') as mock_c:

            mock_check.return_value = False  # Low maturity
            mock_scores_fn.return_value = mock_scores
            mock_c.query.get.return_value = mock_comp

            result = detect_gaps(30, main_targets)

            assert result['metadata']['has_roles'] is False

            # Competency 1 should have gaps
            comp_1_data = result['by_competency'][1]
            assert comp_1_data['has_gap'] is True
            assert 1 in comp_1_data['levels_needed']  # Users at 0 need level 1
            assert 2 in comp_1_data['levels_needed']  # Users at 0 need level 2
            assert 4 in comp_1_data['levels_needed']  # Users below 4 need level 4

    def test_any_gap_principle(self):
        """Test that even 1 user with gap triggers LO generation"""

        # 19 users at target, 1 user below target
        mock_scores = [4] * 19 + [0]

        main_targets = {1: 4}
        for i in range(2, 17):
            main_targets[i] = 0

        mock_comp = Mock()
        mock_comp.competency_name = 'Systems Thinking'

        with patch('app.services.learning_objectives_core.check_if_org_has_roles') as mock_check, \
             patch('app.services.learning_objectives_core.get_all_user_scores_for_competency') as mock_scores_fn, \
             patch('app.services.learning_objectives_core.Competency') as mock_c:

            mock_check.return_value = False
            mock_scores_fn.return_value = mock_scores
            mock_c.query.get.return_value = mock_comp

            result = detect_gaps(30, main_targets)

            # Should have gap even though median is 4
            comp_1_data = result['by_competency'][1]
            assert comp_1_data['has_gap'] is True
            assert len(comp_1_data['levels_needed']) > 0

    def test_no_gap_all_at_target(self):
        """Test no gaps when all users at or above target"""

        # All users at or above target
        mock_scores = [4, 4, 6, 6]

        main_targets = {1: 4}
        for i in range(2, 17):
            main_targets[i] = 0

        mock_comp = Mock()
        mock_comp.competency_name = 'Systems Thinking'

        with patch('app.services.learning_objectives_core.check_if_org_has_roles') as mock_check, \
             patch('app.services.learning_objectives_core.get_all_user_scores_for_competency') as mock_scores_fn, \
             patch('app.services.learning_objectives_core.Competency') as mock_c:

            mock_check.return_value = False
            mock_scores_fn.return_value = mock_scores
            mock_c.query.get.return_value = mock_comp

            result = detect_gaps(30, main_targets)

            # Should have NO gap
            comp_1_data = result['by_competency'][1]
            assert comp_1_data['has_gap'] is False
            assert len(comp_1_data['levels_needed']) == 0

    def test_progressive_levels(self):
        """Test that progressive levels are generated (1, 2, 4 not just 4)"""

        # User at level 0, target is 4
        mock_scores = [0]

        main_targets = {1: 4}
        for i in range(2, 17):
            main_targets[i] = 0

        mock_comp = Mock()
        mock_comp.competency_name = 'Systems Thinking'

        with patch('app.services.learning_objectives_core.check_if_org_has_roles') as mock_check, \
             patch('app.services.learning_objectives_core.get_all_user_scores_for_competency') as mock_scores_fn, \
             patch('app.services.learning_objectives_core.Competency') as mock_c:

            mock_check.return_value = False
            mock_scores_fn.return_value = mock_scores
            mock_c.query.get.return_value = mock_comp

            result = detect_gaps(30, main_targets)

            comp_1_data = result['by_competency'][1]

            # Should generate ALL intermediate levels
            assert 1 in comp_1_data['levels_needed']
            assert 2 in comp_1_data['levels_needed']
            assert 4 in comp_1_data['levels_needed']
            assert 6 not in comp_1_data['levels_needed']  # Target is 4, not 6


# =============================================================================
# TEST HELPER FUNCTIONS
# =============================================================================

class TestHelperFunctions:
    """Test suite for helper functions"""

    def test_calculate_median_odd_count(self):
        """Test median calculation with odd number of values"""
        assert calculate_median([1, 2, 3, 4, 5]) == 3

    def test_calculate_median_even_count(self):
        """Test median calculation with even number of values"""
        assert calculate_median([1, 2, 3, 4]) == 2  # (2 + 3) / 2 = 2.5 → 2

    def test_calculate_median_empty(self):
        """Test median with empty list"""
        assert calculate_median([]) == 0

    def test_calculate_mean(self):
        """Test mean calculation"""
        assert calculate_mean([2, 4, 4, 4, 6]) == 4.0

    def test_calculate_variance(self):
        """Test variance calculation"""
        values = [2, 4, 4, 4, 6]
        variance = calculate_variance(values)
        assert variance > 0  # Should have some variance

    def test_determine_training_method_high_gap(self):
        """Test training method for high gap percentage"""
        result = determine_training_method(0.8, 0.5, 20)
        assert result['method'] == 'group'
        assert result['confidence'] == 'high'

    def test_determine_training_method_low_gap(self):
        """Test training method for low gap percentage"""
        result = determine_training_method(0.2, 0.5, 20)
        assert result['method'] == 'individual'
        assert result['confidence'] == 'high'

    def test_determine_training_method_high_variance(self):
        """Test training method for high variance"""
        result = determine_training_method(0.5, 2.5, 20)
        assert result['method'] == 'mixed'


# =============================================================================
# INTEGRATION TESTS
# =============================================================================

class TestIntegration:
    """Integration tests combining multiple algorithms"""

    def test_full_pipeline_basic(self):
        """Test full pipeline: targets → validation → gaps"""

        # Step 1: Calculate targets
        strategies = [
            {'strategy_id': 1, 'strategy_name': 'Common basic understanding'}
        ]

        mock_archetype = Mock()
        for i in range(1, 17):
            setattr(mock_archetype, f'competency_{i}_target', 2)

        with patch('app.services.learning_objectives_core.StrategyArchetype') as mock_sa:
            mock_sa.query.filter_by.return_value.first.return_value = mock_archetype

            targets = calculate_combined_targets(strategies)

            assert targets['main_targets'][1] == 2
            assert targets['ttt_selected'] is False

        # Step 2: Validate (low maturity - should be OK)
        with patch('app.services.learning_objectives_core.check_if_org_has_roles') as mock_check:
            mock_check.return_value = False

            validation = validate_mastery_requirements(30, strategies, targets['main_targets'])

            assert validation['status'] == 'OK'

        # Step 3: Detect gaps
        mock_scores = [0, 0, 2, 2]
        mock_comp = Mock()
        mock_comp.competency_name = 'Systems Thinking'

        with patch('app.services.learning_objectives_core.check_if_org_has_roles') as mock_check, \
             patch('app.services.learning_objectives_core.get_all_user_scores_for_competency') as mock_scores_fn, \
             patch('app.services.learning_objectives_core.Competency') as mock_c:

            mock_check.return_value = False
            mock_scores_fn.return_value = mock_scores
            mock_c.query.get.return_value = mock_comp

            gaps = detect_gaps(30, targets['main_targets'])

            assert gaps['by_competency'][1]['has_gap'] is True
