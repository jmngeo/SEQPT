# SE-QPT Phase 1 Task 3: Training Strategy Selection Implementation

## 1. Strategy Profile Cards Data Structure

### 1.1 Seven SE Training Strategies

```javascript
const SE_TRAINING_STRATEGIES = [
  {
    id: 'se_for_managers',
    name: 'SE for Managers',
    category: 'FOUNDATIONAL',
    description: 'This strategy focuses in particular on managers. They play a major role in the introduction of SE, particularly with regard to change management. They are enablers of change in a company and therefore need an understanding of what it means to introduce and use SE.',
    qualificationLevel: 'Understanding',
    suitablePhase: 'Introductory Phase',
    targetAudience: 'Management and Leadership',
    groupSize: {
      min: 5,
      max: 30,
      optimal: '10-20 managers'
    },
    duration: '1-2 days workshop',
    benefits: [
      'Creates top-level buy-in',
      'Enables change management',
      'Communicates SE benefits clearly'
    ],
    implementation: {
      format: 'Executive Workshop',
      frequency: 'One-time or quarterly refresh',
      prerequisites: 'None'
    }
  },
  
  {
    id: 'common_understanding',
    name: 'Common Basic Understanding',
    category: 'AWARENESS',
    description: 'This strategy is an approach that focuses on interdisciplinary exchange and thus creates awareness for the topic of SE. The focus here is on understanding the fundamental interrelationships of SE as part of basic training and reflecting on them in the group.',
    qualificationLevel: 'Recognition',
    suitablePhase: 'Motivation Phase',
    targetAudience: 'All stakeholders regardless of expertise',
    groupSize: {
      min: 10,
      max: 100,
      optimal: '20-50 participants'
    },
    duration: '2-3 days',
    benefits: [
      'Standardized vocabulary',
      'Low barrier to entry',
      'Breaking down silo thinking',
      'Broad participation possible'
    ],
    drawbacks: [
      'No project reference',
      'Little depth of content',
      'Less acceptance without practical context'
    ]
  },
  
  {
    id: 'orientation_pilot',
    name: 'Orientation in Pilot Project',
    category: 'APPLICATION',
    description: 'The strategy follows an application-oriented approach to qualification. Participants should gain an orientation in SE while applying SE in a pilot project. A team of developers is trained and recognizes the added value of SE through its application.',
    qualificationLevel: 'Application',
    suitablePhase: 'Initial Implementation',
    targetAudience: 'Development teams',
    groupSize: {
      min: 5,
      max: 20,
      optimal: '8-15 team members'
    },
    duration: 'Initial intro + continuous coaching (3-6 months)',
    benefits: [
      'High acceptance',
      'Measurable benefit',
      'Direct testing of content',
      'Motivation through visible success'
    ],
    drawbacks: [
      'Effectiveness depends on project',
      'Not useful for all roles',
      'Time pressure on project makes learning difficult',
      'Suitable project necessary'
    ]
  },
  
  {
    id: 'certification',
    name: 'Certification',
    category: 'SPECIALIZATION',
    description: 'Certifications provide fixed and standardized training content with certification certificates. Typical certifications for SE are SE-Zert and CSEP. Suitable for creating internal SE experts.',
    qualificationLevel: 'Application',
    suitablePhase: 'Motivation Phase',
    targetAudience: 'SE specialists and experts',
    groupSize: {
      min: 1,
      max: 25,
      optimal: '5-15 specialists'
    },
    duration: '5-10 days intensive',
    certificationOptions: ['SE-Zert', 'CSEP', 'INCOSE'],
    benefits: [
      'High standard',
      'International recognition',
      'Technical depth',
      'Ideal for specialists'
    ],
    drawbacks: [
      'No project reference',
      'Low transferability without company-wide introduction',
      'Cost-intensive'
    ]
  },
  
  {
    id: 'continuous_support',
    name: 'Continuous Support',
    category: 'SUSTAINMENT',
    description: 'This qualification strategy focuses on continuous learning in an organization. Based on self-directed, proactive learning, employee queries are collected, documented and answered.',
    qualificationLevel: 'Application',
    suitablePhase: 'Continuation Phase',
    targetAudience: 'All employees in SE environment',
    groupSize: {
      min: 20,
      max: 'Unlimited',
      optimal: 'Scalable to entire organization'
    },
    duration: 'Ongoing',
    requirements: [
      'Trained organization',
      'Defined processes, methods, and tools',
      'Established SE culture'
    ],
    benefits: [
      'Continuous improvement',
      'Just-in-time learning',
      'Cost-effective at scale',
      'Maintains SE momentum'
    ]
  },
  
  {
    id: 'needs_based_project',
    name: 'Needs-based Project-oriented Training',
    category: 'TARGETED',
    description: 'This strategy is aimed at targeted further training for specific roles within the company. Projects are accompanied over a longer period with basic and expert knowledge imparted through training courses.',
    qualificationLevel: 'Understanding to Application',
    suitablePhase: 'Implementation Phase',
    targetAudience: 'Specific roles in projects',
    groupSize: {
      min: 10,
      max: 50,
      optimal: '15-30 per cohort'
    },
    duration: 'Project lifecycle (6-12 months)',
    structure: [
      'Basic training for all participants',
      'Role-specific deepening',
      'Repeated topic-specific sessions'
    ],
    requirements: [
      'Defined processes, methods, and tools',
      'Specified roles and tasks'
    ],
    benefits: [
      'Role-specific content',
      'Direct application',
      'Progressive skill building'
    ]
  },
  
  {
    id: 'train_the_trainer',
    name: 'Train the SE-Trainer',
    category: 'MULTIPLIER',
    description: 'This strategy focuses on training coaches and trainers with the task of bringing SE into the company. Covers company challenges, SE skills, and didactic/moderation skills.',
    qualificationLevel: 'Mastery',
    suitablePhase: 'All phases (supplementary)',
    targetAudience: 'Internal trainers or external providers',
    groupSize: {
      min: 2,
      max: 10,
      optimal: '4-6 trainers'
    },
    duration: '10-20 days intensive + practice',
    trainingAreas: [
      'Company challenges and working methods',
      'Necessary SE skills',
      'Didactic and moderation skills'
    ],
    decisionFactors: {
      internal: {
        pros: ['Repeated training without additional costs', 'Deep company knowledge'],
        cons: ['Extensive upfront training required', 'Time investment']
      },
      external: {
        pros: ['Existing SE knowledge', 'Quick deployment'],
        cons: ['Needs company adaptation', 'Ongoing costs']
      }
    }
  }
];
```

