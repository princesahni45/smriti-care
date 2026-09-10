/**
 * src/reminders/reminderContext.jsx
 *
 * MindCare NER — Smart Reminders React Context & Custom Hook
 *
 * Provides a clean reactive state management layer for Smart Reminders,
 * following the established pattern of patientSession.jsx.
 *
 * SEPARATION OF CONCERNS:
 * - Pure business logic and storage reside in reminderService.js and reminderModel.js.
 * - This context coordinates React re-renders, action dispatches, and computed selectors.
 * - ZERO UI rendering or markup is included in this file.
 *
 * USAGE:
 * Wrap the application tree (or specific caregiver / patient routes) in <ReminderProvider>:
 *
 *   <ReminderProvider defaultPatientId="MC-2048">
 *     <YourComponent />
 *   </ReminderProvider>
 *
 * Consume via useReminders() hook:
 *
 *   const {
 *     reminders,
 *     todayReminders,
 *     dueReminders,
 *     stats,
 *     createReminder,
 *     acknowledgeReminder,
 *     snoozeReminder,
 *   } = useReminders()
 */

import { createContext, useContext, useState, useEffect, useCallback, useMemo } from 'react'
import {
  loadAllReminders,
  saveReminder as serviceSaveReminder,
  deleteReminder as serviceDeleteReminder,
  acknowledgeReminderById,
  snoozeReminderById,
  toggleReminderEnabledById,
  getReminderStats,
  resetRemindersToMock,
  REMINDERS_STORAGE_KEY,
} from './reminderService.js'
import { isReminderDue, isReminderForDate } from './reminderModel.js'

export const ReminderContext = createContext(null)
ReminderContext.displayName = 'ReminderContext'

export function ReminderProvider({ children, defaultPatientId = 'MC-2048' }) {
  const [activePatientId, setActivePatientId] = useState(defaultPatientId)
  const [reminders, setReminders] = useState(() => loadAllReminders())

  // Reload when activePatientId changes or upon external storage trigger
  const refresh = useCallback(() => {
    setReminders(loadAllReminders())
  }, [])

  // Listen to multi-tab storage changes
  useEffect(() => {
    function handleStorage(e) {
      if (e.key === REMINDERS_STORAGE_KEY) {
        refresh()
      }
    }
    if (typeof window !== 'undefined') {
      window.addEventListener('storage', handleStorage)
      return () => window.removeEventListener('storage', handleStorage)
    }
  }, [refresh])

  // Actions
  const create = useCallback((reminderInput) => {
    const payload = {
      patientId: activePatientId,
      ...reminderInput,
    }
    const saved = serviceSaveReminder(payload)
    refresh()
    return saved
  }, [activePatientId, refresh])

  const update = useCallback((id, updates) => {
    const saved = serviceSaveReminder({ id, ...updates })
    refresh()
    return saved
  }, [refresh])

  const remove = useCallback((id) => {
    const success = serviceDeleteReminder(id)
    if (success) refresh()
    return success
  }, [refresh])

  const acknowledge = useCallback((id, timestamp) => {
    const updated = acknowledgeReminderById(id, timestamp)
    if (updated) refresh()
    return updated
  }, [refresh])

  const snooze = useCallback((id, minutes) => {
    const updated = snoozeReminderById(id, minutes)
    if (updated) refresh()
    return updated
  }, [refresh])

  const toggleEnabled = useCallback((id, enabled) => {
    const updated = toggleReminderEnabledById(id, enabled)
    if (updated) refresh()
    return updated
  }, [refresh])

  const reset = useCallback(() => {
    const resetSeeds = resetRemindersToMock()
    setReminders(resetSeeds)
    return resetSeeds
  }, [])

  // Filtered queries for active patient
  const patientReminders = useMemo(() => {
    return reminders.filter(r => !activePatientId || r.patientId === activePatientId)
  }, [reminders, activePatientId])

  const todayReminders = useMemo(() => {
    const now = new Date()
    return patientReminders.filter(r => isReminderForDate(r, now))
  }, [patientReminders])

  const dueReminders = useMemo(() => {
    const now = new Date()
    return patientReminders.filter(r => isReminderDue(r, now))
  }, [patientReminders])

  const stats = useMemo(() => {
    return getReminderStats(activePatientId)
  }, [activePatientId, reminders])

  const contextValue = useMemo(() => ({
    // State
    patientId: activePatientId,
    setPatientId: setActivePatientId,
    reminders: patientReminders,
    allReminders: reminders,
    todayReminders,
    dueReminders,
    stats,

    // Operations
    createReminder: create,
    updateReminder: update,
    deleteReminder: remove,
    acknowledgeReminder: acknowledge,
    snoozeReminder: snooze,
    toggleReminderEnabled: toggleEnabled,
    refreshReminders: refresh,
    resetReminders: reset,
  }), [
    activePatientId,
    patientReminders,
    reminders,
    todayReminders,
    dueReminders,
    stats,
    create,
    update,
    remove,
    acknowledge,
    snooze,
    toggleEnabled,
    refresh,
    reset,
  ])

  return (
    <ReminderContext.Provider value={contextValue}>
      {children}
    </ReminderContext.Provider>
  )
}

/**
 * useReminders()
 *
 * Custom hook to access reminders state and operations.
 * Throws an informative error if invoked outside <ReminderProvider>.
 *
 * @returns {Object} Reminders state and operations
 */
export function useReminders() {
  const ctx = useContext(ReminderContext)
  if (!ctx) {
    throw new Error(
      '[MindCare Reminders] useReminders() must be used within a <ReminderProvider>.\n' +
      'Wrap your caregiver dashboard or patient views in <ReminderProvider>.'
    )
  }
  return ctx
}
