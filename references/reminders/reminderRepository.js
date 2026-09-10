/**
 * src/reminders/reminderRepository.js
 *
 * MindCare NER — Offline-First Reminder Repository
 *
 * ARCHITECTURAL PRINCIPLES:
 * 1. Offline-First: All reads and writes target local persistence immediately.
 * 2. Zero Network Latency: No network request is required to read, trigger, or
 *    acknowledge scheduled reminders.
 * 3. Mutation Outbox Pattern: Every state change (create, edit, delete, acknowledge,
 *    snooze, deliver, escalate) is enqueued into a persistent outbox queue for future
 *    safe synchronization when online.
 * 4. Deduplication & Idempotency: Uses unique IDs and ISO timestamps to guarantee
 *    deterministic conflict resolution without duplicating reminders upon reconnection.
 * 5. UI-Independent & Pluggable: Can be consumed by React hooks, background timers,
 *    service workers, or backend synchronization adapters.
 */

import {
  REMINDER_STATUS,
  REMINDER_TYPES,
} from './reminderTypes.js'
import {
  createReminder,
  validateReminder,
  acknowledgeReminder,
  snoozeReminder,
  markReminderDelivered,
  markReminderNotAcknowledged,
  dismissReminder,
  toggleReminderEnabled,
  isReminderDue,
  isReminderForDate,
} from './reminderModel.js'
import { getInitialMockReminders } from './mockReminders.js'

export const REMINDERS_STORAGE_KEY = 'mindcare-patient-reminders-v1'
export const REMINDERS_OUTBOX_STORAGE_KEY = 'mindcare-reminders-outbox-v1'
export const CAREGIVER_ALERTS_STORAGE_KEY = 'mindcare-caregiver-alerts-v1'

/**
 * SSR and environment-safe storage accessor with in-memory fallback.
 */
let inMemoryFallback = null

function getSafeStorage() {
  if (typeof window !== 'undefined' && window.localStorage) {
    return window.localStorage
  }
  if (typeof globalThis !== 'undefined' && globalThis.localStorage) {
    return globalThis.localStorage
  }
  if (!inMemoryFallback) {
    const memoryStore = {}
    inMemoryFallback = {
      getItem: key => memoryStore[key] ?? null,
      setItem: (key, val) => { memoryStore[key] = String(val) },
      removeItem: key => { delete memoryStore[key] },
      clear: () => { Object.keys(memoryStore).forEach(k => delete memoryStore[k]) },
    }
  }
  return inMemoryFallback
}

/**
 * Generates a unique mutation ID.
 * @returns {string}
 */
