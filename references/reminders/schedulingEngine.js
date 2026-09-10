/**
 * src/reminders/schedulingEngine.js
 *
 * MindCare NER — Frontend Smart Reminder Scheduling Engine
 *
 * ARCHITECTURE & PRINCIPLES:
 * 1. Self-contained: Runs on the device's local system time without internet or external time APIs.
 * 2. Single-timer architecture: Uses a centralized heartbeat ticker to prevent timer proliferation.
 * 3. Dementia-friendly sequential queue: If multiple reminders are due at once, delivers them
 *    one at a time so vulnerable patients are never overwhelmed by stacked modals.
 * 4. Deduplication & recurrence:
 *    - Daily reminders check if today's occurrence was already acknowledged (avoids duplicate alerts).
 *    - One-time reminders trigger once and retire upon completion.
 *    - Disabled reminders are strictly ignored.
 *    - Snoozed reminders awaken when snoozedUntil is reached.
 * 5. Clean lifecycle: Starts and stops cleanly without dangling intervals.
 * 6. Zero UI dependencies: Pure business logic decoupled from React components.
 */

import {
  REMINDER_STATUS,
  REMINDER_REPEAT,
} from './reminderTypes.js'
import {
  loadAllReminders,
  saveAllReminders,
  getRemindersByPatient,
  acknowledgeReminderById,
  snoozeReminderById,
  deliverReminderById,
  getSnoozeDurationMinutes,
  getMaxRetries,
  getRetryIntervalMinutes,
  escalateReminderOccurrence,
} from './reminderService.js'

/**
 * Checks whether two Date objects correspond to the same local calendar day.
 *
 * @param {Date|string} d1
 * @param {Date|string} d2
 * @returns {boolean}
 */
export function isSameCalendarDay(d1, d2) {
  if (!d1 || !d2) return false
  const date1 = d1 instanceof Date ? d1 : new Date(d1)
  const date2 = d2 instanceof Date ? d2 : new Date(d2)

  if (Number.isNaN(date1.getTime()) || Number.isNaN(date2.getTime())) return false

  return (
    date1.getFullYear() === date2.getFullYear() &&
    date1.getMonth() === date2.getMonth() &&
    date1.getDate() === date2.getDate()
  )
}

/**
 * Extracts hours and minutes from a scheduledTime string or Date.
 *
 * @param {Date|string} scheduledTime
 * @returns {{ hours: number, minutes: number }}
 */
export function extractScheduledTimeOfDay(scheduledTime) {
  const d = scheduledTime instanceof Date ? scheduledTime : new Date(scheduledTime)
  if (Number.isNaN(d.getTime())) {
    return { hours: 9, minutes: 0 }
  }
  return { hours: d.getHours(), minutes: d.getMinutes() }
}

/**
 * Calculates the exact scheduled Date occurrence for a reminder on a target calendar day.
 *
 * @param {Object} reminder
 * @param {Date} [targetDay=new Date()]
 * @returns {Date}
 */
export function getOccurrenceDateForDay(reminder, targetDay = new Date()) {
  const { hours, minutes } = extractScheduledTimeOfDay(reminder.scheduledTime)
  const occurrence = new Date(targetDay)
  occurrence.setHours(hours, minutes, 0, 0)
  return occurrence
}

/**
 * Determines whether a reminder is eligible and due for triggering at `currentTime`.
 *
 * Evaluates:
 * - enabled flag (must be true)
 * - repeat rule (none, daily, weekdays, weekends, custom)
 * - snooze expiration
 * - completion for the current occurrence (preventing repeat triggers on same day)
 *
 * @param {Object} reminder
 * @param {Date} [currentTime=new Date()]
 * @returns {boolean}
 */
