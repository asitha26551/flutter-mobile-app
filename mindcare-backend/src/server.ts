import 'dotenv/config';
import express from 'express';
import { getApps, initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth, type DecodedIdToken } from 'firebase-admin/auth';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';

const firebaseApp =
  getApps()[0] ??
  initializeApp({
    credential: applicationDefault(),
  });

const db = getFirestore(firebaseApp);
const firebaseAuth = getAuth(firebaseApp);

const app = express();
const PORT = Number(process.env.PORT ?? '3000');

app.use(express.json());

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

for (const route of appointmentConfirmRoutes) {
  app.post(route, handleConfirmAppointment);
  app.patch(route, handleConfirmAppointment);
  app.put(route, handleConfirmAppointment);
}

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
}): Promise<{ joinUrl: string; startUrl: string }> {
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
    join_url?: string;
    start_url?: string;
  };

  if (!payload.join_url || !payload.start_url) {
    throw new Error('Zoom meeting response missing join_url or start_url');
  }

  return {
    joinUrl: payload.join_url,
    startUrl: payload.start_url,
  };
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

    if (sessionType === 'video') {
      const meeting = await createZoomMeeting({
        appointmentId,
        startAt: appointmentStart,
        durationMinutes,
      });
      joinUrl = meeting.joinUrl;
      startUrl = meeting.startUrl;
    }

    const updatedValues: Record<string, unknown> = {
      status: 'confirmed',
      updatedAt: FieldValue.serverTimestamp(),
      meetingLink: joinUrl ?? (typeof appointmentData.meetingLink === 'string' ? appointmentData.meetingLink : null),
    };

    await appointmentSnapshot.ref.update(updatedValues);

    if (sessionType === 'video' && startUrl) {
      await db.collection('zoomMeetings').doc(appointmentId).set(
        {
          appointmentId,
          startUrl,
          joinUrl: joinUrl ?? null,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

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
