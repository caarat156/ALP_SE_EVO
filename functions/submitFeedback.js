const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cloud Function to submit feedback for an event.
 * Saves the feedback doc, and aggregates the EO rating on their profile document.
 */
exports.submitFeedback = functions.https.onCall(async (data, context) => {
  // Authentication check (for 3-Tier Security)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const { id, eventId, pesertaId, rating, comment, type } = data;

  if (!eventId || !pesertaId || rating === undefined) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "eventId, pesertaId, and rating are required."
    );
  }

  const feedbackId = id || db.collection("feedback").doc().id;
  const feedbackRef = db.collection("feedback").doc(feedbackId);

  try {
    const result = await db.runTransaction(async (transaction) => {
      // 1. Fetch Event to find creator (EO / Panitia ID)
      const eventRef = db.collection("events").doc(eventId);
      const eventDoc = await transaction.get(eventRef);

      if (!eventDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Event not found.");
      }

      const eventData = eventDoc.data();
      const eoId = eventData.created_by;

      if (!eoId) {
        throw new functions.https.HttpsError("failed-precondition", "Event organizer ID is missing.");
      }

      // 2. Save feedback document
      const feedbackData = {
        id: feedbackId,
        event_id: eventId,
        peserta_id: pesertaId,
        target_id: eoId,
        rating: Number(rating),
        comment: comment || "",
        type: type || "panitia",
        created_at: admin.firestore.FieldValue.serverTimestamp()
      };
      transaction.set(feedbackRef, feedbackData);

      // 3. Query all previous feedbacks for this EO to aggregate average rating
      const allFeedbacksQuery = await db.collection("feedback")
        .where("target_id", "==", eoId)
        .get();

      let totalRatingSum = Number(rating);
      let count = 1;

      allFeedbacksQuery.forEach((doc) => {
        if (doc.id !== feedbackId) {
          const fb = doc.data();
          totalRatingSum += Number(fb.rating || 0);
          count += 1;
        }
      });

      const averageRating = totalRatingSum / count;

      // 4. Update the EO's profile doc in users collection
      const eoUserRef = db.collection("users").doc(eoId);
      transaction.update(eoUserRef, {
        averageRating: Number(averageRating.toFixed(2)),
        ratingCount: count
      });

      return { status: "success", averageRating, ratingCount: count };
    });

    return result;

  } catch (error) {
    console.error("Submit feedback transaction failed: ", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      "internal",
      error.message || "An error occurred during feedback submission."
    );
  }
});
