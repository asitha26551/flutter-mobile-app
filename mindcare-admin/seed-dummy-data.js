const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

const serviceAccount = require('./serviceAccountKey.json');

const COUNSELOR_ID = '5aPcHFRSnxcaWEQXeMC1TfvMdAf2';
const BATCH_ID = 'counselor-test-data-001';
const DAY_MS = 24 * 60 * 60 * 1000;

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const students = [
  ['student-test-001', 'Avery Sen', 'avery.sen+mindcare-test@example.com', 'MC-ST-2601', 'Faculty of Computing', 'Software Engineering', 'BSc Software Engineering', 'Year 2', '2025/2026'],
  ['student-test-002', 'Maya Perera', 'maya.perera+mindcare-test@example.com', 'MC-ST-2602', 'Faculty of Business', 'Business Administration', 'BBA Business Administration', 'Year 3', '2024/2025'],
  ['student-test-003', 'Noah Wijesinghe', 'noah.wijesinghe+mindcare-test@example.com', 'MC-ST-2603', 'Faculty of Engineering', 'Electrical Engineering', 'BSc Electrical Engineering', 'Year 1', '2026/2027'],
  ['student-test-004', 'Lina Fernando', 'lina.fernando+mindcare-test@example.com', 'MC-ST-2604', 'Faculty of Arts', 'Digital Media', 'BA Digital Media', 'Year 2', '2025/2026'],
  ['student-test-005', 'Ethan Jayawardena', 'ethan.jayawardena+mindcare-test@example.com', 'MC-ST-2605', 'Faculty of Science', 'Environmental Science', 'BSc Environmental Science', 'Year 4', '2023/2024'],
  ['student-test-006', 'Sofia Raman', 'sofia.raman+mindcare-test@example.com', 'MC-ST-2606', 'Faculty of Health Sciences', 'Public Health', 'BSc Public Health', 'Year 3', '2024/2025'],
].map(([uid, fullName, email, studentId, faculty, department, degreeProgram, academicYear, batch]) => ({
  uid, fullName, email, studentId, faculty, department, degreeProgram, academicYear, batch,
  alias: `Student#${studentId.slice(-4)}`,
  priorityLevel: 'normal',
  authorizedCounselorIds: [COUNSELOR_ID],
  phoneNumber: '+94 70 555 01' + uid.slice(-1),
  whatsappNumber: '+94 71 555 01' + uid.slice(-1),
  enrollmentStatus: 'active',
}));

const reasons = [
  'Academic workload',
  'Examination pressure',
  'Difficulty managing study routine',
  'General personal concerns',
  'Time-management difficulties',
];

function localDate(daysFromToday, hour, minute = 0) {
  const date = new Date();
  date.setHours(0, 0, 0, 0);
  date.setTime(date.getTime() + daysFromToday * DAY_MS);
  date.setHours(hour, minute, 0, 0);
  return date;
}

function timestamp(date) {
  return Timestamp.fromDate(date);
}

function addDays(date, days) {
  return new Date(date.getTime() + days * DAY_MS);
}

function appointment(id, studentIndex, daysFromToday, hour, status, sessionType, reasonIndex, extra = {}) {
  const start = localDate(daysFromToday, hour);
  const end = addDays(start, 0);
  end.setMinutes(end.getMinutes() + 45);
  const created = status === 'completed' ? addDays(start, -10) : addDays(new Date(), -1);
  return {
    id,
    studentId: students[studentIndex].uid,
    counselorId: COUNSELOR_ID,
    appointmentDate: timestamp(start),
    startAt: timestamp(start),
    endAt: timestamp(end),
    startTime: `${String(start.getHours()).padStart(2, '0')}:00`,
    endTime: `${String(end.getHours()).padStart(2, '0')}:${String(end.getMinutes()).padStart(2, '0')}`,
    sessionType,
    status,
    reason: reasons[reasonIndex % reasons.length],
    studentNotes: 'Fictional test request for dashboard and appointment workflow coverage.',
    createdAt: timestamp(created),
    updatedAt: timestamp(created),
    isDummyData: true,
    dummyDataBatchId: BATCH_ID,
    ...extra,
  };
}

function availability(id, daysFromToday, startTime, endTime, sessionDuration) {
  const date = localDate(daysFromToday, 0);
  return {
    id,
    counselorId: COUNSELOR_ID,
    dayOfWeek: date.toLocaleDateString('en-US', { weekday: 'long' }),
    startTime,
    endTime,
    sessionDuration,
    isAvailable: true,
    createdAt: timestamp(new Date()),
    updatedAt: timestamp(new Date()),
    isDummyData: true,
    dummyDataBatchId: BATCH_ID,
  };
}

