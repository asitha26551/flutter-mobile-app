import 'dotenv/config';
import express from 'express';
import { getApps, initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth, type DecodedIdToken } from 'firebase-admin/auth';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';

const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

const firebaseApp =
  getApps()[0] ??
  initializeApp({
    credential: serviceAccountJson
      ? cert(JSON.parse(serviceAccountJson))
      : applicationDefault(),
  });

const db = getFirestore(firebaseApp);
const firebaseAuth = getAuth(firebaseApp);

const app = express();
const PORT = Number(process.env.PORT ?? '3000');

app.use(express.json());

const configuredCorsOrigins = new Set(
  (process.env.MINDCARE_CORS_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
);
const localDevelopmentOrigin = /^https?:\/\/(localhost|127\.0\.0\.1|\[::1\])(:\d+)?$/i;

app.use((req, res, next) => {
  const origin = req.get('origin');
  const allowed = !origin || configuredCorsOrigins.has(origin) || localDevelopmentOrigin.test(origin);
  if (origin && allowed) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, PUT, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    if (req.get('access-control-request-private-network') === 'true') {
      res.setHeader('Access-Control-Allow-Private-Network', 'true');
    }
  }
  if (req.method === 'OPTIONS') {
    res.sendStatus(allowed ? 204 : 403);
    return;
  }
  next();
});

app.get('/', (_req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'mindcare-backend',
    health: '/health',
  });
});

app.get('/health', (_req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'mindcare-backend',
  });
});

const appointmentConfirmRoutes = [
  '/appointments/:appointmentId/confirm',
  '/api/appointments/:appointmentId/confirm',
  '/counselor/appointments/:appointmentId/confirm',
];

const appointmentRejectRoutes = [
  '/appointments/:appointmentId/reject',
  '/api/appointments/:appointmentId/reject',
];

const appointmentRescheduleRoutes = [
  '/appointments/:appointmentId/reschedule',
  '/api/appointments/:appointmentId/reschedule',
];

const appointmentHostLinkRoutes = [
  '/appointments/:appointmentId/host-link',
  '/api/appointments/:appointmentId/host-link',
];

for (const route of appointmentConfirmRoutes) {
  app.post(route, handleConfirmAppointment);
  app.patch(route, handleConfirmAppointment);
  app.put(route, handleConfirmAppointment);
}
for (const route of appointmentRejectRoutes) app.post(route, handleRejectAppointment);
for (const route of appointmentRescheduleRoutes) app.post(route, handleRescheduleAppointment);
for (const route of appointmentHostLinkRoutes) app.get(route, handleHostLink);

function getAuthorizationToken(headerValue: string | undefined): string | null {
  if (!headerValue) {
    return null;
  }

  const trimmed = headerValue.trim();
  if (!trimmed) {
    return null;
  }

  if (/^Bearer\s+/i.test(trimmed)) {
    return trimmed.replace(/^Bearer\s+/i, '').trim();
  }

  return trimmed;
}

function toDate(value: unknown): Date {
  if (value instanceof Timestamp) {
    return value.toDate();
  }

  if (value instanceof Date) {
    return value;
  }

  if (typeof value === 'string' || typeof value === 'number') {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }

  if (value && typeof value === 'object' && 'toDate' in value) {
    const maybeDate = value as { toDate?: () => Date };
    if (typeof maybeDate.toDate === 'function') {
      return maybeDate.toDate();
    }
  }

  throw new Error('Invalid date value');
}

function getSessionType(data: Record<string, unknown>): string {
  const value = String(data.sessionType ?? data.type ?? 'chat');
  return value.toLowerCase();
}

function normalizeStatus(value: unknown): string {
  return String(value ?? '').trim().toLowerCase();
}

function appointmentNotification(
  userId: string,
  appointmentId: string,
  title: string,
  body: string,
  type: string,
): Record<string, unknown> {
  return {
    userId,
    title,
    body,
    type,
    relatedId: appointmentId,
    isRead: false,
    createdAt: FieldValue.serverTimestamp(),
  };
}

