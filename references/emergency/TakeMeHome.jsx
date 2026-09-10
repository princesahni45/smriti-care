import { useState, useEffect, useCallback, useRef } from 'react'
import {
  Home, MapPin, Navigation, Volume2, AlertTriangle, Phone, ShieldAlert,
  Share2, RotateCcw, X, ArrowLeft, ArrowUp, Compass, Check, HeartHandshake
} from 'lucide-react'
import {
  getEmergencyContact,
  getEmergencyConfig,
  getHomeLocation,
  calculateDistanceKm,
  calculateCompassBearing,
  formatTelLink
} from './emergencyContactService'
import { useTranslation } from '../i18n/index.js'
import { speakInLanguage } from '../i18n/voiceDetection.js'
import './TakeMeHome.css'

export default function TakeMeHome({ onBack, backLabel }) {
  const { t, language } = useTranslation()
  const displayBackLabel = backLabel || t('common.back', 'Back')

  // Saved locations and contact configuration
  const [homeLocation, setHomeLocation] = useState(getHomeLocation)
  const [caregiverContact, setCaregiverContact] = useState(getEmergencyContact)
  const [emergencyConfig, setEmergencyConfig] = useState(getEmergencyConfig)

  // Current GPS coordinates (defaults to a simulated/last-known nearby position if GPS unavailable)
  const [currentCoords, setCurrentCoords] = useState({
    latitude: 26.1750,
    longitude: 91.7450,
    isRealGps: false,
    error: null,
  })

  const [loadingGps, setLoadingGps] = useState(false)
  const [viewMode, setViewMode] = useState('navigation') // 'navigation' | 'sos'
  const [callConfirmation, setCallConfirmation] = useState(null) // null | { type: 'caregiver' | 'emergency', name: string, phone: string }
  const [shareSuccessMessage, setShareSuccessMessage] = useState('')

  // Read current GPS location on mount
  const fetchLocation = useCallback(() => {
    if (typeof window === 'undefined' || !navigator.geolocation) {
      setCurrentCoords((prev) => ({
        ...prev,
        error: 'Location services not supported on this device.',
      }))
      return
    }

    setLoadingGps(true)
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setCurrentCoords({
          latitude: Number(position.coords.latitude.toFixed(4)),
          longitude: Number(position.coords.longitude.toFixed(4)),
          isRealGps: true,
          error: null,
        })
        setLoadingGps(false)
      },
      (error) => {
        console.warn('Geolocation warning:', error.message)
        setCurrentCoords((prev) => ({
          ...prev,
          error: 'Could not acquire precise GPS. Using estimated nearby location.',
        }))
        setLoadingGps(false)
      },
      { enableHighAccuracy: true, timeout: 8000, maximumAge: 30000 }
    )
  }, [])

  useEffect(() => {
    fetchLocation()
  }, [fetchLocation])

  // Distance and Direction calculations
  const distanceKm = calculateDistanceKm(
    currentCoords.latitude,
    currentCoords.longitude,
    homeLocation.latitude,
    homeLocation.longitude
  )

  const { bearingDegrees, compassDirection } = calculateCompassBearing(
    currentCoords.latitude,
    currentCoords.longitude,
    homeLocation.latitude,
    homeLocation.longitude
  )

  // Voice Read-Aloud Direction
  const speakDirection = () => {
    const distText = distanceKm !== null ? `${distanceKm} km` : ''
    const text = `${t('safety.title', 'Take Me Home')}. ${t('safety.walkToward', 'Walk toward')} ${compassDirection}. ${distText}.`
    speakInLanguage(text, language, { rate: 0.85 })
  }

  // Handle Initiating Call Confirmation
  const promptCallCaregiver = () => {
    if (!caregiverContact || !caregiverContact.phone) {
      setCallConfirmation({
        type: 'missing_caregiver',
        title: t('sos.missingCaregiver', 'No Caregiver Phone Configured'),
        message: 'A caregiver contact number has not been set yet. Please ask your caregiver to set their number in settings.',
      })
      return
    }

    setCallConfirmation({
      type: 'caregiver',
      title: `${t('sos.confirmMessage', 'Are you sure you want to call')} ${caregiverContact.name}?`,
      name: `${caregiverContact.name} (${caregiverContact.relationship})`,
      phone: caregiverContact.phone,
    })
  }

  const promptCallEmergency = () => {
    setCallConfirmation({
      type: 'emergency',
      title: `${t('sos.confirmMessage', 'Are you sure you want to call')} ${emergencyConfig.emergencyNumber}?`,
      name: emergencyConfig.label,
      phone: emergencyConfig.emergencyNumber,
    })
  }

  // Confirm and Execute Call via tel: Link
  const executeCall = (phone) => {
    setCallConfirmation(null)
    const telUri = formatTelLink(phone)
    if (typeof window !== 'undefined') {
      window.location.href = telUri
    }
  }

  // Share Location using Web Share API or copy link
  const shareLocation = async () => {
    const mapsUrl = `https://www.google.com/maps?q=${currentCoords.latitude},${currentCoords.longitude}`
    const shareText = `I need assistance. Here is my current location: ${mapsUrl}`

    if (typeof navigator !== 'undefined' && navigator.share) {
      try {
        await navigator.share({
          title: 'My Current Location - MindCare NER',
          text: shareText,
          url: mapsUrl,
        })
        setShareSuccessMessage('Location shared successfully!')
        setTimeout(() => setShareSuccessMessage(''), 4000)
        return
      } catch (err) {
        if (err.name !== 'AbortError') {
          console.warn('Web Share failed, using clipboard fallback', err)
        }
      }
    }

    // Fallback: Copy link to clipboard
    if (typeof navigator !== 'undefined' && navigator.clipboard) {
      try {
        await navigator.clipboard.writeText(mapsUrl)
        setShareSuccessMessage('Location link copied to clipboard!')
        setTimeout(() => setShareSuccessMessage(''), 4000)
        return
      } catch (err) {
        console.warn('Clipboard write failed', err)
      }
    }

    setShareSuccessMessage(`Maps link: ${mapsUrl}`)
    setTimeout(() => setShareSuccessMessage(''), 6000)
  }

  return (
    <div className="tmh-page">
      {/* Top Header */}
      <header className="tmh-topbar">
        <div className="container tmh-topbar-inner">
          <button
            type="button"
            className="btn btn-secondary tmh-back-btn"
            onClick={onBack}
            aria-label={displayBackLabel}
          >
            <Home size={20} aria-hidden="true" />
            <span>{displayBackLabel}</span>
          </button>

          <div className="tmh-title">
            <span className="icon-bubble teal" aria-hidden="true">
              <Navigation size={22} />
            </span>
            <div>
              <h1>{t('safety.title', 'Take Me Home')} &amp; {t('sos.sosButton', '🆘 SOS')}</h1>
              <p>{t('landing.safeHomeDesc', 'Safe navigation and emergency assistance')}</p>
            </div>
          </div>
        </div>
      </header>

      <main className="container tmh-main">
        {/* ========================================================== */}
        {/* VIEW 1: NAVIGATION MODE (Direction to Home)                */}
        {/* ========================================================== */}
        {viewMode === 'navigation' && (
          <div className="tmh-nav-screen">
            {/* Direction and Compass Visual Card */}
            <section className="tmh-card tmh-direction-card" aria-label="Home direction guidance">
              <div className="tmh-card-badge">
                <Home size={16} aria-hidden="true" />
                <span>{t('safety.destination', 'Destination')}: {homeLocation.address}</span>
              </div>

              {/* Big Compass Arrow */}
              <div
                className="tmh-compass-circle"
                aria-label={`Arrow pointing toward ${compassDirection}`}
              >
                <div
                  className="tmh-compass-arrow"
                  style={{ transform: `rotate(${bearingDegrees}deg)` }}
                >
                  <ArrowUp size={64} aria-hidden="true" strokeWidth={3} />
                </div>
              </div>

              {/* Distance and Compass Heading */}
              <div className="tmh-heading-details">
                <h2 className="tmh-distance-text">
                  {distanceKm !== null ? `${distanceKm} km` : '1.2 km'} {t('safety.distanceAway', 'away from home')}
                </h2>
                <p className="tmh-direction-text">
                  {t('safety.walkToward', 'Walk toward')} <strong>{compassDirection}</strong>
                </p>
              </div>

              {/* Action Buttons: Voice read aloud & SOS */}
              <div className="tmh-action-stack">
                <button
                  type="button"
                  className="btn btn-secondary tmh-voice-btn"
                  onClick={speakDirection}
                  aria-label={t('safety.readDirection', 'Read Direction Aloud')}
                >
                  <Volume2 size={24} aria-hidden="true" />
                  <span>{t('safety.readDirection', 'Read Direction Aloud')}</span>
                </button>

                <button
                  type="button"
                  className="tmh-sos-trigger-btn"
                  onClick={() => setViewMode('sos')}
                  aria-label="Open emergency assistance and SOS options"
                >
                  <AlertTriangle size={32} aria-hidden="true" />
                  <span>{t('sos.sosButton', '🆘 SOS')} / {t('sos.emergencyTitle', 'NEED HELP')}</span>
                </button>
              </div>
            </section>
          </div>
        )}

        {/* ========================================================== */}
        {/* VIEW 2: SOS EMERGENCY SCREEN                               */}
        {/* ========================================================== */}
        {viewMode === 'sos' && (
          <div className="tmh-sos-screen">
            <section className="tmh-card tmh-sos-card" aria-label="Emergency help menu">
              <div className="tmh-sos-banner">
                <span className="tmh-sos-emblem" aria-hidden="true">🆘</span>
                <div>
                  <h2>{t('sos.emergencyTitle', 'Emergency Assistance')}</h2>
                  <p>{t('sos.emergencySubtitle', 'If you need help, tap one of the options below.')}</p>
                </div>
              </div>

              {/* Large Emergency Buttons */}
              <div className="tmh-sos-grid">
                {/* 1. Call Caregiver */}
                <button
                  type="button"
                  className="tmh-sos-action-btn tmh-btn-caregiver"
                  onClick={promptCallCaregiver}
                  aria-label={`Call Caregiver: ${caregiverContact?.name || 'Saved Contact'}`}
                >
                  <div className="tmh-btn-icon-bubble" aria-hidden="true">
                    <Phone size={32} />
                  </div>
                  <div className="tmh-btn-copy">
                    <strong>{t('sos.callCaregiver', 'CALL CAREGIVER')}</strong>
                    <span>
                      {caregiverContact?.phone
                        ? `${caregiverContact.name} (${caregiverContact.phone})`
                        : 'No number set'}
                    </span>
                  </div>
                </button>

                {/* 2. Call Emergency 112 */}
                <button
                  type="button"
                  className="tmh-sos-action-btn tmh-btn-emergency"
                  onClick={promptCallEmergency}
                  aria-label={`Call Emergency Services ${emergencyConfig.emergencyNumber}`}
                >
                  <div className="tmh-btn-icon-bubble" aria-hidden="true">
                    <ShieldAlert size={32} />
                  </div>
                  <div className="tmh-btn-copy">
                    <strong>{t('sos.callEmergency', 'CALL EMERGENCY (112)')} — {emergencyConfig.emergencyNumber}</strong>
                    <span>National Emergency / Police (India)</span>
                  </div>
                </button>

                {/* 3. Location Box & Share */}
                <div className="tmh-location-panel">
                  <div className="tmh-location-info">
                    <div className="tmh-loc-header">
                      <MapPin size={22} className="tmh-loc-icon" aria-hidden="true" />
                      <strong>{t('sos.myLocation', 'YOUR CURRENT LOCATION')}</strong>
                    </div>

                    <p className="tmh-coords-text">
                      Latitude: <b>{currentCoords.latitude}</b> • Longitude: <b>{currentCoords.longitude}</b>
                    </p>

                    <p className="tmh-dist-text">
                      🏠 {t('safety.distance', 'Distance to Home')}: <b>{distanceKm !== null ? `${distanceKm} km` : '1.2 km'}</b>
                    </p>

                    {currentCoords.error && (
                      <p className="tmh-loc-error">{currentCoords.error}</p>
                    )}

                    {shareSuccessMessage && (
                      <div className="tmh-share-banner" role="status">
                        <Check size={16} aria-hidden="true" />
                        <span>{shareSuccessMessage}</span>
                      </div>
                    )}
                  </div>

                  <div className="tmh-location-btns">
                    <button
                      type="button"
                      className="btn btn-secondary tmh-loc-btn"
                      onClick={fetchLocation}
                      disabled={loadingGps}
                      aria-label="Refresh your current GPS location"
                    >
                      <RotateCcw size={18} className={loadingGps ? 'spin' : ''} aria-hidden="true" />
                      <span>{loadingGps ? t('common.loading', 'Locating...') : t('safety.refreshGps', 'Refresh GPS')}</span>
                    </button>

                    <button
                      type="button"
                      className="btn btn-primary tmh-loc-btn"
                      onClick={shareLocation}
                      aria-label="Share location with caregiver"
                    >
                      <Share2 size={18} aria-hidden="true" />
                      <span>{t('sos.shareLocation', 'Share My Location')}</span>
                    </button>
                  </div>
                </div>

                {/* 4. Return to Take Me Home */}
                <button
                  type="button"
                  className="tmh-sos-action-btn tmh-btn-return"
                  onClick={() => setViewMode('navigation')}
                  aria-label="Return to Take Me Home directions screen"
                >
                  <div className="tmh-btn-icon-bubble" aria-hidden="true">
                    <Home size={30} />
                  </div>
                  <div className="tmh-btn-copy">
                    <strong>{t('sos.takeMeHome', 'TAKE ME HOME')}</strong>
                    <span>Return to direction guidance</span>
                  </div>
                </button>
              </div>
            </section>
          </div>
        )}

        {/* Safety Notice Required by Specification */}
        <footer className="tmh-safety-notice">
          <HeartHandshake size={18} aria-hidden="true" />
          <p>
            {t('sos.safetyNotice', 'If you are lost or feel unsafe, stay in a public place and call your caregiver or 112 immediately.')}
          </p>
        </footer>
      </main>

      {/* ========================================================== */}
      {/* ACCIDENTAL CALL PROTECTION CONFIRMATION DIALOG             */}
      {/* ========================================================== */}
      {callConfirmation && (
        <div className="modal-backdrop" role="dialog" aria-modal="true">
          <div className="modal tmh-confirm-modal">
            {callConfirmation.type === 'missing_caregiver' ? (
              <>
                <div className="tmh-confirm-icon amber">
                  <AlertTriangle size={36} aria-hidden="true" />
                </div>
                <h2>{callConfirmation.title}</h2>
                <p className="tmh-confirm-desc">{callConfirmation.message}</p>
                <div className="tmh-modal-actions">
                  <button
                    type="button"
                    className="btn btn-primary tmh-confirm-full-btn"
                    onClick={() => setCallConfirmation(null)}
                    autoFocus
                  >
                    {t('common.close', 'Got it')}
                  </button>
                </div>
              </>
            ) : (
              <>
                <div className={`tmh-confirm-icon ${callConfirmation.type === 'emergency' ? 'red' : 'teal'}`}>
                  {callConfirmation.type === 'emergency' ? (
                    <ShieldAlert size={36} aria-hidden="true" />
                  ) : (
                    <Phone size={36} aria-hidden="true" />
                  )}
                </div>

                <h2>{callConfirmation.title}</h2>

                <p className="tmh-confirm-desc">
                  {t('sos.confirmMessage', 'You are about to call')} <strong>{callConfirmation.name}</strong>:
                </p>

                <div className="tmh-confirm-phone-pill">
                  {callConfirmation.phone}
                </div>

                <div className="tmh-modal-actions">
                  <button
                    type="button"
                    className="btn btn-secondary tmh-confirm-btn"
                    onClick={() => setCallConfirmation(null)}
                  >
                    <X size={20} aria-hidden="true" />
                    <span>{t('sos.confirmCancel', 'CANCEL')}</span>
                  </button>

                  <button
                    type="button"
                    className={`btn ${callConfirmation.type === 'emergency' ? 'tmh-btn-call-emergency' : 'btn-primary'} tmh-confirm-btn`}
                    onClick={() => executeCall(callConfirmation.phone)}
                    autoFocus
                  >
                    <Phone size={20} aria-hidden="true" />
                    <span>{t('sos.confirmYes', 'YES, CALL')} {callConfirmation.type === 'emergency' ? callConfirmation.phone : ''}</span>
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