## 2. Decision Tree Implementation

### 2.1 Core Decision Logic

```javascript
class StrategySelectionEngine {
  constructor(maturityData, targetGroupSize) {
    this.maturityData = maturityData;
    this.targetGroupSize = targetGroupSize;
    this.selectedStrategies = [];
    this.decisionPath = [];
  }

  selectStrategies() {
    // Step 1: Always consider Train-the-Trainer first
    this.evaluateTrainTheTrainer();
    
    // Step 2: Main strategy selection based on maturity
    const seProcessesValue = this.maturityData.seRolesProcesses;
    const rolloutScopeValue = this.maturityData.rolloutScope;
    
    if (seProcessesValue <= 1) {
      // Low maturity path: Motivation Phase
      this.selectLowMaturityStrategies();
    } else {
      // Higher maturity path: Implementation/Continuation Phase
      this.selectHighMaturityStrategies(rolloutScopeValue);
    }
    
    // Step 3: Validate strategies against target group size
    this.validateAgainstGroupSize();
    
    return {
      strategies: this.selectedStrategies,
      decisionPath: this.decisionPath,
      reasoning: this.generateReasoning()
    };
  }
  
  evaluateTrainTheTrainer() {
    const shouldAddTrainer = 
      this.targetGroupSize.value >= 100 || 
      this.targetGroupSize.category === 'LARGE' ||
      this.targetGroupSize.category === 'VERY_LARGE' ||
      this.targetGroupSize.category === 'ENTERPRISE';
    
    if (shouldAddTrainer) {
      this.selectedStrategies.push({
        strategy: 'train_the_trainer',
        priority: 'SUPPLEMENTARY',
        reason: `With ${this.targetGroupSize.range} people to train, a train-the-trainer approach will enable scalable knowledge transfer`
      });
      
      this.decisionPath.push({
        step: 1,
        decision: 'Add Train-the-Trainer',
        reason: 'Large target group requires multiplier approach'
      });
    }
  }
  
  selectLowMaturityStrategies() {
    // Primary strategy for low maturity
    this.selectedStrategies.push({
      strategy: 'se_for_managers',
      priority: 'PRIMARY',
      reason: 'Management buy-in is essential for SE introduction in organizations with undefined processes'
    });
    
    this.decisionPath.push({
      step: 2,
      decision: 'Select SE for Managers as primary',
      reason: `SE Processes maturity is "${this.getMaturityLevelName(this.maturityData.seRolesProcesses)}" - requires management enablement first`
    });
    
    // Secondary strategy selection (will be refined by user preference)
    this.secondaryStrategies = [
      {
        strategy: 'common_understanding',
        condition: 'If focus on basic understanding',
        benefits: ['Standardized vocabulary', 'Low barrier to entry', 'Broad participation']
      },
      {
        strategy: 'orientation_pilot',
        condition: 'If focus on practical application',
        benefits: ['High acceptance', 'Measurable benefits', 'Direct testing']
      },
      {
        strategy: 'certification',
        condition: 'If focus on creating experts',
        benefits: ['High standard', 'International recognition', 'Technical depth']
      }
    ];
    
    this.decisionPath.push({
      step: 3,
      decision: 'Select secondary strategy based on preference',
      options: this.secondaryStrategies
    });
  }
  
  selectHighMaturityStrategies(rolloutScopeValue) {
    if (rolloutScopeValue <= 1) {
      // Narrow rollout
      this.selectedStrategies.push({
        strategy: 'needs_based_project',
        priority: 'PRIMARY',
        reason: 'SE processes are defined but not widely deployed - needs targeted project-based training'
      });
      
      this.decisionPath.push({
        step: 2,
        decision: 'Select Needs-based Project-oriented Training',
        reason: `Rollout scope is "${this.getRolloutLevelName(rolloutScopeValue)}" - requires expansion through project training`
      });
    } else {
      // Broad rollout
      this.selectedStrategies.push({
        strategy: 'continuous_support',
        priority: 'PRIMARY',
        reason: 'SE is widely deployed - requires continuous support for sustainment'
      });
      
      this.decisionPath.push({
        step: 2,
        decision: 'Select Continuous Support',
        reason: `Rollout scope is "${this.getRolloutLevelName(rolloutScopeValue)}" - focus on continuous improvement`
      });
    }
  }
  
  getMaturityLevelName(value) {
    const levels = [
      'Not Available',
      'Ad hoc / Undefined',
      'Individually Controlled',
      'Defined and Established',
      'Quantitatively Predictable',
      'Optimized'
    ];
    return levels[value] || 'Unknown';
  }
  
  getRolloutLevelName(value) {
    const levels = [
      'Not Available',
      'Individual Area',
      'Development Area',
      'Company Wide',
      'Value Chain'
    ];
    return levels[value] || 'Unknown';
  }
  
  generateReasoning() {
    const reasoning = {
      maturityFactors: {
        seProcesses: {
          value: this.maturityData.seRolesProcesses,
          level: this.getMaturityLevelName(this.maturityData.seRolesProcesses),
          implication: this.maturityData.seRolesProcesses <= 1 
            ? 'Organization needs foundational SE establishment'
            : 'Organization has established SE processes'
        },
        rolloutScope: {
          value: this.maturityData.rolloutScope,
          level: this.getRolloutLevelName(this.maturityData.rolloutScope),
          implication: this.maturityData.rolloutScope <= 1
            ? 'SE needs broader organizational deployment'
            : 'SE is already widely deployed'
        },
        seMindset: {
          value: this.maturityData.seMindset,
          level: this.getSEMindsetLevelName(this.maturityData.seMindset),
          impact: 'Influences learning readiness and approach'
        },
        knowledgeBase: {
          value: this.maturityData.knowledgeBase,
          level: this.getKnowledgeLevelName(this.maturityData.knowledgeBase),
          impact: 'Affects available resources for training'
        }
      },
      targetGroupConsiderations: {
        size: this.targetGroupSize.range,
        implication: this.getGroupSizeImplication()
      },
      recommendations: this.generateRecommendations()
    };
    
    return reasoning;
  }
  
  getSEMindsetLevelName(value) {
    const levels = [
      'Not Available',
      'Individual / Ad hoc',
      'Fragmented',
      'Established',
      'Optimized'
    ];
    return levels[value] || 'Unknown';
  }
  
  getKnowledgeLevelName(value) {
    const levels = [
      'Not Available',
      'Individual / Ad hoc',
      'Fragmented', 
      'Established',
      'Optimized'
    ];
    return levels[value] || 'Unknown';
  }
  
  getGroupSizeImplication() {
    const implications = {
      'SMALL': 'Suitable for intensive workshops and direct coaching',
      'MEDIUM': 'Requires mixed format approach with cohorts',
      'LARGE': 'Needs scalable formats and train-the-trainer approach',
      'VERY_LARGE': 'Requires phased rollout with multiple trainers',
      'ENTERPRISE': 'Demands enterprise learning program with LMS'
    };
    return implications[this.targetGroupSize.category];
  }
  
  generateRecommendations() {
    const recommendations = [];
    
    // Add specific recommendations based on maturity profile
    if (this.maturityData.seRolesProcesses <= 1) {
      recommendations.push({
        type: 'CRITICAL',
        message: 'Focus on establishing management commitment before broad rollout'
      });
    }
    
    if (this.maturityData.seMindset <= 1) {
      recommendations.push({
        type: 'IMPORTANT',
        message: 'Emphasize cultural change and SE mindset development'
      });
    }
    
    if (this.maturityData.knowledgeBase <= 1) {
      recommendations.push({
        type: 'SUGGESTED',
        message: 'Consider establishing knowledge management system alongside training'
      });
    }
    
    return recommendations;
  }
  
  validateAgainstGroupSize() {
    // Check if selected strategies are appropriate for group size
    this.selectedStrategies.forEach(selection => {
      const strategy = SE_TRAINING_STRATEGIES.find(s => s.id === selection.strategy);
      if (strategy) {
        const targetSize = this.targetGroupSize.value;
        
        if (strategy.groupSize.max !== 'Unlimited' && targetSize > strategy.groupSize.max) {
          selection.warning = `Strategy typically supports up to ${strategy.groupSize.max} participants. Consider multiple cohorts or alternative approach.`;
        }
      }
    });
  }
}
```

