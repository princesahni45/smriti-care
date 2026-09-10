/**
 * src/reminders/PatientReminderModal.jsx
 *
 * MindCare NER — Patient-Facing Smart Reminder Notification Dialog
 *
 * DEMENTIA & COGNITIVE-FRIENDLY UX PRINCIPLES:
 * - Very large text (32px+ heading, 22px+ message)
 * - Oversized touch targets (buttons >= 68px min-height)
 * - Ultra high contrast (WCAG AAA compliant)
 * - Zero complex menus, zero swipe gestures, zero drag-and-drop
 * - NO tiny close 'X' button (patients must choose [ ✓ DONE ] or [ REMIND ME LATER ])
 * - Zero technical metadata (no IDs, timestamps, or system jargon)
 * - Zero clinical medication dosage instructions
 * - Friendly confirmation screen on completion ("Done. Well done!")
 * - Gentle reassurance on snooze (configurable snooze interval, NO stressful countdowns)
 * - Optional Voice Assistance:
 *   - Uses native Web Speech API (zero external heavy libraries).
 *   - Category-specific gentle prompts ("It's time to have some water", "It's time for your scheduled medicine", etc.).
 *   - Spoken ONCE on appearance (never repeats or loops).
 *   - Accessible Mute / Unmute toggle button right on the dialog.
 *   - Respects autoplay restrictions and gracefully handles unsupported devices.
 *   - Visual reminder is ALWAYS 100% available and prominent.
 * - Accessible keyboard navigation with autofocus on primary [ ✓ DONE ] action
 */

import { useState, useEffect, useRef } from 'react'
import {
  Check, Clock3, Volume2, VolumeX, Pill, Droplets, CalendarDays, Gamepad2, CheckCircle2
} from 'lucide-react'
import { REMINDER_TYPES } from './reminderTypes.js'
import { getSnoozeDurationMinutes } from './reminderService.js'
import {
  isSpeechSupported,
  isVoiceMuted,
  toggleVoiceMuted,
  speakReminderVoice,
  cancelReminderVoice,
  getVoiceReminderMessage,
} from './voiceReminderService.js'

