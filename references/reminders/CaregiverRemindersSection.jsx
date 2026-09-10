/**
 * src/reminders/CaregiverRemindersSection.jsx
 *
 * MindCare NER — Smart Reminders Section for Caregiver Dashboard
 *
 * Displays today's scheduled patient reminders with clear time indicators,
 * category badges, repeat info, status chips, and enable/disable toggles.
 *
 * Features:
 * - Prominent, accessible [ + Add Reminder ] button opening ReminderModal
 * - Inline Enable/Disable toggle switches
 * - Edit and Delete actions (with accessible confirmation)
 * - Immediate optimistic state update upon saving
 * - Fully accessible, tablet-friendly, high-contrast, keyboard-navigable
 */

import { useState, useEffect, useMemo, useCallback } from 'react'
import {
  Plus, Edit3, Trash2, Pill, Droplets, CalendarDays, Gamepad2, Clock3,
  CheckCircle2, Clock, AlertTriangle, Timer, BellOff, Volume2, RotateCcw, Settings2,
  Wifi, WifiOff, RefreshCw
} from 'lucide-react'
import {
  REMINDER_TYPES,
  REMINDER_STATUS,
} from './reminderTypes.js'
import {
  loadAllReminders,
  saveReminder,
  deleteReminder,
  toggleReminderEnabledById,
  resetRemindersToMock,
  loadCaregiverAlerts,
  dismissCaregiverAlert,
  getMaxRetries,
  setMaxRetries,
  getRetryIntervalMinutes,
  setRetryIntervalMinutes,
  getSyncStatus,
  syncPendingMutations,
} from './reminderService.js'
import { isReminderForDate } from './reminderModel.js'
import { ReminderModal } from './ReminderModal.jsx'
import { useTranslation } from '../i18n'

/**
 * Formats an ISO date string into friendly 12-hour time: "09:00 AM"
 */
function formatDisplayTime(isoString) {
  if (!isoString) return '--:--'
  try {
    const d = new Date(isoString)
    if (Number.isNaN(d.getTime())) return '--:--'
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true })
  } catch {
    return '--:--'
  }
}

/**
 * Returns repeat description label
 */
function formatRepeatLabel(repeat) {
  switch (repeat) {
    case 'daily':
      return 'Every day'
    case 'weekdays':
      return 'Weekdays'
    case 'weekends':
      return 'Weekends'
    case 'weekly':
      return 'Weekly'
    case 'custom':
      return 'Custom'
    case 'none':
    default:
      return 'Once'
  }
}

