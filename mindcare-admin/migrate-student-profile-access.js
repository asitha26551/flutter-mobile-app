const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function migrate() {
  const appointments = await db.collection('appointments').get();
  const counselorsByStudent = new Map();

  for (const document of appointments.docs) {
    const data = document.data();
    const studentId = data.studentId || data.userId;
    const counselorId = data.counselorId;
    if (!studentId || !counselorId) continue;
    const counselors = counselorsByStudent.get(studentId) ?? new Set();
    counselors.add(counselorId);
    counselorsByStudent.set(studentId, counselors);
  }

  const batch = db.batch();
  let changed = 0;
  for (const [studentId, counselorIds] of counselorsByStudent) {
    const reference = db.collection('students').doc(studentId);
    const snapshot = await reference.get();
    if (!snapshot.exists) continue;
    const data = snapshot.data() || {};
    const changes = {
      authorizedCounselorIds: Array.from(counselorIds),
      priorityLevel: data.priorityLevel || 'normal',
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (!data.alias && data.studentId) {
      changes.alias = `Student#${String(data.studentId).slice(-4)}`;
    }
    batch.update(reference, changes);
    changed += 1;
  }

  if (changed > 0) await batch.commit();
  console.log(`Migrated ${changed} student profiles.`);
}

migrate().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
