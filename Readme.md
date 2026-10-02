# Flutter + Firebase Project Environment Setup

This guide explains how to set up a **Flutter + Firebase development environment** for a Flutter mobile application.

The setup includes:

* Flutter SDK
* Dart
* Visual Studio Code
* Android Studio
* Android SDK
* Android Emulator
* Firebase CLI
* FlutterFire CLI
* Firebase Authentication
* Cloud Firestore
* Firebase Storage

---

## 1. Prerequisites

Before creating the project, install the following:

| Software           | Purpose                                     |
| ------------------ | ------------------------------------------- |
| Flutter SDK        | Flutter application development             |
| Dart SDK           | Programming language used by Flutter        |
| Visual Studio Code | Code editor                                 |
| Android Studio     | Android SDK and emulator                    |
| Node.js            | Required for Firebase CLI                   |
| Firebase CLI       | Firebase project management                 |
| FlutterFire CLI    | Connects Flutter applications with Firebase |

---

# 2. Install Flutter

Download and install the Flutter SDK from the official Flutter website.

Example installation location:

```text
D:\flutter
```

Add the following directory to the Windows `PATH`:

```text
D:\flutter\bin
```

Verify the installation:

```powershell
flutter --version
```

Then run:

```powershell
flutter doctor
```

`flutter doctor` checks whether the required Flutter development components are installed correctly.

---

# 3. Install Visual Studio Code

Install Visual Studio Code.

Install the following extensions:

* Flutter
* Dart

After installing the extensions, restart Visual Studio Code if necessary.

Verify Flutter again:

```powershell
flutter doctor
```

---

# 4. Install Android Studio

Android Studio is required for Android development because it provides:

* Android SDK
* Android SDK Platform
* Android SDK Build-Tools
* Android SDK Command-line Tools
* Android Emulator
* Android SDK Platform-Tools

Open:

```text
Android Studio
    → SDK Manager
```

Make sure the required Android SDK components are installed.

Then accept the Android licenses:

```powershell
flutter doctor --android-licenses
```

Accept the required licenses.

Finally:

```powershell
flutter doctor
```

Resolve any remaining Android-related issues before continuing.

---

# 5. Create an Android Emulator

Open Android Studio:

```text
Android Studio
    → Device Manager
    → Create Virtual Device
```

For example:

```text
Device: Pixel
System Image: Google APIs
Architecture: x86_64
```

Start the emulator.

Check whether Flutter detects it:

```powershell
flutter devices
```

You should see an Android device similar to:

```text
sdk gphone16k x86 64
```

---

# 6. Test Flutter

Before connecting Firebase, verify that Flutter can create and run an application.

Create a temporary project:

```powershell
flutter create test_app
```

Enter the project:

```powershell
cd test_app
```

Run the application:

```powershell
flutter run
```

If the default Flutter application opens successfully on the Android emulator, the Flutter and Android environment is working correctly.

---

# 7. Install Node.js

Firebase CLI requires Node.js.

Verify the installation:

```powershell
node --version
```

and:

```powershell
npm --version
```

If these commands do not work, install Node.js before continuing.

---

# 8. Install Firebase CLI

Install Firebase CLI globally:

```powershell
npm install -g firebase-tools
```

Verify:

```powershell
firebase --version
```

Log in to Firebase:

```powershell
firebase login
```

A browser window will open. Sign in using the Google account associated with your Firebase projects.

Check your Firebase projects:

```powershell
firebase projects:list
```

---

# 9. Install FlutterFire CLI

FlutterFire CLI is used to connect a Flutter project to a Firebase project.

Install it using:

```powershell
dart pub global activate flutterfire_cli
```

Verify:

```powershell
flutterfire --version
```

If Windows cannot find the `flutterfire` command, make sure the Dart Pub Cache `bin` directory is included in your Windows `PATH`.

Usually:

```text
%LOCALAPPDATA%\Pub\Cache\bin
```

Restart VS Code or PowerShell after changing the PATH.

---

# 10. Create a Firebase Project

Open the Firebase Console:

https://console.firebase.google.com/