function generateMutationId() {
  return `mut_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
}

/**
 * ── ReminderRepository Class ─────────────────────────────────────────
 */
export class ReminderRepository {
  constructor({
    remindersKey = REMINDERS_STORAGE_KEY,
    outboxKey = REMINDERS_OUTBOX_STORAGE_KEY,
    alertsKey = CAREGIVER_ALERTS_STORAGE_KEY,
  } = {}) {
    this.remindersKey = remindersKey
    this.outboxKey = outboxKey
    this.alertsKey = alertsKey
  }

  /* ───────────────────────────────────────────────────────────────────
   * 1. Outbox Mutation Queue (Offline-First Sync Pattern)
   * ─────────────────────────────────────────────────────────────────── */

  /**
   * Retrieves all pending mutations waiting to sync.
   * @returns {Array<Object>}
   */
  getOutbox() {
    try {
      const storage = getSafeStorage()
      const raw = storage.getItem(this.outboxKey)
      if (!raw) return []
      const parsed = JSON.parse(raw)
      return Array.isArray(parsed) ? parsed : []
    } catch {
      return []
    }
  }

  /**
   * Persists the outbox mutation queue and dispatches sync event.
   * @param {Array<Object>} queue
   * @returns {boolean}
   */
  saveOutbox(queue) {
    try {
      const storage = getSafeStorage()
      storage.setItem(this.outboxKey, JSON.stringify(queue))
      if (typeof window !== 'undefined' && typeof window.dispatchEvent === 'function') {
        try {
          window.dispatchEvent(new CustomEvent('mindcare:outbox-updated', { detail: { queue } }))
        } catch {}
      }
      return true
    } catch {
      return false
    }
  }

  /**
   * Enqueues a mutation into the persistent outbox.
   *
   * @param {Object} mutation
   * @returns {Object} The recorded mutation
   */
  enqueueMutation({ entityId, type, payload = {} }) {
    const queue = this.getOutbox()
    const mutation = {
      id: generateMutationId(),
      entityId,
      type, // 'REMINDER_UPSERT' | 'REMINDER_ACKNOWLEDGE' | 'REMINDER_SNOOZE' | 'REMINDER_DELIVER' | 'REMINDER_NOT_ACKNOWLEDGED' | 'REMINDER_DELETE' | 'ALERT_CREATE' | 'ALERT_DISMISS'
      payload,
      timestamp: new Date().toISOString(),
      status: 'pending',
    }
    queue.push(mutation)
    this.saveOutbox(queue)
    return mutation
  }

  /**
   * Clears the outbox or removes specific mutation IDs after successful sync.
   *
   * @param {Array<string>} [mutationIds]
   * @returns {number} Remaining pending mutation count
   */
  clearOutbox(mutationIds = null) {
    if (!mutationIds) {
      this.saveOutbox([])
      return 0
    }
    const idSet = new Set(mutationIds)
    const filtered = this.getOutbox().filter(m => !idSet.has(m.id))
    this.saveOutbox(filtered)
    return filtered.length
  }

  /* ───────────────────────────────────────────────────────────────────
   * 2. Reminders Local Store Operations (Offline Source of Truth)
   * ─────────────────────────────────────────────────────────────────── */

  /**
   * Loads all reminders from local storage.
   * If empty on first launch, seeds with default mock data.
   *
   * @returns {Array<Object>}
   */
  getAll() {
    try {
      const storage = getSafeStorage()
      const raw = storage.getItem(this.remindersKey)
      if (!raw) {
        const seeds = getInitialMockReminders()
        this.saveAll(seeds, { recordMutation: false })
        return seeds
      }
      const parsed = JSON.parse(raw)
      if (Array.isArray(parsed)) {
        return parsed.map(item => {
          try {
            return createReminder(item)
          } catch {
            return null
          }
        }).filter(Boolean)
      }
      const seeds = getInitialMockReminders()
      this.saveAll(seeds, { recordMutation: false })
      return seeds
    } catch {
      return getInitialMockReminders()
    }
  }

  /**
   * Persists reminders array to local storage and broadcasts update event.
   *
   * @param {Array<Object>} reminders
   * @param {Object} [options={ recordMutation: false }]
   * @returns {boolean}
   */
  saveAll(reminders, { recordMutation = false } = {}) {
    try {
      const storage = getSafeStorage()
      storage.setItem(this.remindersKey, JSON.stringify(reminders))
      if (typeof window !== 'undefined' && typeof window.dispatchEvent === 'function') {
        try {
          window.dispatchEvent(new CustomEvent('mindcare:reminders-updated', { detail: { reminders } }))
        } catch {}
      }
      return true
    } catch {
      return false
    }
  }

  /**
   * Retrieves all reminders for a specific patient ID.
   *
   * @param {string} patientId
   * @returns {Array<Object>}
   */
  getByPatient(patientId) {
    if (!patientId) return []
    return this.getAll().filter(r => r.patientId === patientId)
  }

  /**
   * Retrieves a single reminder by ID.
   *
   * @param {string} id
   * @returns {Object|null}
   */
  getById(id) {
    if (!id) return null
    const all = this.getAll()
    return all.find(r => r.id === id) || null
  }

  /**
   * Creates or updates a reminder locally.
   * Enqueues an offline mutation record into the outbox for future backend sync.
   *
   * @param {Object} reminderData
   * @param {Object} [options={ recordMutation: true }]
   * @returns {Object} Saved reminder object
   */
  save(reminderData, { recordMutation = true } = {}) {
    const validated = createReminder(reminderData)
    const all = this.getAll()
    const index = all.findIndex(r => r.id === validated.id)

    if (index >= 0) {
      all[index] = validated
    } else {
      all.push(validated)
    }

    this.saveAll(all)

    if (recordMutation) {
      this.enqueueMutation({
        entityId: validated.id,
        type: 'REMINDER_UPSERT',
        payload: validated,
      })
    }

    return validated
  }

  /**
   * Deletes a reminder locally.
   * Enqueues a deletion mutation into the outbox for future backend sync.
   *
   * @param {string} id
   * @param {Object} [options={ recordMutation: true }]
   * @returns {boolean}
   */
  delete(id, { recordMutation = true } = {}) {
    const all = this.getAll()
    const filtered = all.filter(r => r.id !== id)
    if (filtered.length === all.length) return false

    this.saveAll(filtered)

    if (recordMutation) {
      this.enqueueMutation({
        entityId: id,
        type: 'REMINDER_DELETE',
        payload: { id },
      })
    }

    return true
  }

  /**
   * Acknowledges a reminder locally (Patient tapped [ ✓ DONE ]).
   * Records acknowledgement timestamp and outbox mutation immediately.
   *
   * @param {string} id
   * @param {string|Date} [timestamp=new Date()]
   * @param {Object} [options={ recordMutation: true }]
   * @returns {Object|null}
   */
  acknowledge(id, timestamp = new Date(), { recordMutation = true } = {}) {
    const all = this.getAll()
    const index = all.findIndex(r => r.id === id)
    if (index === -1) return null

    const updated = acknowledgeReminder(all[index], timestamp)
    all[index] = updated
    this.saveAll(all)

    if (recordMutation) {
      this.enqueueMutation({
        entityId: id,
        type: 'REMINDER_ACKNOWLEDGE',
        payload: {
          id,
          acknowledgedTime: updated.acknowledgedTime,
          acknowledgedAt: updated.acknowledgedAt,
          status: updated.status,
        },
      })
    }

    return updated
  }

  /**
   * Snoozes a reminder locally (Patient tapped [ REMIND ME LATER ]).
   * Sets snoozedUntil and records outbox mutation.
   *
   * @param {string} id
   * @param {number} [minutes=10]
   * @param {Date} [fromTime=new Date()]
   * @param {Object} [options={ recordMutation: true }]
   * @returns {Object|null}
   */
  snooze(id, minutes = 10, fromTime = new Date(), { recordMutation = true } = {}) {
    const all = this.getAll()
    const index = all.findIndex(r => r.id === id)
    if (index === -1) return null

    const updated = snoozeReminder(all[index], minutes, fromTime)
    all[index] = updated
    this.saveAll(all)

    if (recordMutation) {
      this.enqueueMutation({
        entityId: id,
        type: 'REMINDER_SNOOZE',
        payload: {
          id,
          snoozedUntil: updated.snoozedUntil,
          snoozed: updated.snoozed,
          status: updated.status,
        },
      })
    }

    return updated
  }

  /**
   * Marks a reminder as delivered / due locally upon trigger.
   * Increments attempt counter and records triggeredTime.
   *
   * @param {string} id
   * @param {Date} [timestamp=new Date()]
   * @param {Object} [options={ recordMutation: true }]
   * @returns {Object|null}
   */
  deliver(id, timestamp = new Date(), { recordMutation = true } = {}) {
    const all = this.getAll()
    const index = all.findIndex(r => r.id === id)
    if (index === -1) return null

    const updated = markReminderDelivered(all[index], timestamp)
    all[index] = updated
    this.saveAll(all)

    if (recordMutation) {
      this.enqueueMutation({
        entityId: id,
        type: 'REMINDER_DELIVER',
        payload: {
          id,
          triggeredTime: updated.triggeredTime,
          attempts: updated.attempts,
          status: updated.status,
        },
      })
    }

    return updated
  }

  /**
   * Marks a reminder as not acknowledged locally upon escalation.
   *
   * @param {string} id
   * @param {Date} [timestamp=new Date()]
   * @param {Object} [options={ recordMutation: true }]
   * @returns {Object|null}
   */
  markNotAcknowledged(id, timestamp = new Date(), { recordMutation = true } = {}) {
    const all = this.getAll()
    const index = all.findIndex(r => r.id === id)
    if (index === -1) return null

    const updated = markReminderNotAcknowledged(all[index])
    all[index] = updated
    this.saveAll(all)

    if (recordMutation) {
      this.enqueueMutation({
        entityId: id,
        type: 'REMINDER_NOT_ACKNOWLEDGED',
        payload: {
          id,
          status: updated.status,
          attempts: updated.attempts,
        },
      })
    }

    return updated
  }

  /* ───────────────────────────────────────────────────────────────────
   * 3. Caregiver Alerts Local Store Operations
   * ─────────────────────────────────────────────────────────────────── */

  /**
   * Loads caregiver alerts from local storage.
   *
   * @param {string|null} [patientId=null]
   * @param {Object} [options={ includeResolved: false }]
   * @returns {Array<Object>}
   */
  loadAlerts(patientId = null, { includeResolved = false } = {}) {
    try {
      const storage = getSafeStorage()
      const raw = storage.getItem(this.alertsKey)
      let alerts = []
      if (!raw) {
        alerts = [
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
        this.saveAllAlerts(alerts)
      } else {
        const parsed = JSON.parse(raw)
        alerts = Array.isArray(parsed) ? parsed : []
      }

      if (patientId) {
        alerts = alerts.filter(a => a.patientId === patientId)
      }
      if (!includeResolved) {
        alerts = alerts.filter(a => !a.resolved)
      }
      return alerts
    } catch {
      return []
    }
  }

  /**
   * Persists caregiver alerts to storage.
   *
   * @param {Array<Object>} alerts
   * @returns {boolean}
   */
  saveAllAlerts(alerts) {
    try {
      const storage = getSafeStorage()
      storage.setItem(this.alertsKey, JSON.stringify(alerts))
      if (typeof window !== 'undefined' && typeof window.dispatchEvent === 'function') {
        try {
          window.dispatchEvent(new CustomEvent('mindcare:alerts-updated', { detail: { alerts } }))
        } catch {}
      }
      return true
    } catch {
      return false
    }
  }

  /**
   * Saves a caregiver alert with deduplication protection.
   *
   * @param {Object} alertData
   * @param {Object} [options={ recordMutation: true }]
   * @returns {Object}
   */
  saveAlert(alertData, { recordMutation = true } = {}) {
    const alerts = this.loadAlerts(null, { includeResolved: true })

    // Deduplication check by occurrenceKey
    if (alertData.occurrenceKey) {
      const existing = alerts.find(a => a.occurrenceKey === alertData.occurrenceKey)
      if (existing) {
        return existing
      }
    }

    const newAlert = {
      id: alertData.id || `alert_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
      reminderId: alertData.reminderId || null,
      patientId: alertData.patientId || 'MC-2048',
      type: alertData.type || 'daily_routine',
      title: alertData.title || 'Reminder not acknowledged',
      message: alertData.message || 'The reminder was not acknowledged.',
      scheduledTime: alertData.scheduledTime || null,
      createdAt: alertData.createdAt || new Date().toISOString(),
      escalatedAt: alertData.escalatedAt || new Date().toISOString(),
      resolved: false,
      resolvedAt: null,
      occurrenceKey: alertData.occurrenceKey || null,
    }

    alerts.unshift(newAlert)
    this.saveAllAlerts(alerts)

    if (recordMutation) {
      this.enqueueMutation({
        entityId: newAlert.id,
        type: 'ALERT_CREATE',
        payload: newAlert,
      })
    }

    return newAlert
  }

  /**
   * Dismisses a caregiver alert locally.
   *
   * @param {string} alertId
   * @param {Object} [options={ recordMutation: true }]
   * @returns {boolean}
   */
  dismissAlert(alertId, { recordMutation = true } = {}) {
    const alerts = this.loadAlerts(null, { includeResolved: true })
    const index = alerts.findIndex(a => a.id === alertId)
    if (index === -1) return false

    alerts[index] = {
      ...alerts[index],
      resolved: true,
      resolvedAt: new Date().toISOString(),
    }

    this.saveAllAlerts(alerts)

    if (recordMutation) {
      this.enqueueMutation({
        entityId: alertId,
        type: 'ALERT_DISMISS',
        payload: { id: alertId, resolvedAt: alerts[index].resolvedAt },
      })
    }

    return true
  }

  /**
   * Resets all storage to initial demo state and clears mutation outbox.
   *
   * @returns {Array<Object>}
   */
  resetToMock() {
    const seeds = getInitialMockReminders()
    this.saveAll(seeds, { recordMutation: false })
    this.saveAllAlerts([
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
    ])
    this.clearOutbox()
    return seeds
  }
}

/**
 * Default global repository singleton instance.
 */
export const reminderRepository = new ReminderRepository()