export function PatientReminderModal({
  reminder,
  onDone,
  onSnooze,
}) {
  const [feedbackState, setFeedbackState] = useState('idle') // 'idle' | 'done' | 'snooze'
  const [muted, setMuted] = useState(() => isVoiceMuted())
  const doneButtonRef = useRef(null)
  const timerRef = useRef(null)
  const hasSpokenRef = useRef(false)

  // Listen to cross-tab or dialog mute changes
  useEffect(() => {
    function onMuteChange(e) {
      if (typeof e.detail?.isMuted === 'boolean') {
        setMuted(e.detail.isMuted)
      }
    }
    if (typeof window !== 'undefined') {
      window.addEventListener('mindcare:voice-mute-changed', onMuteChange)
      return () => window.removeEventListener('mindcare:voice-mute-changed', onMuteChange)
    }
  }, [])

  // Clear timer and speech on unmount
  useEffect(() => {
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current)
      cancelReminderVoice()
    }
  }, [])

  // Reset feedbackState & spoken tracker when reminder changes
  useEffect(() => {
    setFeedbackState('idle')
    hasSpokenRef.current = false
  }, [reminder?.id])

  // Autofocus the primary [ ✓ DONE ] button on mount for easy keyboard/touch access
  useEffect(() => {
    if (reminder && feedbackState === 'idle') {
      const timer = setTimeout(() => {
        doneButtonRef.current?.focus()
      }, 80)
      return () => clearTimeout(timer)
    }
  }, [reminder, feedbackState])

  // Spoken ONCE when reminder appears (if voiceEnabled is true and not muted)
  useEffect(() => {
    if (
      reminder?.voiceEnabled &&
      !muted &&
      feedbackState === 'idle' &&
      !hasSpokenRef.current
    ) {
      hasSpokenRef.current = true
      speakReminderVoice(reminder)
    }
  }, [reminder, muted, feedbackState])

  // Toggle Mute / Unmute handler right on the reminder UI
  function handleToggleMute() {
    const nextMuted = toggleVoiceMuted()
    setMuted(nextMuted)
    if (!nextMuted) {
      // Unmuting: play the reminder prompt immediately (user gesture bypasses autoplay restrictions)
      speakReminderVoice(reminder, { force: true })
    } else {
      cancelReminderVoice()
    }
  }

  // Handle DONE action with friendly confirmation
  function handleDoneClick() {
    if (feedbackState !== 'idle') return
    setFeedbackState('done')

    // Optional gentle voice confirmation if not muted
    if (reminder?.voiceEnabled && !muted && isSpeechSupported()) {
      try {
        cancelReminderVoice()
        const doneUtterance = new SpeechSynthesisUtterance('Done. Well done!')
        doneUtterance.rate = 0.85
        doneUtterance.pitch = 1.0
        doneUtterance.volume = 0.95
        window.speechSynthesis.speak(doneUtterance)
      } catch {}
    }

    // Friendly display pause before closing modal and completing action
    timerRef.current = setTimeout(() => {
      onDone(reminder)
    }, 1300)
  }

  // Handle SNOOZE action with gentle reassurance
  function handleSnoozeClick() {
    if (feedbackState !== 'idle') return
    setFeedbackState('snooze')

    const snoozeMinutes = getSnoozeDurationMinutes()

    // Optional gentle voice reassurance if not muted
    if (reminder?.voiceEnabled && !muted && isSpeechSupported()) {
      try {
        cancelReminderVoice()
        const snoozeUtterance = new SpeechSynthesisUtterance(`No problem. We will remind you in ${snoozeMinutes} minutes.`)
        snoozeUtterance.rate = 0.85
        snoozeUtterance.pitch = 1.0
        snoozeUtterance.volume = 0.95
        window.speechSynthesis.speak(snoozeUtterance)
      } catch {}
    }

    // Friendly display pause before closing modal and snoozing
    timerRef.current = setTimeout(() => {
      onSnooze(reminder, snoozeMinutes)
    }, 1200)
  }

  // Handle keyboard: Esc maps to Snooze so accidental press does not discard without action
  useEffect(() => {
    function handleKeyDown(e) {
      if (e.key === 'Escape' && reminder && feedbackState === 'idle') {
        e.preventDefault()
        handleSnoozeClick()
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [reminder, feedbackState])

  if (!reminder) return null

  // ── 1. CONFIRMATION SCREEN: [ ✓ DONE ] ─────────────────────────────
  if (feedbackState === 'done') {
    return (
      <div
        className="pr-overlay"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="pr-confirm-title"
      >
        <div className="pr-card pr-feedback-card pr-feedback-done">
          <div className="pr-feedback-icon-wrap" aria-hidden="true">
            <CheckCircle2 size={80} className="pr-feedback-check-icon" />
          </div>
          <h1 id="pr-confirm-title" className="pr-title pr-feedback-title">
            Done. Well done!
          </h1>
          <p className="pr-message pr-feedback-sub">
            Your reminder has been completed.
          </p>
          <div className="sr-only" role="status" aria-live="polite">
            Done. Well done!
          </div>
        </div>
      </div>
    )
  }

  // ── 2. REASSURANCE SCREEN: [ REMIND ME LATER ] ─────────────────────
  if (feedbackState === 'snooze') {
    const snoozeMinutes = getSnoozeDurationMinutes()
    return (
      <div
        className="pr-overlay"
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="pr-snooze-title"
      >
        <div className="pr-card pr-feedback-card pr-feedback-snooze">
          <div className="pr-feedback-icon-wrap pr-snooze-icon-wrap" aria-hidden="true">
            <Clock3 size={72} className="pr-feedback-clock-icon" />
          </div>
          <h1 id="pr-snooze-title" className="pr-title pr-feedback-title">
            Reminding You Later
          </h1>
          <p className="pr-message pr-feedback-sub">
            No problem at all. We will remind you in {snoozeMinutes} minutes.
          </p>
          <div className="sr-only" role="status" aria-live="polite">
            We will remind you in {snoozeMinutes} minutes.
          </div>
        </div>
      </div>
    )
  }

  // ── 3. STANDARD REMINDER PRESENTATION ──────────────────────────────
  const getCategoryDisplay = () => {
    switch (reminder.type) {
      case REMINDER_TYPES.MEDICATION:
        return {
          icon: <Pill size={64} aria-hidden="true" />,
          emoji: '💊',
          themeClass: 'pr-theme-medication',
          fallbackTitle: 'Medication Reminder',
          fallbackMessage: "It's time for your scheduled medicine.",
        }
      case REMINDER_TYPES.HYDRATION:
        return {
          icon: <Droplets size={64} aria-hidden="true" />,
          emoji: '💧',
          themeClass: 'pr-theme-hydration',
          fallbackTitle: 'Time for Water',
          fallbackMessage: "Let's have some water.",
        }
      case REMINDER_TYPES.APPOINTMENT:
        return {
          icon: <CalendarDays size={64} aria-hidden="true" />,
          emoji: '📅',
          themeClass: 'pr-theme-appointment',
          fallbackTitle: 'Appointment Reminder',
          fallbackMessage: 'You have an appointment today.',
        }
      case REMINDER_TYPES.COGNITIVE_ACTIVITY:
        return {
          icon: <Gamepad2 size={64} aria-hidden="true" />,
          emoji: '🧠',
          themeClass: 'pr-theme-cognitive',
          fallbackTitle: 'Brain Activity',
          fallbackMessage: 'Time for a gentle brain activity.',
        }
      case REMINDER_TYPES.DAILY_ROUTINE:
      default:
        return {
          icon: <Clock3 size={64} aria-hidden="true" />,
          emoji: '⏰',
          themeClass: 'pr-theme-routine',
          fallbackTitle: 'Daily Routine',
          fallbackMessage: 'Here is a gentle reminder for your routine.',
        }
    }
  }

  const cat = getCategoryDisplay()
  const displayTitle = reminder.title || cat.fallbackTitle
  const displayMessage = reminder.message || cat.fallbackMessage

  return (
    <div
      className="pr-overlay"
      role="alertdialog"
      aria-modal="true"
      aria-labelledby="pr-title"
      aria-describedby="pr-message"
    >
      <div className={`pr-card ${cat.themeClass}`}>
        {/* Large Prominent Category Icon */}
        <div className="pr-icon-container" aria-hidden="true">
          <span className="pr-emoji">{cat.emoji}</span>
        </div>

        {/* Gentle retry banner if retried (No alarming sounds, purely reassuring) */}
        {reminder.attempts > 1 && (
          <div className="pr-gentle-retry-tag" aria-label="Gentle reminder prompt">
            <span>Gentle Reminder</span>
          </div>
        )}

        {/* Large Elder-Friendly Title */}
        <h1 id="pr-title" className="pr-title">
          {displayTitle}
        </h1>

        {/* Large Gentle Message */}
        <p id="pr-message" className="pr-message">
          "{displayMessage}"
        </p>

        {/* ── Voice Assistance Control (Optional Mute / Unmute) ─────── */}
        {reminder.voiceEnabled && isSpeechSupported() && (
          <div className="pr-voice-control-wrap">
            <button
              type="button"
              className={`pr-voice-btn ${muted ? 'is-muted' : 'is-active'}`}
              onClick={handleToggleMute}
              aria-pressed={muted}
              aria-label={muted ? 'Voice is muted. Tap to play voice prompt' : 'Voice is on. Tap to mute voice'}
            >
              {muted ? (
                <>
                  <VolumeX size={20} className="pr-voice-icon" aria-hidden="true" />
                  <span>Voice Muted · Tap to Play</span>
                </>
              ) : (
                <>
                  <Volume2 size={20} className="pr-voice-icon" aria-hidden="true" />
                  <span>Voice ON · Tap to Mute</span>
                </>
              )}
            </button>
          </div>
        )}

        {/* ── Oversized Elder-Friendly Action Buttons ────────────── */}
        <div className="pr-actions-container">
          {/* 1. Primary [ ✓ DONE ] Button */}
          <button
            ref={doneButtonRef}
            type="button"
            className="pr-btn-done"
            onClick={handleDoneClick}
            disabled={feedbackState !== 'idle'}
            aria-label={`Mark done: ${displayTitle}`}
          >
            <Check size={32} className="pr-btn-icon" aria-hidden="true" />
            <span>✓ DONE</span>
          </button>

          {/* 2. Secondary [ REMIND ME LATER ] Button */}
          <button
            type="button"
            className="pr-btn-snooze"
            onClick={handleSnoozeClick}
            disabled={feedbackState !== 'idle'}
            aria-label={`Remind me later about ${displayTitle}`}
          >
            <Clock3 size={24} className="pr-btn-icon" aria-hidden="true" />
            <span>REMIND ME LATER</span>
          </button>
        </div>
      </div>
    </div>
  )
}