function ensureAuthorizedCounselor(userData: Record<string, unknown>): boolean {
  return (
    String(userData.role ?? '') === 'counselor' &&
    String(userData.accountStatus ?? '') === 'active' &&
    String(userData.verificationStatus ?? '') === 'approved'
  );
}

async function fetchZoomAccessToken(): Promise<string> {
  const accountId = process.env.ZOOM_ACCOUNT_ID;
  const clientId = process.env.ZOOM_CLIENT_ID;
  const clientSecret = process.env.ZOOM_CLIENT_SECRET;

  if (!accountId || !clientId || !clientSecret) {
    throw new Error('Zoom OAuth configuration is missing');
  }

  const authHeader = `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`;
  const query = new URLSearchParams({
    grant_type: 'account_credentials',
    account_id: accountId,
  });

  const response = await fetch(`https://zoom.us/oauth/token?${query.toString()}`, {
    method: 'POST',
    headers: {
      Authorization: authHeader,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Zoom OAuth token exchange failed (${response.status}): ${body}`);
  }

  const payload = (await response.json()) as { access_token?: string };

  if (!payload.access_token) {
    throw new Error('Zoom OAuth response did not include an access token');
  }

  return payload.access_token;
}

async function createZoomMeeting(input: {
  appointmentId: string;
  startAt: Date;
  durationMinutes: number;
}): Promise<{ meetingId: string; joinUrl: string; startUrl: string }> {
  const accessToken = await fetchZoomAccessToken();
  const response = await fetch('https://api.zoom.us/v2/users/me/meetings', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      topic: `MindCare Counseling Session ${input.appointmentId}`,
      type: 2,
      start_time: input.startAt.toISOString(),
      duration: Math.max(15, input.durationMinutes),
      timezone: 'UTC',
      settings: {
        host_video: true,
        participant_video: true,
        join_before_host: false,
        mute_upon_entry: true,
        waiting_room: false,
      },
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Zoom meeting creation failed (${response.status}): ${body}`);
  }

  const payload = (await response.json()) as {
    id?: string | number;
    join_url?: string;
    start_url?: string;
  };

  if (!payload.id || !payload.join_url || !payload.start_url) {
    throw new Error('Zoom meeting response missing id, join_url or start_url');
  }

  return {
    meetingId: String(payload.id),
    joinUrl: payload.join_url,
    startUrl: payload.start_url,
  };
}

async function updateZoomMeeting(input: {
  meetingId: string;
  startAt: Date;
  durationMinutes: number;
}): Promise<void> {
  const accessToken = await fetchZoomAccessToken();
  const response = await fetch(`https://api.zoom.us/v2/meetings/${encodeURIComponent(input.meetingId)}`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      start_time: input.startAt.toISOString(),
      duration: Math.max(15, input.durationMinutes),
      timezone: 'UTC',
    }),
  });
  if (!response.ok) {
    const body = await response.text();
    if (body.includes('4711') || body.includes('meeting:update:meeting')) {
      throw new Error(
        'The Zoom Server-to-Server OAuth app is missing meeting update permission. Add the meeting:update:meeting and meeting:update:meeting:admin scopes in the Zoom Marketplace app, activate the app, and restart the backend.',
      );
    }
    throw new Error(`Zoom meeting update failed (${response.status}): ${body}`);
  }
}

function meetingIdFromUrls(...values: unknown[]): string | null {
  for (const value of values) {
    if (typeof value !== 'string') continue;
    const match = value.match(/\/(?:j|s)\/(\d{6,})/);
    if (match?.[1]) return match[1];
  }
  return null;
}

async function getAuthorizedCounselor(req: express.Request, res: express.Response) {
  const idToken = getAuthorizationToken(req.headers.authorization);
  if (!idToken) {
    res.status(401).json({ error: 'Authorization header is required.' });
    return null;
  }
  try {
    const decodedToken = await firebaseAuth.verifyIdToken(idToken);
    const userSnapshot = await db.collection('users').doc(decodedToken.uid).get();
    const userData = (userSnapshot.data() ?? {}) as Record<string, unknown>;
    if (!userSnapshot.exists || !ensureAuthorizedCounselor(userData)) {
      res.status(403).json({ error: 'An active, approved counselor account is required.' });
      return null;
    }
    return decodedToken;
  } catch {
    res.status(401).json({ error: 'Invalid Firebase ID token.' });
    return null;
  }
}