## 3. User Interface Components

### 3.1 Strategy Selection Page Component

```javascript
const StrategySelectionPage = ({ maturityData, targetGroupSize, onStrategyConfirm }) => {
  const [selectedStrategies, setSelectedStrategies] = useState([]);
  const [decisionPath, setDecisionPath] = useState([]);
  const [reasoning, setReasoning] = useState(null);
  const [userPreference, setUserPreference] = useState(null);
  const [showProConComparison, setShowProConComparison] = useState(false);
  
  useEffect(() => {
    // Run strategy selection engine
    const engine = new StrategySelectionEngine(maturityData, targetGroupSize);
    const results = engine.selectStrategies();
    
    setSelectedStrategies(results.strategies);
    setDecisionPath(results.decisionPath);
    setReasoning(results.reasoning);
    
    // Check if we need user preference for secondary strategy
    if (maturityData.seRolesProcesses <= 1) {
      setShowProConComparison(true);
    }
  }, [maturityData, targetGroupSize]);
  
  return (
    <div className="strategy-selection-container">
      <header className="page-header">
        <h1>Select SE Training Strategy</h1>
        <p className="subtitle">
          Based on your organization's maturity assessment, we'll recommend 
          appropriate training strategies
        </p>
      </header>
      
      {/* Decision Path Visualization */}
      <section className="decision-visualization">
        <h2>Strategy Selection Process</h2>
        <DecisionTreeVisualization 
          maturityData={maturityData}
          decisionPath={decisionPath}
        />
      </section>
      
      {/* Reasoning Explanation */}
      <section className="reasoning-section">
        <h2>Our Recommendation Rationale</h2>
        <ReasoningExplanation reasoning={reasoning} />
      </section>
      
      {/* Strategy Cards Display */}
      <section className="strategies-display">
        <h2>Training Strategies</h2>
        <p className="section-intro">
          We've pre-selected the most suitable strategies based on your assessment. 
          You can review and modify the selection as needed.
        </p>
        
        <div className="strategy-cards-grid">
          {SE_TRAINING_STRATEGIES.map(strategy => (
            <StrategyCard 
              key={strategy.id}
              strategy={strategy}
              isSelected={selectedStrategies.some(s => s.strategy === strategy.id)}
              isRecommended={selectedStrategies.some(s => 
                s.strategy === strategy.id && s.priority === 'PRIMARY'
              )}
              onToggle={() => handleStrategyToggle(strategy.id)}
            />
          ))}
        </div>
      </section>
      
      {/* Pro-Con Comparison for Low Maturity */}
      {showProConComparison && (
        <section className="pro-con-comparison">
          <h2>Choose Your Secondary Strategy</h2>
          <p>Since your SE processes are in early stages, select a secondary strategy 
             that aligns with your immediate goals:</p>
          <ProConComparison 
            strategies={['common_understanding', 'orientation_pilot', 'certification']}
            onSelect={setUserPreference}
          />
        </section>
      )}
      
      {/* Strategy Summary */}
      <section className="strategy-summary">
        <h2>Selected Training Strategies</h2>
        <StrategySummary 
          strategies={selectedStrategies}
          targetGroupSize={targetGroupSize}
        />
        
        <div className="action-buttons">
          <button className="btn-secondary" onClick={() => window.history.back()}>
            Back
          </button>
          <button 
            className="btn-primary" 
            onClick={() => onStrategyConfirm(selectedStrategies)}
            disabled={selectedStrategies.length === 0}
          >
            Confirm Strategy Selection
          </button>
        </div>
      </section>
    </div>
  );
};
```

