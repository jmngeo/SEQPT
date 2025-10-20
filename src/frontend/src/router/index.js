import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { usePhaseProgression } from '@/composables/usePhaseProgression'
import { ElMessage } from 'element-plus'

// Layout components
import MainLayout from '@/layouts/MainLayout.vue'
import AuthLayout from '@/layouts/AuthLayout.vue'

// View components
import Home from '@/views/Home.vue'
import Login from '@/views/auth/Login.vue'
import Register from '@/views/auth/Register.vue'
import Dashboard from '@/views/Dashboard.vue'


// Assessment views
import Assessments from '@/views/assessments/Assessments.vue'
import CreateAssessment from '@/views/assessments/CreateAssessment.vue'
import AssessmentDetails from '@/views/assessments/AssessmentDetails.vue'
import TakeAssessment from '@/views/assessments/TakeAssessment.vue'

// SE-QPT Phase views
import PhaseOne from '@/views/phases/PhaseOne.vue'
import PhaseTwo from '@/views/phases/PhaseTwo.vue'
import PhaseThree from '@/views/phases/PhaseThree.vue'
import PhaseFour from '@/views/phases/PhaseFour.vue'

// Qualification Plan views
import QualificationPlans from '@/views/plans/QualificationPlans.vue'
import CreatePlan from '@/views/plans/CreatePlan.vue'
import PlanDetails from '@/views/plans/PlanDetails.vue'

// Learning Objectives views
import LearningObjectives from '@/views/objectives/LearningObjectives.vue'
import GenerateObjectives from '@/views/objectives/GenerateObjectives.vue'
import RAGObjectives from '@/views/RAGObjectives.vue'

// Learning Module views
import LearningModules from '@/views/modules/LearningModules.vue'

// Analytics views
import Analytics from '@/views/analytics/Analytics.vue'

// Profile and Settings
import Profile from '@/views/Profile.vue'
import Settings from '@/views/Settings.vue'

// Admin views
import AdminDashboard from '@/views/admin/AdminDashboard.vue'
import AdminPanel from '@/views/admin/AdminPanel.vue'
import UserManagement from '@/views/admin/UserManagement.vue'
import CompetencyManagement from '@/views/admin/CompetencyManagement.vue'
import ModuleManagement from '@/views/admin/ModuleManagement.vue'
import SystemConfig from '@/views/admin/SystemConfig.vue'
import Reports from '@/views/admin/Reports.vue'