function parseRequestedDate(value: unknown): Date {
  if (typeof value !== 'string' || !/(Z|[+-]\d{2}:?\d{2})$/i.test(value)) {
    throw new Error('A date with an explicit timezone is required.');
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) throw new Error('Invalid appointment date.');
  return date;
}

async function handleRejectAppointment(req: express.Request, res: express.Response): Promise<void> {
  const counselor = await getAuthorizedCounselor(req, res);
  if (!counselor) return;
  const appointmentId = String(req.params.appointmentId ?? '').trim();
  const rejectionReason = typeof req.body?.rejectionReason === 'string'
    ? req.body.rejectionReason.trim()
    : '';
  if (!rejectionReason) {
    res.status(400).json({ error: 'A rejection reason is required.' });
    return;
  }
  const ref = db.collection('appointments').doc(appointmentId);
  try {
    const snapshot = await ref.get();
    if (!snapshot.exists) { res.status(404).json({ error: 'Appointment not found.' }); return; }
    const appointment = snapshot.data() ?? {};
    if (appointment.counselorId !== counselor.uid) { res.status(403).json({ error: 'Counselor does not own this appointment.' }); return; }
    if (normalizeStatus(appointment.status) !== 'pending') { res.status(409).json({ error: 'Only pending appointments can be rejected.' }); return; }
    const batch = db.batch();
    batch.update(ref, { status: 'rejected', rejectionReason, updatedAt: FieldValue.serverTimestamp() });
    batch.set(db.collection('notifications').doc(`appointment_${appointmentId}_rejected`), appointmentNotification(
      String(appointment.studentId),
      appointmentId,
      'Appointment request declined',
      'Your counselor could not accept this appointment request.',
      'appointment_rejected',
    ));
    await batch.commit();
    res.status(200).json({ success: true, appointmentId, status: 'rejected' });
  } catch (error) {
    res.status(500).json({ error: error instanceof Error ? error.message : 'Unable to reject appointment.' });
  }
}