### 3.2 Strategy Card Component

```javascript
const StrategyCard = ({ strategy, isSelected, isRecommended, onToggle }) => {
  return (
    <div className={`strategy-card ${isSelected ? 'selected' : ''} ${isRecommended ? 'recommended' : ''}`}>
      {isRecommended && (
        <div className="recommendation-badge">
          <span>✓ Recommended</span>
        </div>
      )}
      
      <div className="card-header">
        <input 
          type="checkbox"
          checked={isSelected}
          onChange={onToggle}
          className="strategy-checkbox"
        />
        <h3>{strategy.name}</h3>
        <span className={`category-badge ${strategy.category.toLowerCase()}`}>
          {strategy.category}
        </span>
      </div>
      
      <div className="card-content">
        <p className="description">{strategy.description}</p>
        
        <div className="strategy-details">
          <div className="detail-item">
            <span className="label">Qualification Level:</span>
            <span className="value">{strategy.qualificationLevel}</span>
          </div>
          
          <div className="detail-item">
            <span className="label">Target Group Size:</span>
            <span className="value">{strategy.groupSize.optimal}</span>
          </div>
          
          <div className="detail-item">
            <span className="label">Duration:</span>
            <span className="value">{strategy.duration}</span>
          </div>
          
          <div className="detail-item">
            <span className="label">Suitable Phase:</span>
            <span className="value">{strategy.suitablePhase}</span>
          </div>
        </div>
        
        {strategy.benefits && (
          <div className="benefits-section">
            <h4>Key Benefits:</h4>
            <ul className="benefits-list">
              {strategy.benefits.slice(0, 3).map((benefit, idx) => (
                <li key={idx}>{benefit}</li>
              ))}
            </ul>
          </div>
        )}
      </div>
      
      <button className="view-details-btn" onClick={() => showStrategyDetails(strategy)}>
        View Full Details
      </button>
    </div>
  );
};
```

