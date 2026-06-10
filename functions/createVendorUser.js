const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cloud Function to create a Vendor.
 * Registers the vendor user account in Firebase Auth and saves
 * corresponding Firestore documents in 'users' and 'vendors' collections.
 */
exports.createVendorUser = functions.https.onCall(async (data, context) => {
  // Authorization Check - Admin only
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  // Double check user role is indeed admin
  const callerUserDoc = await db.collection("users").doc(context.auth.uid).get();
  if (!callerUserDoc.exists || callerUserDoc.data().role !== "admin") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only administrators are authorized to add vendors."
    );
  }

  const { name, email, phone } = data;

  if (!name || !email) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Vendor name and email are required fields."
    );
  }

  try {
    // 1. Create Auth User in Firebase Auth
    const defaultPassword = "password"; // Default temporary password
    const userRecord = await admin.auth().createUser({
      email: email,
      emailVerified: true,
      password: defaultPassword,
      displayName: name
    });

    const uid = userRecord.uid;

    const batch = db.batch();

    // 2. Add to 'users' collection
    const userRef = db.collection("users").doc(uid);
    const userData = {
      id: uid,
      email: email,
      name: name,
      role: "vendor",
      created_at: admin.firestore.FieldValue.serverTimestamp()
    };
    batch.set(userRef, userData);

    // 3. Add to 'vendors' collection
    const vendorRef = db.collection("vendors").doc(uid);
    const vendorData = {
      id: uid,
      name: name,
      email: email,
      phone: phone || null,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    };
    batch.set(vendorRef, vendorData);

    // Commit batch write
    await batch.commit();

    return { status: "success", uid, email };

  } catch (error) {
    console.error("Failed to create vendor user: ", error);
    if (error.code === "auth/email-already-in-use") {
      throw new functions.https.HttpsError(
        "already-exists",
        "The email address is already in use by another account."
      );
    }
    throw new functions.https.HttpsError(
      "internal",
      error.message || "An error occurred while creating the vendor user."
    );
  }
});