async function handleRescheduleAppointment(req: express.Request, res: express.Response): Promise<void> {
  const counselor = await getAuthorizedCounselor(req, res);
  if (!counselor) return;
  const appointmentId = String(req.params.appointmentId ?? '').trim();
  const ref = db.collection('appointments').doc(appointmentId);
  try {
    const startAt = parseRequestedDate(req.body?.startAt);
    const endAt = parseRequestedDate(req.body?.endAt);
    if (endAt <= startAt) { res.status(400).json({ error: 'Appointment end time must be after start time.' }); return; }
    const snapshot = await ref.get();
    if (!snapshot.exists) { res.status(404).json({ error: 'Appointment not found.' }); return; }
    const appointment = (snapshot.data() ?? {}) as Record<string, unknown>;
    const status = normalizeStatus(appointment.status);
    if (appointment.counselorId !== counselor.uid) { res.status(403).json({ error: 'Counselor does not own this appointment.' }); return; }
    if (!['confirmed', 'rescheduled'].includes(status)) { res.status(409).json({ error: 'Only confirmed appointments can be rescheduled.' }); return; }
    const sessionType = getSessionType(appointment);
    let meetingLink = typeof appointment.meetingLink === 'string' ? appointment.meetingLink : null;
    let meetingId: string | null = null;
    if (sessionType === 'video') {
      const meetingRef = db.collection('zoomMeetings').doc(appointmentId);
      const meetingSnapshot = await meetingRef.get();
      const stored = (meetingSnapshot.data() ?? {}) as Record<string, unknown>;
      const activeMeetingId = String(stored.zoomMeetingId ?? stored.meetingId ?? meetingIdFromUrls(stored.startUrl, stored.joinUrl) ?? '');
      const durationMinutes = Math.max(1, Math.round((endAt.getTime() - startAt.getTime()) / 60000));
      if (meetingSnapshot.exists && activeMeetingId) {
        await updateZoomMeeting({ meetingId: activeMeetingId, startAt, durationMinutes });
        meetingId = activeMeetingId;
        meetingLink = typeof stored.joinUrl === 'string' ? stored.joinUrl : meetingLink;
      } else if (meetingSnapshot.exists) {
        throw new Error('The existing Zoom meeting ID is unavailable; rescheduling was stopped to avoid creating a duplicate meeting.');
      } else {
        const meeting = await createZoomMeeting({ appointmentId, startAt, durationMinutes });
        meetingId = meeting.meetingId;
        meetingLink = meeting.joinUrl;
        await meetingRef.set({ appointmentId, zoomMeetingId: meeting.meetingId, startUrl: meeting.startUrl, joinUrl: meeting.joinUrl, createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      }
    }
    const batch = db.batch();
    batch.update(ref, { status: 'rescheduled', startAt: Timestamp.fromDate(startAt), endAt: Timestamp.fromDate(endAt), ...(sessionType === 'video' ? { meetingLink } : {}), updatedAt: FieldValue.serverTimestamp() });
    batch.set(db.collection('notifications').doc(`appointment_${appointmentId}_rescheduled_${startAt.getTime()}`), appointmentNotification(
      String(appointment.studentId),
      appointmentId,
      'Appointment rescheduled',
      'Your counselor proposed a new time for your appointment.',
      'appointment_rescheduled',
    ));
    await batch.commit();
    if (sessionType === 'video' && meetingId) {
      await db.collection('zoomMeetings').doc(appointmentId).set({ zoomMeetingId: meetingId, joinUrl: meetingLink, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    }
    res.status(200).json({ success: true, appointmentId, status: 'rescheduled', startAt: startAt.toISOString(), endAt: endAt.toISOString(), meetingLink });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unable to reschedule appointment.';
    res.status(message.includes('timezone') || message.includes('date') ? 400 : 500).json({ error: message });
  }
}

async function handleHostLink(req: express.Request, res: express.Response): Promise<void> {
  const counselor = await getAuthorizedCounselor(req, res);
  if (!counselor) return;
  const appointmentId = String(req.params.appointmentId ?? '').trim();
  const snapshot = await db.collection('appointments').doc(appointmentId).get();
  if (!snapshot.exists) { res.status(404).json({ error: 'Appointment not found.' }); return; }
  const appointment = snapshot.data() ?? {};
  if (appointment.counselorId !== counselor.uid) { res.status(403).json({ error: 'Counselor does not own this appointment.' }); return; }
  if (getSessionType(appointment) !== 'video' || !['confirmed', 'rescheduled'].includes(normalizeStatus(appointment.status))) {
    res.status(409).json({ error: 'Host link is unavailable for this appointment.' }); return;
  }
  const meeting = await db.collection('zoomMeetings').doc(appointmentId).get();
  const startUrl = meeting.data()?.startUrl;
  if (!meeting.exists || typeof startUrl !== 'string' || !startUrl) { res.status(404).json({ error: 'Host link not available.' }); return; }
  res.status(200).json({ startUrl });
}

async function handleConfirmAppointment(
  req: express.Request,
  res: express.Response,
): Promise<void> {
  const appointmentId = String(req.params.appointmentId ?? '').trim();

  if (!appointmentId) {
    res.status(400).json({ error: 'Appointment ID is required.' });
    return;
  }

  const idToken = getAuthorizationToken(req.headers.authorization);

  if (!idToken) {
    res.status(401).json({ error: 'Authorization header is required.' });
    return;
  }

  try {
    const decodedToken: DecodedIdToken = await firebaseAuth.verifyIdToken(idToken);
    const userSnapshot = await db.collection('users').doc(decodedToken.uid).get();

    if (!userSnapshot.exists) {
      res.status(403).json({ error: 'Counselor account not found.' });
      return;
    }

    const userData = (userSnapshot.data() ?? {}) as Record<string, unknown>;

    if (!ensureAuthorizedCounselor(userData)) {
      res.status(403).json({
        error: 'Counselor is not authorized to confirm appointments.',
      });
      return;
    }

    const appointmentSnapshot = await db.collection('appointments').doc(appointmentId).get();

    if (!appointmentSnapshot.exists) {
      res.status(404).json({ error: 'Appointment not found.' });
      return;
    }

    const appointmentData = (appointmentSnapshot.data() ?? {}) as Record<string, unknown>;
    const appointmentCounselorId = String(appointmentData.counselorId ?? '');
    const currentStatus = normalizeStatus(appointmentData.status);
    const sessionType = getSessionType(appointmentData);

    if (appointmentCounselorId !== decodedToken.uid) {
      res.status(403).json({ error: 'Counselor does not own this appointment.' });
      return;
    }

    if (currentStatus !== 'pending' && currentStatus !== 'rescheduled' && currentStatus !== 'confirmed') {
      res.status(409).json({
        error: `Appointment status ${currentStatus || 'unknown'} cannot be confirmed.`,
      });
      return;
    }

    const appointmentStart = toDate(appointmentData.startAt ?? appointmentData.appointmentDate);
    const appointmentEnd = appointmentData.endAt ? toDate(appointmentData.endAt) : null;

    if (appointmentEnd && appointmentEnd.getTime() <= appointmentStart.getTime()) {
      res.status(400).json({ error: 'Appointment end time must be after start time.' });
      return;
    }

    const durationMinutes = appointmentEnd
      ? Math.max(1, Math.round((appointmentEnd.getTime() - appointmentStart.getTime()) / 60000))
      : 60;

    let joinUrl: string | null = null;
    let startUrl: string | null = null;
    let zoomMeetingId: string | null = null;

    if (sessionType === 'video') {
      const meetingRef = db.collection('zoomMeetings').doc(appointmentId);
      const existingMeetingSnapshot = await meetingRef.get();
      const existingMeeting = (existingMeetingSnapshot.data() ?? {}) as Record<string, unknown>;
      if (existingMeetingSnapshot.exists && typeof existingMeeting.startUrl === 'string' && typeof existingMeeting.joinUrl === 'string') {
        zoomMeetingId = String(existingMeeting.zoomMeetingId ?? existingMeeting.meetingId ?? meetingIdFromUrls(existingMeeting.startUrl, existingMeeting.joinUrl) ?? '');
        joinUrl = existingMeeting.joinUrl;
        startUrl = existingMeeting.startUrl;
        if (!zoomMeetingId) throw new Error('The existing Zoom meeting ID is unavailable.');
        await updateZoomMeeting({ meetingId: zoomMeetingId, startAt: appointmentStart, durationMinutes });
        await meetingRef.set({ zoomMeetingId, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      } else {
      const meeting = await createZoomMeeting({
        appointmentId,
        startAt: appointmentStart,
        durationMinutes,
      });
      joinUrl = meeting.joinUrl;
      startUrl = meeting.startUrl;
      zoomMeetingId = meeting.meetingId;
      await meetingRef.set({
        appointmentId,
        zoomMeetingId,
        startUrl,
        joinUrl,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      }
    }

    const updatedValues: Record<string, unknown> = {
      status: 'confirmed',
      updatedAt: FieldValue.serverTimestamp(),
      meetingLink: joinUrl ?? (typeof appointmentData.meetingLink === 'string' ? appointmentData.meetingLink : null),
    };

    const batch = db.batch();
    batch.update(appointmentSnapshot.ref, updatedValues);
    if (currentStatus !== 'confirmed') {
      batch.set(db.collection('notifications').doc(`appointment_${appointmentId}_confirmed`), appointmentNotification(
        String(appointmentData.studentId),
        appointmentId,
        'Appointment confirmed',
        'Your counselor confirmed your appointment.',
        'appointment_confirmed',
      ));
    }
    await batch.commit();

    res.status(200).json({
      success: true,
      appointmentId,
      status: 'confirmed',
      sessionType,
      meetingLink: joinUrl ?? (typeof appointmentData.meetingLink === 'string' ? appointmentData.meetingLink : null),
      startUrl,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unable to confirm appointment.';
    if (message.includes('verifyIdToken') || message.includes('ID token')) {
      res.status(401).json({ error: 'Invalid Firebase ID token.' });
      return;
    }

    res.status(500).json({ error: message });
  }
}

export { app };
export default app;

if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`Mindcare backend running on port ${PORT}`);
  });
}