### 3.3 Pro-Con Comparison Component

```javascript
const ProConComparison = ({ strategies, onSelect }) => {
  const [selectedStrategy, setSelectedStrategy] = useState(null);
  
  const strategyProCons = {
    common_understanding: {
      pros: [
        'Standardized vocabulary',
        'Low barrier to entry',
        'Breaking down silo thinking',
        'Broad participation possible'
      ],
      cons: [
        'No project reference',
        'Little depth of content',
        'Less acceptance'
      ]
    },
    orientation_pilot: {
      pros: [
        'High acceptance',
        'Measurable benefit',
        'Direct testing of the content',
        'Motivation through visible success'
      ],
      cons: [
        'Effectiveness depends on project',
        'Not useful for all roles',
        'Time pressure on project makes learning difficult',
        'Suitable project necessary'
      ]
    },
    certification: {
      pros: [
        'High standard',
        'International recognition',
        'Technical depth',
        'Ideal for specialists'
      ],
      cons: [
        'No project reference',
        'Low transferability without company-wide introduction',
        'Cost-intensive'
      ]
    }
  };
  
  return (
    <div className="pro-con-comparison">
      <div className="comparison-grid">
        {strategies.map(strategyId => {
          const strategy = SE_TRAINING_STRATEGIES.find(s => s.id === strategyId);
          const proCon = strategyProCons[strategyId];
          
          return (
            <div 
              key={strategyId}
              className={`comparison-card ${selectedStrategy === strategyId ? 'selected' : ''}`}
              onClick={() => {
                setSelectedStrategy(strategyId);
                onSelect(strategyId);
              }}
            >
              <h3>{strategy.name}</h3>
              
              <div className="pros-section">
                <h4>✓ Pros</h4>
                <ul>
                  {proCon.pros.map((pro, idx) => (
                    <li key={idx}>{pro}</li>
                  ))}
                </ul>
              </div>
              
              <div className="cons-section">
                <h4>✗ Cons</h4>
                <ul>
                  {proCon.cons.map((con, idx) => (
                    <li key={idx}>{con}</li>
                  ))}
                </ul>
              </div>
              
              <button className="select-strategy-btn">
                {selectedStrategy === strategyId ? 'Selected' : 'Select This Strategy'}
              </button>
            </div>
          );
        })}
      </div>
    </div>
  );
};
```

