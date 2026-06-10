const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const HMAC_SECRET = "evo-secret-key-123456";

/**
 * Cloud Function to register a participant for an event.
 * Using a Firestore transaction to prevent overbooking by verifying
 * that registeredCount is strictly less than quota.
 */
exports.registerEvent = functions.https.onCall(async (data, context) => {
  // Authentication check (for 3-Tier Architecture Security)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const { pesertaId, eventId } = data;

  if (!pesertaId || !eventId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "pesertaId and eventId are required parameters."
    );
  }

  const eventRef = db.collection("events").doc(eventId);
  const ticketId = db.collection("tickets").doc().id; // Pre-generate ticket ID
  const ticketRef = db.collection("tickets").doc(ticketId);

  try {
    const result = await db.runTransaction(async (transaction) => {
      const eventDoc = await transaction.get(eventRef);

      if (!eventDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Event does not exist.");
      }

      const eventData = eventDoc.data();
      const quota = eventData.quota || 0;
      const registeredCount = eventData.registered_count || 0;

      // Logic check to prevent quota leak / overbooking
      if (registeredCount >= quota) {
        throw new functions.https.HttpsError(
          "resource-exhausted",
          "Event quota is fully booked."
        );
      }

      // Check if ticket already exists for this participant & event
      const existingTicketsQuery = await transaction.get(
        db.collection("tickets")
          .where("event_id", "==", eventId)
          .where("peserta_id", "==", pesertaId)
          .limit(1)
      );

      if (!existingTicketsQuery.empty) {
        throw new functions.https.HttpsError(
          "already-exists",
          "Participant is already registered for this event."
        );
      }

      // 1. Update registered count on the event
      transaction.update(eventRef, {
        registered_count: registeredCount + 1
      });

      // Generate payload & cryptographic HMAC-SHA256 signature
      const timestamp = Date.now();
      const payload = `${ticketId}|${eventId}|${pesertaId}|${timestamp}`;
      const signature = crypto
        .createHmac("sha256", HMAC_SECRET)
        .update(payload)
        .digest("hex");
      
      // Combine payload and signature into the QR code data
      const encryptedData = Buffer.from(`${payload}|${signature}`).toString("base64");

      const ticketData = {
        id: ticketId,
        event_id: eventId,
        peserta_id: pesertaId,
        status: "active",
        encrypted_data: encryptedData,
        created_at: admin.firestore.FieldValue.serverTimestamp()
      };

      // 2. Create the ticket document
      transaction.set(ticketRef, ticketData);

      return { ticketId, status: "success" };
    });

    return result;

  } catch (error) {
    console.error("Transaction failed: ", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      "internal",
      error.message || "An error occurred during registration."
    );
  }
});
