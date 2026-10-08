const { initializeApp, cert } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const serviceAccount = require("./serviceAccountKey.json");

const app = initializeApp({
  credential: cert(serviceAccount),
});

const auth = getAuth(app);
const db = getFirestore(app);

async function makeAdmin() {
  // CHANGE THIS TO THE ADMIN EMAIL
  const adminEmail = process.env.ADMIN_EMAIL;

  try {
    // Find the Firebase Authentication user
    const user = await auth.getUserByEmail(adminEmail);

    console.log("Found user:");
    console.log("UID:", user.uid);
    console.log("Email:", user.email);

    // Set Firebase Authentication custom claim
    await auth.setCustomUserClaims(user.uid, {
      admin: true,
    });

    // Create/update Firestore user profile
    await db.collection("users").doc(user.uid).set(
      {
        uid: user.uid,
        role: "admin",
        email: user.email,
        fullName: "MindCare Administrator",
        accountStatus: "active",
        updatedAt: FieldValue.serverTimestamp(),
      },
      {
        merge: true,
      }
    );

    console.log("");
    console.log("================================");
    console.log("ADMIN CREATED SUCCESSFULLY");
    console.log("================================");
    console.log("UID:", user.uid);
    console.log("Email:", user.email);
    console.log("Firestore role: admin");
    console.log("Custom claim: admin = true");
    console.log("");
    console.log("Sign out and sign in again in the Flutter app.");
  } catch (error) {
    console.error("ERROR:", error);
  }
}

makeAdmin();