### 3.4 Decision Tree Visualization Component

```javascript
const DecisionTreeVisualization = ({ maturityData, decisionPath }) => {
  return (
    <div className="decision-tree-viz">
      <svg viewBox="0 0 800 600" className="tree-svg">
        {/* Render decision tree nodes and connections */}
        <g className="tree-nodes">
          {/* Start Node */}
          <circle cx="400" cy="50" r="30" className="start-node" />
          <text x="400" y="55" textAnchor="middle">Start</text>
          
          {/* Train-the-Trainer Decision */}
          <rect x="350" y="100" width="100" height="60" className="decision-node" />
          <text x="400" y="130" textAnchor="middle">Train the</text>
          <text x="400" y="145" textAnchor="middle">Trainer?</text>
          
          {/* SE Processes Maturity Decision */}
          <rect x="350" y="200" width="100" height="60" className="decision-node" />
          <text x="400" y="225" textAnchor="middle">SE Processes</text>
          <text x="400" y="240" textAnchor="middle">≤ Ad hoc?</text>
          
          {/* Strategy Nodes */}
          <rect x="150" y="300" width="120" height="50" 
                className={`strategy-node ${isStrategySelected('se_for_managers') ? 'selected' : ''}`} />
          <text x="210" y="330" textAnchor="middle">SE for Managers</text>
          
          <rect x="530" y="300" width="120" height="50"
                className={`strategy-node ${isStrategySelected('needs_based_project') ? 'selected' : ''}`} />
          <text x="590" y="325" textAnchor="middle">Needs-based</text>
          <text x="590" y="340" textAnchor="middle">Training</text>
          
          {/* Connection lines */}
          <path d="M 400 80 L 400 100" className="connection-line" />
          <path d="M 400 160 L 400 200" className="connection-line" />
          <path d="M 350 230 L 210 300" className="connection-line yes-path" />
          <path d="M 450 230 L 590 300" className="connection-line no-path" />
          
          {/* Labels */}
          <text x="280" y="265" className="path-label">Yes</text>
          <text x="520" y="265" className="path-label">No</text>
        </g>
        
        {/* Highlight decision path */}
        {decisionPath.map((step, idx) => (
          <g key={idx} className="decision-highlight">
            {/* Render highlighting for each decision step */}
          </g>
        ))}
      </svg>
      
      {/* Decision Path Summary */}
      <div className="path-summary">
        <h3>Your Decision Path:</h3>
        <ol className="path-steps">
          {decisionPath.map((step, idx) => (
            <li key={idx}>
              <strong>{step.decision}</strong>
              <p>{step.reason}</p>
            </li>
          ))}
        </ol>
      </div>
    </div>
  );
};
```

