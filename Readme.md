# MindCare Wellness

A Flutter + Firebase mobile application for university counseling and student wellness management.

This document explains how collaborators can install the required software, clone the project, configure Firebase, run the application, and follow the project's security rules.

---

# 1. Technology Stack

MindCare Wellness uses:

* Flutter
* Dart
* Firebase Authentication
* Cloud Firestore
* Firebase Storage (if enabled by the project)
* Firebase Cloud Messaging (if enabled)
* Android
* Git
* GitHub

The application does **not** use a separate traditional backend such as Spring Boot.

Firebase provides the backend services used by the Flutter application.

---

# 2. Required Software

Every collaborator should install the following:

| Software         | Required              | Purpose                                             |
| ---------------- | --------------------- | --------------------------------------------------- |
| Git              | Yes                   | Clone and manage the repository                     |
| Flutter SDK      | Yes                   | Develop and run the Flutter application             |
| Dart SDK         | Included with Flutter | Dart programming                                    |
| Android Studio   | Recommended           | Android SDK, emulator and Android development tools |
| VS Code          | Recommended           | Flutter/Dart development                            |
| Android SDK      | Yes                   | Build and run Android applications                  |
| Android Emulator | Recommended           | Test the application                                |
| Firebase CLI     | Recommended           | Firebase project management                         |
| FlutterFire CLI  | Recommended           | Configure Flutter with Firebase                     |

---

# 3. Recommended Installation Setup

The recommended development environment is:

```text
Windows
   │
   ├── Git
   │
   ├── Flutter SDK
   │
   ├── Android Studio
   │      ├── Android SDK
   │      ├── Android SDK Platform Tools
   │      ├── Android Emulator
   │      └── Android SDK Command-line Tools
   │
   ├── VS Code
   │      ├── Flutter Extension
   │      └── Dart Extension
   │
   └── Firebase CLI
```

Android Studio and VS Code have different purposes.

### Android Studio

Mainly used for:

* Android SDK
* Android SDK Manager
* Android Emulator
* Android build tools
* Android debugging tools

### VS Code

Mainly used for:

* Writing Flutter/Dart code
* Managing the project
* Debugging
* Git integration
* Flutter development

You can develop mainly in VS Code while using Android Studio for the Android SDK and emulator.

---

# 4. Option A — Install Android Studio

Download Android Studio from the official Android developer website.

During installation, make sure the following components are installed:

* Android SDK
* Android SDK Platform
* Android SDK Platform-Tools
* Android Emulator
* Android SDK Build-Tools

After installation:

1. Open Android Studio.
2. Open:

```text
More Actions → SDK Manager
```

3. Check that an Android SDK is installed.

Then open:

```text
More Actions → Virtual Device Manager
```

Create an Android Virtual Device.

Recommended:

```text
Device: Pixel
System Image: Recent stable Android image
Architecture: x86_64
```

Start the emulator.

---

# 5. Option B — Install VS Code

Download Visual Studio Code.

After installation, open VS Code.

Install these extensions:

### Required

```text
Flutter
Dart
```

The Flutter extension normally installs/supports the Dart extension as well.

### Useful

```text
GitLens
Error Lens
Firebase
```

The additional extensions are optional.

---

# 6. Install Git

Install Git for Windows.

After installation, open PowerShell and check:

```powershell
git --version
```

You should receive a version such as:

```text
git version 2.x.x
```

If the command is not recognized, restart the terminal or verify that Git was added to PATH.

---

# 7. Install Flutter

Download and install the Flutter SDK.

Example installation location:

```text
C:\src\flutter
```

or:

```text
D:\flutter
```

Avoid installing Flutter inside:

```text
C:\Program Files\
```

because permissions can sometimes cause problems.

Add the Flutter `bin` directory to the Windows PATH.

For example:

```text
D:\flutter\bin
```

Open a new PowerShell window and run:

```powershell
flutter --version
```

Then run:

```powershell
flutter doctor
```

---

# 8. Configure Android

Run:

```powershell
flutter doctor
```

Look for the Android toolchain.

If Flutter reports that Android licenses have not been accepted, run:

```powershell
flutter doctor --android-licenses
```

Accept the required licenses.

Then run:

```powershell
flutter doctor
```

again.

The goal is to have the required Flutter, Android and development components detected correctly.

---

# 9. Clone the MindCare Repository

Open PowerShell.

Navigate to the folder where you keep your projects.

Example:

```powershell
cd "C:\Users\<YOUR_USERNAME>\Documents\GitHub"
```