function sessionNote(id, appointmentRecord, summary, observations, followUpPlan) {
  return {
    id,
    appointmentId: appointmentRecord.id,
    studentId: appointmentRecord.studentId,
    counselorId: COUNSELOR_ID,
    summary,
    observations,
    followUpPlan,
    note: summary,
    createdAt: appointmentRecord.endAt,
    updatedAt: appointmentRecord.endAt,
    isDummyData: true,
    dummyDataBatchId: BATCH_ID,
  };
}

function notification(id, title, body, type, relatedId, isRead, daysAgo) {
  return {
    id,
    userId: COUNSELOR_ID,
    title,
    body,
    type,
    relatedId,
    isRead,
    createdAt: timestamp(addDays(new Date(), -daysAgo)),
    isDummyData: true,
    dummyDataBatchId: BATCH_ID,
  };
}

const availabilityRecords = Array.from({ length: 7 }, (_, index) =>
  availability(`dummy-availability-${String(index + 1).padStart(3, '0')}`, index, '09:00', '12:00', 45),
);

const appointmentRecords = [
  appointment('dummy-appointment-001', 0, 0, 9, 'pending', 'chat', 0),
  appointment('dummy-appointment-002', 1, 0, 10, 'confirmed', 'video', 1, { meetingLink: 'https://example.com/mindcare-test-meeting/appointment-002' }),
  appointment('dummy-appointment-003', 2, 1, 9, 'confirmed', 'audio', 2),
  appointment('dummy-appointment-004', 3, 1, 10, 'confirmed', 'in_person', 3, { location: 'MindCare Test Counseling Room, North Campus' }),
  appointment('dummy-appointment-005', 4, 2, 9, 'pending', 'chat', 4),
  appointment('dummy-appointment-006', 5, 2, 10, 'confirmed', 'video', 0, { meetingLink: 'https://example.com/mindcare-test-meeting/appointment-006' }),
  appointment('dummy-appointment-007', 0, 4, 9, 'confirmed', 'in_person', 1, { location: 'MindCare Test Counseling Room, North Campus' }),
  appointment('dummy-appointment-008', 1, 4, 10, 'pending', 'audio', 2),
  appointment('dummy-appointment-009', 2, 5, 9, 'confirmed', 'chat', 3),
  appointment('dummy-appointment-010', 3, 6, 9, 'confirmed', 'video', 4, { meetingLink: 'https://example.com/mindcare-test-meeting/appointment-010' }),
  appointment('dummy-appointment-011', 4, 6, 10, 'cancelled', 'chat', 0, { cancellationReason: 'Student requested a different appointment time.', cancelledBy: students[4].uid }),
  appointment('dummy-appointment-012', 0, -3, 9, 'completed', 'chat', 0),
  appointment('dummy-appointment-013', 0, -10, 10, 'completed', 'video', 1, { meetingLink: 'https://example.com/mindcare-test-meeting/appointment-013' }),
  appointment('dummy-appointment-014', 1, -5, 9, 'completed', 'in_person', 2, { location: 'MindCare Test Counseling Room, North Campus' }),
  appointment('dummy-appointment-015', 2, -8, 10, 'completed', 'audio', 3),
  appointment('dummy-appointment-016', 3, -14, 9, 'completed', 'chat', 4),
];

const completedAppointments = appointmentRecords.filter(({ status }) => status === 'completed');
const sessionNotes = completedAppointments.map((record, index) => sessionNote(
  `dummy-session-note-${String(index + 1).padStart(3, '0')}`,
  record,
  'Student discussed balancing academic responsibilities and maintaining a consistent study routine.',
  ['Student was engaged and identified manageable changes to their weekly schedule.', 'Student described moderate study-related pressure and responded well to planning prompts.', 'Student reflected on workload patterns and selected one priority for the coming week.', 'Student participated thoughtfully and identified existing routines that are working well.', 'Student reviewed recent academic demands and discussed practical ways to protect rest time.'][index],
  'Try a structured weekly plan, take regular breaks, and review progress in a future session if needed.',
));