Select:

```text
Create a project
```

Example:

```text
Project name:
MindCare Wellness
```

Firebase will generate a unique project ID.

Example:

```text
mindcare-wellness-xxxxx
```

Keep this Firebase project associated with your Flutter application.

---

# 11. Create the Flutter Project

Navigate to the directory where you keep your projects:

```powershell
cd C:\Users\YourName\Documents\GitHub
```

Create the Flutter project:

```powershell
flutter create mindcare
```

Enter the project:

```powershell
cd mindcare
```

Open the project in Visual Studio Code:

```powershell
code .
```

The basic project structure will look like:

```text
mindcare/
├── android/
├── ios/
├── lib/
│   └── main.dart
├── test/
├── pubspec.yaml
├── analysis_options.yaml
└── .gitignore
```

---

# 12. Connect Flutter to Firebase

Make sure you are inside the Flutter project:

```powershell
cd C:\Users\YourName\Documents\GitHub\mindcare
```

Make sure you are logged into Firebase:

```powershell
firebase login
```

Run:

```powershell
flutterfire configure
```

FlutterFire will ask you to:

1. Select your Firebase account.
2. Select the Firebase project.
3. Select the platforms.
4. Configure the Firebase application.

For an Android-only application, select:

```text
Android
```

FlutterFire will generate:

```text
lib/firebase_options.dart
```

This file contains the Firebase configuration required by the Flutter application.

---

# 13. Add Firebase Core

Add Firebase Core:

```powershell
flutter pub add firebase_core
```

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('MindCare Wellness'),
        ),
      ),
    );
  }
}
```

Run the application:

```powershell
flutter run
```

If the application starts without a Firebase initialization error, Flutter is successfully connected to Firebase.

---

# 14. Enable Firebase Authentication

Open:

```text
Firebase Console
    → Build
    → Authentication
    → Get started
```

Enable:

```text
Email/Password
```

Add Firebase Authentication to Flutter:

```powershell
flutter pub add firebase_auth
```

Import it when required:

```dart
import 'package:firebase_auth/firebase_auth.dart';
```

Firebase Authentication will handle:

* User registration
* Login
* Logout
* Password management
* Email verification
* Firebase UID

Passwords should **not** be stored in Firestore.

---

# 15. Enable Cloud Firestore

Open:

```text
Firebase Console
    → Build
    → Firestore Database
    → Create database
```

Add Firestore to Flutter:

```powershell
flutter pub add cloud_firestore
```

Import:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
```

Firestore can then be used for application data such as:

```text
users
students
counselors
appointments
messages
notifications
```

---

# 16. Initialize Firebase in the Flutter Project

Inside the Flutter project, run:

```powershell
firebase init
```

Select the Firebase services required by the project.

For a Flutter + Firebase application, Firestore is one of the main services.

This can create files such as:

```text
firebase.json
firestore.rules
firestore.indexes.json
```

These files should normally be committed to Git.

---

# 17. Firebase Storage

Firebase Storage can be used when the application needs to store files such as:

* Profile pictures
* Counselor verification documents
* Chat attachments

Add Firebase Storage:

```powershell
flutter pub add firebase_storage
```

Enable Storage from:

```text
Firebase Console
    → Build
    → Storage
```

Storage security rules should be configured before using Storage in production.

---

# 18. MindCare Wellness Firestore Structure

For the MindCare Wellness application, the planned Firestore structure is:

```text
Firestore
│
├── users
├── students
├── counselors
├── counselor_availability
├── appointments
├── conversations
├── messages
├── notifications
├── mood_entries
├── journal_entries
├── session_notes
└── admin_actions
```

### users

Stores common information about authenticated users.

Example:

```text
users/{uid}

uid
role
fullName
email
phoneNumber
whatsappNumber
profileImageUrl
emailVerified
accountStatus
createdAt
updatedAt
```

Roles:

```text
student
counselor
admin
```

Passwords must never be stored here.

---

### students

Stores student-specific information:

```text
students/{uid}

uid
studentId
faculty
department
degreeProgram
academicYear
batch
enrollmentStatus
createdAt
updatedAt
```