Clone the repository:

```powershell
git clone <GITHUB_REPOSITORY_URL>
```

Then enter the project:

```powershell
cd mindcare
```

If the repository uses a different name, use the actual repository name.

---

# 10. Install Flutter Dependencies

Inside the project directory, run:

```powershell
flutter pub get
```

This downloads the packages defined in:

```text
pubspec.yaml
```

Do not manually download individual Dart packages unless specifically required.

---

# 11. Firebase Configuration

MindCare uses Firebase.

The project already contains:

```text
lib/firebase_options.dart
```

This file contains the Firebase client configuration required by the Flutter application.

### Important

`firebase_options.dart` is normally committed to GitHub.

Do NOT replace it with your own Firebase project configuration unless the project owner specifically instructs you to do so.

The application should connect to the project's existing Firebase project.

---

# 12. Firebase Project

The current MindCare Firebase project is:

```text
Project name:
counselor-booking

Project ID:
counselor-booking-a5e04
```

Collaborators should **not create another Firebase project** unless specifically instructed.

The team should work with the existing Firebase project.

---

# 13. Firebase CLI

Install the Firebase CLI.

After installation, check:

```powershell
firebase --version
```

Log in:

```powershell
firebase login
```

Then check the available projects:

```powershell
firebase projects:list
```

You should be able to see the MindCare Firebase project if your Google account has been granted the necessary Firebase permissions.

---

# 14. Firebase Access for Collaborators

A collaborator needs access to the Firebase project if they need to:

* View Firestore data
* Modify Firestore rules
* Manage Firebase Authentication
* View Firebase logs
* Configure Firebase services
* Deploy Firebase configuration

The project owner should add collaborators through the Firebase/Google Cloud project permissions.

Do not share:

```text
serviceAccountKey.json
```

or other private credentials through GitHub, WhatsApp, email, or the project repository.

---

# 15. Firebase Initialization in Flutter

The application initializes Firebase in `main.dart`.

The structure should be similar to:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MindCareApp());
}
```

Do not remove Firebase initialization.

---

# 16. Run the Application

Start an Android emulator.

Check that Flutter can detect it:

```powershell
flutter devices
```

You should see an Android device.

For example:

```text
sdk gphone16k x86 64
```

Then run:

```powershell
flutter run
```

Alternatively, in VS Code:

1. Open the MindCare project.
2. Select the Android emulator/device.
3. Press `F5`.

---

# 17. If No Android Device Is Found

Run:

```powershell
flutter devices
```

If no Android device appears:

1. Open Android Studio.
2. Open Device Manager.
3. Start an emulator.
4. Wait until Android finishes booting.
5. Run:

```powershell
flutter devices
```

again.

Then:

```powershell
flutter run
```

---

# 18. Check the Project Before Development

After cloning the repository, run:

```powershell
flutter doctor
```

Then:

```powershell
flutter pub get
```

Then:

```powershell
flutter devices
```

Finally:

```powershell
flutter run
```

The basic setup sequence is:

```text
Install software
      ↓
Clone repository
      ↓
cd mindcare
      ↓
flutter pub get
      ↓
Start Android emulator
      ↓
flutter devices
      ↓
flutter run
      ↓
Test Firebase connection
```

---

# 19. Project Structure

The project generally follows this structure:

```text
mindcare/
│
├── android/
│
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   │
│   ├── models/
│   │
│   ├── services/
│   │
│   ├── screens/
│   │
│   └── widgets/
│
├── test/
│
├── pubspec.yaml
├── pubspec.lock
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
└── .gitignore
```

Do not create a separate traditional backend directory inside the Flutter application unless the team specifically decides to introduce another backend service.

Firebase acts as the backend infrastructure.

---

# 20. Firestore Collections

The current Firestore structure contains:

```text
users
students
counselors
counselor_availability
appointments
conversations
messages
notifications
mood_entries
journal_entries
session_notes
admin_actions
```

Important:

Do not create unrelated collections without discussing them with the team.

In particular, the current design does NOT use:

```text
wellness_resources
counselor_reviews
```

unless the team later decides to add them.

---

# 21. User Roles

MindCare has three main roles:

```text
student
counselor
admin
```

The application determines the user's role from:

```text
users/{uid}
```

Example:

```text
users/{uid}
    role: student
```

or:

```text
users/{uid}
    role: counselor
```

or:

```text
users/{uid}
    role: admin
