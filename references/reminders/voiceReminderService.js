/**
 * src/reminders/voiceReminderService.js
 *
 * MindCare NER — Optional Voice Assistance for Smart Reminders
 *
 * ARCHITECTURAL PRINCIPLES:
 * 1. Native browser/device Web Speech API: Zero external heavy libraries or cloud API dependencies.
 * 2. Dementia & Elderly UX:
 *    - Short, gentle, calming sentences.
 *    - Unhurried speaking rate (0.85x).
 *    - Spoken ONCE on reminder delivery — never loops or continuously repeats.
 * 3. User & Caregiver Control:
 *    - Optional per reminder (governed by reminder.voiceEnabled).
 *    - Instant Mute/Unmute toggle on the patient reminder dialog.
 *    - Persistent mute preference in localStorage.
 * 4. Resilient Fallbacks:
 *    - Gracefully handles environments without speech synthesis (e.g. Node, legacy devices).
 *    - Catches browser autoplay restrictions silently.
 *    - Visual reminder is always 100% available regardless of speech status.
 */

import { REMINDER_TYPES } from './reminderTypes.js'
import { getSavedLanguageCode, TRANSLATION_CATALOG } from '../i18n/index.js'
import { detectLanguageVoice } from '../i18n/voiceDetection.js'

export const VOICE_MUTED_STORAGE_KEY = 'mindcare-reminders-voice-muted'

/**
 * Standardized gentle short messages by category as specified.
 * Defaults to English, overridden by getVoiceReminderMessage with active language.
 */
export const CATEGORY_VOICE_MESSAGES = {
  [REMINDER_TYPES.HYDRATION]: "It's time to have some water.",
  [REMINDER_TYPES.MEDICATION]: "It's time for your scheduled medicine.",
  [REMINDER_TYPES.APPOINTMENT]: "You have an appointment today.",
  [REMINDER_TYPES.COGNITIVE_ACTIVITY]: "Your brain activity is ready.",
  [REMINDER_TYPES.DAILY_ROUTINE]: "It's time for your daily routine.",
}

/**
 * Checks whether the browser / device supports Web Speech Synthesis.
 *
 * @returns {boolean}
 */
export function isSpeechSupported() {
  if (typeof window === 'undefined') return false
  return (
    'speechSynthesis' in window &&
    typeof window.speechSynthesis !== 'undefined' &&
    typeof window.SpeechSynthesisUtterance !== 'undefined'
  )
}

/**
 * Resolves the short spoken message for a reminder in the target language.
 * Prioritizes standard dementia-friendly category prompts.
 *
 * @param {Object} reminder
 * @param {string} [langCode]
 * @returns {string}
 */
export function getVoiceReminderMessage(reminder, langCode) {
  if (!reminder) return ''
  const lang = langCode || getSavedLanguageCode()
  const dict = TRANSLATION_CATALOG[lang] || TRANSLATION_CATALOG['en']

  if (reminder.type) {
    const typeMap = {
      [REMINDER_TYPES.HYDRATION]: dict.reminders?.hydration,
      [REMINDER_TYPES.MEDICATION]: dict.reminders?.medicine,
      [REMINDER_TYPES.APPOINTMENT]: dict.reminders?.appointment,
      [REMINDER_TYPES.COGNITIVE_ACTIVITY]: dict.reminders?.activity,
      [REMINDER_TYPES.DAILY_ROUTINE]: dict.reminders?.routine,
    }
    if (typeMap[reminder.type]) {
      return typeMap[reminder.type]
    }
    if (CATEGORY_VOICE_MESSAGES[reminder.type]) {
      return CATEGORY_VOICE_MESSAGES[reminder.type]
    }
  }

  // Fallback to title or message
  if (reminder.message && reminder.message.trim().length > 0) {
    return reminder.message.trim()
  }

  if (reminder.title && reminder.title.trim().length > 0) {
    return reminder.title.trim()
  }

  return dict.reminders?.title || "It's time for your scheduled reminder."
}

/**
 * Checks if voice is currently muted by user/patient preference.
 *
 * @returns {boolean}
 */