export function isReminderDueForOccurrence(reminder, currentTime = new Date()) {
  if (!reminder || !reminder.enabled) return false

  const nowMillis = currentTime.getTime()

  // 1. Snoozed reminder evaluation
  if (reminder.status === REMINDER_STATUS.SNOOZED && reminder.snoozedUntil) {
    const snoozeMillis = new Date(reminder.snoozedUntil).getTime()
    return nowMillis >= snoozeMillis
  }

  // 2. If reminder is already marked not acknowledged or dismissed, do not trigger
  if (
    reminder.status === REMINDER_STATUS.NOT_ACKNOWLEDGED ||
    reminder.status === 'not_acknowledged' ||
    reminder.status === 'missed' ||
    reminder.status === 'dismissed'
  ) {
    return false
  }

  const repeat = reminder.repeat || REMINDER_REPEAT.NONE

  // 3. ONE-TIME REMINDER (`repeat === 'none'`)
  if (repeat === REMINDER_REPEAT.NONE) {
    // If already acknowledged, one-time reminder is permanently finished
    if (reminder.status === REMINDER_STATUS.ACKNOWLEDGED || reminder.acknowledgedAt) {
      return false
    }

    const scheduledDate = new Date(reminder.scheduledTime)
    // Only due if current time is at or past scheduled time
    return nowMillis >= scheduledDate.getTime()
  }

  // 4. RECURRING REMINDERS (Daily, Weekdays, etc.)
  const dayOfWeek = currentTime.getDay() // 0 = Sunday, 1 = Monday, ..., 6 = Saturday

  // Weekdays check: only Monday(1) to Friday(5)
  if (repeat === REMINDER_REPEAT.WEEKDAYS && (dayOfWeek === 0 || dayOfWeek === 6)) {
    return false
  }

  // Weekends check: only Saturday(6) or Sunday(0)
  if (repeat === REMINDER_REPEAT.WEEKENDS && dayOfWeek !== 0 && dayOfWeek !== 6) {
    return false
  }

  // Occurrence time on today's calendar day
  const todayScheduledOccurrence = getOccurrenceDateForDay(reminder, currentTime)

  // Has the scheduled time arrived today?
  if (nowMillis < todayScheduledOccurrence.getTime()) {
    return false
  }

  // Has it already been acknowledged for today's occurrence?
  if (reminder.acknowledgedAt && isSameCalendarDay(reminder.acknowledgedAt, currentTime)) {
    return false
  }

  return true
}

/**
 * ── Scheduling Engine Class ──────────────────────────────────────────
 *
 * Manages background monitoring of reminders for a patient using a single
 * central heartbeat interval and an elder-friendly sequential queue.
 */
export class ReminderScheduler {
  constructor({
    patientId = 'MC-2048',
    checkIntervalMs = 5000, // Check every 5 seconds
    onDue = null,
    onQueueChange = null,
  } = {}) {
    this.patientId = patientId
    this.checkIntervalMs = checkIntervalMs
    this.onDue = onDue
    this.onQueueChange = onQueueChange

    this.timerId = null
    this.isRunning = false
    this.activeReminder = null
    this.activePresentedAt = null
    this.dueQueue = []
    this.handledOccurrenceKeys = new Set() // Set of `${reminderId}_${dateString}` to prevent double triggering
  }

  /**
   * Starts the central scheduler heartbeat ticker.
   */
  start() {
    if (this.isRunning) return
    this.isRunning = true

    // Initial check immediately
    this.tick()

    // Single unified interval for checking due reminders
    this.timerId = setInterval(() => {
      this.tick()
    }, this.checkIntervalMs)
  }

  /**
   * Stops the central scheduler and cleans up timers.
   */
  stop() {
    if (this.timerId) {
      clearInterval(this.timerId)
      this.timerId = null
    }
    this.isRunning = false
  }

  /**
   * Sets or updates the target patient ID.
   *
   * @param {string} nextPatientId
   */
  setPatientId(nextPatientId) {
    if (this.patientId !== nextPatientId) {
      this.patientId = nextPatientId
      this.activeReminder = null
      this.activePresentedAt = null
      this.dueQueue = []
      this.tick()
    }
  }

