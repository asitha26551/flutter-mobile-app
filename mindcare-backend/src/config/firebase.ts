import { getApps, initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

const app =
  getApps()[0] ??
  initializeApp({
    credential: applicationDefault(),
  });

export const db = getFirestore(app);
export const firebaseAuth = getAuth(app);