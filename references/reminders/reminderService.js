/**
 * src/reminders/reminderService.js
 *
 * MindCare NER — Smart Reminders Storage & Business Logic Service
 *
 * Provides a clean, UI-independent service layer for:
 * 1. CRUD operations on scheduled patient reminders
 * 2. Storage persistence (localStorage with in-memory fallback)
 * 3. Lifecycle transitions (acknowledge, snooze, deliver, dismiss)
 * 4. Caregiver monitoring queries & analytics aggregations
 *
 * ARCHITECTURAL SEPARATION:
 * This service contains ZERO UI dependencies or JSX. It can be utilized by
 * React hooks, background timers, service workers, or test scripts identically.
 *
 * BACKEND SYNCHRONIZATION HOOKS:
 * Each function contains clear TODO documentation showing how to connect
 * real REST/GraphQL APIs, WebSockets, WebPush notifications, and offline sync.
 */

import {
  REMINDER_STATUS,
  REMINDER_TYPES,
} from './reminderTypes.js'
import {
  createReminder,
  updateReminder,
  acknowledgeReminder,
  snoozeReminder,
  markReminderDelivered,
  markReminderNotAcknowledged,
  markReminderMissed,
  dismissReminder,
  toggleReminderEnabled,
  isReminderDue,
  isReminderForDate,
} from './reminderModel.js'
import { getInitialMockReminders } from './mockReminders.js'
import {
  reminderRepository,
  ReminderRepository,
  REMINDERS_STORAGE_KEY,
  REMINDERS_OUTBOX_STORAGE_KEY,
  CAREGIVER_ALERTS_STORAGE_KEY,
} from './reminderRepository.js'
import {
  reminderSyncService,
  ReminderSyncService,
} from './reminderSyncService.js'

export {
  reminderRepository,
  ReminderRepository,
  reminderSyncService,
  ReminderSyncService,
  REMINDERS_STORAGE_KEY,
  REMINDERS_OUTBOX_STORAGE_KEY,
  CAREGIVER_ALERTS_STORAGE_KEY,
}

/**
 * Loads all reminders from persistent storage via ReminderRepository.
 * If storage is empty, seeds with initial mock data.
 *
 * @returns {Array<Object>} List of valid reminder objects
 */
export function loadAllReminders() {
  return reminderRepository.getAll()
}

/**
 * Persists the entire reminders array to local storage.
 *
 * @param {Array<Object>} reminders
 * @returns {boolean} True if successfully persisted
 */
export function saveAllReminders(reminders) {
  return reminderRepository.saveAll(reminders)
}

/**
 * Retrieves all reminders for a specific patient ID.
 *
 * @param {string} patientId
 * @returns {Array<Object>}
 */
export function getRemindersByPatient(patientId) {
  return reminderRepository.getByPatient(patientId)
}

/**
 * Retrieves a single reminder by its unique identifier.
 *
 * @param {string} id
 * @returns {Object|null}
 */
export function getReminderById(id) {
  return reminderRepository.getById(id)
}

/**
 * Creates a new reminder or updates an existing one offline-first.
 * Automatically records an outbox mutation for future backend synchronization.
 *
 * @param {Object} reminderInput
 * @returns {Object} Saved reminder
 */
export function saveReminder(reminderInput) {
  return reminderRepository.save(reminderInput)
}

/**
 * Deletes a reminder by ID offline-first.
 * Automatically records an outbox deletion mutation for future backend sync.
 *
 * @param {string} id
 * @returns {boolean} True if found and deleted
 */
export function deleteReminder(id) {
  return reminderRepository.delete(id)
}

/**
 * Records that a patient acknowledged a reminder (Patient tapped [ ✓ DONE ]).
 * Works 100% offline and records outbox mutation immediately.
 *
 * @param {string} id
 * @param {string|Date} [timestamp=new Date()]
 * @returns {Object|null} The updated reminder
 */
export function acknowledgeReminderById(id, timestamp = new Date()) {
  return reminderRepository.acknowledge(id, timestamp)
}

/**
 * Configurable snooze duration in minutes for the prototype (default: 10 minutes).
 */
export const DEFAULT_SNOOZE_MINUTES = 10

let configuredSnoozeMinutes = DEFAULT_SNOOZE_MINUTES

/**
 * Returns the currently configured snooze duration in minutes.
 * @returns {number}
 */
export function getSnoozeDurationMinutes() {
  return configuredSnoozeMinutes
}

/**
 * Updates the global snooze duration in minutes.
 * @param {number} minutes
 * @returns {number}
 */
export function setSnoozeDurationMinutes(minutes) {
  if (typeof minutes === 'number' && Number.isFinite(minutes) && minutes > 0) {
    configuredSnoozeMinutes = Math.round(minutes)
  }
  return configuredSnoozeMinutes
}

