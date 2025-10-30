<template>
  <div class="role-identification-container">
    <!-- HIDDEN: Pathway info banner removed (redundant) -->
    <!--
    <el-alert
      :type="pathway === 'STANDARD' ? 'info' : 'warning'"
      :title="pathway === 'STANDARD' ? 'Standard Role Selection' : 'Undefined SE Roles'"
      :closable="false"
      show-icon
      class="pathway-alert"
    >
      <template v-if="pathway === 'STANDARD'">
        Your organization has <strong>defined SE processes</strong> (Maturity Level: {{ maturityLevel }}).
        Select from the standard SE role clusters.
      </template>
      <template v-else>
        Based on your maturity assessment results (Maturity Level: {{ maturityLevel }}),
        your organization <strong>does not have clearly defined Systems Engineering roles</strong>.
      </template>
    </el-alert>
    -->

    <!-- Step indicator -->
    <el-steps
      :active="currentStep - 1"
      align-center
      finish-status="success"
      class="step-indicator"
    >
      <el-step title="Target Group Size" />
      <el-step :title="pathway === 'STANDARD' ? 'Map Roles' : 'Role Selection'" />
      <el-step v-if="pathway === 'STANDARD'" title="Role-Process Matrix" />
    </el-steps>

    <!-- Step 1: Target Group Size -->
    <div v-if="currentStep === 1">
      <TargetGroupSize
        :roles-count="identifiedRoles.count"
        :maturity-id="maturityData.id"
        :existing-target-group="existingTargetGroup"
        @complete="handleTargetGroupComplete"
        @back="handleBack"
      />
    </div>

    <!-- Step 2: Role Selection/Mapping -->
    <div v-if="currentStep === 2">
      <StandardRoleSelection
        v-if="pathway === 'STANDARD'"
        :maturity-id="maturityData.id"
        :existing-roles="existingRoles"
        @complete="handleRolesComplete"
        @back="goToStep(1)"
      />

      <!-- HIDDEN FOR NOW: Task-based mapping feature removed from Phase 1 -->
      <!-- May be restored in future versions if needed -->
      <!--
      <TaskBasedMapping
        v-else
        :maturity-id="maturityData.id"
        :existing-roles="existingRoles"
        @complete="handleRolesComplete"
        @back="goToStep(1)"
      />
      -->

      <!-- Message for organizations without defined SE roles -->
      <el-card v-if="pathway === 'TASK_BASED'" class="undefined-roles-message">
        <template #header>
          <div class="card-header">
            <span>SE Roles Not Yet Defined</span>
          </div>
        </template>
        <div class="message-content">
          <p>
            Based on your maturity assessment results (Maturity Level: {{ maturityLevel }}),
            your organization does not yet have clearly defined Systems Engineering roles.
          </p>
          <p class="info-note">
            <strong>Next Step:</strong> In the following step, you will receive recommended Training Strategy
            information based on your organizational maturity assessment and target group size.
          </p>
        </div>
        <template #footer>
          <el-button @click="goToStep(1)">Back to Target Group Size</el-button>
          <el-button type="primary" @click="handleUndefinedRolesComplete">Continue to Strategy Selection</el-button>
        </template>
      </el-card>
    </div>

    <!-- Step 3: Role-Process Matrix (only for STANDARD pathway) -->
    <div v-if="currentStep === 3 && pathway === 'STANDARD'">
      <RoleProcessMatrix
        v-if="identifiedRoles.roles && identifiedRoles.roles.length > 0"
        :maturity-id="maturityData.id"
        :roles="identifiedRoles.roles"
        @complete="handleMatrixComplete"
        @back="goToStep(2)"
      />
      <el-alert
        v-else
        title="Please Complete Role Selection First"
        description="You must identify and map your organization's roles before defining the role-process matrix."
        type="warning"
        show-icon
        :closable="false"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import StandardRoleSelection from './StandardRoleSelection.vue'
import RoleProcessMatrix from './RoleProcessMatrix.vue'
// HIDDEN FOR NOW: Task-based mapping feature removed from Phase 1
// May be restored in future if needed
// import TaskBasedMapping from './TaskBasedMapping.vue'
import TargetGroupSize from './TargetGroupSize.vue'

