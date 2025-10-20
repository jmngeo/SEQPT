<template>
  <div class="role-identification-container">
    <!-- Pathway info banner -->
    <el-alert
      :type="pathway === 'STANDARD' ? 'info' : 'warning'"
      :title="pathway === 'STANDARD' ? 'Standard Role Selection' : 'Task-Based Role Mapping'"
      :closable="false"
      show-icon
      class="pathway-alert"
    >
      <template v-if="pathway === 'STANDARD'">
        Your organization has <strong>defined SE processes</strong> (Maturity Level: {{ maturityLevel }}).
        Select from the standard SE role clusters.
      </template>
      <template v-else>
        Your organization is <strong>developing SE processes</strong> (Maturity Level: {{ maturityLevel }}).
        We'll help identify roles by analyzing your job profiles.
      </template>
    </el-alert>

    <!-- Step indicator -->
    <el-steps
      :active="currentStep - 1"
      align-center
      finish-status="success"
      class="step-indicator"
    >
      <el-step :title="pathway === 'STANDARD' ? 'Select Roles' : 'Map Job Profiles'" />
      <el-step title="Target Group Size" />
    </el-steps>

    <!-- Step 1: Role Selection/Mapping -->
    <div v-if="currentStep === 1">
      <StandardRoleSelection
        v-if="pathway === 'STANDARD'"
        :maturity-id="maturityData.id"
        :existing-roles="existingRoles"
        @complete="handleRolesComplete"
        @back="handleBack"
      />
      <TaskBasedMapping
        v-else
        :maturity-id="maturityData.id"
        :existing-roles="existingRoles"
        @complete="handleRolesComplete"
        @back="handleBack"
      />
    </div>

    <!-- Step 2: Target Group Size -->
    <div v-if="currentStep === 2">
      <TargetGroupSize
        :roles-count="identifiedRoles.count"
        :maturity-id="maturityData.id"
        :existing-target-group="existingTargetGroup"
        @complete="handleTargetGroupComplete"
        @back="goToStep(1)"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import StandardRoleSelection from './StandardRoleSelection.vue'
import TaskBasedMapping from './TaskBasedMapping.vue'
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
const steps = computed(() => [
  {
    title: pathway.value === 'STANDARD' ? 'Select Roles' : 'Map Job Profiles',
    value: 1
  },
  {
    title: 'Target Group Size',
    value: 2
  }
])

// Handle roles complete
const handleRolesComplete = (rolesData) => {
  console.log('[RoleIdentification] Roles identified:', rolesData)
  identifiedRoles.value = rolesData
  currentStep.value = 2
}

// Handle target group complete
const handleTargetGroupComplete = (targetGroupData) => {
  console.log('[RoleIdentification] Target group selected:', targetGroupData)

  // Emit completion with all data
  emit('complete', {
    roles: identifiedRoles.value,
    targetGroup: targetGroupData,
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

  // Check if existing roles data is available
  if (props.existingRoles && props.existingRoles.roles && props.existingRoles.roles.length > 0) {
    console.log('[RoleIdentification] Loading existing roles:', props.existingRoles)
    identifiedRoles.value = {
      roles: props.existingRoles.roles,
      count: props.existingRoles.count || props.existingRoles.roles.length
    }
    // If target group also exists, stay on step 1 for review, otherwise go to step 2
    if (!props.existingTargetGroup || !props.existingTargetGroup.size_range) {
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

.pathway-alert {
  margin-bottom: 24px;
}

.step-indicator {
  margin-bottom: 32px;
}
</style>