/**
 * Resets the snooze duration to the default (10 minutes).
 * @returns {number}
 */
export function resetSnoozeDurationMinutes() {
  configuredSnoozeMinutes = DEFAULT_SNOOZE_MINUTES
  return configuredSnoozeMinutes
}

/**
 * ── Configurable Escalation & Retry Settings ─────────────────────────
 * Default: 2 gentle retries before escalating; 10 minutes retry interval.
 */
export const DEFAULT_MAX_RETRIES = 2
export const DEFAULT_RETRY_INTERVAL_MINUTES = 10

let configuredMaxRetries = DEFAULT_MAX_RETRIES
let configuredRetryIntervalMinutes = DEFAULT_RETRY_INTERVAL_MINUTES

/**
 * Returns the currently configured max retry attempts before escalation.
 * @returns {number}
 */
export function getMaxRetries() {
  return configuredMaxRetries
}

/**
 * Updates the max retry count before escalation.
 * @param {number} num
 * @returns {number}
 */
export function setMaxRetries(num) {
  if (typeof num === 'number' && Number.isFinite(num) && num >= 1) {
    configuredMaxRetries = Math.round(num)
  }
  return configuredMaxRetries
}

/**
 * Returns the retry interval in minutes between unacknowledged reminder prompts.
 * @returns {number}
 */
export function getRetryIntervalMinutes() {
  return configuredRetryIntervalMinutes
}

/**
 * Sets the retry interval in minutes between gentle prompts.
 * @param {number} minutes
 * @returns {number}
 */
export function setRetryIntervalMinutes(minutes) {
  if (typeof minutes === 'number' && Number.isFinite(minutes) && minutes > 0) {
    configuredRetryIntervalMinutes = Math.round(minutes)
  }
  return configuredRetryIntervalMinutes
}

/**
 * Resets escalation and retry parameters to defaults.
 * @returns {{ maxRetries: number, retryIntervalMinutes: number }}
 */
export function resetEscalationConfig() {
  configuredMaxRetries = DEFAULT_MAX_RETRIES
  configuredRetryIntervalMinutes = DEFAULT_RETRY_INTERVAL_MINUTES
  return {
    maxRetries: configuredMaxRetries,
    retryIntervalMinutes: configuredRetryIntervalMinutes,
  }
}

/**
 * Snoozes a reminder for a given number of minutes.
 * Defaults to the centrally configured snooze duration (10 minutes).
 *
 * TODO: In production:
 * await apiClient.patch(`/api/v1/reminders/${id}/snooze`, { minutes, snoozedUntil })
 *
 * @param {string} id
 * @param {number} [minutes=getSnoozeDurationMinutes()]
 * @param {Date} [fromTime=new Date()]
 * @returns {Object|null} The updated reminder
 */
export function snoozeReminderById(id, minutes = getSnoozeDurationMinutes(), fromTime = new Date()) {
  return reminderRepository.snooze(id, minutes, fromTime)
}

/**
 * Marks a reminder as delivered on the patient device.
 * Increments attempt counter and records triggeredTime offline.
 *
 * @param {string} id
 * @param {Date} [timestamp=new Date()]
 * @returns {Object|null}
 */
export function deliverReminderById(id, timestamp = new Date()) {
  return reminderRepository.deliver(id, timestamp)
}

/**
 * Marks a reminder as Not Acknowledged when its scheduled window passes.
 *
 * POLICY NOTE:
 * Uses "Not acknowledged" instead of "Medication missed" to avoid false medical conclusions.
 *
 * @param {string} id
 * @param {Date} [timestamp=new Date()]
 * @returns {Object|null}
 */
export function markReminderNotAcknowledgedById(id, timestamp = new Date()) {
  return reminderRepository.markNotAcknowledged(id, timestamp)
}

/** Backwards-compatible alias */
export const markReminderMissedById = markReminderNotAcknowledgedById

/**
 * Dismisses a reminder.
 *
 * @param {string} id
 * @returns {Object|null}
 */
export function dismissReminderById(id) {
  const all = loadAllReminders()
  const index = all.findIndex(r => r.id === id)
  if (index === -1) return null

  const updated = dismissReminder(all[index])
  all[index] = updated
  saveAllReminders(all)
  return updated
}

/**
 * Toggles a reminder's enabled status.
 *
 * @param {string} id
 * @param {boolean} [enabled]
 * @returns {Object|null}
 */
export function toggleReminderEnabledById(id, enabled) {
  const all = loadAllReminders()
  const index = all.findIndex(r => r.id === id)
  if (index === -1) return null

  const updated = toggleReminderEnabled(all[index], enabled)
  all[index] = updated
  saveAllReminders(all)
  return updated
}

