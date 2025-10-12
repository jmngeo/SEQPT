# Edit Questionnaires

Easy questionnaire editing system for maintaining and updating assessment questions.

## Command Actions:
1. List all available questionnaires by phase
2. Open questionnaire editor for selected questionnaire
3. Validate question structure and logic
4. Test conditional question flows
5. Update scoring algorithms
6. Generate preview of questionnaire
7. Backup current version before changes
8. Validate integration with assessment logic
9. Update database schema if needed
10. Deploy questionnaire updates

## Questionnaire Structure:
```json
{
  "questionnaire_id": "unique_id",
  "name": "Display Name",
  "phase": "phase1|phase2|phase3|phase4", 
  "questions": [...],
  "scoring": {...},
  "validation": {...}
}
```

## Editing Features:
- Add/remove/modify questions
- Update scoring weights and methods
- Configure conditional logic
- Set validation rules
- Preview questionnaire flow
- Test with sample data

## Interactive Menu:

1. Phase 1: Maturity Assessment, Archetype Selection
2. Phase 2: Competency Assessment (Derik's + Extensions)
3. Phase 3: Format Preferences, Module Selection
4. Phase 4: Implementation Planning, Success Criteria
