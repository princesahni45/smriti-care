/**
 * src/reminders/usePatientDueReminder.js
 *
 * MindCare NER — Patient Due Reminder Scheduling Hook
 *
 * Wraps the centralized ReminderScheduler engine in a clean React hook.
 *
 * FEATURES:
 * - Single-timer architecture (no duplicate or stacked intervals)
 * - Sequential queue delivery for dementia patients
 * - Automatically cleans up timers upon component unmount
 * - Listens to storage events across tabs (e.g. when caregiver adds/edits a reminder)
 * - Safe page refresh recovery
 */

import { useState, useEffect, useRef, useCallback } from 'react'
import { ReminderScheduler } from './schedulingEngine.js'
import { REMINDERS_STORAGE_KEY, getSnoozeDurationMinutes } from './reminderService.js'

export function usePatientDueReminder(patientId = 'MC-2048') {
  const [activeReminder, setActiveReminder] = useState(null)
  const [dueQueueCount, setDueQueueCount] = useState(0)

  const schedulerRef = useRef(null)

  // Initialize and manage scheduler lifecycle
  useEffect(() => {
    // Instantiate single scheduler
    const scheduler = new ReminderScheduler({
      patientId,
      checkIntervalMs: 5000,
      onDue: (reminder) => {
        setActiveReminder(reminder)
      },
      onQueueChange: (queue) => {
        setDueQueueCount(queue.length)
      },
    })

    schedulerRef.current = scheduler
    scheduler.start()

    // Multi-tab storage synchronization
    function handleStorage(e) {
      if (e.key === REMINDERS_STORAGE_KEY) {
        scheduler.tick()
      }
    }

    if (typeof window !== 'undefined') {
      window.addEventListener('storage', handleStorage)
    }

    // Cleanup upon component unmount
    return () => {
      if (typeof window !== 'undefined') {
        window.removeEventListener('storage', handleStorage)
      }
      scheduler.destroy()
      schedulerRef.current = null
    }
  }, [patientId])

  // Action: Patient tapped [ ✓ DONE ]
  const handleDone = useCallback((reminder) => {
    if (schedulerRef.current) {
      schedulerRef.current.acknowledgeActive()
    }
  }, [])

  // Action: Patient tapped [ REMIND ME LATER ]
  const handleSnooze = useCallback((reminder, snoozeMinutes) => {
    if (schedulerRef.current) {
      const minutes = typeof snoozeMinutes === 'number' ? snoozeMinutes : getSnoozeDurationMinutes()
      schedulerRef.current.snoozeActive(minutes)
    }
  }, [])

  // Force an immediate evaluation
  const checkNow = useCallback(() => {
    if (schedulerRef.current) {
      schedulerRef.current.tick()
    }
  }, [])

  return {
    dueReminder: activeReminder,
    dueQueueCount,
    handleDone,
    handleSnooze,
    triggerCheck: checkNow,
  }
}