```

---

# 22. Firebase Authentication

Firebase Authentication handles:

* Registration
* Login
* Logout
* Password reset
* Email verification

Passwords must NOT be stored in Firestore.

The authenticated Firebase user's UID should be used as the user's identifier.

Example:

```dart
final uid = FirebaseAuth.instance.currentUser!.uid;
```

---

# 23. Student Data

Student authentication information and student academic information are kept separately.

Authentication/user information:

```text
users/{uid}
```

Student-specific information:

```text
students/{uid}
```

Student information can include:

```text
studentId
alias
faculty
department
degreeProgram
academicYear
batch
enrollmentStatus
priorityLevel
```

Do not duplicate these fields into unrelated documents unless there is a specific architectural reason.

---

# 24. Student Priority

Students have:

```text
priorityLevel
```

Possible values:

```text
normal
high
```

The default value is:

```text
normal
```

A counselor can mark a student as high priority from the appropriate active-session workflow.

The operation should only modify:

```text
priorityLevel
```

It should not overwrite the student's other profile information.

---

# 25. Counselor Accounts

Counselors require administrative verification.

Typical workflow:

```text
Counselor registers
        ↓
Account status = pending
        ↓
Admin reviews counselor
        ↓
Admin approves/rejects
        ↓
Approved counselor
        ↓
Account becomes active
```

Counselors should not receive access to restricted counselor functionality before approval.

---

# 26. Admin Security

The application uses two concepts:

### Firestore user role

```text
users/{uid}.role = "admin"
```

This is useful for application-level routing/UI.

### Firebase custom claim

```text
admin: true
```

This is used for privileged Firestore authorization.

Do not rely only on:

```text
users/{uid}.role == "admin"
```

for highly privileged Firestore operations.

---

# 27. Private Admin Files

Some administrative files must NEVER be committed to GitHub.

Examples:

```text
serviceAccountKey.json
.env
```

The Firebase Admin SDK service account key must remain in the private admin environment.

Example:

```text
mindcare-admin/
├── set-admin.js
├── package.json
├── package-lock.json
├── .env                     ← PRIVATE
└── serviceAccountKey.json   ← PRIVATE
```

---

# 28. Git Security

Before committing code, check:

```powershell
git status
```

Make sure private files are not included.

Never commit:

```text
.env
serviceAccountKey.json
*.jks
*.keystore
key.properties
```

These files should be included in `.gitignore`.

---

# 29. Firebase Client Configuration

The following file is normally safe to commit:

```text
lib/firebase_options.dart
```

Do not confuse it with:

```text
serviceAccountKey.json
```

They serve completely different purposes.

### Client configuration

```text
firebase_options.dart
```

Used by the Flutter application.

### Admin credentials

```text
serviceAccountKey.json
```

Provides privileged Firebase Admin SDK access.

The Admin SDK private key must remain secret.

---

# 30. Android Signing Files

You may encounter these files when preparing a release build:

```text
android/key.properties
```

and:

```text
*.jks
*.keystore
```

These are Android signing credentials.

They should NOT be committed to GitHub.

If they do not exist in your development environment, that is normal.

They are generally needed when configuring release signing rather than basic emulator development.

---

# 31. Git Workflow

Before starting work:

```powershell
git pull
```

Create a feature branch:

```powershell
git checkout -b feature/<feature-name>
```

Example:

```powershell
git checkout -b feature/student-profile
```

Make your changes.

Check:

```powershell
git status
```

Run the application and test your changes.

Then:

```powershell
git add .
```

Commit:

```powershell
git commit -m "Add student profile"
```

Push:

```powershell
git push -u origin feature/student-profile
```

Create a Pull Request on GitHub.

---

# 32. Do Not Directly Modify Another Person's Feature

Before modifying another developer's feature:

1. Check the current branch.
2. Pull the latest changes.
3. Discuss major architectural changes with the team.
4. Avoid overwriting another person's work.
5. Use feature branches.
6. Create Pull Requests.

---

# 33. Before Pushing Code

Always run:

```powershell
flutter analyze
```

Then:

```powershell
flutter test
```

If applicable, run:

```powershell
flutter run
```

Then check:

```powershell
git status
```

Make sure no secrets are staged.

---

# 34. Common Commands

### Check Flutter

```powershell
flutter --version
```

### Check Flutter environment

```powershell
flutter doctor
```

### Get dependencies

```powershell
flutter pub get
```

### Analyze code

```powershell
flutter analyze
```

### Run tests

```powershell
flutter test
```

### Check devices

```powershell
flutter devices
```

### Run application

```powershell
flutter run
```

### Clean Flutter build files

```powershell
flutter clean
```

Then:

```powershell
flutter pub get
```

### Check Git

```powershell
git status
```

### Get latest GitHub changes

```powershell
git pull
```

---

# 35. Common Problems

## Problem: `flutter` is not recognized

Check that Flutter's `bin` directory is in PATH.

Example:

```text
D:\flutter\bin
```

Restart PowerShell after changing PATH.

---

## Problem: Android SDK not found

Open Android Studio:

```text
SDK Manager
```

Install the required Android SDK components.

Then run:

```powershell
flutter doctor
```

---

## Problem: No Android emulator

Open:

```text
Android Studio
→ Device Manager
```

Create/start an emulator.

Then:

```powershell
flutter devices
```

---

## Problem: Flutter dependencies are missing

Run:

```powershell
flutter pub get
```

---

## Problem: Firebase permission denied

If Firestore returns:

```text
PERMISSION_DENIED
```

do not immediately change the security rules.

First check:

* Is the user logged in?
* Is the user email verified if required?
* Does the user's Firestore document exist?
* Does the user have the correct role?
* Is the operation allowed by `firestore.rules`?
* Is the user using the correct Firebase project?

Contact the project owner before weakening Firestore security rules.

---

# 36. Important Security Rules

Never:

* Store passwords in Firestore
* Commit service-account credentials
* Commit `.env` files containing secrets
* Commit Android signing keys
* Disable Firestore rules just to make an operation work
* Give students access to other students' private data
* Give students access to counselor private session notes
* Trust a client-provided role for privileged operations
* Hardcode administrative credentials in Flutter code

---

# 37. Data Privacy

MindCare handles potentially sensitive counseling-related information.

Developers must be especially careful with:

```text
mood_entries
journal_entries
session_notes
appointments
messages
student profiles
```

Do not expose private information through:

* Debug logs
* Screenshots
* GitHub commits
* Test data
* Public repositories
* Hardcoded credentials

Use fictional data when creating test records.

---

# 38. Development Rule

When implementing a new feature:

```text
1. Understand the existing architecture
2. Check existing models
3. Check existing services
4. Check existing Firestore structure
5. Reuse existing code where possible
6. Make minimal changes
7. Implement the feature
8. Test it
9. Run flutter analyze
10. Commit using a clear message
11. Push to your feature branch
12. Create a Pull Request
```

Avoid creating duplicate:

```text
models
services
Firestore collections
authentication systems
```

when an existing implementation can be extended.

---

# 39. Recommended First-Time Setup

A new collaborator should follow these commands in order:

```powershell
# 1. Clone repository
git clone <GITHUB_REPOSITORY_URL>

