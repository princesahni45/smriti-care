import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

/**
 * Priority 2 — Patient code redemption Cloud Function.
 *
 * Secure server-side redemption ensuring:
 * 1. Anonymous clients NEVER read patientAccessCodes directly (zero PII exposure).
 * 2. Atomic mutual linking with race condition and concurrent request protection via Firestore transaction.
 * 3. Validation of caller authentication, code existence, active status, unlinked status, and expiry.
 * 4. Immutable binding of patientSessions/{uid} to caller's UID.
 * 5. Returns strictly the minimal necessary data ({ success, patientId, patientName }).
 */
export const verifyAndLinkPatientCode = onCall(async (request) => {
  // 1. Validate caller authentication
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError(
      "unauthenticated",
      "Authentication required. Anonymous sign-in must precede code verification."
    );
  }

  const callerUid = request.auth.uid;

  // 2. Validate input code
  const rawCode = request.data?.code;
  if (!rawCode || typeof rawCode !== "string") {
    throw new HttpsError("invalid-argument", "Access code is required.");
  }

  const cleanCode = rawCode.trim().toUpperCase();
  if (cleanCode.length < 7) {
    throw new HttpsError("invalid-argument", "Invalid access code format.");
  }

  const codeRef = db.collection("patientAccessCodes").doc(cleanCode);
  const sessionRef = db.collection("patientSessions").doc(callerUid);

  try {
    return await db.runTransaction(async (transaction) => {
      // 3. Read access code document inside transaction
      const codeSnap = await transaction.get(codeRef);
      if (!codeSnap.exists) {
        throw new HttpsError(
          "not-found",
          "That code is not correct. Please ask your caregiver to check it."
        );
      }

      const codeData = codeSnap.data()!;

      // 4. Validate active status
      if (codeData.isActive !== true) {
        throw new HttpsError(
          "failed-precondition",
          "This code is no longer active. Please ask your caregiver for a new code."
        );
      }

      // 5. Validate unlinked status (prevent reuse / race conditions)
      if (codeData.isLinked === true) {
        throw new HttpsError(
          "already-exists",
          "This code has already been linked to a device. Please ask your caregiver for a new code."
        );
      }

      // 6. Validate expiry (supports both Firestore Timestamp and legacy ISO string)
      const now = admin.firestore.Timestamp.now();
      if (codeData.expiresAtTimestamp) {
        const exp = codeData.expiresAtTimestamp as admin.firestore.Timestamp;
        if (exp.toMillis() <= now.toMillis()) {
          throw new HttpsError(
            "failed-precondition",
            "This code has expired. Please ask your caregiver for a new code."
          );
        }
      } else if (codeData.expiresAt && typeof codeData.expiresAt === "string") {
        const expDate = new Date(codeData.expiresAt);
        if (expDate.getTime() <= Date.now()) {
          throw new HttpsError(
            "failed-precondition",
            "This code has expired. Please ask your caregiver for a new code."
          );
        }
      }

      // 7. Validate patientId
      const targetPatientId = codeData.patientId;
      if (!targetPatientId || typeof targetPatientId !== "string") {
        throw new HttpsError("internal", "Code record contains invalid patient mapping.");
      }

      // 8. Prevent rebinding existing session to a different patient
      const sessionSnap = await transaction.get(sessionRef);
      if (sessionSnap.exists) {
        const existingSession = sessionSnap.data()!;
        if (existingSession.patientId && existingSession.patientId !== targetPatientId) {
          throw new HttpsError(
            "permission-denied",
            "This device session is already bound to another patient. Cannot rebind."
          );
        }
      }

      // 9. Execute atomic writes
      transaction.update(codeRef, {
        isLinked: true,
        linkedUid: callerUid,
        linkedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      transaction.set(sessionRef, {
        patientId: targetPatientId,
        code: cleanCode,
        anonymousUid: callerUid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isLinked: true,
      });

      // 10. Return MINIMAL data needed by client (zero caregiver PII, no internal keys)
      return {
        success: true,
        patientId: targetPatientId,
        patientName: codeData.patientName || "Patient",
      };
    });
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", (error as Error).message);
  }
});