---

### counselors

Stores counselor professional information:

```text
counselors/{uid}

uid
counselorId
department
qualifications
specializations
yearsOfExperience
registrationNumber
registrationBody
professionalBio
languages
sessionTypes
officeLocation
verificationStatus
accountStatus
createdAt
updatedAt
```

Counselor verification status can be:

```text
pending
approved
rejected
```

---

### counselor_availability

Stores counselor availability:

```text
counselor_availability/{availabilityId}

counselorId
dayOfWeek
startTime
endTime
sessionDuration
isAvailable
createdAt
updatedAt
```

---

### appointments

Stores counseling appointments:

```text
appointments/{appointmentId}

studentId
counselorId
appointmentDate
startTime
endTime
sessionType
status
reason
meetingLink
location
studentNotes
cancellationReason
cancelledBy
createdAt
updatedAt
```

Appointment statuses:

```text
pending
confirmed
rejected
cancelled
rescheduled
completed
no_show
```

---

### conversations

Stores counseling conversations:

```text
conversations/{conversationId}

studentId
counselorId
appointmentId
status
lastMessage
lastMessageAt
createdAt
updatedAt
```

---

### messages

Stores individual chat messages:

```text
messages/{messageId}

conversationId
senderId
receiverId
messageType
message
attachmentUrl
isRead
sentAt
```

---

### notifications

Stores application notifications:

```text
notifications/{notificationId}

userId
title
body
type
relatedId
isRead
createdAt
```

---

### mood_entries

Stores private student mood entries:

```text
mood_entries/{moodEntryId}

studentId
mood
moodScore
note
createdAt
```

---

### journal_entries

Stores private student journal entries:

```text
journal_entries/{journalId}

studentId
title
content
mood
createdAt
updatedAt
```

---

### session_notes

Stores private counselor session notes separately from appointments:

```text
session_notes/{sessionNoteId}

appointmentId
studentId
counselorId
note
createdAt
updatedAt
```

Session notes should not be placed directly inside an appointment document if students are allowed to read their appointment documents.

---

### admin_actions

Stores administrative actions:

```text
admin_actions/{actionId}

adminId
action
targetUserId
targetRole
reason
createdAt
```

---

# 19. Firebase Security

The application has three main roles:

```text
Student
Counselor
Admin
```

Security rules should restrict access according to the authenticated user's role and ownership.

### Student

A student should generally be able to:

```text
Read/update own profile
Create/read own appointments
Read own notifications
Create/read own mood entries
Create/read own journal entries
Participate in permitted conversations
```

### Counselor

An approved counselor should generally be able to:

```text
Manage own availability
Read/manage own appointments
Participate in assigned conversations
Send/read messages in permitted conversations
Create/read own session notes
```

### Admin

Administrators should be able to perform administrative operations such as:

```text
Approve counselors
Reject counselors
Suspend accounts
Reactivate accounts
Manage administrative records
```

Admin authorization should use a Firebase Authentication custom claim:

```text
admin: true
```

rather than relying only on the `role` field stored in Firestore.

---

# 20. Recommended Flutter Project Structure

After the initial setup, organize the project as follows:

```text
lib/
│
├── main.dart
├── firebase_options.dart
│
├── models/
│   ├── app_user.dart
│   ├── student.dart
│   ├── counselor.dart
│   ├── appointment.dart
│   ├── conversation.dart
│   ├── message.dart
│   └── session_note.dart
│
├── services/
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── appointment_service.dart
│   ├── counselor_service.dart
│   ├── message_service.dart
│   └── session_note_service.dart
│
├── screens/
│   ├── auth/
│   ├── student/
│   ├── counselor/
│   └── admin/
│
├── widgets/
│
└── utils/
```

This keeps:

```text
UI
↓
Services
↓
Firebase
```

separated from each other.

---

# 21. Recommended Development Order

Do not implement every Firebase feature at once.

A recommended order is:

