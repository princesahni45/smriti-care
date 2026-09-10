/**
 * emergencyContactService.js
 * 
 * Manages emergency contact information, home location, and emergency number configurations.
 * Uses localStorage with resilient fallbacks so all data remains accessible offline.
 * Provides client-side geographical calculations (Haversine distance and compass bearing)
 * with zero paid external APIs.
 */

const STORAGE_KEYS = {
  CONTACT: 'mindcare_emergency_contact',
  CONFIG: 'mindcare_emergency_config',
  HOME: 'mindcare_home_location',
}

// Default India emergency configuration (Configurable for other countries)
const DEFAULT_EMERGENCY_CONFIG = {
  emergencyNumber: '112',
  label: 'National Emergency Response Support System',
  country: 'India',
}

// Default initial caregiver contact (customizable and editable by caregiver)
const DEFAULT_CAREGIVER_CONTACT = {
  name: 'Rahul Das',
  relationship: 'Son',
  phone: '+91 98765 43210',
  secondaryPhone: '+91 98765 01234',
  updatedAt: new Date().toISOString(),
}

// Default home location (Guwahati, Assam, North-East India)
const DEFAULT_HOME_LOCATION = {
  address: 'Ambari, Guwahati, Assam',
  latitude: 26.1856,
  longitude: 91.7539,
  updatedAt: new Date().toISOString(),
}

/**
 * Validate telephone numbers.
 * Supports:
 * - 10-digit Indian numbers (e.g. 9876543210)
 * - Numbers with country code (e.g. +91 98765 43210, +919876543210)
 * - Emergency numbers (e.g. 112, 100, 911) when allowEmergencyServices is true
 */
export function validatePhoneNumber(phone, allowEmergencyServices = false) {
  if (!phone || typeof phone !== 'string') {
    return { valid: false, error: 'Phone number is required.' }
  }

  const trimmed = phone.trim()
  // Clean allowed formatting characters (spaces, dashes, parens)
  const cleaned = trimmed.replace(/[\s\-()]/g, '')

  // Allow short emergency numbers like 112, 911 only when enabled
  if (allowEmergencyServices && /^\d{3,4}$/.test(cleaned)) {
    return { valid: true, cleaned }
  }

  // Standard phone check: optional leading +, then 8 to 15 digits
  const phoneRegex = /^\+?[0-9]{8,15}$/
  if (!phoneRegex.test(cleaned)) {
    return {
      valid: false,
      error: 'Please enter a valid phone number with 8 to 15 digits (and optional +country code).',
    }
  }

  return { valid: true, cleaned }
}

/**
 * Format phone number for tel: links
 */
export function formatTelLink(phone) {
  if (!phone) return ''
  return `tel:${phone.replace(/[\s\-()]/g, '')}`
}

/**
 * Retrieve saved emergency contact from localStorage
 */
export function getEmergencyContact() {
  if (typeof window === 'undefined') return DEFAULT_CAREGIVER_CONTACT

  try {
    if (localStorage.getItem(STORAGE_KEYS.CONTACT + '_cleared') === 'true') {
      return null
    }
    const raw = localStorage.getItem(STORAGE_KEYS.CONTACT)
    if (!raw) return DEFAULT_CAREGIVER_CONTACT
    const parsed = JSON.parse(raw)
    return parsed
  } catch (err) {
    console.error('Error reading emergency contact from storage:', err)
    return DEFAULT_CAREGIVER_CONTACT
  }
}

/**
 * Save or update caregiver emergency contact
 */
export function saveEmergencyContact(contact) {
  if (typeof window === 'undefined') return { success: false, error: 'Window unavailable' }

  if (!contact || !contact.name || !contact.phone) {
    return { success: false, error: 'Caregiver name and primary phone are required.' }
  }

  const primaryVal = validatePhoneNumber(contact.phone, false)
  if (!primaryVal.valid) {
    return { success: false, error: `Primary phone: ${primaryVal.error}` }
  }

  if (contact.secondaryPhone && contact.secondaryPhone.trim() !== '') {
    const secVal = validatePhoneNumber(contact.secondaryPhone, false)
    if (!secVal.valid) {
      return { success: false, error: `Secondary phone: ${secVal.error}` }
    }
  }

  const record = {
    name: contact.name.trim(),
    relationship: (contact.relationship || 'Caregiver').trim(),
    phone: contact.phone.trim(),
    secondaryPhone: contact.secondaryPhone ? contact.secondaryPhone.trim() : '',
    updatedAt: new Date().toISOString(),
  }

  try {
    localStorage.removeItem(STORAGE_KEYS.CONTACT + '_cleared')
    localStorage.setItem(STORAGE_KEYS.CONTACT, JSON.stringify(record))
    return { success: true, contact: record }
  } catch (err) {
    console.error('Error saving emergency contact:', err)
    return { success: false, error: 'Failed to write to local storage.' }
  }
}