  /**
   * Evaluates all reminders for the active patient.
   * Called on every heartbeat tick.
   * Handles:
   * 1. Due reminder detection and queuing
   * 2. Gentle retries when a reminder remains unattended
   * 3. Escalation and caregiver alerts when retry threshold is exceeded
   *
   * @param {Date} [referenceTime=new Date()]
   */
  tick(referenceTime = new Date()) {
    if (!this.patientId) return

    const reminders = getRemindersByPatient(this.patientId)
    const newlyDue = []
    const nowMillis = referenceTime.getTime()
    const maxRetries = getMaxRetries()
    const retryIntervalMs = getRetryIntervalMinutes() * 60 * 1000

    // 1. Detect due reminders for this occurrence
    for (const reminder of reminders) {
      // Skip if this reminder is currently active in the UI
      if (this.activeReminder && this.activeReminder.id === reminder.id) {
        continue
      }

      // Skip if already waiting in the queue
      if (this.dueQueue.some(item => item.id === reminder.id)) {
        continue
      }

      // Check if due for this occurrence
      if (isReminderDueForOccurrence(reminder, referenceTime)) {
        // Occurrence key to prevent double alerts for the same occurrence
        const occurrenceKey = reminder.status === REMINDER_STATUS.SNOOZED
          ? `${reminder.id}_snooze_${reminder.snoozedUntil}`
          : `${reminder.id}_${referenceTime.toDateString()}`

        if (!this.handledOccurrenceKeys.has(occurrenceKey)) {
          newlyDue.push(reminder)
        }
      }
    }

    if (newlyDue.length > 0) {
      // Sort newly due reminders by scheduled time
      newlyDue.sort((a, b) => new Date(a.scheduledTime) - new Date(b.scheduledTime))

      // Append to the sequential queue
      this.dueQueue.push(...newlyDue)

      if (this.onQueueChange) {
        this.onQueueChange([...this.dueQueue])
      }
    }

    // 2. Escalation & Gentle Retry Check on currently active screen reminder
    if (this.activeReminder) {
      const presentedTime = this.activePresentedAt || (
        this.activeReminder.triggeredTime
          ? new Date(this.activeReminder.triggeredTime).getTime()
          : nowMillis
      )
      const elapsed = nowMillis - presentedTime

      if (elapsed >= retryIntervalMs) {
        const attempts = this.activeReminder.attempts || 1
        if (attempts < maxRetries) {
          // Gentle retry attempt
          this.retryActiveReminder(referenceTime)
        } else {
          // Exceeded retry limit without acknowledgement -> escalate to Not Acknowledged & generate alert
          this.escalateActive(referenceTime)
        }
      }
    }

    // 3. Background escalation check for stored delivered/snoozed occurrences that timed out
    for (const rem of reminders) {
      if (this.activeReminder && this.activeReminder.id === rem.id) continue

      if (
        rem.status === REMINDER_STATUS.DUE ||
        rem.status === 'delivered' ||
        rem.status === REMINDER_STATUS.SNOOZED
      ) {
        if ((rem.attempts || 0) >= maxRetries) {
          const lastActivity = rem.snoozedUntil
            ? new Date(rem.snoozedUntil).getTime()
            : (rem.triggeredTime ? new Date(rem.triggeredTime).getTime() : 0)

          if (lastActivity && (nowMillis - lastActivity >= retryIntervalMs)) {
            escalateReminderOccurrence(rem, referenceTime)
          }
        }
      }
    }

    // If no reminder is currently active on screen, present the next due reminder from queue
    if (!this.activeReminder && this.dueQueue.length > 0) {
      this.presentNextDue(referenceTime)
    }
  }

  /**
   * Presents the next due reminder from the queue to the patient.
   *
   * @param {Date} [referenceTime=new Date()]
   */
  presentNextDue(referenceTime = new Date()) {
    if (this.dueQueue.length === 0) {
      this.activeReminder = null
      this.activePresentedAt = null
      if (this.onDue) this.onDue(null)
      return
    }

    // Dequeue first due reminder
    const nextReminder = this.dueQueue.shift()
    this.activeReminder = nextReminder
    this.activePresentedAt = referenceTime.getTime()

    // Mark as DUE/DELIVERED in persistence layer so caregiver portal reflects delivery
    if (nextReminder.status === REMINDER_STATUS.PENDING || nextReminder.status === REMINDER_STATUS.UPCOMING) {
      const delivered = deliverReminderById(nextReminder.id, referenceTime)
      if (delivered) {
        this.activeReminder = delivered
      }
    }

    // Notify listener
    if (this.onDue) {
      this.onDue(this.activeReminder)
    }
    if (this.onQueueChange) {
      this.onQueueChange([...this.dueQueue])
    }
  }