/**
 * Finds all active reminders that are due right now for a patient.
 *
 * @param {string} patientId
 * @param {Date} [referenceTime=new Date()]
 * @returns {Array<Object>}
 */
export function getDueReminders(patientId, referenceTime = new Date()) {
  const patientReminders = getRemindersByPatient(patientId)
  return patientReminders.filter(r => isReminderDue(r, referenceTime))
}

/**
 * Finds all reminders scheduled for today for a patient.
 *
 * @param {string} patientId
 * @param {Date} [referenceDate=new Date()]
 * @returns {Array<Object>}
 */
export function getTodayReminders(patientId, referenceDate = new Date()) {
  const patientReminders = getRemindersByPatient(patientId)
  return patientReminders.filter(r => isReminderForDate(r, referenceDate))
}

/**
 * Calculates summary statistics for caregiver monitoring of a patient's reminders.
 *
 * TODO: In production:
 * GET /api/v1/patients/:patientId/reminders/analytics?date=today
 *
 * @param {string} patientId
 * @param {Date} [referenceDate=new Date()]
 * @returns {Object} Aggregated stats for caregiver dashboard
 */
export function getReminderStats(patientId, referenceDate = new Date()) {
  const reminders = getRemindersByPatient(patientId)
  const todayReminders = reminders.filter(r => isReminderForDate(r, referenceDate))

  const total = reminders.length
  const totalToday = todayReminders.length
  const acknowledgedToday = todayReminders.filter(r => r.status === REMINDER_STATUS.ACKNOWLEDGED).length
  const pendingToday = todayReminders.filter(
    r => r.status === REMINDER_STATUS.PENDING || r.status === REMINDER_STATUS.DELIVERED
  ).length
  const snoozedToday = todayReminders.filter(r => r.status === REMINDER_STATUS.SNOOZED).length
  const notAcknowledgedToday = todayReminders.filter(
    r => r.status === REMINDER_STATUS.NOT_ACKNOWLEDGED || r.status === 'not_acknowledged' || r.status === 'missed'
  ).length
  const missedToday = notAcknowledgedToday // Backwards compatibility

  // Categorical breakdown
  const byType = {
    [REMINDER_TYPES.MEDICATION]: 0,
    [REMINDER_TYPES.HYDRATION]: 0,
    [REMINDER_TYPES.APPOINTMENT]: 0,
    [REMINDER_TYPES.COGNITIVE_ACTIVITY]: 0,
    [REMINDER_TYPES.DAILY_ROUTINE]: 0,
  }

  for (const rem of reminders) {
    if (byType[rem.type] !== undefined) {
      byType[rem.type]++
    }
  }

  return {
    patientId,
    total,
    totalToday,
    acknowledgedToday,
    pendingToday,
    snoozedToday,
    notAcknowledgedToday,
    missedToday,
    complianceRate: totalToday > 0 ? Math.round((acknowledgedToday / totalToday) * 100) : 0,
    byType,
  }
}

/**
 * ── Non-Clinical Formatters & Safety Helpers ─────────────────────────
 * IMPORTANT: MindCare NER reports solely that a reminder was not acknowledged.
 * Never conclude whether water was drunk or medication was taken.
 */

/**
 * Formats an ISO string into standard 12-hour time: "11:00 AM".
 *
 * @param {string|Date} isoString
 * @returns {string}
 */
export function formatReminderDisplayTime(isoString) {
  if (!isoString) return '--:--'
  try {
    const d = isoString instanceof Date ? isoString : new Date(isoString)
    if (Number.isNaN(d.getTime())) return '--:--'
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true })
  } catch {
    return '--:--'
  }
}

/**
 * Returns human-friendly category label for alerts and summaries.
 *
 * @param {string} type
 * @returns {string}
 */
export function getReminderCategoryLabel(type) {
  switch (type) {
    case REMINDER_TYPES.MEDICATION:
      return 'Medication'
    case REMINDER_TYPES.HYDRATION:
      return 'Hydration'
    case REMINDER_TYPES.APPOINTMENT:
      return 'Appointment'
    case REMINDER_TYPES.COGNITIVE_ACTIVITY:
      return 'Cognitive Activity'
    case REMINDER_TYPES.DAILY_ROUTINE:
    default:
      return 'Daily Routine'
  }
}

/**
 * Generates initial mock caregiver alerts for prototype demo.
 * Corresponds to the mock appointment that was not acknowledged.
 *
 * @returns {Array<Object>}
 */
export function getInitialMockCaregiverAlerts() {
  return [
    {
      id: 'mock-alert-1',
      reminderId: 'mock-rem-4',
      patientId: 'MC-2048',
      type: REMINDER_TYPES.APPOINTMENT,
      title: 'Reminder not acknowledged',
      message: 'Appointment reminder scheduled for 04:30 PM has not been acknowledged.',
      scheduledTime: new Date().toISOString(),
      createdAt: new Date().toISOString(),
      escalatedAt: new Date().toISOString(),
      resolved: false,
      resolvedAt: null,
      occurrenceKey: 'mock-rem-4_seed_escalation',
    },
  ]
}