/**
 * Clear/delete caregiver emergency contact
 */
export function deleteEmergencyContact() {
  if (typeof window === 'undefined') return
  try {
    localStorage.removeItem(STORAGE_KEYS.CONTACT)
    localStorage.setItem(STORAGE_KEYS.CONTACT + '_cleared', 'true')
  } catch (err) {
    console.error('Error removing emergency contact:', err)
  }
}

/**
 * Get emergency number configuration (Default 112)
 */
export function getEmergencyConfig() {
  if (typeof window === 'undefined') return DEFAULT_EMERGENCY_CONFIG

  try {
    const raw = localStorage.getItem(STORAGE_KEYS.CONFIG)
    if (!raw) return DEFAULT_EMERGENCY_CONFIG
    return JSON.parse(raw)
  } catch (err) {
    return DEFAULT_EMERGENCY_CONFIG
  }
}

/**
 * Save emergency number configuration
 */
export function saveEmergencyConfig(config) {
  if (typeof window === 'undefined') return { success: false }

  const record = {
    emergencyNumber: config.emergencyNumber?.trim() || '112',
    label: config.label?.trim() || 'Emergency Services',
    country: config.country?.trim() || 'India',
    updatedAt: new Date().toISOString(),
  }

  try {
    localStorage.setItem(STORAGE_KEYS.CONFIG, JSON.stringify(record))
    return { success: true, config: record }
  } catch (err) {
    return { success: false, error: err.message }
  }
}

/**
 * Get saved Home location
 */
export function getHomeLocation() {
  if (typeof window === 'undefined') return DEFAULT_HOME_LOCATION

  try {
    const raw = localStorage.getItem(STORAGE_KEYS.HOME)
    if (!raw) return DEFAULT_HOME_LOCATION
    return JSON.parse(raw)
  } catch (err) {
    return DEFAULT_HOME_LOCATION
  }
}

/**
 * Save Home location
 */
export function saveHomeLocation(location) {
  if (typeof window === 'undefined') return { success: false }

  const record = {
    address: location.address?.trim() || 'Saved Home Location',
    latitude: Number(location.latitude) || DEFAULT_HOME_LOCATION.latitude,
    longitude: Number(location.longitude) || DEFAULT_HOME_LOCATION.longitude,
    updatedAt: new Date().toISOString(),
  }

  try {
    localStorage.setItem(STORAGE_KEYS.HOME, JSON.stringify(record))
    return { success: true, location: record }
  } catch (err) {
    return { success: false, error: err.message }
  }
}

/**
 * Haversine formula to compute great-circle distance between two points in km
 */
export function calculateDistanceKm(lat1, lon1, lat2, lon2) {
  if (!Number.isFinite(lat1) || !Number.isFinite(lon1) || !Number.isFinite(lat2) || !Number.isFinite(lon2)) {
    return null
  }

  const R = 6371 // Earth's mean radius in kilometers
  const toRad = (d) => (d * Math.PI) / 180

  const dLat = toRad(lat2 - lat1)
  const dLon = toRad(lon2 - lon1)

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2)

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
  const distance = R * c

  return Number(distance.toFixed(2))
}

/**
 * Calculate compass bearing and direction from patient coordinates to home
 */
export function calculateCompassBearing(lat1, lon1, lat2, lon2) {
  if (!Number.isFinite(lat1) || !Number.isFinite(lon1) || !Number.isFinite(lat2) || !Number.isFinite(lon2)) {
    return { bearingDegrees: 0, compassDirection: 'North' }
  }

  const toRad = (d) => (d * Math.PI) / 180
  const toDeg = (r) => (r * 180) / Math.PI

  const y = Math.sin(toRad(lon2 - lon1)) * Math.cos(toRad(lat2))
  const x =
    Math.cos(toRad(lat1)) * Math.sin(toRad(lat2)) -
    Math.sin(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.cos(toRad(lon2 - lon1))

  const bearingDegrees = Math.round((toDeg(Math.atan2(y, x)) + 360) % 360)

  const directions = [
    'North',
    'North-East',
    'East',
    'South-East',
    'South',
    'South-West',
    'West',
    'North-West',
  ]
  const index = Math.round(bearingDegrees / 45) % 8
  const compassDirection = directions[index]

  return { bearingDegrees, compassDirection }
}

/**
 * Format distance in kilometers or meters
 */
export function formatDistance(distKm) {
  if (distKm === null || distKm === undefined || isNaN(distKm)) {
    return '--'
  }
  if (distKm < 1) {
    return `${Math.round(distKm * 1000)} m`
  }
  return `${distKm.toFixed(1)} km`
}

/**
 * Generate a free, non-paid Google Maps coordinates URL (No API key needed)
 */
export function generateGoogleMapsUrl(lat, lng) {
  return `https://www.google.com/maps?q=${lat},${lng}`
}