  /**
   * Re-prompts the patient with a gentle reminder retry without alarming sounds.
   *
   * @param {Date} [referenceTime=new Date()]
   * @returns {Object|null}
   */
  retryActiveReminder(referenceTime = new Date()) {
    if (!this.activeReminder) return null

    const all = loadAllReminders()
    const index = all.findIndex(r => r.id === this.activeReminder.id)
    if (index === -1) return null

    const current = all[index]
    const nextAttempts = (current.attempts || 1) + 1
    const updated = {
      ...current,
      attempts: nextAttempts,
      triggeredTime: referenceTime.toISOString(),
      status: REMINDER_STATUS.DUE,
    }
    all[index] = updated
    saveAllReminders(all)

    this.activeReminder = updated
    this.activePresentedAt = referenceTime.getTime()

    if (this.onDue) {
      this.onDue(this.activeReminder)
    }

    return updated
  }

  /**
   * Escalates the active unacknowledged reminder:
   * 1. Marks occurrence as 'Not Acknowledged'
   * 2. Emits caregiver alert with strict non-clinical wording
   * 3. Retires active modal from screen and shows next item in queue
   *
   * @param {Date} [referenceTime=new Date()]
   * @returns {{ reminder: Object, alert: Object }|null}
   */
  escalateActive(referenceTime = new Date()) {
    if (!this.activeReminder) return null

    const target = this.activeReminder
    const result = escalateReminderOccurrence(target, referenceTime)

    // Mark handled to avoid repeat triggering today
    const keyDate = referenceTime instanceof Date ? referenceTime : new Date(referenceTime)
    this.handledOccurrenceKeys.add(`${target.id}_${keyDate.toDateString()}`)

    this.activeReminder = null
    this.activePresentedAt = null

    // Present next reminder from queue if any
    this.presentNextDue(referenceTime)

    return result
  }

  /**
   * Acknowledges the active reminder (Patient tapped [ ✓ DONE ]).
   *
   * @param {string|Date} [timestamp=new Date()]
   * @returns {Object|null}
   */
  acknowledgeActive(timestamp = new Date()) {
    if (!this.activeReminder) return null

    const id = this.activeReminder.id
    const updated = acknowledgeReminderById(id, timestamp)

    // Mark occurrence as handled
    const keyDate = timestamp instanceof Date ? timestamp : new Date(timestamp)
    this.handledOccurrenceKeys.add(`${id}_${keyDate.toDateString()}`)

    this.activeReminder = null
    this.activePresentedAt = null

    // Present next due reminder if any in queue
    this.presentNextDue()

    return updated
  }

  /**
   * Snoozes the active reminder (Patient tapped [ REMIND ME LATER ]).
   *
   * @param {number} [minutes=getSnoozeDurationMinutes()]
   * @param {Date} [fromTime=new Date()]
   * @returns {Object|null}
   */
  snoozeActive(minutes = getSnoozeDurationMinutes(), fromTime = new Date()) {
    if (!this.activeReminder) return null

    const id = this.activeReminder.id
    const updated = snoozeReminderById(id, minutes, fromTime)

    this.activeReminder = null
    this.activePresentedAt = null

    // Present next due reminder if any in queue
    this.presentNextDue()

    return updated
  }

  /**
   * Cleans up all resources.
   */
  destroy() {
    this.stop()
    this.activeReminder = null
    this.activePresentedAt = null
    this.dueQueue = []
    this.handledOccurrenceKeys.clear()
    this.onDue = null
    this.onQueueChange = null
  }
}