# 2. Enter project
cd mindcare

# 3. Check Flutter
flutter doctor

# 4. Install Flutter dependencies
flutter pub get

# 5. Check available devices
flutter devices

# 6. Start Android emulator if necessary

# 7. Run application
flutter run

# 8. Check code
flutter analyze

# 9. Run tests
flutter test
```

If all of these work, the basic development environment is ready.

---

# 40. Team Development Structure

Recommended responsibilities can be divided into areas such as:

```text
Developer 1
    UI / Screens

Developer 2
    Authentication / User Profiles

Developer 3
    Firestore / Database / Security Rules

Developer 4
    Appointments / Availability

Developer 5
    Messaging / Notifications

Developer 6
    Testing / Integration
```

These responsibilities can overlap, but developers should coordinate before changing shared models, Firestore rules, or database structures.

---

# 41. Final Checklist

Before considering your setup complete:

* [ ] Git installed
* [ ] Flutter installed
* [ ] `flutter doctor` checked
* [ ] Android Studio installed
* [ ] Android SDK installed
* [ ] Android emulator created
* [ ] VS Code installed
* [ ] Flutter extension installed
* [ ] Dart extension installed
* [ ] Repository cloned
* [ ] `flutter pub get` completed
* [ ] Firebase project access confirmed
* [ ] Android emulator starts
* [ ] `flutter devices` detects emulator
* [ ] `flutter run` works
* [ ] Firebase Authentication works
* [ ] Firestore connection works
* [ ] No private credentials committed
* [ ] `flutter analyze` passes
* [ ] `flutter test` passes

---

# 42. Important Rule for Collaborators

If you are unsure whether a change affects the database, authentication, security rules, or another developer's feature, **ask the team before making the change**.

The goal is to keep the MindCare architecture consistent and avoid breaking existing functionality.
