/**
 * src/reminders/index.js
 *
 * MindCare NER — Smart Reminders Module Barrel Export
 *
 * Centralizes exports for:
 * - Constants, types, and schema definitions
 * - Model factory, validation, and lifecycle state transition helpers
 * - Dosage guard validation
 * - Prototype mock data
 * - UI-independent storage and business logic service
 * - UI components: CaregiverRemindersSection & ReminderModal
 * - React Context & Hooks
 */

// 1. Types, Constants & Schema
export {
  REMINDER_TYPES,
  REMINDER_TYPE_CONFIG,
  REMINDER_REPEAT,
  REMINDER_STATUS,
  DEFAULT_REMINDER,
  isValidReminderType,
  isValidReminderRepeat,
  isValidReminderStatus,
} from './reminderTypes.js'

// 2. Data Model & Pure State Transitions
export {
  generateReminderId,
  validateReminder,
  createReminder,
  acknowledgeReminder,
  snoozeReminder,
  markReminderDelivered,
  markReminderNotAcknowledged,
  markReminderMissed,
  dismissReminder,
  toggleReminderEnabled,
  updateReminder,
  isReminderDue,
  isReminderForDate,
} from './reminderModel.js'

// 3. Medication Dosage Safety Guard
export { checkDosageSafety } from './dosageGuard.js'

// 4. Mock Data
export {
  INITIAL_MOCK_REMINDERS_RAW,
  getInitialMockReminders,
} from './mockReminders.js'

// 5. Storage & Business Logic Service
export {
  REMINDERS_STORAGE_KEY,
  loadAllReminders,
  saveAllReminders,
  getRemindersByPatient,
  getReminderById,
  saveReminder,
  deleteReminder,
  acknowledgeReminderById,
  snoozeReminderById,
  deliverReminderById,
  markReminderNotAcknowledgedById,
  markReminderMissedById,
  dismissReminderById,
  toggleReminderEnabledById,
  DEFAULT_SNOOZE_MINUTES,
  getSnoozeDurationMinutes,
  setSnoozeDurationMinutes,
  resetSnoozeDurationMinutes,
  DEFAULT_MAX_RETRIES,
  DEFAULT_RETRY_INTERVAL_MINUTES,
  CAREGIVER_ALERTS_STORAGE_KEY,
  getMaxRetries,
  setMaxRetries,
  getRetryIntervalMinutes,
  setRetryIntervalMinutes,
  resetEscalationConfig,
  formatReminderDisplayTime,
  getReminderCategoryLabel,
  getInitialMockCaregiverAlerts,
  loadCaregiverAlerts,
  saveAllCaregiverAlerts,
  saveCaregiverAlert,
  dismissCaregiverAlert,
  resolveCaregiverAlert,
  escalateReminderOccurrence,
  getDueReminders,
  getTodayReminders,
  getReminderStats,
  resetRemindersToMock,
  reminderRepository,
  ReminderRepository,
  reminderSyncService,
  ReminderSyncService,
  REMINDERS_OUTBOX_STORAGE_KEY,
  getSyncStatus,
  syncPendingMutations,
  setSimulatedOffline,
  isOnline,
} from './reminderService.js'

// 5b. Offline-First Repository & Sync Service Abstractions
export {
  ReminderRepository as CoreReminderRepository,
  reminderRepository as coreReminderRepository,
} from './reminderRepository.js'

export {
  ReminderSyncService as CoreReminderSyncService,
  reminderSyncService as coreReminderSyncService,
} from './reminderSyncService.js'

// 6. Scheduling Engine
export {
  isSameCalendarDay,
  extractScheduledTimeOfDay,
  getOccurrenceDateForDay,
  isReminderDueForOccurrence,
  ReminderScheduler,
} from './schedulingEngine.js'

// 7. Voice Assistance for Smart Reminders
export {
  VOICE_MUTED_STORAGE_KEY,
  CATEGORY_VOICE_MESSAGES,
  isSpeechSupported,
  getVoiceReminderMessage,
  isVoiceMuted,
  setVoiceMuted,
  toggleVoiceMuted,
  cancelReminderVoice,
  speakReminderVoice,
} from './voiceReminderService.js'

