// src/router/index.js
import { createRouter, createWebHistory } from 'vue-router';
import WelcomePage from '../components/WelcomePage.vue';
import RoleSelectionPage from '../components/RoleSelectionPage.vue';
import FindRole from '../components/FindRole.vue';

// Newly added components
import AdminLogin from '../components/AdminLogin.vue'; // New admin login page
import AdminPanel from '../components/AdminPanel.vue';
import CompetencyCrud from '../components/CompetencyCrud.vue';
import CompetencyIndicatorCrud from '../components/CompetencyIndicatorCrud.vue';
import RoleProcessMatrixCrud from '../components/RoleProcessMatrixCrud.vue';
import ProcessCompetencyMatrixCrud from '../components/ProcessCompetencyMatrixCrud.vue';
import RoleCompetencyMatrixView from '../components/RoleCompetencyMatrixView.vue';
import OrganizationCrud from '../components/OrganizationCrud.vue';
import SurveyUserCreate from '@/components/SurveyUserCreate.vue';
import CompetencySurvey from '@/components/CompetencySurvey.vue';
import SurveyCompletion from '@/components/SurveyCompletion.vue';
import SurveyResults from '@/components/SurveyResults.vue';
import SurveyResultsAdmin from '@/components/SurveyResultsAdmin.vue';
import FindUserPerformingISOProcess from '@/components/FindUserPerformingISOProcess.vue';
import SurveyTypeSelection from '@/components/SurveyTypeSelection.vue';
import ISOProcess from '@/components/ISOProcess.vue';
import RoleClusters from '@/components/RoleClusters.vue';

const routes = [
  { path: '/', component: WelcomePage },
  { path: '/findRole', component: FindRole },
  { path: '/roleSelectionPage', component: RoleSelectionPage },

  // Public routes
  { path: '/SurveyUserCreate', component: SurveyUserCreate },
  { path: '/competencySurvey', component: CompetencySurvey },
  { path: '/surveyCompletion', component: SurveyCompletion },
  { path: '/surveyResults', component: SurveyResults },
  { path: '/findProcesses', component: FindUserPerformingISOProcess },
  { path: '/surveyTypeSelection', component: SurveyTypeSelection },
  { path: '/ISOProcess', component: ISOProcess },
  { path: '/RoleClusters', component: RoleClusters },

  // Admin login route (this is not protected)
  { path: '/admin/login', name: 'AdminLogin', component: AdminLogin },

  // Admin routes (protected with meta.requiresAuth)
  { path: '/adminPanel', component: AdminPanel, meta: { requiresAuth: true } },
  { path: '/competencyCrud', component: CompetencyCrud, meta: { requiresAuth: true } },
  { path: '/competencyIndicatorCrud', component: CompetencyIndicatorCrud, meta: { requiresAuth: true } },
  { path: '/roleProcessMatrixCrud', component: RoleProcessMatrixCrud, meta: { requiresAuth: true } },
  { path: '/processCompetencyMatrixCrud', component: ProcessCompetencyMatrixCrud, meta: { requiresAuth: true } },
  { path: '/roleCompetencyMatrixView', component: RoleCompetencyMatrixView, meta: { requiresAuth: true } },
  { path: '/OrganizationCrud', component: OrganizationCrud, meta: { requiresAuth: true } },
  { path: '/surveyResultsAdmin', component: SurveyResultsAdmin, meta: { requiresAuth: true } },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

// Global navigation guard to protect admin routes
router.beforeEach((to, from, next) => {
  if (to.meta.requiresAuth) {
    // Check if admin is authenticated; for example, check a flag in localStorage.
    // On a successful admin login, set localStorage.setItem('isAdminAuthenticated', 'true')
    const isAdminAuthenticated = localStorage.getItem('isAdminAuthenticated') === 'true';
    if (!isAdminAuthenticated) {
      // Redirect to admin login if not authenticated
      next({ name: 'AdminLogin' });
    } else {
      next();
    }
  } else {
    next();
  }
});

export default router;
