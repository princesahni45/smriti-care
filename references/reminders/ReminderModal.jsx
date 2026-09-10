/**
 * src/reminders/ReminderModal.jsx
 *
 * MindCare NER — Add / Edit Reminder Modal Dialog
 *
 * Accessible, keyboard-navigable, high-contrast modal dialog for creating
 * and editing Smart Reminders for patients.
 *
 * POLICY:
 * Does NOT allow caregivers to enter medication dosage instructions (enforced
 * via dosageGuard.js with friendly warning).
 */

import { useState, useEffect, useRef } from 'react'
import {
  X, Pill, Droplets, CalendarDays, Gamepad2, Clock3,
  AlertCircle, Sparkles, Volume2, BellRing
} from 'lucide-react'
import {
  REMINDER_TYPES,
  REMINDER_TYPE_CONFIG,
  REMINDER_REPEAT,
  REMINDER_STATUS,
} from './reminderTypes.js'
import { checkDosageSafety } from './dosageGuard.js'
import { getVoiceReminderMessage } from './voiceReminderService.js'

// Map repeat option values to friendly user-facing labels
const REPEAT_OPTIONS = [
  { value: 'none', label: 'Once', description: 'One-time reminder today' },
  { value: 'daily', label: 'Every day', description: 'Repeats daily at scheduled time' },
  { value: 'weekdays', label: 'Weekdays', description: 'Monday to Friday only' },
  { value: 'custom', label: 'Custom', description: 'Custom scheduled routine' },
]

