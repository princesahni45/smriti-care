// test/rules_emulator/firestore_rules.spec.js
//
// Firestore Security Rules automated tests running against the Firebase Local Emulator
// via @firebase/rules-unit-testing.
//
// Tests:
// 1. Anonymous code reads denied (PII protection).
// 2. Caregiver profile PII protected (no anonymous reads via caregiverCode).
// 3. Caregiver code directory minimal lookup allowed for authenticated users.
// 4. Valid atomic redemption allowed via mutual getAfter() batch.
// 5. Expired code redemption denied.
// 6. Reused / already-linked code redemption denied.
// 7. Patient session rebinding denied (immutable sessions).
// 8. Patient ownership on dailySteps & game results.
// 9. Assigned-caregiver authorization scope.
// 10. Emergency settings access restricted to medical staff and verified patient.

const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'smriti-care-security-test';

describe('Smriti Care — Firestore Security Rules Test Suite', () => {
  let testEnv;

  before(async () => {
    const rulesPath = path.resolve(__dirname, '../../firestore.rules');
    const rulesContent = fs.readFileSync(rulesPath, 'utf8');

    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: rulesContent,
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    if (testEnv) {
      await testEnv.clearFirestore();
    }
  });

  // ── Priority 1: PII Protection Tests ──────────────────────────────────────────

  describe('Priority 1: PII Protection & Access Restrictions', () => {
    it('Denies direct patientAccessCodes reads to anonymous clients', async () => {
      // Seed code document as admin
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('patientAccessCodes').doc('SMR-4827-KP').set({
          code: 'SMR-4827-KP',
          patientId: 'MC-2048',
          patientName: 'Mr. Ramesh Das',
          caregiverId: 'cg_mohak_01',
          caregiverName: 'Mohak Singh',
          isActive: true,
          isLinked: false,
        });
      });

      // Anonymous client attempt
      const anonContext = testEnv.authenticatedContext('anon_user_123', {
        provider_id: 'anonymous',
      });
      const anonDb = anonContext.firestore();

      await assertFails(
        anonDb.collection('patientAccessCodes').doc('SMR-4827-KP').get()
      );
    });

    it('Protects Caregiver Profile PII: anonymous users cannot read full caregiver profile', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('caregivers').doc('cg_mohak_01').set({
          name: 'Mohak Singh',
          email: 'singhmohak360@gmail.com',
          phone: '+91 98765 43210',
          caregiverCode: 'CG-4827',
        });
      });

      const anonContext = testEnv.authenticatedContext('anon_user_123');
      const anonDb = anonContext.firestore();

      // Attempting to read caregiver profile using caregiverId must be denied
      await assertFails(
        anonDb.collection('caregivers').doc('cg_mohak_01').get()
      );

      // Caregiver self-read is allowed
      const caregiverContext = testEnv.authenticatedContext('cg_mohak_01');
      await assertSucceeds(
        caregiverContext.firestore().collection('caregivers').doc('cg_mohak_01').get()
      );
    });

    it('Allows authenticated lookup on minimal caregiverCodeDirectory without exposing private PII', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('caregiverCodeDirectory').doc('CG-4827').set({
          caregiverId: 'cg_mohak_01',
          caregiverName: 'Mohak Singh',
        });
      });

      const anonContext = testEnv.authenticatedContext('anon_user_123');
      await assertSucceeds(
        anonContext.firestore().collection('caregiverCodeDirectory').doc('CG-4827').get()
      );
    });
  });

  // ── Priority 2 & 3: Code Redemption & Session Immutability ──────────────────

  describe('Priority 2 & 3: Atomic Code Redemption & Session Immutability', () => {
    const validFutureTimestamp = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    const expiredTimestamp = new Date(Date.now() - 24 * 60 * 60 * 1000);

    it('Allows atomic batch redemption for valid unlinked code', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('patientAccessCodes').doc('SMR-7777-AA').set({
          code: 'SMR-7777-AA',
          patientId: 'patient_alpha',
          caregiverId: 'cg_01',
          isActive: true,
          isLinked: false,
          expiresAtTimestamp: validFutureTimestamp,
        });
      });

      const patientContext = testEnv.authenticatedContext('patient_device_uid');
      const db = patientContext.firestore();
      const batch = db.batch();

      batch.set(db.collection('patientSessions').doc('patient_device_uid'), {
        patientId: 'patient_alpha',
        code: 'SMR-7777-AA',
        anonymousUid: 'patient_device_uid',
        isLinked: true,
      });

      batch.update(db.collection('patientAccessCodes').doc('SMR-7777-AA'), {
        isLinked: true,
        linkedUid: 'patient_device_uid',
        linkedAt: new Date().toISOString(),
      });

      await assertSucceeds(batch.commit());
    });

    it('Denies redemption of an expired access code', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('patientAccessCodes').doc('SMR-EXPD-99').set({
          code: 'SMR-EXPD-99',
          patientId: 'patient_beta',
          caregiverId: 'cg_01',
          isActive: true,
          isLinked: false,
          expiresAtTimestamp: expiredTimestamp,
        });
      });

      const patientContext = testEnv.authenticatedContext('patient_device_exp');
      const db = patientContext.firestore();
      const batch = db.batch();

      batch.set(db.collection('patientSessions').doc('patient_device_exp'), {
        patientId: 'patient_beta',
        code: 'SMR-EXPD-99',
        anonymousUid: 'patient_device_exp',
        isLinked: true,
      });

      batch.update(db.collection('patientAccessCodes').doc('SMR-EXPD-99'), {
        isLinked: true,
        linkedUid: 'patient_device_exp',
        linkedAt: new Date().toISOString(),
      });

      await assertFails(batch.commit());
    });

    it('Denies reuse of an already-linked access code', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('patientAccessCodes').doc('SMR-USED-01').set({
          code: 'SMR-USED-01',
          patientId: 'patient_gamma',
          caregiverId: 'cg_01',
          isActive: true,
          isLinked: true,
          linkedUid: 'prior_device_uid',
          expiresAtTimestamp: validFutureTimestamp,
        });
      });

      const secondDeviceContext = testEnv.authenticatedContext('second_device_uid');
      const db = secondDeviceContext.firestore();
      const batch = db.batch();

      batch.set(db.collection('patientSessions').doc('second_device_uid'), {
        patientId: 'patient_gamma',
        code: 'SMR-USED-01',
        anonymousUid: 'second_device_uid',
        isLinked: true,
      });

      batch.update(db.collection('patientAccessCodes').doc('SMR-USED-01'), {
        isLinked: true,
        linkedUid: 'second_device_uid',
        linkedAt: new Date().toISOString(),
      });

      await assertFails(batch.commit());
    });

    it('Enforces session immutability: denies updating an existing patientSession', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('patientSessions').doc('device_uid_immut').set({
          patientId: 'patient_original',
          code: 'SMR-1111-XX',
          anonymousUid: 'device_uid_immut',
          isLinked: true,
        });
      });

      const deviceContext = testEnv.authenticatedContext('device_uid_immut');
      const db = deviceContext.firestore();

      // Attempt to rebind to another patient must fail
      await assertFails(
        db.collection('patientSessions').doc('device_uid_immut').update({
          patientId: 'patient_hijacked',
        })
      );
    });
  });

  // ── Resource Authorization & Ownership Tests ─────────────────────────────────

  describe('Resource Ownership: dailySteps, gameResults, emergency_settings', () => {
    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        // Patient session binding
        await context.firestore().collection('patientSessions').doc('verified_device').set({
          patientId: 'MC-2048',
          code: 'SMR-2048-KP',
          anonymousUid: 'verified_device',
          isLinked: true,
        });

        // Patient record with assigned caregiver
        await context.firestore().collection('patients').doc('MC-2048').set({
          patientName: 'Mr. Ramesh Das',
          caregiverId: 'assigned_cg_uid',
        });
      });
    });

    it('Allows verified patient to record daily steps for their assigned patientId only', async () => {
      const patientDb = testEnv.authenticatedContext('verified_device').firestore();

      // Write to verified patient ID -> allowed
      await assertSucceeds(
        patientDb.collection('patients').doc('MC-2048').collection('dailySteps').doc('2026-10-23').set({
          patientId: 'MC-2048',
          date: '2026-10-23',
          steps: 2500,
          goal: 5000,
          updatedAt: new Date().toISOString(),
          source: 'pedometer',
        })
      );

      // Attempt write to unassigned patient -> denied
      await assertFails(
        patientDb.collection('patients').doc('MC-9999').collection('dailySteps').doc('2026-10-23').set({
          patientId: 'MC-9999',
          date: '2026-10-23',
          steps: 2500,
          goal: 5000,
          updatedAt: new Date().toISOString(),
          source: 'pedometer',
        })
      );
    });

    it('Enforces cognitive game result score bounds (0-100) and immutability', async () => {
      const patientDb = testEnv.authenticatedContext('verified_device').firestore();

      // Score 85 -> allowed
      await assertSucceeds(
        patientDb.collection('patientGameResults').doc('game_res_valid').set({
          patientId: 'MC-2048',
          gameId: 'memory_match',
          score: 85,
          timestamp: new Date().toISOString(),
        })
      );

      // Score 150 (out of bounds) -> denied
      await assertFails(
        patientDb.collection('patientGameResults').doc('game_res_invalid').set({
          patientId: 'MC-2048',
          gameId: 'memory_match',
          score: 150,
          timestamp: new Date().toISOString(),
        })
      );

      // Updating a game result -> denied (strictly immutable event record)
      await assertFails(
        patientDb.collection('patientGameResults').doc('game_res_valid').update({
          score: 99,
        })
      );
    });

    it('Restricts emergency_settings writes to assigned caregiver only', async () => {
      // Assigned caregiver write -> allowed
      const assignedCgDb = testEnv.authenticatedContext('assigned_cg_uid', { role: 'caregiver' }).firestore();
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await ctx.firestore().collection('users').doc('assigned_cg_uid').set({ role: 'caregiver' });
      });

      await assertSucceeds(
        assignedCgDb.collection('patients').doc('MC-2048').collection('emergency_settings').doc('main').set({
          primaryNumber: '+91 98765 43210',
          secondaryNumber: '+91 91234 56780',
          updatedAt: new Date().toISOString(),
        })
      );

      // Unassigned caregiver write -> denied
      const unassignedCgDb = testEnv.authenticatedContext('unassigned_cg_uid', { role: 'caregiver' }).firestore();
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await ctx.firestore().collection('users').doc('unassigned_cg_uid').set({ role: 'caregiver' });
      });

      await assertFails(
        unassignedCgDb.collection('patients').doc('MC-2048').collection('emergency_settings').doc('main').set({
          primaryNumber: '+91 00000 00000',
        })
      );
    });
  });
});