## 4. Updated Phase 1 Review & Confirm Page

```javascript
const Phase1ReviewConfirm = ({ 
  organizationData, 
  maturityAssessment, 
  identifiedRoles, 
  selectedStrategies,
  targetGroupSize 
}) => {
  return (
    <div className="phase1-review-container">
      <header className="review-header">
        <h1>Phase 1: Review & Confirm</h1>
        <p>Please review your SE training preparation details before proceeding</p>
      </header>
      
      <div className="review-sections">
        {/* Section 1: Organization Overview */}
        <section className="review-section">
          <h2>1. Organization Overview</h2>
          <div className="review-content">
            <div className="review-item">
              <span className="label">Organization Name:</span>
              <span className="value">{organizationData.name}</span>
            </div>
            <div className="review-item">
              <span className="label">Organization Size:</span>
              <span className="value">{organizationData.size}</span>
            </div>
            <div className="review-item">
              <span className="label">Industry:</span>
              <span className="value">{organizationData.industry}</span>
            </div>
          </div>
        </section>
        
        {/* Section 2: Systems Engineering Maturity Level */}
        <section className="review-section">
          <h2>2. Systems Engineering Maturity Level</h2>
          <div className="review-content">
            <div className="maturity-overview">
              <div className="overall-score">
                <h3>Overall Maturity Score</h3>
                <div className="score-display">
                  <span className="score-value">{maturityAssessment.finalScore}</span>
                  <span className="score-level">{maturityAssessment.maturityName}</span>
                </div>
              </div>
              
              <div className="dimension-scores">
                <h3>Dimension Scores</h3>
                <div className="dimension-grid">
                  <div className="dimension">
                    <span>Rollout Scope:</span>
                    <span>{maturityAssessment.rolloutScope.level}</span>
                  </div>
                  <div className="dimension">
                    <span>SE Processes:</span>
                    <span>{maturityAssessment.seRolesProcesses.level}</span>
                  </div>
                  <div className="dimension">
                    <span>SE Mindset:</span>
                    <span>{maturityAssessment.seMindset.level}</span>
                  </div>
                  <div className="dimension">
                    <span>Knowledge Base:</span>
                    <span>{maturityAssessment.knowledgeBase.level}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
        
        {/* Section 3: Training Target Group Size */}
        <section className="review-section">
          <h2>3. Training Target Group Size</h2>
          <div className="review-content">
            <div className="review-item">
              <span className="label">Target Group Size:</span>
              <span className="value highlight">{targetGroupSize.range} people</span>
            </div>
            <div className="review-item">
              <span className="label">Size Category:</span>
              <span className="value">{targetGroupSize.category}</span>
            </div>
            <div className="review-item">
              <span className="label">Training Approach:</span>
              <span className="value">{targetGroupSize.approach}</span>
            </div>
          </div>
        </section>
        
        {/* Section 4: Identified SE Roles */}
        <section className="review-section">
          <h2>4. Identified SE Roles</h2>
          <div className="review-content">
            <div className="roles-summary">
              <p>Total roles identified: <strong>{identifiedRoles.length}</strong></p>
              <ul className="roles-list">
                {identifiedRoles.slice(0, 5).map(role => (
                  <li key={role.id}>
                    {role.orgName || role.standardName}
                  </li>
                ))}
                {identifiedRoles.length > 5 && (
                  <li className="more-indicator">
                    ... and {identifiedRoles.length - 5} more roles
                  </li>
                )}
              </ul>
            </div>
          </div>
        </section>
        
        {/* Section 5: Selected Qualification Archetypes */}
        <section className="review-section">
          <h2>5. Selected Qualification Archetypes</h2>
          <div className="review-content">
            <div className="strategies-summary">
              {selectedStrategies.map(strategy => (
                <div key={strategy.strategy} className="strategy-summary-item">
                  <h4>{getStrategyName(strategy.strategy)}</h4>
                  <span className={`priority-badge ${strategy.priority.toLowerCase()}`}>
                    {strategy.priority}
                  </span>
                  <p>{strategy.reason}</p>
                </div>
              ))}
            </div>
          </div>
        </section>
      </div>
      
      {/* Action Buttons */}
      <div className="review-actions">
        <button className="btn-secondary" onClick={() => window.history.back()}>
          Back to Edit
        </button>
        <button className="btn-primary" onClick={() => proceedToPhase2()}>
          Confirm & Proceed to Phase 2
        </button>
      </div>
    </div>
  );
};
```

