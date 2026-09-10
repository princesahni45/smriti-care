import { useState } from 'react'
import {
  ShieldAlert, Phone, MapPin, Edit3, Trash2, Plus, Check, X, AlertCircle, Home
} from 'lucide-react'
import {
  getEmergencyContact,
  saveEmergencyContact,
  deleteEmergencyContact,
  getHomeLocation,
  saveHomeLocation,
  getEmergencyConfig,
  saveEmergencyConfig,
  validatePhoneNumber
} from './emergencyContactService'
import { useTranslation } from '../i18n'
import './CaregiverEmergencySection.css'

export default function CaregiverEmergencySection({ onPreviewTakeMeHome }) {
  const { t } = useTranslation()
  const [contact, setContact] = useState(getEmergencyContact)
  const [homeLocation, setHomeLocation] = useState(getHomeLocation)
  const [emergencyConfig, setEmergencyConfig] = useState(getEmergencyConfig)

  // Edit Modals
  const [editingContact, setEditingContact] = useState(false)
  const [editingHome, setEditingHome] = useState(false)
  const [editingConfig, setEditingConfig] = useState(false)

  // Contact Form State
  const [formName, setFormName] = useState('')
  const [formRel, setFormRel] = useState('')
  const [formPhone, setFormPhone] = useState('')
  const [formSecPhone, setFormSecPhone] = useState('')
  const [contactError, setContactError] = useState('')

  // Home Form State
  const [formAddress, setFormAddress] = useState('')
  const [formLat, setFormLat] = useState('')
  const [formLng, setFormLng] = useState('')

  // Emergency Config Form State
  const [formNumber, setFormNumber] = useState('')
  const [formLabel, setFormLabel] = useState('')
  const [formCountry, setFormCountry] = useState('')

  // Open Contact Modal
  const openContactModal = () => {
    setFormName(contact?.name || '')
    setFormRel(contact?.relationship || '')
    setFormPhone(contact?.phone || '')
    setFormSecPhone(contact?.secondaryPhone || '')
    setContactError('')
    setEditingContact(true)
  }

  const handleSaveContact = (e) => {
    e.preventDefault()
    setContactError('')

    const res = saveEmergencyContact({
      name: formName,
      relationship: formRel,
      phone: formPhone,
      secondaryPhone: formSecPhone,
    })

    if (!res.success) {
      setContactError(res.error)
      return
    }

    setContact(res.contact)
    setEditingContact(false)
  }

  const handleDeleteContact = () => {
    if (window.confirm('Are you sure you want to clear the emergency caregiver contact?')) {
      deleteEmergencyContact()
      setContact(null)
    }
  }

  // Open Home Location Modal
  const openHomeModal = () => {
    setFormAddress(homeLocation?.address || '')
    setFormLat(String(homeLocation?.latitude || '26.1856'))
    setFormLng(String(homeLocation?.longitude || '91.7539'))
    setEditingHome(true)
  }

  const handleSaveHome = (e) => {
    e.preventDefault()
    const res = saveHomeLocation({
      address: formAddress,
      latitude: parseFloat(formLat) || 26.1856,
      longitude: parseFloat(formLng) || 91.7539,
    })
    if (res.success) {
      setHomeLocation(res.location)
      setEditingHome(false)
    }
  }

  // Open Emergency Config Modal
  const openConfigModal = () => {
    setFormNumber(emergencyConfig?.emergencyNumber || '112')
    setFormLabel(emergencyConfig?.label || 'National Emergency Response Support System')
    setFormCountry(emergencyConfig?.country || 'India')
    setEditingConfig(true)
  }

  const handleSaveConfig = (e) => {
    e.preventDefault()
    const res = saveEmergencyConfig({
      emergencyNumber: formNumber,
      label: formLabel,
      country: formCountry,
    })
    if (res.success) {
      setEmergencyConfig(res.config)
      setEditingConfig(false)
    }
  }

  return (
    <section className="dash-card ces-card" aria-labelledby="ces-heading">
      <div className="card-title">
        <div>
          <p className="dash-kicker">{t('safety.safetyResponse') || 'SAFETY & RESPONSE'}</p>
          <h2 id="ces-heading">{t('safety.emergencySettings') || 'Emergency & Safety Settings'}</h2>
        </div>
        <span className="icon-bubble coral" aria-hidden="true">
          <ShieldAlert size={20} />
        </span>
      </div>

      <p className="ces-intro">
        {t('safety.emergencySettingsDesc') || "These settings are used by the patient's Take Me Home compass and SOS emergency screen. All data is stored securely in local offline storage."}
      </p>

      <div className="ces-grid">
        {/* 1. Primary Caregiver Contact */}
        <div className="ces-setting-box">
          <div className="ces-box-header">
            <span className="ces-icon-bubble teal" aria-hidden="true"><Phone size={18} /></span>
            <div className="ces-box-title">
              <h3>{t('safety.primaryCaregiver') || 'Primary Caregiver'}</h3>
              <p>{t('safety.directContactPatient') || 'Direct contact for patient SOS calls'}</p>
            </div>
          </div>

          {contact?.phone ? (
            <div className="ces-contact-details">
              <p className="ces-contact-name">
                <strong>{contact.name}</strong> <span>• {contact.relationship}</span>
              </p>
              <p className="ces-contact-phone">📞 {contact.phone}</p>
              {contact.secondaryPhone && (
                <p className="ces-contact-sec-phone">{t('safety.familyPhone') || 'Family phone'}: {contact.secondaryPhone}</p>
              )}
              <div className="ces-btn-row">
                <button
                  type="button"
                  className="ces-action-btn edit"
                  onClick={openContactModal}
                  aria-label={t('safety.editContact') || "Edit caregiver emergency contact"}
                >
                  <Edit3 size={15} aria-hidden="true" /> {t('safety.editContact') || 'Edit Contact'}
                </button>
                <button
                  type="button"
                  className="ces-action-btn delete"
                  onClick={handleDeleteContact}
                  aria-label={t('safety.remove') || "Delete caregiver emergency contact"}
                >
                  <Trash2 size={15} aria-hidden="true" /> {t('safety.remove') || 'Remove'}
                </button>
              </div>
            </div>
          ) : (
            <div className="ces-empty-state">
              <p>{t('safety.noCaregiverPhone') || 'No caregiver phone number configured.'}</p>
              <button
                type="button"
                className="btn btn-primary ces-add-btn"
                onClick={openContactModal}
              >
                <Plus size={16} aria-hidden="true" /> {t('safety.addEmergencyContact') || 'Add Emergency Contact'}
              </button>
            </div>
          )}
        </div>

        {/* 2. Home Location Settings */}
        <div className="ces-setting-box">
          <div className="ces-box-header">
            <span className="ces-icon-bubble blue" aria-hidden="true"><Home size={18} /></span>
            <div className="ces-box-title">
              <h3>{t('safety.homeLocation') || 'Home Location'}</h3>
              <p>{t('safety.targetTakeMeHome') || 'Target location for Take Me Home guidance'}</p>
            </div>
          </div>

          <div className="ces-location-details">
            <p className="ces-loc-address">
              <MapPin size={16} aria-hidden="true" />
              <strong>{homeLocation.address}</strong>
            </p>
            <p className="ces-loc-coords">
              {t('safety.coordinates') || 'Coordinates'}: {homeLocation.latitude}, {homeLocation.longitude}
            </p>
            <button
              type="button"
              className="ces-action-btn edit"
              onClick={openHomeModal}
              aria-label={t('safety.changeHomeLocation') || "Set or change saved home location"}
            >
              <Edit3 size={15} aria-hidden="true" /> {t('safety.changeHomeLocation') || 'Change Home Location'}
            </button>
          </div>
        </div>

        {/* 3. National Emergency Helpline */}
        <div className="ces-setting-box">
          <div className="ces-box-header">
            <span className="ces-icon-bubble coral" aria-hidden="true"><ShieldAlert size={18} /></span>
            <div className="ces-box-title">
              <h3>{t('safety.emergencyHelpline') || 'Emergency Services Helpline'}</h3>
              <p>{t('safety.nationalResponseNumber') || 'National emergency response number'}</p>
            </div>
          </div>

          <div className="ces-config-details">
            <p className="ces-config-number">
              <strong>{emergencyConfig.emergencyNumber}</strong> ({emergencyConfig.country})
            </p>
            <p className="ces-config-label">{emergencyConfig.label}</p>
            <button
              type="button"
              className="ces-action-btn edit"
              onClick={openConfigModal}
              aria-label={t('safety.configureNumber') || "Configure emergency number"}
            >
              <Edit3 size={15} aria-hidden="true" /> {t('safety.configureNumber') || 'Configure Number'}
            </button>
          </div>
        </div>
      </div>

      {onPreviewTakeMeHome && (
        <div className="ces-preview-footer">
          <button
            type="button"
            className="ces-preview-btn"
            onClick={onPreviewTakeMeHome}
          >
            🧭 {t('patient.takeMeHomeSOS') || 'Open Take Me Home & SOS View'}
          </button>
        </div>
      )}

      {/* ── Modal: Edit Caregiver Contact ─────────────────────────── */}
      {editingContact && (
        <div className="modal-backdrop" role="dialog" aria-modal="true">
          <div className="modal ces-modal">
            <button
              type="button"
              className="modal-x"
              onClick={() => setEditingContact(false)}
              aria-label="Close dialog"
            >
              <X size={20} />
            </button>

            <h2>Emergency Contact Setup</h2>
            <p className="ces-modal-sub">
              Enter the phone number that should ring when the patient taps <strong>Call Caregiver</strong> in an emergency.
            </p>

            {contactError && (
              <div className="ces-error-banner" role="alert">
                <AlertCircle size={16} aria-hidden="true" />
                <span>{contactError}</span>
              </div>
            )}

            <form onSubmit={handleSaveContact} className="ces-form">
              <label>
                Caregiver Name *
                <input
                  type="text"
                  value={formName}
                  onChange={(e) => setFormName(e.target.value)}
                  placeholder="e.g. Rahul Das"
                  required
                />
              </label>

              <label>
                Relationship *
                <input
                  type="text"
                  value={formRel}
                  onChange={(e) => setFormRel(e.target.value)}
                  placeholder="e.g. Son, Daughter, Nurse"
                  required
                />
              </label>

              <label>
                Primary Caregiver Phone Number *
                <input
                  type="tel"
                  value={formPhone}
                  onChange={(e) => setFormPhone(e.target.value)}
                  placeholder="e.g. +91 98765 43210"
                  required
                />
              </label>

              <label>
                Secondary Family Phone Number (Optional)
                <input
                  type="tel"
                  value={formSecPhone}
                  onChange={(e) => setFormSecPhone(e.target.value)}
                  placeholder="e.g. +91 98765 01234"
                />
              </label>

              <div className="ces-form-actions">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setEditingContact(false)}
                >
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  <Check size={18} aria-hidden="true" /> Save Emergency Contact
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── Modal: Edit Home Location ─────────────────────────────── */}
      {editingHome && (
        <div className="modal-backdrop" role="dialog" aria-modal="true">
          <div className="modal ces-modal">
            <button
              type="button"
              className="modal-x"
              onClick={() => setEditingHome(false)}
              aria-label="Close dialog"
            >
              <X size={20} />
            </button>

            <h2>Set Home Location</h2>
            <p className="ces-modal-sub">
              This address and coordinates are used to guide the patient home.
            </p>

            <form onSubmit={handleSaveHome} className="ces-form">
              <label>
                Home Address / Description
                <input
                  type="text"
                  value={formAddress}
                  onChange={(e) => setFormAddress(e.target.value)}
                  placeholder="e.g. Ambari, Guwahati, Assam"
                  required
                />
              </label>

              <div className="ces-coords-row">
                <label>
                  Latitude
                  <input
                    type="number"
                    step="0.0001"
                    value={formLat}
                    onChange={(e) => setFormLat(e.target.value)}
                    required
                  />
                </label>
                <label>
                  Longitude
                  <input
                    type="number"
                    step="0.0001"
                    value={formLng}
                    onChange={(e) => setFormLng(e.target.value)}
                    required
                  />
                </label>
              </div>

              <div className="ces-form-actions">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setEditingHome(false)}
                >
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  <Check size={18} aria-hidden="true" /> Save Home Location
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── Modal: Configure Emergency Helpline ───────────────────── */}
      {editingConfig && (
        <div className="modal-backdrop" role="dialog" aria-modal="true">
          <div className="modal ces-modal">
            <button
              type="button"
              className="modal-x"
              onClick={() => setEditingConfig(false)}
              aria-label="Close dialog"
            >
              <X size={20} />
            </button>

            <h2>Emergency Number Configuration</h2>
            <p className="ces-modal-sub">
              Configured default is 112 (National Emergency Response Support System - India).
            </p>

            <form onSubmit={handleSaveConfig} className="ces-form">
              <label>
                Emergency Number
                <input
                  type="text"
                  value={formNumber}
                  onChange={(e) => setFormNumber(e.target.value)}
                  placeholder="112"
                  required
                />
              </label>

              <label>
                Service Label
                <input
                  type="text"
                  value={formLabel}
                  onChange={(e) => setFormLabel(e.target.value)}
                  placeholder="e.g. National Emergency Services"
                  required
                />
              </label>

              <label>
                Country / Region
                <input
                  type="text"
                  value={formCountry}
                  onChange={(e) => setFormCountry(e.target.value)}
                  placeholder="e.g. India"
                  required
                />
              </label>

              <div className="ces-form-actions">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setEditingConfig(false)}
                >
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  <Check size={18} aria-hidden="true" /> Save Configuration
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </section>
  )
}
