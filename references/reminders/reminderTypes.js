/**
 * src/reminders/reminderTypes.js
 *
 * MindCare NER — Smart Reminders Constants & Schema Definitions
 *
 * This module defines:
 * 1. The 5 core reminder categories (Medication, Hydration, Appointment,
 *    Cognitive Activity, Daily Routine)
 * 2. Recurrence/repeat patterns
 * 3. Reminder lifecycle statuses
 * 4. Default schema specification for reminder items
 *
 * DATA PRIVACY GUARANTEE:
 * Reminder entities MUST NEVER store passwords, auth tokens, session secrets,
 * or full confidential clinical diagnoses.
 *
 * FUTURE BACKEND INTEGRATION:
 * The enum values and schema structure directly align with future backend
 * database collections (e.g. MongoDB, PostgreSQL/Prisma, or Cloud Firestore).
 */

/**
 * ── 1. Reminder Categories ──────────────────────────────────────────
 * Core categories specified for MindCare NER eldercare support.
 */
export const REMINDER_TYPES = Object.freeze({
  MEDICATION: 'medication',
  HYDRATION: 'hydration',
  APPOINTMENT: 'appointment',
  COGNITIVE_ACTIVITY: 'cognitive_activity',
  DAILY_ROUTINE: 'daily_routine',
})

/**
 * Metadata and display configurations for each reminder category.
 */
export const REMINDER_TYPE_CONFIG = Object.freeze({
  [REMINDER_TYPES.MEDICATION]: Object.freeze({
    type: REMINDER_TYPES.MEDICATION,
    label: 'Medication',
    description: 'Prescription & OTC medicines with dosage and schedule instructions',
    defaultVoicePrefix: 'It is time for your medication: ',
    badgeColor: 'coral',
    iconName: 'Pill',
  }),
  [REMINDER_TYPES.HYDRATION]: Object.freeze({
    type: REMINDER_TYPES.HYDRATION,
    label: 'Hydration',
    description: 'Regular reminders to drink water or healthy fluids throughout the day',
    defaultVoicePrefix: 'Time for a glass of water: ',
    badgeColor: 'teal',
    iconName: 'Droplets',
  }),
  [REMINDER_TYPES.APPOINTMENT]: Object.freeze({
    type: REMINDER_TYPES.APPOINTMENT,
    label: 'Appointment',
    description: 'Medical checkups, doctor consultations, and therapy visits',
    defaultVoicePrefix: 'You have an upcoming appointment: ',
    badgeColor: 'blue',
    iconName: 'CalendarDays',
  }),
  [REMINDER_TYPES.COGNITIVE_ACTIVITY]: Object.freeze({
    type: REMINDER_TYPES.COGNITIVE_ACTIVITY,
    label: 'Cognitive Activity',
    description: 'Scheduled brain exercises, memory matching, and recognition sessions',
    defaultVoicePrefix: 'Time for a gentle brain activity: ',
    badgeColor: 'violet',
    iconName: 'Gamepad2',
  }),
  [REMINDER_TYPES.DAILY_ROUTINE]: Object.freeze({
    type: REMINDER_TYPES.DAILY_ROUTINE,
    label: 'Daily Routine',
    description: 'Everyday routines like morning stretch, meals, evening walk, and rest',
    defaultVoicePrefix: 'Here is a gentle reminder for your routine: ',
    badgeColor: 'amber',
    iconName: 'Clock3',
  }),
})

/**
 * ── 2. Repeat Cadences ──────────────────────────────────────────────
 */
export const REMINDER_REPEAT = Object.freeze({
  NONE: 'none',
  DAILY: 'daily',
  WEEKDAYS: 'weekdays',
  WEEKENDS: 'weekends',
  WEEKLY: 'weekly',
  CUSTOM: 'custom',
})

/**
 * ── 3. Lifecycle Statuses ───────────────────────────────────────────
 * Possible statuses:
 * - Upcoming: Scheduled for later today or future date
 * - Due: Currently active on patient device awaiting response
 * - Acknowledged: Patient confirmed [ ✓ DONE ]
 * - Snoozed: Patient requested [ REMIND ME LATER ]
 * - Not Acknowledged: Alert window elapsed without patient confirmation
 *
 * NOTE: "Not acknowledged" is strictly used instead of "Medication missed"
 * because the platform cannot infer whether medicine was taken if the device
 * was merely not interacted with. No medical conclusions are made.
 */
export const REMINDER_STATUS = Object.freeze({
  UPCOMING: 'upcoming',
  DUE: 'due',
  ACKNOWLEDGED: 'acknowledged',
  SNOOZED: 'snoozed',
  NOT_ACKNOWLEDGED: 'not_acknowledged',

  // Backwards-compatible aliases
  PENDING: 'upcoming',
  DELIVERED: 'due',
  MISSED: 'not_acknowledged',
  DISMISSED: 'not_acknowledged',
})

/**
 * ── 4. Baseline Default Schema ──────────────────────────────────────
 * Defines the complete shape of a Reminder entity with occurrence tracking.
 */
export const DEFAULT_REMINDER = Object.freeze({
  id: null,
  patientId: null,
  type: REMINDER_TYPES.DAILY_ROUTINE,
  title: '',
  message: '',
  scheduledTime: null,
  repeat: REMINDER_REPEAT.NONE,
  enabled: true,
  voiceEnabled: true,
  status: REMINDER_STATUS.UPCOMING,
  createdAt: null,
  // Occurrence tracking data
  triggeredTime: null,       // Timestamp when reminder was triggered/delivered
  acknowledgedTime: null,    // Timestamp when patient acknowledged
  snoozed: false,            // Boolean: whether this occurrence has been snoozed
  attempts: 0,               // Number of delivery / notification attempts
  acknowledgedAt: null,      // Backwards-compatible alias for acknowledgedTime
  snoozedUntil: null,
})

/**
 * Checks if a candidate string is a valid reminder type.
 * @param {string} candidate
 * @returns {boolean}
 */
export function isValidReminderType(candidate) {
  return Object.values(REMINDER_TYPES).includes(candidate)
}

/**
 * Checks if a candidate string is a valid repeat pattern.
 * @param {string} candidate
 * @returns {boolean}
 */
export function isValidReminderRepeat(candidate) {
  return Object.values(REMINDER_REPEAT).includes(candidate)
}

/**
 * Checks if a candidate string is a valid lifecycle status.
 * @param {string} candidate
 * @returns {boolean}
 */
export function isValidReminderStatus(candidate) {
  return Object.values(REMINDER_STATUS).includes(candidate)
}
