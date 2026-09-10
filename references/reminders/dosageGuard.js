/**
 * src/reminders/dosageGuard.js
 *
 * MindCare NER — Medication Dosage Restriction Guard
 *
 * POLICY ENFORCEMENT:
 * MindCare NER is strictly for cognitive support and routine schedule reminders.
 * It is NOT a medical advice, clinical prescription, or dosage management system.
 * Caregivers are prohibited from entering pharmaceutical dosage amounts
 * (e.g., "5mg", "500 mg", "2 tablets", "10ml", "2 pills") into reminder titles or messages.
 */

// Regex patterns to detect pharmaceutical dosage amounts and instructions
const DOSAGE_PATTERNS = [
  // Numbers followed by weight/volume units: e.g. 5mg, 500 mg, 0.5mcg, 10ml, 2g, 100iu
  /\b\d+(\.\d+)?\s*(mg|milligrams?|mcg|micrograms?|ml|milliliters?|g|grams?|iu|units?)\b/i,

  // Numbers followed by pill/tablet/capsule counts: e.g. 2 tablets, 1 pill, 3 capsules, 5 drops
  /\b\d+\s*(tablets?|pills?|capsules?|drops?|teaspoons?|tablespoons?|tbsp|tsp|puffs?)\b/i,

  // Explicit dosage keywords: e.g. "dosage: 10", "dose 20"
  /\b(dosage|dose|prescribe|prescription)\s*[:=]?\s*\d+/i,
]

/**
 * Checks text for prohibited medication dosage entries.
 *
 * @param {string} text - Title or message string to test
 * @returns {{ hasDosage: boolean, matched: string|null, message: string }}
 */
export function checkDosageSafety(text) {
  if (!text || typeof text !== 'string') {
    return { hasDosage: false, matched: null, message: '' }
  }

  for (const pattern of DOSAGE_PATTERNS) {
    const match = text.match(pattern)
    if (match) {
      return {
        hasDosage: true,
        matched: match[0],
        message:
          `MindCare NER is for routine reminders only. Prescription dosages (e.g. "${match[0]}") cannot be entered. Please use a routine prompt title like "Morning medicine" or "Afternoon medicine".`,
      }
    }
  }

  return { hasDosage: false, matched: null, message: '' }
}
