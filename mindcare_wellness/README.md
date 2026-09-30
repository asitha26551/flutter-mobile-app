# MindCare Wellness
## Admin setup

There is no public admin registration. Admin authorization uses a Firebase
Authentication custom claim and a matching `users/{uid}` profile:

```js
await getAuth().setCustomUserClaims(uid, { admin: true });
await getFirestore().doc(`users/${uid}`).set({
	uid,
	role: 'admin',
	accountStatus: 'active',
	emailVerified: true,
	updatedAt: FieldValue.serverTimestamp(),
}, { merge: true });
```

Run this only from a trusted Firebase Admin SDK environment, such as a local
one-time setup script or an HTTPS callable Cloud Function restricted to an
existing administrator. Never expose Admin SDK credentials in Flutter. The
administrator must sign out and back in, or refresh the ID token, after the
claim is assigned. Flutter uses the profile role for routing, while rules use
the `admin` claim for authorization.

Deploy the rules from the project root with:

```text
firebase deploy --only firestore:rules
```

## Admin capabilities

Admins enter through the existing login screen and are routed by `AuthGate` to
the admin dashboard. The dashboard shows student, counselor, pending,
approved, rejected, and suspended counts. User management supports search by
name, email, and student/staff ID; status filtering; student suspension and
reactivation; counselor review; approval; rejection with a required reason;
and counselor suspension/reactivation. Each privileged decision creates an
`adminActions/{actionId}` audit record with actor, action, target, role, and a
server timestamp.

Counselor registration creates `users/{uid}` and `counselors/{uid}` with
`role: counselor`, `accountStatus: pending`, and
`verificationStatus: pending`. Email verification alone does not grant access.
Counselors reach their dashboard only when email is verified, verification is
approved, and the account is active. Rejected and suspended accounts remain
in Firestore and are blocked by `AuthGate`.

The rules prevent normal users from changing roles, account status, or
verification fields and prevent non-admin users from reading administrative
collections. Student private counseling data is not read by admin views.