## 5. Database Schema Updates

```sql
-- Strategy Selection Table
CREATE TABLE strategy_selection (
  id INTEGER PRIMARY KEY,
  org_id INTEGER FOREIGN KEY,
  assessment_id INTEGER FOREIGN KEY,
  
  -- Selected Strategies
  primary_strategy VARCHAR(50),
  secondary_strategy VARCHAR(50),
  has_train_trainer BOOLEAN,
  train_trainer_type VARCHAR(20), -- 'INTERNAL' or 'EXTERNAL'
  
  -- Decision Factors
  decision_based_on_processes INTEGER,
  decision_based_on_rollout INTEGER,
  user_preference VARCHAR(50), -- For low maturity secondary choice
  
  -- Reasoning
  decision_path JSON,
  reasoning_summary TEXT,
  
  -- Timestamps
  created_date TIMESTAMP,
  modified_date TIMESTAMP
);

-- Strategy Customization Table
CREATE TABLE strategy_customization (
  id INTEGER PRIMARY KEY,
  selection_id INTEGER FOREIGN KEY,
  strategy_id VARCHAR(50),
  
  -- Customizations
  custom_duration VARCHAR(100),
  custom_group_size VARCHAR(100),
  implementation_notes TEXT,
  warnings TEXT,
  
  created_date TIMESTAMP
);
```

## 6. API Endpoints

```javascript
// Strategy selection endpoints
POST /api/strategy/calculate
  Body: { maturityData, targetGroupSize }
  Response: { strategies, decisionPath, reasoning }

GET /api/strategy/definitions
  Response: { strategies: [...] }

POST /api/strategy/select
  Body: { orgId, assessmentId, strategies, reasoning }
  Response: { success, selectionId }

GET /api/strategy/pro-con/{strategyIds}
  Response: { comparisons: [...] }

POST /api/strategy/validate
  Body: { strategies, targetGroupSize }
  Response: { valid, warnings }

// Phase 1 completion
POST /api/phase1/complete
  Body: { orgId, maturity, roles, strategies, targetGroupSize }
  Response: { success, phase1Summary }

GET /api/phase1/summary/{orgId}
  Response: { complete phase 1 data }
```

## 7. Styling Guidelines

```css
/* Strategy Card Styling */
.strategy-card {
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  padding: 20px;
  transition: all 0.3s ease;
}

.strategy-card.selected {
  border-color: #2563eb;
  background-color: #eff6ff;
}

.strategy-card.recommended {
  box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.2);
}

.recommendation-badge {
  background: linear-gradient(135deg, #10b981, #059669);
  color: white;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 600;
}

/* Decision Tree Visualization */
.decision-tree-viz {
  background: #f9fafb;
  border-radius: 12px;
  padding: 30px;
}

.tree-svg {
  max-width: 100%;
  height: auto;
}

.decision-node {
  fill: #3b82f6;
  stroke: #1e40af;
  stroke-width: 2;
}

.strategy-node {
  fill: #10b981;
  stroke: #059669;
  stroke-width: 2;
}

.strategy-node.selected {
  fill: #fbbf24;
  stroke: #d97706;
}

.connection-line {
  stroke: #6b7280;
  stroke-width: 2;
  fill: none;
}

.yes-path {
  stroke: #10b981;
  stroke-dasharray: 5,5;
}

.no-path {
  stroke: #ef4444;
  stroke-dasharray: 5,5;
}

/* Pro-Con Comparison */
.comparison-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.comparison-card {
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.comparison-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 10px 25px rgba(0,0,0,0.1);
}

.comparison-card.selected {
  border-color: #3b82f6;
  background: linear-gradient(to bottom, #eff6ff, #ffffff);
}

.pros-section {
  margin-bottom: 20px;
}

.pros-section h4 {
  color: #10b981;
  margin-bottom: 10px;
}

.cons-section h4 {
  color: #ef4444;
  margin-bottom: 10px;
}
```