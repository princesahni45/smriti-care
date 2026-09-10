/**
 * src/reminders/mockReminders.js
 *
 * MindCare NER — Initial Seed Mock Reminders for Prototype
 *
 * Provides realistic prototype demonstration reminders for patient 'MC-2048' (Ramesh).
 *
 * POLICY:
 * Does NOT contain clinical medication dosages or sensitive medical diagnoses.
 * Reflects the 5 core categories: Medication, Hydration, Appointment,
 * Cognitive Activity, and Daily Routine.
 */

import {
  REMINDER_TYPES,
  REMINDER_REPEAT,
  REMINDER_STATUS,
} from './reminderTypes.js'
import { createReminder } from './reminderModel.js'

/**
 * Helper to compute an ISO string relative to today's local date.
 *
 * @param {number} hours (0-23)
 * @param {number} minutes (0-59)
 * @param {number} [dayOffset=0]
 * @returns {string} ISO Date String
 */
function getRelativeIso(hours, minutes, dayOffset = 0) {
  const date = new Date()
  date.setDate(date.getDate() + dayOffset)
  date.setHours(hours, minutes, 0, 0)
  return date.toISOString()
}

export const INITIAL_MOCK_REMINDERS_RAW = [
  // 1. Medication (09:00 AM - Acknowledged at 09:04 AM)
  {
    id: 'rem-mock-001',
    patientId: 'MC-2048',
    type: REMINDER_TYPES.MEDICATION,
    title: 'Morning Medicine',
    message: "It's time for your scheduled medicine with breakfast.",
    scheduledTime: getRelativeIso(9, 0, 0),
    repeat: REMINDER_REPEAT.DAILY,
    enabled: true,
    voiceEnabled: true,
    status: REMINDER_STATUS.ACKNOWLEDGED,
    createdAt: getRelativeIso(8, 0, -2),
    triggeredTime: getRelativeIso(9, 0, 0),
    acknowledgedTime: getRelativeIso(9, 4, 0),
    acknowledgedAt: getRelativeIso(9, 4, 0),
    snoozed: false,
    attempts: 1,
    snoozedUntil: null,
  },

  // 2. Hydration (11:00 AM - Acknowledged)
  {
    id: 'rem-mock-002',
    patientId: 'MC-2048',
    type: REMINDER_TYPES.HYDRATION,
    title: 'Time for Water',
    message: "Let's have some fresh water to stay healthy and hydrated.",
    scheduledTime: getRelativeIso(11, 0, 0),
    repeat: REMINDER_REPEAT.DAILY,
    enabled: true,
    voiceEnabled: true,
    status: REMINDER_STATUS.ACKNOWLEDGED,
    createdAt: getRelativeIso(8, 0, -2),
    triggeredTime: getRelativeIso(11, 0, 0),
    acknowledgedTime: getRelativeIso(11, 1, 0),
    acknowledgedAt: getRelativeIso(11, 1, 0),
    snoozed: false,
    attempts: 1,
    snoozedUntil: null,
  },

  // 3. Cognitive Activity (02:00 PM - Upcoming)
  {
    id: 'rem-mock-003',
    patientId: 'MC-2048',
    type: REMINDER_TYPES.COGNITIVE_ACTIVITY,
    title: 'Brain Activity',
    message: 'Time for a gentle brain activity and memory game.',
    scheduledTime: getRelativeIso(14, 0, 0),
    repeat: REMINDER_REPEAT.DAILY,
    enabled: true,
    voiceEnabled: true,
    status: REMINDER_STATUS.UPCOMING,
    createdAt: getRelativeIso(8, 0, -2),
    triggeredTime: null,
    acknowledgedTime: null,
    acknowledgedAt: null,
    snoozed: false,
    attempts: 0,
    snoozedUntil: null,
  },

  // 4. Appointment (04:30 PM - Not Acknowledged)
  {
    id: 'rem-mock-004',
    patientId: 'MC-2048',
    type: REMINDER_TYPES.APPOINTMENT,
    title: 'Doctor Appointment',
    message: 'You have a wellness review appointment today.',
    scheduledTime: getRelativeIso(16, 30, 0),
    repeat: REMINDER_REPEAT.DAILY,
    enabled: true,
    voiceEnabled: true,
    status: REMINDER_STATUS.NOT_ACKNOWLEDGED,
    createdAt: getRelativeIso(8, 0, -2),
    triggeredTime: getRelativeIso(16, 30, 0),
    acknowledgedTime: null,
    acknowledgedAt: null,
    snoozed: false,
    attempts: 2,
    snoozedUntil: null,
  },

  // 5. Daily Routine (06:00 PM - Upcoming)
  {
    id: 'rem-mock-005',
    patientId: 'MC-2048',
    type: REMINDER_TYPES.DAILY_ROUTINE,
    title: 'Gentle Evening Courtyard Walk',
    message: 'Take a relaxed 15-minute walk in the garden with your caregiver.',
    scheduledTime: getRelativeIso(18, 0, 0),
    repeat: REMINDER_REPEAT.DAILY,
    enabled: true,
    voiceEnabled: true,
    status: REMINDER_STATUS.UPCOMING,
    createdAt: getRelativeIso(8, 0, -2),
    triggeredTime: null,
    acknowledgedTime: null,
    acknowledgedAt: null,
    snoozed: false,
    attempts: 0,
    snoozedUntil: null,
  },
]

/**
 * Returns frozen, validated mock reminders.
 *
 * @returns {Array<Object>} List of frozen reminder objects
 */
export function getInitialMockReminders() {
  return INITIAL_MOCK_REMINDERS_RAW.map(raw => {
    try {
      return createReminder(raw)
    } catch {
      return null
    }
  }).filter(Boolean)
}