export function CaregiverRemindersSection({ patientId = 'MC-2048' }) {
  const { t } = useTranslation()
  // Reminders and Escalation Alerts state
  const [reminders, setReminders] = useState(() => loadAllReminders())
  const [alerts, setAlerts] = useState(() => loadCaregiverAlerts(patientId))
  const [syncStatus, setSyncStatus] = useState(() => getSyncStatus())
  const [modalOpen, setModalOpen] = useState(false)
  const [configOpen, setConfigOpen] = useState(false)
  const [configRetries, setConfigRetries] = useState(() => getMaxRetries())
  const [configInterval, setConfigInterval] = useState(() => getRetryIntervalMinutes())
  const [editingReminder, setEditingReminder] = useState(null)
  const [deleteConfirmId, setDeleteConfirmId] = useState(null)
  const [feedbackMessage, setFeedbackMessage] = useState('')

  // Reload helper for reminders, alerts, and sync status
  const reload = useCallback(() => {
    const all = loadAllReminders()
    setReminders(all)
    setAlerts(loadCaregiverAlerts(patientId))
    setSyncStatus(getSyncStatus())
  }, [patientId])

  // Synchronize automatically when reminders, escalation alerts, or network state changes
  useEffect(() => {
    function handleSync() {
      reload()
    }
    function handleSyncTelemetry() {
      setSyncStatus(getSyncStatus())
    }

    if (typeof window !== 'undefined') {
      window.addEventListener('storage', handleSync)
      window.addEventListener('mindcare:reminders-updated', handleSync)
      window.addEventListener('mindcare:alerts-updated', handleSync)
      window.addEventListener('mindcare:outbox-updated', handleSyncTelemetry)
      window.addEventListener('mindcare:connectivity-changed', handleSyncTelemetry)
      window.addEventListener('mindcare:sync-status-changed', handleSyncTelemetry)
      window.addEventListener('mindcare:sync-completed', handleSync)
      window.addEventListener('online', handleSyncTelemetry)
      window.addEventListener('offline', handleSyncTelemetry)
    }
    return () => {
      if (typeof window !== 'undefined') {
        window.removeEventListener('storage', handleSync)
        window.removeEventListener('mindcare:reminders-updated', handleSync)
        window.removeEventListener('mindcare:alerts-updated', handleSync)
        window.removeEventListener('mindcare:outbox-updated', handleSyncTelemetry)
        window.removeEventListener('mindcare:connectivity-changed', handleSyncTelemetry)
        window.removeEventListener('mindcare:sync-status-changed', handleSyncTelemetry)
        window.removeEventListener('mindcare:sync-completed', handleSync)
        window.removeEventListener('online', handleSyncTelemetry)
        window.removeEventListener('offline', handleSyncTelemetry)
      }
    }
  }, [reload])

  // Show transient announcement
  const notify = (msg) => {
    setFeedbackMessage(msg)
    setTimeout(() => {
      setFeedbackMessage('')
    }, 4000)
  }

  // Filter reminders for today and for this patient
  const todayReminders = useMemo(() => {
    const today = new Date()
    const patientList = reminders.filter(r => r.patientId === patientId)
    const list = patientList.filter(r => isReminderForDate(r, today))

    // Sort by scheduled time ascending
    return list.sort((a, b) => new Date(a.scheduledTime) - new Date(b.scheduledTime))
  }, [reminders, patientId])

  // Summary counts for quick caregiver daily overview
  const stats = useMemo(() => {
    const total = todayReminders.length
    const acknowledged = todayReminders.filter(r => r.status === REMINDER_STATUS.ACKNOWLEDGED).length
    const notAcknowledged = todayReminders.filter(
      r => r.status === REMINDER_STATUS.NOT_ACKNOWLEDGED || r.status === 'not_acknowledged' || r.status === 'missed'
    ).length
    const upcoming = todayReminders.filter(
      r => r.status === REMINDER_STATUS.UPCOMING ||
           r.status === REMINDER_STATUS.DUE ||
           r.status === REMINDER_STATUS.SNOOZED ||
           r.status === 'pending' ||
           r.status === 'delivered'
    ).length
    return { total, acknowledged, upcoming, notAcknowledged }
  }, [todayReminders])

  // Handlers
  function handleOpenAdd() {
    setEditingReminder(null)
    setModalOpen(true)
  }

  function handleOpenEdit(reminder) {
    setEditingReminder(reminder)
    setModalOpen(true)
  }

  function handleCloseModal() {
    setModalOpen(false)
    setEditingReminder(null)
  }

  function handleSaveReminder(payload) {
    const saved = saveReminder(payload)
    reload()
    handleCloseModal()
    notify(`Reminder "${saved.title}" saved successfully.`)
  }

  function handleToggleEnabled(reminder) {
    const updated = toggleReminderEnabledById(reminder.id)
    if (updated) {
      reload()
      notify(`Reminder "${reminder.title}" ${updated.enabled ? 'enabled' : 'disabled'}.`)
    }
  }

  function handleDeleteClick(id) {
    setDeleteConfirmId(id)
  }

  function handleConfirmDelete(id) {
    const target = reminders.find(r => r.id === id)
    const success = deleteReminder(id)
    if (success) {
      reload()
      notify(`Reminder "${target?.title || 'item'}" deleted.`)
    }
    setDeleteConfirmId(null)
  }

  function handleCancelDelete() {
    setDeleteConfirmId(null)
  }

  function handleResetSeeds() {
    resetRemindersToMock()
    reload()
    notify('Sample prototype reminders reset to default.')
  }

  function handleDismissAlert(alertId) {
    const success = dismissCaregiverAlert(alertId)
    if (success) {
      reload()
      notify('Reminder alert dismissed.')
    }
  }

  function handleSaveConfig(e) {
    e.preventDefault()
    setMaxRetries(Number(configRetries))
    setRetryIntervalMinutes(Number(configInterval))
    setConfigOpen(false)
    notify(`Escalation settings updated: ${configRetries} retries every ${configInterval} mins.`)
  }

  // Category Icon & Label
  const getCategoryPresentation = (type) => {
    switch (type) {
      case REMINDER_TYPES.MEDICATION:
        return {
          icon: <Pill size={16} aria-hidden="true" />,
          label: 'Medication',
          emoji: '💊',
          badgeClass: 'cat-medication',
        }
      case REMINDER_TYPES.HYDRATION:
        return {
          icon: <Droplets size={16} aria-hidden="true" />,
          label: 'Hydration',
          emoji: '💧',
          badgeClass: 'cat-hydration',
        }
      case REMINDER_TYPES.COGNITIVE_ACTIVITY:
        return {
          icon: <Gamepad2 size={16} aria-hidden="true" />,
          label: 'Cognitive Activity',
          emoji: '🧠',
          badgeClass: 'cat-cognitive',
        }
      case REMINDER_TYPES.APPOINTMENT:
        return {
          icon: <CalendarDays size={16} aria-hidden="true" />,
          label: 'Appointment',
          emoji: '📅',
          badgeClass: 'cat-appointment',
        }
      case REMINDER_TYPES.DAILY_ROUTINE:
      default:
        return {
          icon: <Clock3 size={16} aria-hidden="true" />,
          label: 'Daily Routine',
          emoji: '⏰',
          badgeClass: 'cat-routine',
        }
    }
  }

  // Status Badge Presentation for Daily Overview
  const getStatusPresentation = (reminder) => {
    if (!reminder.enabled) {
      return {
        text: 'Disabled',
        icon: <BellOff size={14} aria-hidden="true" />,
        className: 'status-disabled',
      }
    }

    const status = reminder.status

    switch (status) {
      case REMINDER_STATUS.ACKNOWLEDGED: {
        const ackTime = reminder.acknowledgedTime || reminder.acknowledgedAt
        const formatted = ackTime ? formatDisplayTime(ackTime) : null
        return {
          text: formatted ? `Acknowledged at ${formatted}` : 'Acknowledged',
          icon: <CheckCircle2 size={14} aria-hidden="true" />,
          className: 'status-acknowledged',
        }
      }
      case REMINDER_STATUS.NOT_ACKNOWLEDGED:
      case 'missed':
        return {
          text: 'Not acknowledged',
          icon: <AlertTriangle size={14} aria-hidden="true" />,
          className: 'status-not-acknowledged',
        }
      case REMINDER_STATUS.SNOOZED:
        return {
          text: 'Snoozed',
          icon: <Timer size={14} aria-hidden="true" />,
          className: 'status-snoozed',
        }
      case REMINDER_STATUS.DUE:
      case 'delivered':
        return {
          text: 'Due',
          icon: <Clock size={14} aria-hidden="true" />,
          className: 'status-due',
        }
      case REMINDER_STATUS.UPCOMING:
      case 'pending':
      default:
        return {
          text: 'Upcoming',
          icon: <span className="status-dot-icon" aria-hidden="true">○</span>,
          className: 'status-upcoming',
        }
    }
  }

  return (
    <section
      className="dash-card smart-reminders-card"
      aria-labelledby="smart-reminders-title"
    >
      {/* ── Section Header ───────────────────────────────────────── */}
      <div className="reminders-header-bar">
        <div>
          <p className="dash-kicker">{t('reminders.kicker') || 'SMART REMINDERS'}</p>
          <h2 id="smart-reminders-title" className="reminders-main-title">
            {t('reminders.title') || 'Smart Reminders'}
          </h2>
          <p className="reminders-subtitle">
            {t('reminders.subtitle') || "Manage helpful reminders for your patient's daily routine."}
          </p>
        </div>

        <div className="reminders-header-actions">
          {/* Configure Escalation Rules */}
          <button
            type="button"
            className="btn-escalation-config"
            onClick={() => setConfigOpen(true)}
            title={t('reminders.escalationRules') || "Configure gentle retry count and escalation interval"}
            aria-haspopup="dialog"
          >
            <Settings2 size={16} aria-hidden="true" />
            <span>{t('reminders.escalationRules') || 'Escalation Rules'}</span>
          </button>

          {/* Manual Sync Trigger (when pending changes exist) */}
          {syncStatus.pendingCount > 0 && syncStatus.isOnline && (
            <button
              type="button"
              className="btn-sync-now"
              onClick={() => {
                syncPendingMutations()
                notify('Synchronizing offline changes...')
              }}
              title="Synchronize offline changes with backend"
            >
              <RefreshCw size={14} className={syncStatus.isSyncing ? 'spin-icon' : ''} aria-hidden="true" />
              <span>Sync ({syncStatus.pendingCount})</span>
            </button>
          )}

          {/* Prominent Accessible Add Reminder Button */}
          <button
            type="button"
            className="btn-add-reminder"
            onClick={handleOpenAdd}
            aria-haspopup="dialog"
          >
            <Plus size={18} aria-hidden="true" />
            <span>+ {t('reminders.addReminder') || 'Add Reminder'}</span>
          </button>
        </div>
      </div>

      {/* ── Caregiver Escalation Alert Panel ───────────────────────── */}
      {alerts.length > 0 && (
        <div className="caregiver-alerts-panel" role="region" aria-label="Caregiver Escalation Alerts">
          <div className="caregiver-alerts-header">
            <div className="alerts-header-title-wrap">
              <AlertTriangle size={18} className="alert-header-icon" aria-hidden="true" />
              <h3 className="caregiver-alerts-title">⚠ Reminder not acknowledged</h3>
            </div>
            <span className="alerts-count-badge">
              {alerts.length} {alerts.length === 1 ? 'alert' : 'alerts'}
            </span>
          </div>

          <div className="caregiver-alerts-list" role="list">
            {alerts.map(alert => (
              <div key={alert.id} className="caregiver-alert-item" role="listitem">
                <div className="caregiver-alert-content">
                  <p className="caregiver-alert-message">"{alert.message}"</p>
                  <span className="caregiver-alert-time">
                    Recorded at {formatDisplayTime(alert.createdAt || alert.escalatedAt)}
                  </span>
                </div>
                <button
                  type="button"
                  className="btn-dismiss-alert"
                  onClick={() => handleDismissAlert(alert.id)}
                  aria-label={`Dismiss alert: ${alert.message}`}
                >
                  Dismiss
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ── Caregiver Quick Summary Counters ──────────────────────── */}
      <div className="reminders-summary-bar" aria-label="Today's reminders summary">
        {/* Offline-First Connectivity & Sync Indicator */}
        {syncStatus.isOnline ? (
          <div
            className={`summary-pill sync-pill ${syncStatus.pendingCount > 0 ? 'sync-pending' : 'sync-online'}`}
            title={syncStatus.pendingCount > 0 ? `${syncStatus.pendingCount} offline changes pending sync` : 'Connected and synchronized'}
          >
            <Wifi size={13} aria-hidden="true" />
            <span>
              {syncStatus.pendingCount > 0 ? `Syncing (${syncStatus.pendingCount})` : 'Online · Synced'}
            </span>
          </div>
        ) : (
          <div
            className="summary-pill sync-pill sync-offline"
            title="Internet unavailable. Reminders continue working 100% locally on device."
          >
            <WifiOff size={13} aria-hidden="true" />
            <span>Offline Mode · Active Locally</span>
          </div>
        )}

        <div className="summary-pill">
          <span>Today's Total:</span>
          <strong>{stats.total}</strong>
        </div>
        <div className="summary-pill summary-acknowledged">
          <span>✓ Acknowledged:</span>
          <strong>{stats.acknowledged}</strong>
        </div>
        <div className="summary-pill summary-upcoming">
          <span>○ Upcoming:</span>
          <strong>{stats.upcoming}</strong>
        </div>
        {stats.notAcknowledged > 0 && (
          <div className="summary-pill summary-not-acknowledged">
            <span>⚠ Not acknowledged:</span>
            <strong>{stats.notAcknowledged}</strong>
          </div>
        )}
        {feedbackMessage && (
          <div className="reminders-toast" role="status" aria-live="polite">
            {feedbackMessage}
          </div>
        )}
      </div>

      {/* ── Reminders List ───────────────────────────────────────── */}
      {todayReminders.length === 0 ? (
        <div className="reminders-empty-state">
          <Clock3 size={36} className="empty-icon" aria-hidden="true" />
          <h3>No reminders scheduled for today</h3>
          <p>Create scheduled prompts to gently guide your patient throughout the day.</p>
          <div className="empty-actions">
            <button
              type="button"
              className="btn-add-reminder"
              onClick={handleOpenAdd}
            >
              <Plus size={18} aria-hidden="true" />
              <span>+ Add First Reminder</span>
            </button>
            <button
              type="button"
              className="btn-reset-seeds"
              onClick={handleResetSeeds}
              title="Restore demo mock reminders"
            >
              <RotateCcw size={15} aria-hidden="true" />
              <span>Reset Samples</span>
            </button>
          </div>
        </div>
      ) : (
        <div className="reminders-list" role="list">
          {todayReminders.map(reminder => {
            const cat = getCategoryPresentation(reminder.type)
            const statusInfo = getStatusPresentation(reminder)
            const isDeleting = deleteConfirmId === reminder.id

            return (
              <article
                key={reminder.id}
                role="listitem"
                className={`reminder-item ${!reminder.enabled ? 'is-disabled' : ''}`}
                aria-label={`${reminder.title}, scheduled for ${formatDisplayTime(reminder.scheduledTime)}, status ${statusInfo.text}`}
              >
                {/* 1. Time Column */}
                <div className="reminder-time-col">
                  <span className="reminder-time-text">
                    {formatDisplayTime(reminder.scheduledTime)}
                  </span>
                  <span className="reminder-repeat-badge">
                    {formatRepeatLabel(reminder.repeat)}
                  </span>
                </div>

                {/* 2. Main Content Column */}
                <div className="reminder-main-col">
                  <div className="reminder-title-line">
                    <span className={`reminder-cat-badge ${cat.badgeClass}`}>
                      <span aria-hidden="true">{cat.emoji}</span>
                      <span>{cat.label}</span>
                    </span>
                    {reminder.voiceEnabled && (
                      <span className="reminder-voice-badge" title="Voice assistance prompt enabled">
                        <Volume2 size={13} aria-hidden="true" />
                        <span>Voice</span>
                      </span>
                    )}
                  </div>

                  <h3 className="reminder-item-title">{reminder.title}</h3>

                  {reminder.message && (
                    <p className="reminder-item-message">{reminder.message}</p>
                  )}

                  {/* Occurrence tracking metadata (attempts, triggered time, snoozed state) */}
                  {(reminder.attempts > 0 || reminder.triggeredTime || reminder.snoozed) && (
                    <div className="reminder-occurrence-meta">
                      {reminder.triggeredTime && (
                        <span className="occurrence-meta-tag">
                          Triggered: {formatDisplayTime(reminder.triggeredTime)}
                        </span>
                      )}
                      {reminder.attempts > 0 && (
                        <span className="occurrence-meta-tag">
                          Attempts: {reminder.attempts}
                        </span>
                      )}
                      {reminder.snoozed && (
                        <span className="occurrence-meta-tag occurrence-snooze-tag">
                          Snoozed
                        </span>
                      )}
                    </div>
                  )}
                </div>

                {/* 3. Status Column */}
                <div className="reminder-status-col">
                  <span className={`reminder-status-badge ${statusInfo.className}`}>
                    {statusInfo.icon}
                    <span>{statusInfo.text}</span>
                  </span>
                </div>

                {/* 4. Controls & Actions Column */}
                <div className="reminder-actions-col">
                  {/* Enable / Disable Switch */}
                  <div className="reminder-toggle-wrap">
                    <button
                      type="button"
                      role="switch"
                      aria-checked={reminder.enabled}
                      className={`reminder-mini-switch ${reminder.enabled ? 'is-on' : 'is-off'}`}
                      onClick={() => handleToggleEnabled(reminder)}
                      aria-label={`${reminder.enabled ? 'Disable' : 'Enable'} ${reminder.title}`}
                      title={reminder.enabled ? 'Click to disable' : 'Click to enable'}
                    >
                      <span className="reminder-mini-switch-handle" />
                    </button>
                    <span className="reminder-toggle-label">
                      {reminder.enabled ? 'Active' : 'Paused'}
                    </span>
                  </div>

                  {/* Edit Action Button */}
                  <button
                    type="button"
                    className="reminder-action-btn btn-edit"
                    onClick={() => handleOpenEdit(reminder)}
                    aria-label={`Edit reminder: ${reminder.title}`}
                    title="Edit reminder"
                  >
                    <Edit3 size={16} aria-hidden="true" />
                    <span>Edit</span>
                  </button>

                  {/* Delete Action Button / Confirm */}
                  {isDeleting ? (
                    <div className="reminder-delete-confirm-box" role="alert">
                      <span className="delete-confirm-text">Delete?</span>
                      <button
                        type="button"
                        className="btn-confirm-yes"
                        onClick={() => handleConfirmDelete(reminder.id)}
                        aria-label="Confirm delete"
                      >
                        Yes
                      </button>
                      <button
                        type="button"
                        className="btn-confirm-no"
                        onClick={handleCancelDelete}
                        aria-label="Cancel delete"
                      >
                        No
                      </button>
                    </div>
                  ) : (
                    <button
                      type="button"
                      className="reminder-action-btn btn-delete"
                      onClick={() => handleDeleteClick(reminder.id)}
                      aria-label={`Delete reminder: ${reminder.title}`}
                      title="Delete reminder"
                    >
                      <Trash2 size={16} aria-hidden="true" />
                      <span>Delete</span>
                    </button>
                  )}
                </div>
              </article>
            )
          })}
        </div>
      )}

      {/* ── Add / Edit Modal Dialog ───────────────────────────────── */}
      <ReminderModal
        isOpen={modalOpen}
        onClose={handleCloseModal}
        onSave={handleSaveReminder}
        initialReminder={editingReminder}
        patientId={patientId}
      />

      {/* ── Escalation Rules Modal Dialog ─────────────────────────── */}
      {configOpen && (
        <div className="reminder-modal-backdrop" role="presentation" onClick={() => setConfigOpen(false)}>
          <div
            className="reminder-modal escalation-config-modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="config-modal-title"
            onClick={e => e.stopPropagation()}
          >
            <div className="reminder-modal-header">
              <div className="modal-title-wrap">
                <span className="modal-kicker">CONFIGURATION</span>
                <h2 id="config-modal-title" className="reminder-modal-title">
                  Escalation & Retry Rules
                </h2>
              </div>
              <button
                type="button"
                className="btn-modal-close"
                onClick={() => setConfigOpen(false)}
                aria-label="Close settings"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSaveConfig} className="reminder-form">
              <div className="form-group">
                <label htmlFor="config-retries" className="form-label">
                  Gentle Retries before Caregiver Alert
                </label>
                <select
                  id="config-retries"
                  className="form-select"
                  value={configRetries}
                  onChange={e => setConfigRetries(Number(e.target.value))}
                >
                  <option value={1}>1 retry (prompt twice total)</option>
                  <option value={2}>2 retries (recommended standard)</option>
                  <option value={3}>3 retries</option>
                  <option value={5}>5 retries</option>
                </select>
                <span className="form-hint">
                  Patient receives gentle non-intrusive re-prompts before escalating to caregiver.
                </span>
              </div>

              <div className="form-group">
                <label htmlFor="config-interval" className="form-label">
                  Retry Interval (minutes)
                </label>
                <select
                  id="config-interval"
                  className="form-select"
                  value={configInterval}
                  onChange={e => setConfigInterval(Number(e.target.value))}
                >
                  <option value={5}>5 minutes</option>
                  <option value={10}>10 minutes (recommended)</option>
                  <option value={15}>15 minutes</option>
                  <option value={20}>20 minutes</option>
                  <option value={30}>30 minutes</option>
                </select>
                <span className="form-hint">
                  Delay between consecutive gentle reminder attempts.
                </span>
              </div>

              <div className="escalation-policy-note" role="note">
                <AlertTriangle size={16} className="escalation-policy-icon" aria-hidden="true" />
                <p>
                  <strong>Non-Clinical Safeguard:</strong> MindCare NER only records whether device interaction occurred. It never makes medical inferences or diagnosis conclusions.
                </p>
              </div>

              <div className="modal-actions">
                <button
                  type="button"
                  className="btn-modal-cancel"
                  onClick={() => setConfigOpen(false)}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-modal-save"
                >
                  Save Rules
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </section>
  )
}
