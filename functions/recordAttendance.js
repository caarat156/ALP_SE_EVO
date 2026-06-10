const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const HMAC_SECRET = "evo-secret-key-123456";

/**
 * Cloud Function to record attendance by scanning QR code.
 * Verifies HMAC signature before marking ticket as used.
 */
exports.recordAttendance = functions.https.onCall(async (data, context) => {
  // Authentication check (for 3-Tier Security)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const { eventId, scannedCode } = data;

  if (!eventId || !scannedCode) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "eventId and scannedCode are required."
    );
  }

  // Decode from Base64 if needed
  let decodedCode = scannedCode;
  try {
    const buffer = Buffer.from(scannedCode, "base64");
    const decodedString = buffer.toString("utf8");
    if (decodedString.includes("|")) {
      decodedCode = decodedString;
    }
  } catch (err) {
    // Keep raw scannedCode if Base64 decoding fails or isn't Base64
  }

  const parts = decodedCode.split("|");
  if (parts.length < 5) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Invalid QR code format."
    );
  }

  const ticketId = parts[0];
  const ticketEventId = parts[1];
  const pesertaId = parts[2];
  const timestamp = parts[3];
  const signature = parts[4];

  // 1. Verify Event ID matches
  if (ticketEventId !== eventId) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "This ticket is not for this event."
    );
  }

  // 2. Verify Cryptographic HMAC Signature
  const expectedPayload = `${ticketId}|${ticketEventId}|${pesertaId}|${timestamp}`;
  const expectedSignature = crypto
    .createHmac("sha256", HMAC_SECRET)
    .update(expectedPayload)
    .digest("hex");

  if (signature !== expectedSignature) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Invalid ticket signature (security breach detected)."
    );
  }

  const ticketRef = db.collection("tickets").doc(ticketId);

  try {
    const result = await db.runTransaction(async (transaction) => {
      const ticketDoc = await transaction.get(ticketRef);

      if (!ticketDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Ticket does not exist."
        );
      }

      const ticketData = ticketDoc.data();
      if (ticketData.status === "used") {
        throw new functions.https.HttpsError(
          "already-exists",
          "Ticket has already been scanned and used."
        );
      }

      // Update ticket status
      transaction.update(ticketRef, {
        status: "used",
        used_at: admin.firestore.FieldValue.serverTimestamp()
      });

      return { status: "success", message: "Check-in successful!" };
    });

    return result;

  } catch (error) {
    console.error("Attendance check-in transaction failed: ", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      "internal",
      error.message || "An error occurred during check-in."
    );
  }
});
