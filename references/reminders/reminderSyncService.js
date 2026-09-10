/**
 * src/reminders/reminderSyncService.js
 *
 * MindCare NER — Offline-First Reminder Synchronization Service
 *
 * ARCHITECTURAL RESPONSIBILITIES:
 * 1. Connectivity Detection: Monitors browser online/offline network lifecycle.
 * 2. Background Reconnection Sync: Automatically syncs queued outbox mutations
 *    when network connectivity is restored.
 * 3. Idempotent Deduplication: Merges incoming and outgoing reminders by unique ID
 *    and ISO modification timestamps to guarantee zero reminder duplication.
 * 4. Pluggable Remote Adapter: Clean extension point for future backend REST / GraphQL /
 *    WebSocket integration without needing to modify scheduling or UI layers.
 */

import { reminderRepository, ReminderRepository } from './reminderRepository.js'

export class ReminderSyncService {
  constructor({
    repository = reminderRepository,
    remoteAdapter = null,
  } = {}) {
    this.repository = repository
    this.remoteAdapter = remoteAdapter

    // Network connectivity tracking
    this.isOnline =
      typeof navigator !== 'undefined' && typeof navigator.onLine === 'boolean'
        ? navigator.onLine
        : true
    this.isSimulatedOffline = false
    this.isSyncing = false
    this.lastSyncedAt = null
    this.activeSyncPromise = null

    this.boundOnlineHandler = this.handleOnline.bind(this)
    this.boundOfflineHandler = this.handleOffline.bind(this)

    this.initNetworkListeners()
  }

  /**
   * Initializes browser network event listeners.
   */
  initNetworkListeners() {
    if (typeof window !== 'undefined') {
      window.addEventListener('online', this.boundOnlineHandler)
      window.addEventListener('offline', this.boundOfflineHandler)
    }
  }

  /**
   * Cleans up event listeners.
   */
  destroy() {
    if (typeof window !== 'undefined') {
      window.removeEventListener('online', this.boundOnlineHandler)
      window.removeEventListener('offline', this.boundOfflineHandler)
    }
  }

  /**
   * Returns whether the client is effectively online (factoring in simulation).
   * @returns {boolean}
   */
  getIsOnline() {
    if (this.isSimulatedOffline) return false
    return Boolean(this.isOnline)
  }

  /**
   * Toggles simulated offline mode for testing or demonstration.
   *
   * @param {boolean} simulatedOffline
   */
  setSimulatedOffline(simulatedOffline) {
    this.isSimulatedOffline = Boolean(simulatedOffline)
    if (this.isSimulatedOffline) {
      this.handleOffline()
    } else {
      this.handleOnline()
    }
  }

  /**
   * Handler invoked when browser reports connectivity is restored.
   */
  handleOnline() {
    this.isOnline = true
    this.broadcastConnectivity(true)

    // Automatically synchronize pending mutations when returning online
    this.syncPendingMutations().catch(() => {})
  }

  /**
   * Handler invoked when browser reports connectivity is lost.
   */
  handleOffline() {
    this.isOnline = false
    this.broadcastConnectivity(false)
  }

  /**
   * Broadcasts connectivity state changes across components and tabs.
   *
   * @param {boolean} isOnline
   */
  broadcastConnectivity(isOnline) {
    if (typeof window !== 'undefined' && typeof window.dispatchEvent === 'function') {
      try {
        window.dispatchEvent(new CustomEvent('mindcare:connectivity-changed', {
          detail: { isOnline: this.getIsOnline() },
        }))
        window.dispatchEvent(new CustomEvent('mindcare:sync-status-changed', {
          detail: this.getSyncStatus(),
        }))
      } catch {}
    }
  }

  /**
   * Returns snapshot telemetry of the synchronization layer.
   *
   * @returns {{
   *   isOnline: boolean,
   *   isSyncing: boolean,
   *   pendingCount: number,
   *   lastSyncedAt: string|null
   * }}
   */
  getSyncStatus() {
    return {
      isOnline: this.getIsOnline(),
      isSyncing: this.isSyncing,
      pendingCount: this.repository.getOutbox().length,
      lastSyncedAt: this.lastSyncedAt,
    }
  }