const notificationRecords = [
  notification('dummy-notification-001', 'New Appointment Request', 'A student has submitted a new counseling appointment request.', 'appointment', 'dummy-appointment-001', false, 0),
  notification('dummy-notification-002', 'Upcoming Counseling Session', 'You have a counseling session scheduled for tomorrow.', 'appointment_reminder', 'dummy-appointment-003', false, 0),
  notification('dummy-notification-003', 'New Appointment Request', 'A student has submitted a new counseling appointment request.', 'appointment', 'dummy-appointment-005', false, 1),
  notification('dummy-notification-004', 'Appointment Cancelled', 'A student cancelled an upcoming counseling appointment.', 'appointment_cancelled', 'dummy-appointment-011', true, 1),
  notification('dummy-notification-005', 'Previous Session Completed', 'A previous counseling session has been marked completed.', 'system', 'dummy-appointment-012', true, 3),
  notification('dummy-notification-006', 'Upcoming Counseling Session', 'You have a counseling session scheduled for this week.', 'appointment_reminder', 'dummy-appointment-007', false, 2),
  notification('dummy-notification-007', 'New Appointment Request', 'A student has submitted a new counseling appointment request.', 'appointment', 'dummy-appointment-008', true, 2),
  notification('dummy-notification-008', 'MindCare Test Data', 'This is a fictional notification for dashboard testing.', 'system', null, true, 4),
  notification('dummy-notification-009', 'Upcoming Counseling Session', 'You have a counseling session scheduled for this week.', 'appointment_reminder', 'dummy-appointment-010', false, 1),
  notification('dummy-notification-010', 'Previous Session Completed', 'A previous counseling session has been marked completed.', 'system', 'dummy-appointment-016', true, 6),
];

const generated = [
  ['users', students],
  ['students', students],
  ['counselor_availability', availabilityRecords],
  ['appointments', appointmentRecords],
  ['session_notes', sessionNotes],
  ['notifications', notificationRecords],
];

async function assertSafeToSeed() {
  const counselor = await db.collection('counselors').doc(COUNSELOR_ID).get();
  if (!counselor.exists) throw new Error(`Counselor does not exist: counselors/${COUNSELOR_ID}`);
  const counselorData = counselor.data();
  if (counselorData.verificationStatus !== 'approved' || counselorData.accountStatus !== 'active') {
    throw new Error('The existing counselor must be approved and active; no counselor data was changed.');
  }

  for (const [collection] of generated) {
    const snapshot = await db.collection(collection).where('dummyDataBatchId', '==', BATCH_ID).limit(1).get();
    if (!snapshot.empty) throw new Error(`Dummy batch already exists in ${collection}; refusing to duplicate it.`);
  }
}

async function seed() {
  await assertSafeToSeed();
  const batch = db.batch();
  for (const [collection, records] of generated) {
    for (const record of records) {
      const documentId = collection === 'users' || collection === 'students' ? record.uid : record.id;
      const reference = db.collection(collection).doc(documentId);
      const data = { ...record };
      delete data.id;
      if (collection === 'users' || collection === 'students') {
        data.createdAt = timestamp(new Date());
        data.updatedAt = timestamp(new Date());
      }
      if (collection === 'users') {
        Object.assign(data, { role: 'student', accountStatus: 'active', verificationStatus: null, emailVerified: false });
      }
      batch.create(reference, data);
    }
  }
  await batch.commit();
  console.log('MindCare Dummy Data Created');
  console.log(`Counselor: ${COUNSELOR_ID}`);
  console.log(`Students created: ${students.length}`);
  console.log(`Availability records: ${availabilityRecords.length}`);
  console.log(`Pending appointments: ${appointmentRecords.filter((item) => item.status === 'pending').length}`);
  console.log(`Confirmed appointments: ${appointmentRecords.filter((item) => item.status === 'confirmed').length}`);
  console.log(`Completed appointments: ${completedAppointments.length}`);
  console.log(`Cancelled appointments: ${appointmentRecords.filter((item) => item.status === 'cancelled').length}`);
  console.log(`Session notes: ${sessionNotes.length}`);
  console.log(`Notifications: ${notificationRecords.length}`);
  console.log('Date range: Previous sessions before today; upcoming appointments today through day 7.');
  for (const [collection, records] of generated) {
    const ids = records.map((record) => record.id ?? record.uid);
    console.log(`${collection}: ${ids.join(', ')}`);
  }
}

seed().catch((error) => {
  console.error(`Dummy data was not created: ${error.message}`);
  process.exitCode = 1;
});