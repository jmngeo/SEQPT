<template>
  <div class="phase-four">
    <div class="phase-header">
      <div class="phase-indicator">
        <div class="phase-number">4</div>
        <div class="phase-title">
          <h1>Phase 4: Micro Planning</h1>
          <p>Create detailed implementation concept and timeline</p>
        </div>
      </div>
      <div class="progress-bar">
        <div class="progress-fill" :style="{ width: `${(currentStep / totalSteps) * 100}%` }"></div>
      </div>
    </div>

    <div class="step-indicator">
      <div
        v-for="step in totalSteps"
        :key="step"
        class="step-dot"
        :class="{
          'active': step === currentStep,
          'completed': step < currentStep
        }"
      >
        {{ step }}
      </div>
    </div>

    <!-- Step 1: Cohort Matching -->
    <div v-if="currentStep === 1" class="step-content">
      <div class="step-header">
        <h2><i class="el-icon-user"></i> Cohort Matching & Formation</h2>
        <p>Find and form learning cohorts based on similar qualification needs and preferences</p>
      </div>

      <div class="cohort-matching">
        <el-row :gutter="20">
          <el-col :span="8">
            <el-card class="user-profile">
              <template #header>
                <span>Your Profile</span>
              </template>
              <div class="profile-summary">
                <div class="profile-item">
                  <strong>Role:</strong> {{ userProfile.role }}
                </div>
                <div class="profile-item">
                  <strong>Experience:</strong> {{ userProfile.experience }} years
                </div>
                <div class="profile-item">
                  <strong>Location:</strong> {{ userProfile.location }}
                </div>
                <div class="profile-item">
                  <strong>Qualification Modules:</strong> {{ userProfile.selectedModules.length }}
                </div>
                <div class="profile-item">
                  <strong>Preferred Format:</strong> {{ userProfile.preferredFormat }}
                </div>
                <div class="profile-item">
                  <strong>Availability:</strong> {{ userProfile.availability }}
                </div>
              </div>
            </el-card>
          </el-col>
          <el-col :span="16">
            <el-card class="matching-options">
              <template #header>
                <span>Cohort Formation Options</span>
                <el-button
                  type="text"
                  @click="findMatches"
                  :loading="matching"
                  style="float: right;"
                >
                  <i class="el-icon-search"></i> Find Matches
                </el-button>
              </template>
              <el-tabs v-model="activeMatchingTab" type="card">
                <el-tab-pane label="Automatic Matching" name="automatic">
                  <div class="automatic-matching">
                    <el-form :model="matchingCriteria" label-width="150px">
                      <el-form-item label="Match Priority">
                        <el-radio-group v-model="matchingCriteria.priority">
                          <el-radio label="modules">Similar Modules</el-radio>
                          <el-radio label="role">Same Role</el-radio>
                          <el-radio label="location">Geographic Proximity</el-radio>
                          <el-radio label="schedule">Schedule Compatibility</el-radio>
                        </el-radio-group>
                      </el-form-item>
                      <el-form-item label="Cohort Size">
                        <el-slider
                          v-model="matchingCriteria.cohortSize"
                          :min="3"
                          :max="12"
                          show-stops
                          :marks="{ 3: '3', 6: '6', 9: '9', 12: '12' }"
                        ></el-slider>
                      </el-form-item>
                      <el-form-item label="Match Threshold">
                        <el-slider
                          v-model="matchingCriteria.threshold"
                          :min="50"
                          :max="95"
                          :step="5"
                          show-input
                        ></el-slider>
                      </el-form-item>
                    </el-form>
                  </div>
                </el-tab-pane>
                <el-tab-pane label="Browse Cohorts" name="browse">
                  <div class="browse-cohorts">
                    <div class="cohort-filters">
                      <el-row :gutter="15">
                        <el-col :span="6">
                          <el-select v-model="cohortFilters.status" placeholder="Status">
                            <el-option label="All" value=""></el-option>
                            <el-option label="Forming" value="forming"></el-option>
                            <el-option label="Open" value="open"></el-option>
                            <el-option label="Full" value="full"></el-option>
                          </el-select>
                        </el-col>
                        <el-col :span="6">
                          <el-select v-model="cohortFilters.format" placeholder="Format">
                            <el-option label="All" value=""></el-option>
                            <el-option label="Online" value="online"></el-option>
                            <el-option label="In-Person" value="in-person"></el-option>
                            <el-option label="Hybrid" value="hybrid"></el-option>
                          </el-select>
                        </el-col>
                        <el-col :span="6">
                          <el-select v-model="cohortFilters.role" placeholder="Role">
                            <el-option label="All" value=""></el-option>
                            <el-option
                              v-for="role in availableRoles"
                              :key="role"
                              :label="role"
                              :value="role"
                            ></el-option>
                          </el-select>
                        </el-col>
                        <el-col :span="6">
                          <el-input
                            v-model="cohortFilters.search"
                            placeholder="Search cohorts..."
                            prefix-icon="el-icon-search"
                          ></el-input>
                        </el-col>
                      </el-row>
                    </div>
                  </div>
                </el-tab-pane>
                <el-tab-pane label="Create New" name="create">
                  <div class="create-cohort">
                    <el-form :model="newCohort" label-width="150px">
                      <el-form-item label="Cohort Name" required>
                        <el-input v-model="newCohort.name" placeholder="Enter cohort name"></el-input>
                      </el-form-item>
                      <el-form-item label="Description">
                        <el-input
                          v-model="newCohort.description"
                          type="textarea"
                          :rows="3"
                          placeholder="Describe the cohort goals and target audience"
                        ></el-input>
                      </el-form-item>
                      <el-form-item label="Target Roles">
                        <el-select
                          v-model="newCohort.targetRoles"
                          multiple
                          placeholder="Select target roles"
                        >
                          <el-option
                            v-for="role in availableRoles"
                            :key="role"
                            :label="role"
                            :value="role"
                          ></el-option>
                        </el-select>
                      </el-form-item>
                      <el-form-item label="Max Size">
                        <el-input-number
                          v-model="newCohort.maxSize"
                          :min="3"
                          :max="20"
                        ></el-input-number>
                      </el-form-item>
                      <el-form-item label="Visibility">
                        <el-radio-group v-model="newCohort.visibility">
                          <el-radio label="public">Public</el-radio>
                          <el-radio label="invite-only">Invite Only</el-radio>
                          <el-radio label="organization">Organization Only</el-radio>
                        </el-radio-group>
                      </el-form-item>
                    </el-form>
                    <el-button
                      type="primary"
                      @click="createCohort"
                      :loading="creating"
                      :disabled="!newCohort.name"
                    >
                      Create Cohort
                    </el-button>
                  </div>
                </el-tab-pane>
              </el-tabs>
            </el-card>
          </el-col>
        </el-row>

        <el-card v-if="matchedCohorts.length > 0" class="matched-cohorts">
          <template #header>
            <span>Matched Cohorts ({{ matchedCohorts.length }})</span>
          </template>
          <div class="cohorts-grid">
            <div
              v-for="cohort in filteredCohorts"
              :key="cohort.id"
              class="cohort-card"
              :class="{ 'selected': selectedCohort === cohort.id }"
              @click="selectCohort(cohort.id)"
            >
              <div class="cohort-header">
                <h4>{{ cohort.name }}</h4>
                <el-tag :type="getCohortStatusType(cohort.status)">{{ cohort.status }}</el-tag>
              </div>
              <div class="cohort-details">
                <p>{{ cohort.description }}</p>
                <div class="cohort-stats">
                  <div class="stat">
                    <i class="el-icon-user"></i>
                    <span>{{ cohort.currentMembers }}/{{ cohort.maxSize }}</span>
                  </div>
                  <div class="stat">
                    <i class="el-icon-location"></i>
                    <span>{{ cohort.format }}</span>
                  </div>
                  <div class="stat">
                    <i class="el-icon-star"></i>
                    <span>{{ cohort.compatibility }}% match</span>
                  </div>
                </div>
                <div class="cohort-modules">
                  <small>Modules: {{ cohort.commonModules.join(', ') }}</small>
                </div>
              </div>
            </div>
          </div>
        </el-card>
      </div>

      <div class="step-actions">
        <el-button @click="$router.push('/phases/3')">Back to Phase 3</el-button>
        <el-button
          type="primary"
          @click="nextStep"
          :disabled="!selectedCohort && activeMatchingTab !== 'create'"
        >
          Continue to Schedule Planning
        </el-button>
      </div>
    </div>

    <!-- Step 2: Schedule Planning -->
    <div v-if="currentStep === 2" class="step-content">
      <div class="step-header">
        <h2><i class="el-icon-date"></i> Schedule Planning & Coordination</h2>
        <p>Coordinate schedules and plan training timeline with your cohort</p>
      </div>

      <div class="schedule-planning">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-card class="cohort-info">
              <template #header>
                <span>Cohort Information</span>
              </template>
              <div v-if="currentCohort" class="cohort-summary">
                <h4>{{ currentCohort.name }}</h4>
                <p>{{ currentCohort.description }}</p>
                <div class="members-list">
                  <h5>Members ({{ currentCohort.members.length }})</h5>
                  <div class="member-avatars">
                    <el-avatar
                      v-for="member in currentCohort.members"
                      :key="member.id"
                      :src="member.avatar"
                      :title="member.name"
                    >
                      {{ member.name.charAt(0) }}
                    </el-avatar>
                  </div>
                </div>
              </div>
            </el-card>

            <el-card class="availability-input">
              <template #header>
                <span>Your Availability</span>
              </template>
              <el-form :model="availability" label-width="120px">
                <el-form-item label="Time Zone">
                  <el-select v-model="availability.timezone" placeholder="Select timezone">
                    <el-option
                      v-for="tz in timezones"
                      :key="tz.value"
                      :label="tz.label"
                      :value="tz.value"
                    ></el-option>
                  </el-select>
                </el-form-item>
                <el-form-item label="Preferred Days">
                  <el-checkbox-group v-model="availability.days">
                    <el-checkbox label="monday">Monday</el-checkbox>
                    <el-checkbox label="tuesday">Tuesday</el-checkbox>
                    <el-checkbox label="wednesday">Wednesday</el-checkbox>
                    <el-checkbox label="thursday">Thursday</el-checkbox>
                    <el-checkbox label="friday">Friday</el-checkbox>
                    <el-checkbox label="saturday">Saturday</el-checkbox>
                    <el-checkbox label="sunday">Sunday</el-checkbox>
                  </el-checkbox-group>
                </el-form-item>
                <el-form-item label="Time Slots">
                  <el-time-picker
                    v-model="availability.timeSlots"
                    is-range
                    range-separator="to"
                    start-placeholder="Start time"
                    end-placeholder="End time"
                    format="HH:mm"
                  ></el-time-picker>
                </el-form-item>
                <el-form-item label="Blackout Dates">
                  <el-date-picker
                    v-model="availability.blackoutDates"
                    type="dates"
                    placeholder="Select unavailable dates"
                  ></el-date-picker>
                </el-form-item>
              </el-form>
              <el-button type="primary" @click="updateAvailability" :loading="updatingAvailability">
                Update Availability
              </el-button>
            </el-card>
          </el-col>
          <el-col :span="12">
            <el-card class="schedule-coordination">
              <template #header>
                <span>Schedule Coordination</span>
                <el-button
                  type="text"
                  @click="generateSchedule"
                  :loading="generatingSchedule"
                  style="float: right;"
                >
                  <i class="el-icon-refresh"></i> Generate Options
                </el-button>
              </template>
              <div v-if="scheduleOptions.length === 0" class="no-schedule">
                <el-empty description="No schedule options generated yet">
                  <el-button type="primary" @click="generateSchedule" :loading="generatingSchedule">
                    Generate Schedule Options
                  </el-button>
                </el-empty>
              </div>
              <div v-else class="schedule-options">
                <el-radio-group v-model="selectedSchedule" class="schedule-list">
                  <el-radio
                    v-for="option in scheduleOptions"
                    :key="option.id"
                    :label="option.id"
                    class="schedule-option"
                  >
                    <div class="option-content">
                      <h5>{{ option.name }}</h5>
                      <p>{{ option.description }}</p>
                      <div class="option-details">
                        <span class="duration">{{ option.totalDuration }} days</span>
                        <span class="sessions">{{ option.sessions.length }} sessions</span>
                        <span class="compatibility">{{ option.compatibility }}% compatible</span>
                      </div>
                    </div>
                  </el-radio>
                </el-radio-group>
              </div>
            </el-card>

            <el-card v-if="selectedSchedule" class="schedule-preview">
              <template #header>
                <span>Schedule Preview</span>
              </template>
              <div class="schedule-timeline">
                <div
                  v-for="session in selectedScheduleData.sessions"
                  :key="session.id"
                  class="session-item"
                >
                  <div class="session-date">
                    <div class="date">{{ formatDate(session.date) }}</div>
                    <div class="time">{{ formatTime(session.startTime) }} - {{ formatTime(session.endTime) }}</div>
                  </div>
                  <div class="session-content">
                    <h5>{{ session.module }}</h5>
                    <p>{{ session.description }}</p>
                    <div class="session-details">
                      <span class="format">{{ session.format }}</span>
                      <span class="duration">{{ session.duration }}h</span>
                    </div>
                  </div>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </div>

      <div class="step-actions">
        <el-button @click="previousStep">Previous</el-button>
        <el-button
          type="primary"
          @click="nextStep"
          :disabled="!selectedSchedule"
        >
          Continue to Individual Planning
        </el-button>
      </div>
    </div>

    <!-- Step 3: Individual Planning -->
    <div v-if="currentStep === 3" class="step-content">
      <div class="step-header">
        <h2><i class="el-icon-user"></i> Individual Qualification Planning</h2>
        <p>Create your personalized qualification plan with milestones and progress tracking</p>
      </div>

      <div class="individual-planning">
        <el-row :gutter="20">
          <el-col :span="16">
            <el-card class="plan-builder">
              <template #header>
                <span>Qualification Plan Builder</span>
              </template>
              <el-tabs v-model="activePlanTab" type="card">
                <el-tab-pane label="Modules & Timeline" name="modules">
                  <div class="modules-timeline">
                    <div class="timeline-header">
                      <h4>Training Timeline</h4>
                      <div class="timeline-controls">
                        <el-button-group>
                          <el-button :type="timelineView === 'month' ? 'primary' : ''" @click="timelineView = 'month'">Month</el-button>
                          <el-button :type="timelineView === 'quarter' ? 'primary' : ''" @click="timelineView = 'quarter'">Quarter</el-button>
                          <el-button :type="timelineView === 'year' ? 'primary' : ''" @click="timelineView = 'year'">Year</el-button>
                        </el-button-group>
                      </div>
                    </div>
                    <div class="timeline-content">
                      <div
                        v-for="module in plannedModules"
                        :key="module.id"
                        class="timeline-module"
                        :style="getModulePosition(module)"
                      >
                        <div class="module-info">
                          <h5>{{ module.title }}</h5>
                          <p>{{ formatDateRange(module.startDate, module.endDate) }}</p>
                        </div>
                        <div class="module-progress">
                          <el-progress :percentage="module.progress" :stroke-width="6"></el-progress>
                        </div>
                      </div>
                    </div>
                  </div>
                </el-tab-pane>
                <el-tab-pane label="Learning Objectives" name="objectives">
                  <div class="learning-objectives">
                    <div class="objectives-header">
                      <h4>Personal Learning Objectives</h4>
                      <el-button type="primary" @click="addObjective">
                        <i class="el-icon-plus"></i> Add Objective
                      </el-button>
                    </div>
                    <div class="objectives-list">
                      <div
                        v-for="(objective, index) in personalObjectives"
                        :key="index"
                        class="objective-item"
                      >
                        <div class="objective-content">
                          <el-input
                            v-model="objective.text"
                            placeholder="Enter learning objective..."
                            @blur="updateObjective(index)"
                          ></el-input>
                          <div class="objective-details">
                            <el-select v-model="objective.priority" size="small">
                              <el-option label="High" value="high"></el-option>
                              <el-option label="Medium" value="medium"></el-option>
                              <el-option label="Low" value="low"></el-option>
                            </el-select>
                            <el-date-picker
                              v-model="objective.targetDate"
                              type="date"
                              placeholder="Target date"
                              size="small"
                            ></el-date-picker>
                          </div>
                        </div>
                        <div class="objective-actions">
                          <el-button
                            type="danger"
                            icon="el-icon-delete"
                            size="small"
                            @click="removeObjective(index)"
                          ></el-button>
                        </div>
                      </div>
                    </div>
                  </div>
                </el-tab-pane>
                <el-tab-pane label="Milestones" name="milestones">
                  <div class="milestones">
                    <div class="milestones-header">
                      <h4>Progress Milestones</h4>
                      <el-button type="primary" @click="generateMilestones" :loading="generatingMilestones">
                        <i class="el-icon-magic-stick"></i> Auto-generate
                      </el-button>
                    </div>
                    <div class="milestones-list">
                      <div
                        v-for="milestone in milestones"
                        :key="milestone.id"
                        class="milestone-item"
                        :class="{ 'completed': milestone.completed }"
                      >
                        <div class="milestone-marker">
                          <el-checkbox
                            v-model="milestone.completed"
                            @change="updateMilestone(milestone.id)"
                          ></el-checkbox>
                        </div>
                        <div class="milestone-content">
                          <h5>{{ milestone.title }}</h5>
                          <p>{{ milestone.description }}</p>
                          <div class="milestone-details">
                            <span class="target-date">{{ formatDate(milestone.targetDate) }}</span>
                            <el-tag :type="getMilestoneType(milestone.type)">{{ milestone.type }}</el-tag>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </el-tab-pane>
              </el-tabs>
            </el-card>
          </el-col>
          <el-col :span="8">
            <el-card class="plan-summary">
              <template #header>
                <span>Plan Summary</span>
              </template>
              <div class="summary-stats">
                <div class="stat-group">
                  <div class="stat-item">
                    <div class="stat-value">{{ plannedModules.length }}</div>
                    <div class="stat-label">Training Modules</div>
                  </div>
                  <div class="stat-item">
                    <div class="stat-value">{{ totalTrainingDays }}</div>
                    <div class="stat-label">Training Days</div>
                  </div>
                </div>
                <div class="stat-group">
                  <div class="stat-item">
                    <div class="stat-value">{{ personalObjectives.length }}</div>
                    <div class="stat-label">Personal Objectives</div>
                  </div>
                  <div class="stat-item">
                    <div class="stat-value">{{ completedMilestones }}</div>
                    <div class="stat-label">Completed Milestones</div>
                  </div>
                </div>
              </div>
              <div class="progress-overview">
                <h5>Overall Progress</h5>
                <el-progress
                  type="circle"
                  :percentage="overallProgress"
                  :width="120"
                ></el-progress>
              </div>
            </el-card>

            <el-card class="plan-actions">
              <template #header>
                <span>Actions</span>
              </template>
              <div class="action-buttons">
                <el-button type="primary" @click="exportPlan" :loading="exporting">
                  <i class="el-icon-download"></i> Export Plan
                </el-button>
                <el-button @click="sharePlan">
                  <i class="el-icon-share"></i> Share with Cohort
                </el-button>
                <el-button @click="scheduleMeeting">
                  <i class="el-icon-phone"></i> Schedule Review
                </el-button>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </div>

      <div class="step-actions">
        <el-button @click="previousStep">Previous</el-button>
        <el-button type="primary" @click="nextStep">Continue to Finalization</el-button>
      </div>
    </div>

    <!-- Step 4: Finalization -->
    <div v-if="currentStep === 4" class="step-content">
      <div class="step-header">
        <h2><i class="el-icon-check"></i> Plan Finalization & Launch</h2>
        <p>Review and finalize your complete SE qualification plan</p>
      </div>

      <div class="finalization">
        <el-card class="final-review">
          <template #header>
            <span>Complete Qualification Plan Review</span>
          </template>
          <el-tabs type="border-card">
            <el-tab-pane label="Overview">
              <div class="plan-overview">
                <el-row :gutter="20">
                  <el-col :span="12">
                    <div class="overview-section">
                      <h4>Qualification Summary</h4>
                      <div class="summary-grid">
                        <div class="summary-item">
                          <strong>Target Role:</strong> {{ userProfile.role }}
                        </div>
                        <div class="summary-item">
                          <strong>Qualification Archetype:</strong> {{ selectedArchetype }}
                        </div>
                        <div class="summary-item">
                          <strong>Cohort:</strong> {{ currentCohort?.name || 'Individual' }}
                        </div>
                        <div class="summary-item">
                          <strong>Total Duration:</strong> {{ totalTrainingDays }} days
                        </div>
                        <div class="summary-item">
                          <strong>Start Date:</strong> {{ formatDate(planStartDate) }}
                        </div>
                        <div class="summary-item">
                          <strong>Expected Completion:</strong> {{ formatDate(planEndDate) }}
                        </div>
                      </div>
                    </div>
                  </el-col>
                  <el-col :span="12">
                    <div class="overview-section">
                      <h4>Competency Development</h4>
                      <div class="competency-progress">
                        <div
                          v-for="competency in competencyDevelopment"
                          :key="competency.name"
                          class="competency-item"
                        >
                          <div class="competency-name">{{ competency.name }}</div>
                          <div class="competency-levels">
                            <span class="current-level">Current: L{{ competency.currentLevel }}</span>
                            <el-icon class="arrow"><i class="el-icon-right"></i></el-icon>
                            <span class="target-level">Target: L{{ competency.targetLevel }}</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </el-col>
                </el-row>
              </div>
            </el-tab-pane>
            <el-tab-pane label="Training Schedule">
              <div class="schedule-overview">
                <div class="schedule-header">
                  <h4>Training Schedule</h4>
                  <div class="schedule-stats">
                    <span>{{ plannedModules.length }} modules</span>
                    <span>{{ totalTrainingDays }} days</span>
                    <span>{{ currentCohort?.members.length || 1 }} participants</span>
                  </div>
                </div>
                <div class="schedule-calendar">
                  <div
                    v-for="module in plannedModules"
                    :key="module.id"
                    class="calendar-module"
                  >
                    <div class="module-date">{{ formatDate(module.startDate) }}</div>
                    <div class="module-info">
                      <h5>{{ module.title }}</h5>
                      <p>{{ module.description }}</p>
                      <div class="module-meta">
                        <span>{{ module.duration }}h</span>
                        <span>{{ module.format }}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </el-tab-pane>
            <el-tab-pane label="Learning Objectives">
              <div class="objectives-overview">
                <h4>SMART Learning Objectives</h4>
                <div class="objectives-grid">
                  <div
                    v-for="objective in allObjectives"
                    :key="objective.id"
                    class="objective-card"
                  >
                    <div class="objective-header">
                      <el-tag :type="getPriorityType(objective.priority)">{{ objective.priority }}</el-tag>
                      <span class="objective-type">{{ objective.type }}</span>
                    </div>
                    <div class="objective-content">
                      <p>{{ objective.text }}</p>
                      <div class="objective-validation">
                        <div class="smart-score">
                          <span>SMART Score: {{ objective.smartScore }}%</span>
                          <el-progress :percentage="objective.smartScore" :stroke-width="4"></el-progress>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </el-tab-pane>
          </el-tabs>
        </el-card>

        <el-card class="final-confirmations">
          <template #header>
            <span>Final Confirmations</span>
          </template>
          <div class="confirmations">
            <el-checkbox v-model="finalConfirmations.planReviewed">
              I have thoroughly reviewed my complete qualification plan
            </el-checkbox>
            <el-checkbox v-model="finalConfirmations.scheduleConfirmed">
              I confirm the training schedule and commit to attendance
            </el-checkbox>
            <el-checkbox v-model="finalConfirmations.objectivesAccepted">
              I accept the learning objectives and success criteria
            </el-checkbox>
            <el-checkbox v-model="finalConfirmations.cohortAgreed">
              I agree to participate actively in my cohort (if applicable)
            </el-checkbox>
            <el-checkbox v-model="finalConfirmations.progressTracking">
              I consent to progress tracking and assessment
            </el-checkbox>
            <el-checkbox v-model="finalConfirmations.readyToLaunch">
              I am ready to launch my SE qualification journey
            </el-checkbox>
          </div>
        </el-card>
      </div>

      <div class="step-actions">
        <el-button @click="previousStep">Previous</el-button>
        <el-button
          type="success"
          size="large"
          @click="launchPlan"
          :disabled="!allFinalConfirmationsChecked"
          :loading="launching"
        >
          <i class="el-icon-rocket"></i> Launch Qualification Plan
        </el-button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from '@/api/axios'