  /**
   * Merges a remote list of reminders with local list without creating duplicates.
   *
   * @param {Array<Object>} localList
   * @param {Array<Object>} remoteList
   * @returns {Array<Object>}
   */
  mergeRemindersWithoutDuplicates(localList = [], remoteList = []) {
    const map = new Map()

    for (const rem of localList) {
      if (rem && rem.id) {
        map.set(rem.id, { ...rem })
      }
    }

    for (const rem of remoteList) {
      if (!rem || !rem.id) continue

      if (!map.has(rem.id)) {
        map.set(rem.id, { ...rem })
      } else {
        const existing = map.get(rem.id)
        const existingTime = new Date(existing.lastModifiedAt || existing.updatedAt || existing.createdAt || 0).getTime()
        const remoteTime = new Date(rem.lastModifiedAt || rem.updatedAt || rem.createdAt || 0).getTime()

        if (remoteTime > existingTime) {
          map.set(rem.id, { ...existing, ...rem })
        }
      }
    }

    return Array.from(map.values())
  }

  /**
   * Registers a pluggable remote sync adapter.
   *
   * @param {{ pushMutations?: Function, fetchReminders?: Function }|null} adapter
   */
  setRemoteSyncAdapter(adapter) {
    this.remoteAdapter = adapter
  }

  /**
   * Synchronizes all queued mutations.
   * Shares ongoing sync promise if a sync is already executing.
   *
   * @returns {Promise<{ success: boolean, syncedCount: number, pendingCount: number, lastSyncedAt: string|null, reason?: string }>}
   */
  async syncPendingMutations() {
    if (this.activeSyncPromise) {
      return this.activeSyncPromise
    }

    this.activeSyncPromise = this._executeSync()
    try {
      return await this.activeSyncPromise
    } finally {
      this.activeSyncPromise = null
    }
  }

  /**
   * Internal execution of the mutation sync workflow.
   *
   * @private
   * @returns {Promise<{ success: boolean, syncedCount: number, pendingCount: number, lastSyncedAt: string|null, reason?: string }>}
   */
  async _executeSync() {
    if (!this.getIsOnline()) {
      return {
        success: false,
        reason: 'offline',
        syncedCount: 0,
        pendingCount: this.repository.getOutbox().length,
        lastSyncedAt: this.lastSyncedAt,
      }
    }

    const pending = this.repository.getOutbox()
    if (pending.length === 0) {
      return {
        success: true,
        syncedCount: 0,
        pendingCount: 0,
        lastSyncedAt: this.lastSyncedAt,
      }
    }

    this.isSyncing = true
    this.broadcastSyncStatus()

    try {
      if (this.remoteAdapter && typeof this.remoteAdapter.pushMutations === 'function') {
        // Dispatch to real remote backend
        await this.remoteAdapter.pushMutations(pending)
      }

      // In prototype mode / upon adapter success, flush the outbox
      const syncedIds = pending.map(m => m.id)
      this.repository.clearOutbox(syncedIds)

      this.lastSyncedAt = new Date().toISOString()
      this.isSyncing = false

      this.broadcastSyncStatus()

      if (typeof window !== 'undefined' && typeof window.dispatchEvent === 'function') {
        try {
          window.dispatchEvent(new CustomEvent('mindcare:sync-completed', {
            detail: {
              syncedCount: syncedIds.length,
              timestamp: this.lastSyncedAt,
            },
          }))
        } catch {}
      }

      return {
        success: true,
        syncedCount: syncedIds.length,
        pendingCount: 0,
        lastSyncedAt: this.lastSyncedAt,
      }
    } catch (err) {
      this.isSyncing = false
      this.broadcastSyncStatus()
      return {
        success: false,
        reason: err?.message || 'sync_failed',
        syncedCount: 0,
        pendingCount: this.repository.getOutbox().length,
        lastSyncedAt: this.lastSyncedAt,
      }
    }
  }

  /**
   * Broadcasts current sync status to all listening components.
   */
  broadcastSyncStatus() {
    if (typeof window !== 'undefined' && typeof window.dispatchEvent === 'function') {
      try {
        window.dispatchEvent(new CustomEvent('mindcare:sync-status-changed', {
          detail: this.getSyncStatus(),
        }))
      } catch {}
    }
  }
}

/**
 * Default global sync service singleton instance.
 */
export const reminderSyncService = new ReminderSyncService({
  repository: reminderRepository,
})