export function isVoiceMuted() {
  if (typeof window === 'undefined' || !window.localStorage) return false
  try {
    return window.localStorage.getItem(VOICE_MUTED_STORAGE_KEY) === 'true'
  } catch {
    return false
  }
}

/**
 * Sets the persistent mute preference for voice assistance.
 *
 * @param {boolean} muted
 * @returns {boolean}
 */
export function setVoiceMuted(muted) {
  const isMuted = Boolean(muted)
  if (typeof window !== 'undefined' && window.localStorage) {
    try {
      window.localStorage.setItem(VOICE_MUTED_STORAGE_KEY, String(isMuted))
      // Cancel active speech immediately when muting
      if (isMuted && isSpeechSupported()) {
        window.speechSynthesis.cancel()
      }
      // Broadcast update
      window.dispatchEvent(
        new CustomEvent('mindcare:voice-mute-change', { detail: { muted: isMuted } })
      )
      return true
    } catch {
      return false
    }
  }
  return false
}

/**
 * Toggles the voice mute preference.
 *
 * @returns {boolean}
 */
export function toggleVoiceMuted() {
  return setVoiceMuted(!isVoiceMuted())
}

/**
 * Cancels any active or pending speech synthesis output safely.
 */
export function cancelReminderVoice() {
  if (!isSpeechSupported()) return
  try {
    window.speechSynthesis.cancel()
  } catch {
    // Graceful no-op
  }
}

/**
 * Speaks a reminder message using native Web Speech Synthesis.
 * Slower rate (0.85x), gentle volume, single play.
 *
 * @param {Object} reminder
 * @param {Object} [options]
 * @returns {Promise<{ status: string, message?: string }>}
 */
export async function speakVoiceReminder(reminder, options = {}) {
  // 1. Feature flag guard
  if (!options.force && reminder && reminder.voiceEnabled === false) {
    return { status: 'disabled' }
  }

  // 2. Browser capability check
  if (!isSpeechSupported()) {
    return { status: 'unsupported' }
  }

  // 3. Check if muted
  if (isVoiceMuted() && !options.force) {
    return { status: 'muted' }
  }

  const activeLang = options.lang || getSavedLanguageCode()
  const textToSpeak = getVoiceReminderMessage(reminder, activeLang)
  if (!textToSpeak) return { status: 'empty' }

  // Check if voice is available for target language
  const voiceCheck = detectLanguageVoice(activeLang)
  if (!voiceCheck.hasVoice || !voiceCheck.voice) {
    // Graceful degradation: do not throw or crash
    return { status: 'no_voice_for_language', notice: voiceCheck.notice, message: textToSpeak }
  }

  try {
    // Cancel any previous speech to avoid overlapping
    window.speechSynthesis.cancel()

    const UtteranceConstructor = window.SpeechSynthesisUtterance || SpeechSynthesisUtterance
    const utterance = new UtteranceConstructor(textToSpeak)

    // Dementia-friendly speech parameters:
    // Slower pace (0.85x) to aid cognitive processing and reduce anxiety
    utterance.rate = options.rate || 0.85
    utterance.pitch = 1.0
    utterance.volume = 0.95
    utterance.voice = voiceCheck.voice
    utterance.lang = voiceCheck.voice.lang || 'en-US'

    if (typeof options.onStart === 'function') {
      utterance.onstart = options.onStart
    }

    if (typeof options.onEnd === 'function') {
      utterance.onend = options.onEnd
    }

    utterance.onerror = (e) => {
      // Browser autoplay policy or canceled speech
      if (typeof options.onError === 'function') {
        options.onError(e)
      }
    }

    window.speechSynthesis.speak(utterance)
    return { status: 'spoken', message: textToSpeak }
  } catch (err) {
    // Autoplay restrictions or unsupported device error
    if (typeof options.onError === 'function') {
      options.onError(err)
    }
    return { status: 'unsupported' }
  }
}

/** Backwards-compatibility export */
export const speakReminderVoice = speakVoiceReminder