export default {
  name: 'PhaseFour',
  setup() {
    const router = useRouter()
    const currentStep = ref(1)
    const totalSteps = 4

    // Loading states
    const matching = ref(false)
    const creating = ref(false)
    const updatingAvailability = ref(false)
    const generatingSchedule = ref(false)
    const generatingMilestones = ref(false)
    const exporting = ref(false)
    const launching = ref(false)

    // User profile and data
    const userProfile = ref({
      role: '',
      experience: 0,
      location: '',
      selectedModules: [],
      preferredFormat: '',
      availability: ''
    })

    // Cohort matching
    const activeMatchingTab = ref('automatic')
    const matchingCriteria = ref({
      priority: 'modules',
      cohortSize: 6,
      threshold: 75
    })

    const cohortFilters = ref({
      status: '',
      format: '',
      role: '',
      search: ''
    })

    const newCohort = ref({
      name: '',
      description: '',
      targetRoles: [],
      maxSize: 8,
      visibility: 'public'
    })

    const matchedCohorts = ref([])
    const selectedCohort = ref(null)
    const currentCohort = ref(null)

    // Schedule planning
    const availability = ref({
      timezone: '',
      days: [],
      timeSlots: null,
      blackoutDates: []
    })

    const scheduleOptions = ref([])
    const selectedSchedule = ref(null)

    // Individual planning
    const activePlanTab = ref('modules')
    const timelineView = ref('month')
    const plannedModules = ref([])
    const personalObjectives = ref([])
    const milestones = ref([])

    // Finalization
    const finalConfirmations = ref({
      planReviewed: false,
      scheduleConfirmed: false,
      objectivesAccepted: false,
      cohortAgreed: false,
      progressTracking: false,
      readyToLaunch: false
    })

    // Static data
    const availableRoles = ref([
      'Customer', 'Customer representative', 'Project manager',
      'Internal support (IT, qualification, SE)', 'Process & policy manager',
      'System engineer', 'Developer', 'Production coordinator/ planner',
      'V&V employee', 'Production employee', 'Service technician',
      'Quality manager', 'Innovation and (strategy) management', 'Management'
    ])

    const timezones = ref([
      { label: 'UTC+1 (Central European Time)', value: 'CET' },
      { label: 'UTC+0 (Greenwich Mean Time)', value: 'GMT' },
      { label: 'UTC-5 (Eastern Standard Time)', value: 'EST' },
      { label: 'UTC-8 (Pacific Standard Time)', value: 'PST' }
    ])

    // Computed properties
    const filteredCohorts = computed(() => {
      return matchedCohorts.value.filter(cohort => {
        if (cohortFilters.value.status && cohort.status !== cohortFilters.value.status) return false
        if (cohortFilters.value.format && cohort.format !== cohortFilters.value.format) return false
        if (cohortFilters.value.role && !cohort.targetRoles.includes(cohortFilters.value.role)) return false
        if (cohortFilters.value.search && !cohort.name.toLowerCase().includes(cohortFilters.value.search.toLowerCase())) return false
        return true
      })
    })

    const selectedScheduleData = computed(() => {
      return scheduleOptions.value.find(option => option.id === selectedSchedule.value) || { sessions: [] }
    })

    const totalTrainingDays = computed(() => {
      return plannedModules.value.reduce((total, module) => total + (module.duration || 0), 0)
    })

    const completedMilestones = computed(() => {
      return milestones.value.filter(m => m.completed).length
    })

    const overallProgress = computed(() => {
      if (milestones.value.length === 0) return 0
      return Math.round((completedMilestones.value / milestones.value.length) * 100)
    })

    const allFinalConfirmationsChecked = computed(() => {
      return Object.values(finalConfirmations.value).every(Boolean)
    })

    const competencyDevelopment = computed(() => {
      // Mock data - would come from previous phases
      return [
        { name: 'Systems Thinking', currentLevel: 2, targetLevel: 4 },
        { name: 'Requirements Engineering', currentLevel: 1, targetLevel: 3 },
        { name: 'Architecture Design', currentLevel: 2, targetLevel: 4 }
      ]
    })

    const allObjectives = computed(() => {
      // Combine generated and personal objectives
      return [
        ...personalObjectives.value.map(obj => ({ ...obj, type: 'Personal' })),
        // Mock generated objectives
        {
          id: 1,
          text: 'Demonstrate proficiency in requirements elicitation techniques within 3 months',
          priority: 'high',
          smartScore: 88,
          type: 'Generated'
        }
      ]
    })

    const selectedArchetype = computed(() => {
      return 'Project-Oriented Training' // Would come from Phase 1
    })

    const planStartDate = computed(() => {
      return new Date() // Would be calculated based on schedule
    })

    const planEndDate = computed(() => {
      const start = planStartDate.value
      const duration = totalTrainingDays.value
      const end = new Date(start)
      end.setDate(start.getDate() + duration * 7) // Assuming weekly training
      return end
    })

    // Methods
    const loadUserProfile = async () => {
      try {
        const response = await axios.get('/api/user/profile')
        userProfile.value = response.data
      } catch (error) {
        console.error('Error loading user profile:', error)
      }
    }

    const findMatches = async () => {
      matching.value = true
      try {
        const response = await axios.post('/api/cohorts/match', {
          criteria: matchingCriteria.value,
          userProfile: userProfile.value
        })
        matchedCohorts.value = response.data
        ElMessage.success(`Found ${response.data.length} matching cohorts`)
      } catch (error) {
        console.error('Error finding matches:', error)
        ElMessage.error('Failed to find cohort matches')
      } finally {
        matching.value = false
      }
    }

    const createCohort = async () => {
      creating.value = true
      try {
        const response = await axios.post('/api/cohorts', newCohort.value)
        currentCohort.value = response.data
        selectedCohort.value = response.data.id
        ElMessage.success('Cohort created successfully!')
        nextStep()
      } catch (error) {
        console.error('Error creating cohort:', error)
        ElMessage.error('Failed to create cohort')
      } finally {
        creating.value = false
      }
    }

    const selectCohort = async (cohortId) => {
      selectedCohort.value = cohortId
      try {
        const response = await axios.get(`/api/cohorts/${cohortId}`)
        currentCohort.value = response.data
      } catch (error) {
        console.error('Error loading cohort:', error)
      }
    }

    const updateAvailability = async () => {
      updatingAvailability.value = true
      try {
        await axios.post('/api/user/availability', availability.value)
        ElMessage.success('Availability updated successfully')
      } catch (error) {
        console.error('Error updating availability:', error)
        ElMessage.error('Failed to update availability')
      } finally {
        updatingAvailability.value = false
      }
    }

    const generateSchedule = async () => {
      generatingSchedule.value = true
      try {
        const response = await axios.post('/api/schedules/generate', {
          cohortId: selectedCohort.value,
          modules: userProfile.value.selectedModules,
          availability: availability.value
        })
        scheduleOptions.value = response.data
        ElMessage.success('Schedule options generated successfully')
      } catch (error) {
        console.error('Error generating schedule:', error)
        ElMessage.error('Failed to generate schedule options')
      } finally {
        generatingSchedule.value = false
      }
    }

    const addObjective = () => {
      personalObjectives.value.push({
        text: '',
        priority: 'medium',
        targetDate: null
      })
    }

    const removeObjective = (index) => {
      personalObjectives.value.splice(index, 1)
    }

    const updateObjective = (index) => {
      // Save objective changes
      console.log('Objective updated:', personalObjectives.value[index])
    }

    const generateMilestones = async () => {
      generatingMilestones.value = true
      try {
        const response = await axios.post('/api/milestones/generate', {
          modules: plannedModules.value,
          objectives: personalObjectives.value
        })
        milestones.value = response.data
        ElMessage.success('Milestones generated successfully')
      } catch (error) {
        console.error('Error generating milestones:', error)
        ElMessage.error('Failed to generate milestones')
      } finally {
        generatingMilestones.value = false
      }
    }

    const updateMilestone = async (milestoneId) => {
      try {
        await axios.patch(`/api/milestones/${milestoneId}`, {
          completed: milestones.value.find(m => m.id === milestoneId).completed
        })
      } catch (error) {
        console.error('Error updating milestone:', error)
      }
    }

    const exportPlan = async () => {
      exporting.value = true
      try {
        const response = await axios.post('/api/plans/export', {
          format: 'pdf',
          includeSchedule: true,
          includeObjectives: true
        }, { responseType: 'blob' })

        const url = window.URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        link.href = url
        link.setAttribute('download', 'qualification-plan.pdf')
        document.body.appendChild(link)
        link.click()
        link.remove()

        ElMessage.success('Plan exported successfully')
      } catch (error) {
        console.error('Error exporting plan:', error)
        ElMessage.error('Failed to export plan')
      } finally {
        exporting.value = false
      }
    }

    const sharePlan = () => {
      ElMessageBox.prompt('Enter email addresses to share with:', 'Share Plan', {
        confirmButtonText: 'Share',
        cancelButtonText: 'Cancel',
        inputType: 'textarea',
        inputPlaceholder: 'Enter email addresses separated by commas'
      }).then(({ value }) => {
        // Share plan logic
        ElMessage.success('Plan shared successfully')
      }).catch(() => {
        // User cancelled
      })
    }

    const scheduleMeeting = () => {
      ElMessage.info('Opening calendar integration...')
      // Calendar integration logic
    }

    const launchPlan = async () => {
      launching.value = true
      try {
        await axios.post('/api/plans/launch', {
          cohortId: selectedCohort.value,
          schedule: selectedScheduleData.value,
          objectives: allObjectives.value,
          milestones: milestones.value
        })

        // Store completion data for phase progression
        const phaseData = {
          cohortId: selectedCohort.value,
          schedule: selectedScheduleData.value,
          objectives: allObjectives.value,
          milestones: milestones.value,
          launchedAt: new Date().toISOString()
        }
        localStorage.setItem('se-qpt-phase4-data', JSON.stringify(phaseData))

        ElMessage.success('Qualification plan launched successfully!')

        // Redirect to dashboard or plan overview
        setTimeout(() => {
          router.push('/app/dashboard')
        }, 2000)
      } catch (error) {
        console.error('Error launching plan:', error)
        ElMessage.error('Failed to launch qualification plan')
      } finally {
        launching.value = false
      }
    }

    const nextStep = () => {
      if (currentStep.value < totalSteps) {
        currentStep.value++
      }
    }

    const previousStep = () => {
      if (currentStep.value > 1) {
        currentStep.value--
      }
    }

    // Utility methods
    const getCohortStatusType = (status) => {
      const types = {
        forming: 'warning',
        open: 'success',
        full: 'info',
        closed: 'danger'
      }
      return types[status] || 'info'
    }

    const getPriorityType = (priority) => {
      const types = {
        high: 'danger',
        medium: 'warning',
        low: 'success'
      }
      return types[priority] || 'info'
    }

    const getMilestoneType = (type) => {
      const types = {
        assessment: 'primary',
        completion: 'success',
        checkpoint: 'warning'
      }
      return types[type] || 'info'
    }

    const formatDate = (date) => {
      if (!date) return ''
      return new Date(date).toLocaleDateString()
    }

    const formatTime = (time) => {
      if (!time) return ''
      return new Date(time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }

    const formatDateRange = (start, end) => {
      return `${formatDate(start)} - ${formatDate(end)}`
    }

    const getModulePosition = (module) => {
      // Calculate position for timeline visualization
      return {
        left: '10px',
        width: `${module.duration * 20}px`
      }
    }

    // Lifecycle
    onMounted(async () => {
      await loadUserProfile()
      // Load planned modules from previous phases
      plannedModules.value = userProfile.value.selectedModules || []
    })

    return {
      currentStep,
      totalSteps,
      matching,
      creating,
      updatingAvailability,
      generatingSchedule,
      generatingMilestones,
      exporting,
      launching,
      userProfile,
      activeMatchingTab,
      matchingCriteria,
      cohortFilters,
      newCohort,
      matchedCohorts,
      selectedCohort,
      currentCohort,
      availability,
      scheduleOptions,
      selectedSchedule,
      activePlanTab,
      timelineView,
      plannedModules,
      personalObjectives,
      milestones,
      finalConfirmations,
      availableRoles,
      timezones,
      filteredCohorts,
      selectedScheduleData,
      totalTrainingDays,
      completedMilestones,
      overallProgress,
      allFinalConfirmationsChecked,
      competencyDevelopment,
      allObjectives,
      selectedArchetype,
      planStartDate,
      planEndDate,
      findMatches,
      createCohort,
      selectCohort,
      updateAvailability,
      generateSchedule,
      addObjective,
      removeObjective,
      updateObjective,
      generateMilestones,
      updateMilestone,
      exportPlan,
      sharePlan,
      scheduleMeeting,
      launchPlan,
      nextStep,
      previousStep,
      getCohortStatusType,
      getPriorityType,
      getMilestoneType,
      formatDate,
      formatTime,
      formatDateRange,
      getModulePosition
    }
  }
}
</script>

<style scoped>
.phase-four {
  max-width: 1400px;
  margin: 0 auto;
  padding: 20px;
}

.phase-header {
  text-align: center;
  margin-bottom: 30px;
}

.phase-indicator {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 20px;
  margin-bottom: 20px;
}

.phase-number {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  background: linear-gradient(135deg, #AB47BC 0%, #8E24AA 100%);
  box-shadow: 0 4px 12px rgba(142, 36, 170, 0.25);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  font-weight: bold;
}

.phase-title h1 {
  margin: 0;
  color: #2c3e50;
}

.phase-title p {
  margin: 5px 0 0 0;
  color: #7f8c8d;
}

.progress-bar {
  width: 100%;
  height: 6px;
  background: #ecf0f1;
  border-radius: 3px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #764ba2 0%, #667eea 100%);
  transition: width 0.3s ease;
}

.step-indicator {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin-bottom: 40px;
}

.step-dot {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  border: 2px solid #bdc3c7;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  transition: all 0.3s ease;
}

.step-dot.active {
  border-color: #764ba2;
  background: #764ba2;
  color: white;
}

.step-dot.completed {
  border-color: #27ae60;
  background: #27ae60;
  color: white;
}

.step-content {
  margin-bottom: 40px;
}

.step-header {
  text-align: center;
  margin-bottom: 30px;
}

.step-header h2 {
  color: #2c3e50;
  margin-bottom: 10px;
}

.step-actions {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin-top: 40px;
}

/* Cohort Matching Styles */
.cohort-matching {
  display: grid;
  gap: 20px;
}

.user-profile .profile-summary {
  display: grid;
  gap: 10px;
}

.profile-item {
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.cohorts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.cohort-card {
  border: 2px solid #ecf0f1;
  border-radius: 8px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.cohort-card:hover {
  border-color: #764ba2;
  box-shadow: 0 4px 12px rgba(118, 75, 162, 0.1);
}

.cohort-card.selected {
  border-color: #764ba2;
  background: #f8f9ff;
}

.cohort-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.cohort-header h4 {
  margin: 0;
  color: #2c3e50;
}

.cohort-stats {
  display: flex;
  gap: 15px;
  margin: 10px 0;
}

.stat {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 14px;
  color: #7f8c8d;
}

/* Schedule Planning Styles */
.schedule-timeline {
  display: grid;
  gap: 15px;
}

.session-item {
  display: flex;
  gap: 20px;
  padding: 15px;
  border: 1px solid #ecf0f1;
  border-radius: 8px;
}

.session-date {
  min-width: 120px;
  text-align: center;
}

.date {
  font-weight: bold;
  color: #2c3e50;
}

.time {
  font-size: 14px;
  color: #7f8c8d;
  margin-top: 5px;
}

.session-content {
  flex: 1;
}

.session-content h5 {
  margin: 0 0 5px 0;
  color: #2c3e50;
}

.session-details {
  display: flex;
  gap: 10px;
  margin-top: 10px;
}

.session-details span {
  padding: 2px 8px;
  background: #f8f9fa;
  border-radius: 4px;
  font-size: 12px;
}

/* Individual Planning Styles */
.plan-builder {
  margin-bottom: 20px;
}

.timeline-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.modules-timeline {
  padding: 20px 0;
}

.timeline-module {
  position: relative;
  margin-bottom: 20px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 8px;
  border-left: 4px solid #764ba2;
}

.objectives-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.objective-item {
  display: flex;
  gap: 15px;
  margin-bottom: 15px;
  padding: 15px;
  border: 1px solid #ecf0f1;
  border-radius: 8px;
}

.objective-content {
  flex: 1;
}

.objective-details {
  display: flex;
  gap: 10px;
  margin-top: 10px;
}

.milestones-list {
  display: grid;
  gap: 15px;
}

.milestone-item {
  display: flex;
  gap: 15px;
  padding: 15px;
  border: 1px solid #ecf0f1;
  border-radius: 8px;
  transition: all 0.3s ease;
}

.milestone-item.completed {
  background: #f8fff8;
  border-color: #27ae60;
}

.milestone-details {
  display: flex;
  gap: 15px;
  margin-top: 10px;
  align-items: center;
}

/* Plan Summary Styles */
.plan-summary {
  margin-bottom: 20px;
}

.summary-stats {
  margin-bottom: 30px;
}

.stat-group {
  display: flex;
  gap: 20px;
  margin-bottom: 20px;
}

.stat-item {
  flex: 1;
  text-align: center;
}

.stat-value {
  font-size: 2em;
  font-weight: bold;
  color: #764ba2;
}

.stat-label {
  color: #7f8c8d;
  margin-top: 5px;
  font-size: 14px;
}

.progress-overview {
  text-align: center;
}

.action-buttons {
  display: grid;
  gap: 10px;
}

/* Finalization Styles */
.final-review {
  margin-bottom: 30px;
}

.plan-overview {
  padding: 20px 0;
}

.overview-section {
  margin-bottom: 30px;
}

.summary-grid {
  display: grid;
  gap: 10px;
}

.summary-item {
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.competency-progress {
  display: grid;
  gap: 15px;
}

.competency-item {
  padding: 10px;
  background: #f8f9fa;
  border-radius: 6px;
}

.competency-name {
  font-weight: bold;
  margin-bottom: 5px;
}

.competency-levels {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 14px;
}

.current-level {
  color: #e74c3c;
}

.target-level {
  color: #27ae60;
}

.arrow {
  color: #7f8c8d;
}

.schedule-calendar {
  display: grid;
  gap: 15px;
}

.calendar-module {
  display: flex;
  gap: 20px;
  padding: 15px;
  border: 1px solid #ecf0f1;
  border-radius: 8px;
}

.module-date {
  min-width: 100px;
  font-weight: bold;
  color: #764ba2;
}

.module-meta {
  display: flex;
  gap: 10px;
  margin-top: 5px;
}

.module-meta span {
  padding: 2px 6px;
  background: #f0f0f0;
  border-radius: 4px;
  font-size: 12px;
}

.objectives-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 20px;
}

.objective-card {
  border: 1px solid #ecf0f1;
  border-radius: 8px;
  padding: 15px;
}

.objective-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.objective-type {
  font-size: 12px;
  color: #7f8c8d;
}

.smart-score {
  margin-top: 10px;
}

.smart-score span {
  display: block;
  margin-bottom: 5px;
  font-size: 14px;
  color: #7f8c8d;
}

.confirmations {
  display: grid;
  gap: 15px;
}

.confirmations .el-checkbox {
  margin-bottom: 0;
}
</style>