/**
 * Loads caregiver escalation alerts from storage.
 *
 * @param {string|null} [patientId=null]
 * @param {Object} [options={ includeResolved: false }]
 * @returns {Array<Object>}
 */
export function loadCaregiverAlerts(patientId = null, options = { includeResolved: false }) {
  return reminderRepository.loadAlerts(patientId, options)
}

/**
 * Persists caregiver alerts to storage and broadcasts sync event.
 *
 * @param {Array<Object>} alerts
 * @returns {boolean}
 */
export function saveAllCaregiverAlerts(alerts) {
  return reminderRepository.saveAllAlerts(alerts)
}

/**
 * Saves a caregiver alert with deduplication protection.
 * Prevents multiple alerts from being generated for the same reminder occurrence.
 *
 * @param {Object} alertData
 * @returns {Object} Saved or existing deduplicated alert
 */
export function saveCaregiverAlert(alertData) {
  return reminderRepository.saveAlert(alertData)
}

/**
 * Dismisses / resolves a caregiver alert.
 *
 * @param {string} alertId
 * @returns {boolean}
 */
export function dismissCaregiverAlert(alertId) {
  return reminderRepository.dismissAlert(alertId)
}

export const resolveCaregiverAlert = dismissCaregiverAlert

/**
 * Escalates a reminder occurrence:
 * 1. Transitions the reminder to 'Not Acknowledged' in state and persistent storage.
 * 2. Formats strictly non-clinical alert text:
 *    "[Category] reminder scheduled for [Time] has not been acknowledged."
 * 3. Generates and stores a caregiver alert with deduplication protection.
 *
 * IMPORTANT NON-CLINICAL SAFETY INVARIANT:
 * - We never say "patient did not drink water" or "patient missed medication".
 * - We strictly report what the system knows: "The reminder was not acknowledged."
 *
 * @param {Object} reminder
 * @param {Date|string} [triggerTime=new Date()]
 * @returns {{ reminder: Object, alert: Object }|null}
 */
export function escalateReminderOccurrence(reminder, triggerTime = new Date()) {
  if (!reminder) return null
  const timestamp = triggerTime instanceof Date ? triggerTime : new Date(triggerTime)
  const occurrenceDateStr = timestamp.toDateString()
  const occurrenceKey = `${reminder.id}_${occurrenceDateStr}_escalated`

  // 1. Mark reminder as Not Acknowledged in persistence layer
  const updatedReminder = reminderRepository.markNotAcknowledged(reminder.id, timestamp)

  // 2. Format strictly non-clinical alert message
  const categoryLabel = getReminderCategoryLabel(reminder.type)
  const timeStr = formatReminderDisplayTime(reminder.scheduledTime)
  const message = `${categoryLabel} reminder scheduled for ${timeStr} has not been acknowledged.`

  // 3. Generate caregiver alert (with deduplication)
  const alert = reminderRepository.saveAlert({
    reminderId: reminder.id,
    patientId: reminder.patientId,
    type: reminder.type,
    title: 'Reminder not acknowledged',
    message,
    scheduledTime: reminder.scheduledTime,
    escalatedAt: timestamp.toISOString(),
    createdAt: timestamp.toISOString(),
    occurrenceKey,
  })

  return {
    reminder: updatedReminder || reminder,
    alert,
  }
}

/**
 * Resets storage to initial mock state (useful for demos and testing).
 * Also restores default mock caregiver alerts and escalation configuration.
 *
 * @returns {Array<Object>}
 */
export function resetRemindersToMock() {
  const seeds = reminderRepository.resetToMock()
  resetEscalationConfig()
  resetSnoozeDurationMinutes()
  return seeds
}

/**
 * ── Offline-First Synchronization Helpers ────────────────────────────
 */

/**
 * Returns the current synchronization status and telemetry.
 * @returns {Object}
 */
export function getSyncStatus() {
  return reminderSyncService.getSyncStatus()
}

/**
 * Synchronizes pending outbox mutations with the backend / sync engine.
 * @returns {Promise<Object>}
 */
export function syncPendingMutations() {
  return reminderSyncService.syncPendingMutations()
}

/**
 * Toggles simulated offline mode for testing or demonstration.
 * @param {boolean} val
 */
export function setSimulatedOffline(val) {
  reminderSyncService.setSimulatedOffline(val)
}

/**
 * Returns whether network connectivity is currently active.
 * @returns {boolean}
 */
export function isOnline() {
  return reminderSyncService.getIsOnline()
}