const props = defineProps({
  maturityData: {
    type: Object,
    required: true
  },
  existingRoles: {
    type: Object,
    default: null
  },
  existingTargetGroup: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['complete', 'back'])

const currentStep = ref(1)
const identifiedRoles = ref({
  roles: [],
  count: 0
})

// Determine pathway based on maturity
const MATURITY_THRESHOLD = 3 // "Defined and Established"
const pathway = computed(() => {
  // maturityData IS the results object, not an object containing results
  const seProcessesValue = props.maturityData.strategyInputs?.seProcessesValue || 0
  console.log('[RoleIdentification] seProcessesValue:', seProcessesValue, 'Threshold:', MATURITY_THRESHOLD)
  return seProcessesValue >= MATURITY_THRESHOLD ? 'STANDARD' : 'TASK_BASED'
})

const maturityLevel = computed(() => {
  // maturityData IS the results object
  return props.maturityData.maturityLevel || 1
})

// Steps for stepper
const steps = computed(() => {
  const baseSteps = [
    {
      title: 'Target Group Size',
      value: 1
    },
    {
      title: pathway.value === 'STANDARD' ? 'Map Roles' : 'Role Selection',
      value: 2
    }
  ]

  // Add matrix step only for STANDARD pathway
  if (pathway.value === 'STANDARD') {
    baseSteps.push({
      title: 'Role-Process Matrix',
      value: 3
    })
  }

  return baseSteps
})

// Store target group data
const targetGroupData = ref(null)

// Handle target group complete
const handleTargetGroupComplete = (data) => {
  console.log('[RoleIdentification] Target group selected:', data)
  targetGroupData.value = data
  currentStep.value = 2
}

// Handle roles complete
const handleRolesComplete = (rolesData) => {
  console.log('[RoleIdentification] Roles identified:', rolesData)
  identifiedRoles.value = rolesData

  // For STANDARD pathway, go to matrix step
  // For TASK_BASED pathway, emit completion directly
  if (pathway.value === 'STANDARD') {
    currentStep.value = 3
  } else {
    // Emit completion for TASK_BASED pathway
    emit('complete', {
      roles: rolesData,
      targetGroup: targetGroupData.value,
      pathway: pathway.value,
      maturityId: props.maturityData.id
    })
  }
}

// Handle matrix complete
const handleMatrixComplete = (matrixData) => {
  console.log('[RoleIdentification] Matrix complete:', matrixData)

  // Emit completion with all data
  emit('complete', {
    roles: identifiedRoles.value,
    targetGroup: targetGroupData.value,
    pathway: pathway.value,
    maturityId: props.maturityData.id,
    matrixCompleted: true
  })
}

// Handle undefined roles complete (TASK_BASED pathway)
const handleUndefinedRolesComplete = () => {
  console.log('[RoleIdentification] Proceeding without defined roles (TASK_BASED pathway)')

  // Emit completion with empty roles data
  emit('complete', {
    roles: {
      roles: [],
      count: 0,
      pathway: 'TASK_BASED'
    },
    targetGroup: targetGroupData.value,
    pathway: pathway.value,
    maturityId: props.maturityData.id
  })
}

// Go to specific step
const goToStep = (step) => {
  currentStep.value = step
}

// Handle back
const handleBack = () => {
  emit('back')
}

// Load existing data if available
onMounted(async () => {
  console.log('[RoleIdentification] Mounted with maturity data:', props.maturityData)
  console.log('[RoleIdentification] Pathway determined:', pathway.value)

  // Check if existing target group data is available
  if (props.existingTargetGroup && props.existingTargetGroup.size_range) {
    console.log('[RoleIdentification] Loading existing target group:', props.existingTargetGroup)
    targetGroupData.value = props.existingTargetGroup

    // If roles also exist, stay on step 1 for review, otherwise go to step 2
    if (props.existingRoles && props.existingRoles.roles && props.existingRoles.roles.length > 0) {
      console.log('[RoleIdentification] Loading existing roles:', props.existingRoles)
      identifiedRoles.value = {
        roles: props.existingRoles.roles,
        count: props.existingRoles.count || props.existingRoles.roles.length
      }
      // Both exist, stay on step 1 to allow review
    } else {
      // Only target group exists, go to step 2 (role selection)
      currentStep.value = 2
    }
  }
})
</script>

<style scoped>
.role-identification-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0;
}

/* HIDDEN: pathway-alert styles (banner removed)
.pathway-alert {
  margin-bottom: 24px;
}
*/

.step-indicator {
  margin-bottom: 32px;
}

/* Undefined roles message card */
.undefined-roles-message {
  margin-top: 24px;
}

.undefined-roles-message .card-header {
  font-size: 18px;
  font-weight: 600;
  color: #303133;
}

.undefined-roles-message .message-content p {
  margin-bottom: 16px;
  line-height: 1.6;
  color: #606266;
}

.undefined-roles-message .info-note {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px;
  background-color: #f4f4f5;
  border-radius: 4px;
  font-size: 14px;
  color: #606266;
}
</style>