export function ReminderModal({
  isOpen,
  onClose,
  onSave,
  initialReminder = null,
  patientId = 'MC-2048',
}) {
  const isEdit = Boolean(initialReminder?.id)

  // Form State
  const [type, setType] = useState(initialReminder?.type || REMINDER_TYPES.MEDICATION)
  const [title, setTitle] = useState(initialReminder?.title || '')
  const [message, setMessage] = useState(initialReminder?.message || '')

  // Time extraction (HH:MM format for <input type="time">)
  const [time, setTime] = useState(() => {
    if (initialReminder?.scheduledTime) {
      const d = new Date(initialReminder.scheduledTime)
      if (!Number.isNaN(d.getTime())) {
        const hh = String(d.getHours()).padStart(2, '0')
        const mm = String(d.getMinutes()).padStart(2, '0')
        return `${hh}:${mm}`
      }
    }
    // Default to 09:00 AM
    return '09:00'
  })

  // Repeat Cadence (maps to reminderTypes constants)
  const [repeat, setRepeat] = useState(() => {
    if (initialReminder?.repeat === REMINDER_REPEAT.DAILY) return 'daily'
    if (initialReminder?.repeat === REMINDER_REPEAT.WEEKDAYS) return 'weekdays'
    if (initialReminder?.repeat === REMINDER_REPEAT.CUSTOM) return 'custom'
    return 'daily'
  })

  // Voice Reminder (ON/OFF)
  const [voiceEnabled, setVoiceEnabled] = useState(initialReminder?.voiceEnabled ?? true)

  // Enable Reminder (ON/OFF)
  const [enabled, setEnabled] = useState(initialReminder?.enabled ?? true)

  // Validation Error State
  const [errors, setErrors] = useState({})
  const [generalError, setGeneralError] = useState('')

  const modalRef = useRef(null)
  const firstInputRef = useRef(null)

  // Reset or initialize state when opening / switching reminder
  useEffect(() => {
    if (isOpen) {
      if (initialReminder) {
        setType(initialReminder.type || REMINDER_TYPES.MEDICATION)
        setTitle(initialReminder.title || '')
        setMessage(initialReminder.message || '')
        setRepeat(
          initialReminder.repeat === REMINDER_REPEAT.WEEKDAYS
            ? 'weekdays'
            : initialReminder.repeat === REMINDER_REPEAT.CUSTOM
              ? 'custom'
              : initialReminder.repeat === REMINDER_REPEAT.NONE
                ? 'none'
                : 'daily'
        )
        setVoiceEnabled(initialReminder.voiceEnabled ?? true)
        setEnabled(initialReminder.enabled ?? true)

        if (initialReminder.scheduledTime) {
          const d = new Date(initialReminder.scheduledTime)
          if (!Number.isNaN(d.getTime())) {
            setTime(`${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`)
          }
        }
      } else {
        // Safe default initial form
        setType(REMINDER_TYPES.MEDICATION)
        setTitle('')
        setMessage('')
        setTime('09:00')
        setRepeat('daily')
        setVoiceEnabled(true)
        setEnabled(true)
      }
      setErrors({})
      setGeneralError('')

      // Focus first input on mount
      setTimeout(() => {
        firstInputRef.current?.focus()
      }, 50)
    }
  }, [isOpen, initialReminder])

  // Close on Escape key
  useEffect(() => {
    function handleKeyDown(e) {
      if (!isOpen) return
      if (e.key === 'Escape') {
        e.preventDefault()
        onClose()
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [isOpen, onClose])

  if (!isOpen) return null

  // Type Icon helper
  const getCategoryIcon = (catType) => {
    switch (catType) {
      case REMINDER_TYPES.MEDICATION:
        return <Pill size={18} aria-hidden="true" />
      case REMINDER_TYPES.HYDRATION:
        return <Droplets size={18} aria-hidden="true" />
      case REMINDER_TYPES.APPOINTMENT:
        return <CalendarDays size={18} aria-hidden="true" />
      case REMINDER_TYPES.COGNITIVE_ACTIVITY:
        return <Gamepad2 size={18} aria-hidden="true" />
      case REMINDER_TYPES.DAILY_ROUTINE:
      default:
        return <Clock3 size={18} aria-hidden="true" />
    }
  }

  // Pre-fill helpful template message when type changes (if message is empty or defaulted)
  function handleTypeChange(nextType) {
    setType(nextType)
    if (!title || title === 'Morning Medicine' || title === 'Drink Water' || title === 'Doctor Appointment' || title === 'Brain Activity' || title === 'Daily Routine') {
      switch (nextType) {
        case REMINDER_TYPES.MEDICATION:
          setTitle('Morning Medicine')
          setMessage("It's time for your scheduled medicine.")
          break
        case REMINDER_TYPES.HYDRATION:
          setTitle('Time for Water')
          setMessage('Please drink a fresh glass of water.')
          break
        case REMINDER_TYPES.APPOINTMENT:
          setTitle('Doctor Appointment')
          setMessage('Upcoming consultation at the clinic.')
          break
        case REMINDER_TYPES.COGNITIVE_ACTIVITY:
          setTitle('Brain Activity')
          setMessage('Time for a gentle cognitive exercise.')
          break
        case REMINDER_TYPES.DAILY_ROUTINE:
          setTitle('Daily Routine')
          setMessage('Time for your gentle routine walk.')
          break
        default:
          break
      }
    }
  }

  // Form Validation & Submission
  function handleSubmit(e) {
    e.preventDefault()
    const newErrors = {}

    // 1. Title validation
    const cleanTitle = title.trim()
    if (!cleanTitle) {
      newErrors.title = 'Title is required. Please enter a brief name for this reminder.'
    } else {
      // Dosage guard on title
      const dosageCheck = checkDosageSafety(cleanTitle)
      if (dosageCheck.hasDosage) {
        newErrors.title = dosageCheck.message
      }
    }

    // 2. Message validation
    const cleanMessage = message.trim()
    if (!cleanMessage) {
      newErrors.message = 'Message is required. Please provide a gentle note for the patient.'
    } else {
      // Dosage guard on message
      const dosageCheck = checkDosageSafety(cleanMessage)
      if (dosageCheck.hasDosage) {
        newErrors.message = dosageCheck.message
      }
    }

    // 3. Time validation
    if (!time || !time.includes(':')) {
      newErrors.time = 'A valid time is required.'
    } else {
      const [hStr, mStr] = time.split(':')
      const h = parseInt(hStr, 10)
      const m = parseInt(mStr, 10)
      if (Number.isNaN(h) || Number.isNaN(m) || h < 0 || h > 23 || m < 0 || m > 59) {
        newErrors.time = 'Please enter a valid time (HH:MM).'
      }
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors)
      setGeneralError('Please fix the highlighted errors before saving.')
      return
    }

    // Construct scheduled ISO string for today at the chosen time
    const [hours, minutes] = time.split(':').map(Number)
    const scheduledDate = new Date()
    scheduledDate.setHours(hours, minutes, 0, 0)

    const reminderPayload = {
      ...(initialReminder?.id ? { id: initialReminder.id } : {}),
      patientId: initialReminder?.patientId || patientId,
      type,
      title: cleanTitle,
      message: cleanMessage,
      scheduledTime: scheduledDate.toISOString(),
      repeat: repeat,
      enabled,
      voiceEnabled,
      status: initialReminder?.status || REMINDER_STATUS.PENDING,
    }

    try {
      onSave(reminderPayload)
      onClose()
    } catch (err) {
      setGeneralError(err.message || 'Failed to save reminder. Please try again.')
    }
  }

  return (
    <div
      className="reminder-modal-backdrop"
      role="presentation"
      onClick={onClose}
    >
      <div
        ref={modalRef}
        className="reminder-modal"
        role="dialog"
        aria-modal="true"
        aria-labelledby="reminder-modal-title"
        onClick={e => e.stopPropagation()}
      >
        {/* Header */}
        <div className="reminder-modal-header">
          <div className="reminder-modal-title-group">
            <span className="reminder-modal-badge" aria-hidden="true">
              <BellRing size={16} />
            </span>
            <div>
              <h2 id="reminder-modal-title" className="reminder-modal-title">
                {isEdit ? 'Edit Reminder' : 'Add Reminder'}
              </h2>
              <p className="reminder-modal-subtitle">
                Schedule a gentle prompt for your patient.
              </p>
            </div>
          </div>
          <button
            type="button"
            className="reminder-modal-close"
            onClick={onClose}
            aria-label="Close dialog"
          >
            <X size={20} aria-hidden="true" />
          </button>
        </div>

        {/* Clinical Dosage Advisory */}
        <div className="reminder-safety-notice" role="note">
          <AlertCircle size={16} aria-hidden="true" />
          <span>
            <strong>Reminder Safety Note:</strong> MindCare NER is for routine prompts only.
            Prescription dosages and medication advising are not allowed.
          </span>
        </div>

        {/* General Error Banner */}
        {generalError && (
          <div className="reminder-error-banner" role="alert" aria-live="assertive">
            <AlertCircle size={16} aria-hidden="true" />
            <span>{generalError}</span>
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleSubmit} className="reminder-form" noValidate>
          {/* 1. Reminder Type */}
          <div className="reminder-field-group">
            <label className="reminder-label" id="reminder-type-label">
              Reminder Type <span className="reminder-req">*</span>
            </label>
            <div
              className="reminder-type-selector"
              role="radiogroup"
              aria-labelledby="reminder-type-label"
            >
              {Object.values(REMINDER_TYPES).map(catKey => {
                const config = REMINDER_TYPE_CONFIG[catKey]
                const isSelected = type === catKey
                return (
                  <button
                    key={catKey}
                    type="button"
                    role="radio"
                    aria-checked={isSelected}
                    className={`reminder-type-option ${config.badgeColor} ${isSelected ? 'selected' : ''}`}
                    onClick={() => handleTypeChange(catKey)}
                  >
                    <span className="reminder-type-icon">{getCategoryIcon(catKey)}</span>
                    <span className="reminder-type-name">{config.label}</span>
                  </button>
                )
              })}
            </div>
          </div>

          {/* 2. Title */}
          <div className="reminder-field-group">
            <label htmlFor="reminder-title-input" className="reminder-label">
              Title <span className="reminder-req">*</span>
            </label>
            <input
              ref={firstInputRef}
              id="reminder-title-input"
              type="text"
              className={`reminder-input ${errors.title ? 'has-error' : ''}`}
              placeholder="e.g. Morning Medicine"
              value={title}
              onChange={e => {
                setTitle(e.target.value)
                if (errors.title) setErrors(prev => ({ ...prev, title: null }))
              }}
              aria-invalid={Boolean(errors.title)}
              aria-describedby={errors.title ? 'title-error' : undefined}
            />
            {errors.title && (
              <p id="title-error" className="reminder-field-error" role="alert">
                <AlertCircle size={14} aria-hidden="true" />
                <span>{errors.title}</span>
              </p>
            )}
          </div>

          {/* 3. Message */}
          <div className="reminder-field-group">
            <label htmlFor="reminder-message-input" className="reminder-label">
              Message <span className="reminder-req">*</span>
            </label>
            <textarea
              id="reminder-message-input"
              rows={2}
              className={`reminder-textarea ${errors.message ? 'has-error' : ''}`}
              placeholder="e.g. It's time for your scheduled medicine."
              value={message}
              onChange={e => {
                setMessage(e.target.value)
                if (errors.message) setErrors(prev => ({ ...prev, message: null }))
              }}
              aria-invalid={Boolean(errors.message)}
              aria-describedby={errors.message ? 'message-error' : undefined}
            />
            {errors.message && (
              <p id="message-error" className="reminder-field-error" role="alert">
                <AlertCircle size={14} aria-hidden="true" />
                <span>{errors.message}</span>
              </p>
            )}
          </div>

          {/* 4. Time & Repeat (Side by side on tablet/desktop) */}
          <div className="reminder-row-two-col">
            {/* Time */}
            <div className="reminder-field-group">
              <label htmlFor="reminder-time-input" className="reminder-label">
                Time <span className="reminder-req">*</span>
              </label>
              <input
                id="reminder-time-input"
                type="time"
                className={`reminder-input ${errors.time ? 'has-error' : ''}`}
                value={time}
                onChange={e => {
                  setTime(e.target.value)
                  if (errors.time) setErrors(prev => ({ ...prev, time: null }))
                }}
                aria-invalid={Boolean(errors.time)}
                aria-describedby={errors.time ? 'time-error' : undefined}
              />
              {errors.time && (
                <p id="time-error" className="reminder-field-error" role="alert">
                  <AlertCircle size={14} aria-hidden="true" />
                  <span>{errors.time}</span>
                </p>
              )}
            </div>

            {/* Repeat */}
            <div className="reminder-field-group">
              <label htmlFor="reminder-repeat-select" className="reminder-label">
                Repeat
              </label>
              <select
                id="reminder-repeat-select"
                className="reminder-select"
                value={repeat}
                onChange={e => setRepeat(e.target.value)}
              >
                {REPEAT_OPTIONS.map(opt => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* 5. Toggles: Voice Reminder & Enable Reminder */}
          <div className="reminder-toggles-card">
            {/* Voice Reminder Toggle */}
            <div className="reminder-toggle-row">
              <div className="reminder-toggle-label-wrap">
                <Volume2 size={18} className="reminder-toggle-icon" aria-hidden="true" />
                <div>
                  <strong className="reminder-toggle-title">Voice Reminder</strong>
                  <p className="reminder-toggle-sub">
                    {voiceEnabled
                      ? `Spoken prompt: "${getVoiceReminderMessage({ type: reminderType, title, message })}"`
                      : 'Muted. Visual reminder only.'}
                  </p>
                </div>
              </div>
              <button
                type="button"
                role="switch"
                aria-checked={voiceEnabled}
                className={`reminder-switch ${voiceEnabled ? 'is-on' : 'is-off'}`}
                onClick={() => setVoiceEnabled(v => !v)}
                aria-label="Voice Reminder Toggle"
              >
                <span className="reminder-switch-handle" />
                <span className="reminder-switch-text">{voiceEnabled ? 'ON' : 'OFF'}</span>
              </button>
            </div>

            {/* Enable Reminder Toggle */}
            <div className="reminder-toggle-row">
              <div className="reminder-toggle-label-wrap">
                <BellRing size={18} className="reminder-toggle-icon" aria-hidden="true" />
                <div>
                  <strong className="reminder-toggle-title">Enable Reminder</strong>
                  <p className="reminder-toggle-sub">
                    Keep this reminder active on schedule.
                  </p>
                </div>
              </div>
              <button
                type="button"
                role="switch"
                aria-checked={enabled}
                className={`reminder-switch ${enabled ? 'is-on' : 'is-off'}`}
                onClick={() => setEnabled(v => !v)}
                aria-label="Enable Reminder Toggle"
              >
                <span className="reminder-switch-handle" />
                <span className="reminder-switch-text">{enabled ? 'ON' : 'OFF'}</span>
              </button>
            </div>
          </div>

          {/* Form Actions */}
          <div className="reminder-modal-actions">
            <button
              type="button"
              className="reminder-btn-cancel"
              onClick={onClose}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="reminder-btn-save"
            >
              Save Reminder
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