// Error pages
import NotFound from '@/views/errors/NotFound.vue'
import Unauthorized from '@/views/errors/Unauthorized.vue'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home,
    meta: { requiresAuth: false }
  },
  {
    path: '/auth',
    component: AuthLayout,
    children: [
      {
        path: 'login',
        name: 'Login',
        component: Login,
        meta: { requiresAuth: false }
      },
      {
        path: 'register',
        name: 'Register',
        component: Register,
        meta: { requiresAuth: false }
      }
    ]
  },
  {
    path: '/app',
    component: MainLayout,
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        redirect: '/app/dashboard'
      },
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: Dashboard,
        meta: { title: 'Dashboard' }
      },
      {
        path: 'assessments',
        name: 'Assessments',
        component: Assessments,
        meta: { title: 'Assessments' }
      },
      {
        path: 'assessments/create',
        name: 'CreateAssessment',
        component: CreateAssessment,
        meta: { title: 'Create Assessment' }
      },
      {
        path: 'assessments/:id',
        name: 'AssessmentDetails',
        component: AssessmentDetails,
        meta: { title: 'Assessment Details' }
      },
      {
        path: 'assessments/:id/take',
        name: 'TakeAssessment',
        component: TakeAssessment,
        meta: { title: 'Take Assessment' }
      },
      {
        path: 'assessments/history',
        name: 'AssessmentHistory',
        component: () => import('@/components/assessment/AssessmentHistory.vue'),
        meta: { title: 'Assessment History' }
      },
      {
        path: 'assessments/:id/results',
        name: 'AssessmentResults',
        component: () => import('@/components/phase2/CompetencyResults.vue'),
        meta: { title: 'Assessment Results' }
      },
      {
        path: 'learning-modules',
        name: 'LearningModules',
        component: LearningModules,
        meta: { title: 'Learning Modules' }
      },
      {
        path: 'phases/1',
        name: 'PhaseOne',
        component: PhaseOne,
        meta: { title: 'Phase 1: Prepare SE Training', phase: 1 }
      },
      {
        path: 'phases/2',
        name: 'PhaseTwo',
        component: PhaseTwo,
        meta: { title: 'Phase 2: Identify Requirements and Competencies', phase: 2 },
        beforeEnter: async (to, from, next) => {
          const { checkPhaseCompletion, canAccessPhase, getNextAvailablePhase } = usePhaseProgression()
          await checkPhaseCompletion() // Refresh phase status from database
          if (canAccessPhase(2)) {
            next()
          } else {
            const nextPhase = getNextAvailablePhase()
            ElMessage.warning('Please complete Phase 1 before accessing Phase 2')
            next(`/app/phases/${nextPhase}`)
          }
        }
      },
      {
        path: 'phases/2/new',
        name: 'Phase2New',
        component: () => import('@/views/phases/Phase2NewFlow.vue'),
        meta: { title: 'Phase 2: Competency Assessment (New)', phase: 2 },
        beforeEnter: async (to, from, next) => {
          const { checkPhaseCompletion, canAccessPhase, getNextAvailablePhase } = usePhaseProgression()
          await checkPhaseCompletion() // Refresh phase status from database
          if (canAccessPhase(2)) {
            next()
          } else {
            const nextPhase = getNextAvailablePhase()
            ElMessage.warning('Please complete Phase 1 before accessing Phase 2')
            next(`/app/phases/${nextPhase}`)
          }
        }
      },
      {
        path: 'phases/3',
        name: 'PhaseThree',
        component: PhaseThree,
        meta: { title: 'Phase 3: Module Selection', phase: 3 },
        beforeEnter: async (to, from, next) => {
          const { checkPhaseCompletion, canAccessPhase, getNextAvailablePhase } = usePhaseProgression()
          await checkPhaseCompletion() // Refresh phase status from database
          if (canAccessPhase(3)) {
            next()
          } else {
            const nextPhase = getNextAvailablePhase()
            ElMessage.warning('Please complete previous phases before accessing Phase 3')
            next(`/app/phases/${nextPhase}`)
          }
        }
      },
      {
        path: 'phases/4',
        name: 'PhaseFour',
        component: PhaseFour,
        meta: { title: 'Phase 4: Cohort Formation', phase: 4 },
        beforeEnter: async (to, from, next) => {
          const { checkPhaseCompletion, canAccessPhase, getNextAvailablePhase } = usePhaseProgression()
          await checkPhaseCompletion() // Refresh phase status from database
          if (canAccessPhase(4)) {
            next()
          } else {
            const nextPhase = getNextAvailablePhase()
            ElMessage.warning('Please complete all previous phases before accessing Phase 4')
            next(`/app/phases/${nextPhase}`)
          }
        }
      },
      {
        path: 'test/maturity',
        name: 'TestMaturity',
        component: () => import('@/views/TestMaturityAssessment.vue'),
        meta: { title: 'Test: Maturity Assessment' }
      },
      {
        path: 'plans',
        name: 'QualificationPlans',
        component: QualificationPlans,
        meta: { title: 'Qualification Plans' }
      },
      {
        path: 'plans/create',
        name: 'CreatePlan',
        component: CreatePlan,
        meta: { title: 'Create Qualification Plan' }
      },
      {
        path: 'plans/:uuid',
        name: 'PlanDetails',
        component: PlanDetails,
        meta: { title: 'Plan Details' }
      },
      {
        path: 'objectives',
        name: 'LearningObjectives',
        component: LearningObjectives,
        meta: { title: 'Learning Objectives' }
      },
      {
        path: 'objectives/generate',
        name: 'GenerateObjectives',
        component: GenerateObjectives,
        meta: { title: 'Generate Learning Objectives' }
      },
      {
        path: 'objectives/rag',
        name: 'RAGObjectives',
        component: RAGObjectives,
        meta: { title: 'RAG-LLM Objective Generation' }
      },
      {
        path: 'analytics',
        name: 'Analytics',
        component: Analytics,
        meta: { title: 'Analytics & Insights' }
      },
      {
        path: 'profile',
        name: 'Profile',
        component: Profile,
        meta: { title: 'Profile' }
      },
      {
        path: 'settings',
        name: 'Settings',
        component: Settings,
        meta: { title: 'Settings' }
      }
    ]
  },
  {
    path: '/admin',
    component: MainLayout,
    meta: { requiresAuth: true, requiresAdmin: true },
    children: [
      {
        path: '',
        redirect: '/admin/dashboard'
      },
      {
        path: 'dashboard',
        name: 'AdminDashboard',
        component: AdminDashboard,
        meta: { title: 'Admin Dashboard' }
      },
      {
        path: 'panel',
        name: 'AdminPanel',
        component: AdminPanel,
        meta: { title: 'Admin Panel' }
      },
      {
        path: 'users',
        name: 'UserManagement',
        component: UserManagement,
        meta: { title: 'User Management' }
      },
      {
        path: 'competencies',
        name: 'CompetencyManagement',
        component: CompetencyManagement,
        meta: { title: 'Competency Management' }
      },
      {
        path: 'modules',
        name: 'ModuleManagement',
        component: ModuleManagement,
        meta: { title: 'Module Management' }
      },
      {
        path: 'config',
        name: 'SystemConfig',
        component: SystemConfig,
        meta: { title: 'System Configuration' }
      },
      {
        path: 'reports',
        name: 'Reports',
        component: Reports,
        meta: { title: 'Reports & Analytics' }
      },
      {
        path: 'matrix/role-process',
        name: 'RoleProcessMatrix',
        component: () => import('@/views/admin/matrix/RoleProcessMatrixCrud.vue'),
        meta: { title: 'Role-Process Matrix Configuration' }
      },
      {
        path: 'matrix/process-competency',
        name: 'ProcessCompetencyMatrix',
        component: () => import('@/views/admin/matrix/ProcessCompetencyMatrixCrud.vue'),
        meta: { title: 'Process-Competency Matrix Configuration' }
      }
    ]
  },
  {
    path: '/401',
    name: 'Unauthorized',
    component: Unauthorized,
    meta: { requiresAuth: false }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: NotFound,
    meta: { requiresAuth: false }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) {
      return savedPosition
    } else {
      return { top: 0 }
    }
  }
})

// Navigation guards
router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()

  // Set page title
  if (to.meta.title) {
    document.title = `${to.meta.title} - SE-QPT Platform`
  } else {
    document.title = 'SE-QPT Platform'
  }

  // Check if route requires authentication
  if (to.meta.requiresAuth) {
    // Check if user is authenticated
    if (!authStore.isAuthenticated) {
      // Try to restore auth from token
      await authStore.checkAuth()

      if (!authStore.isAuthenticated) {
        next({
          name: 'Login',
          query: { redirect: to.fullPath }
        })
        return
      }
    }

    // Check admin access
    if (to.meta.requiresAdmin && !authStore.isAdmin) {
      next({ name: 'Unauthorized' })
      return
    }
  }

  // Redirect authenticated users away from auth pages
  if (!to.meta.requiresAuth && authStore.isAuthenticated) {
    if (to.name === 'Login' || to.name === 'Register') {
      next({ name: 'Dashboard' })
      return
    }
  }

  next()
})

export default router