```text
1. Flutter environment
        ↓
2. Android emulator
        ↓
3. Firebase project
        ↓
4. FlutterFire configuration
        ↓
5. Firebase Core
        ↓
6. Firebase Authentication
        ↓
7. User profiles
        ↓
8. Firestore security rules
        ↓
9. Student features
        ↓
10. Counselor features
        ↓
11. Counselor availability
        ↓
12. Appointments
        ↓
13. Chat / conversations
        ↓
14. Notifications
        ↓
15. Mood tracking
        ↓
16. Journaling
        ↓
17. Counselor session notes
        ↓
18. Admin functionality
        ↓
19. Testing
        ↓
20. Production security review
```

---

# 22. Useful Commands

### Check Flutter

```powershell
flutter doctor
```

### Check Flutter version

```powershell
flutter --version
```

### Check connected devices

```powershell
flutter devices
```

### Run application

```powershell
flutter run
```

### Get Flutter dependencies

```powershell
flutter pub get
```

### Add a Flutter package

```powershell
flutter pub add package_name
```

### Upgrade packages

```powershell
flutter pub upgrade
```

### Check Firebase CLI

```powershell
firebase --version
```

### Login to Firebase

```powershell
firebase login
```

### List Firebase projects

```powershell
firebase projects:list
```

### Configure FlutterFire

```powershell
flutterfire configure
```

### Initialize Firebase CLI

```powershell
firebase init
```

### Deploy Firestore rules

```powershell
firebase deploy --only firestore:rules
```

### Deploy Firestore indexes

```powershell
firebase deploy --only firestore:indexes
```

---

# 23. Verify the Complete Environment

Before starting application development, verify:

```powershell
flutter doctor
```

Then:

```powershell
flutter devices
```

Then:

```powershell
firebase projects:list
```

Then:

```powershell
flutterfire --version
```

Finally:

```powershell
flutter run
```

The expected environment is:

```text
Flutter
   │
   ├── VS Code
   │
   └── Android Emulator
          │
          ▼
     Flutter Application
          │
          ▼
       Firebase
       ├── Authentication
       ├── Firestore
       └── Storage
```

---

# 24. Important Security Rules

Never commit sensitive credentials to GitHub.

Do not commit:

```text
serviceAccountKey.json
.env
*.jks
*.keystore
key.properties
```

Firebase service-account credentials must remain in a trusted server/admin environment and should never be placed inside the Flutter application.

`firebase_options.dart` is normally safe to commit because Firebase client configuration is not equivalent to a service-account private key.

---

# 25. Final Setup Checklist

Use this checklist before starting development:

* [ ] Flutter installed
* [ ] Flutter added to PATH
* [ ] VS Code installed
* [ ] Flutter extension installed
* [ ] Dart extension installed
* [ ] Android Studio installed
* [ ] Android SDK installed
* [ ] Android SDK Command-line Tools installed
* [ ] Android licenses accepted
* [ ] Android Emulator created
* [ ] Flutter detects emulator
* [ ] Node.js installed
* [ ] Firebase CLI installed
* [ ] Firebase CLI logged in
* [ ] FlutterFire CLI installed
* [ ] Firebase project created
* [ ] Flutter project created
* [ ] Flutter project connected to Firebase
* [ ] `firebase_core` installed
* [ ] Firebase Authentication enabled
* [ ] Cloud Firestore enabled
* [ ] Firebase Storage enabled if required
* [ ] Firestore rules configured
* [ ] Firebase configuration tested
* [ ] Project runs successfully on Android emulator
* [ ] Git repository configured
* [ ] Sensitive credentials excluded from Git
* [ ] Team members have the required Firebase/GitHub access

---

## Environment Ready

Once all checklist items are completed, the development environment is ready for building the Flutter + Firebase application.

The basic architecture is:

```text
                    MindCare Flutter App
                            │
             ┌──────────────┼──────────────┐
             │              │              │
             ▼              ▼              ▼
       Authentication    Firestore      Storage
             │              │              │
             ▼              ▼              ▼
          Users          App Data       Files
             │
       ┌─────┴─────┐
       │           │
    Student    Counselor
                    │
                  Admin
```
