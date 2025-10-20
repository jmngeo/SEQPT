import { defineStore } from 'pinia';

export const useUserStore = defineStore('user', {
  state: () => ({
    organizationId: null,
    fullName: '',
    username: '',
    tasksResponsibilities: '',
    selectedRoles: [],  // Keep track of selected roles
    competencySelections: [], // Store selected groups for each competency here
    surveyType: null, // Add survey type (known_roles, unknown_roles, all_roles)
  }),
  actions: {
    // Set user details
    setUserDetails(details) {
      this.organizationId = details.organizationId;
      this.fullName = details.fullName;
      this.username = details.username;
      this.tasksResponsibilities = details.tasksResponsibilities;
    },
    // Set selected roles when proceeding
    setSelectedRoles(roles) {
      this.selectedRoles = roles; // Replace all selected roles with provided roles
    },
    // Add or update competency selections
    addOrUpdateCompetencySelections({ competencyId, selectedGroups }) {
      // Find if the competency already exists
      const existingIndex = this.competencySelections.findIndex(cs => cs.competencyId === competencyId);
      
      if (existingIndex !== -1) {
        // If it already exists, update the selections
        this.competencySelections[existingIndex].selectedGroups = selectedGroups;
      } else {
        // If it doesn't exist, push the new competency and selected groups
        this.competencySelections.push({ competencyId, selectedGroups });
      }
    },
    // Clear competency selections if needed
    clearCompetencySelections() {
      this.competencySelections = [];
    },
    // Get the selections for a specific competency
    getCompetencySelections(competencyId) {
      const competency = this.competencySelections.find(cs => cs.competencyId === competencyId);
      return competency ? competency.selectedGroups : [];
    },
    // Clear all user details and roles (single action for resetting store)
    clearAll() {
      this.$reset();  // Reset all state properties to their initial values
    }
  }
});
