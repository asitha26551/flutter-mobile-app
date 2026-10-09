import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Curated calming adjectives for student anonymous aliases.
const List<String> _kPseudonymAdjectives = <String>[
  'Silent', 'Brave', 'Calm', 'Gentle', 'Serene',
  'Peaceful', 'Quiet', 'Noble', 'Kind', 'Wise',
  'Swift', 'Tranquil', 'Hopeful', 'Radiant', 'Resilient',
  'Mindful', 'Hidden', 'Sunny', 'Cosmic', 'Ocean',
  'Golden', 'Silver', 'Amber', 'Mystic', 'Starlight',
  'Cedar', 'Ember', 'Haven', 'Breeze', 'Sky',
];

/// Curated nature nouns and animals for student anonymous aliases.
const List<String> _kPseudonymNouns = <String>[
  'Panda', 'Hawk', 'Otter', 'Falcon', 'Fox',
  'Eagle', 'Sparrow', 'Dolphin', 'Koala', 'Robin',
  'Deer', 'Wolf', 'Bear', 'Tiger', 'Lotus',
  'Willow', 'Breeze', 'River', 'Meadow', 'Phoenix',
  'Badger', 'Lynx', 'Owl', 'Heron', 'Cedar',
];

/// Generates a friendly, anonymous pseudonym (e.g. "SilentPanda42", "BraveHawk88").
String generateRandomPseudonym({Random? random}) {
  final rng = random ?? Random();
  final adjective =
      _kPseudonymAdjectives[rng.nextInt(_kPseudonymAdjectives.length)];
  final noun = _kPseudonymNouns[rng.nextInt(_kPseudonymNouns.length)];
  final number = rng.nextInt(90) + 10; // 10 to 99
  return '$adjective$noun$number';
}

/// Generates a confidential verification passcode (e.g. "STU-8821").
String generatePasscode({String prefix = 'STU-', Random? random}) {
  final rng = random ?? Random();
  final number = rng.nextInt(9000) + 1000; // 1000 to 9999
  return '$prefix$number';
}

/// Service managing student privacy settings and confidential credentials.
/// Implements full CRUD (Create, Read, Update, Reset/Delete) with fallback
/// support for anonymous / unauthenticated students.
class PrivacyService {
  PrivacyService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _customFirestore = firestore,
        _customAuth = auth;

  static PrivacyService? _defaultInstance;
  static PrivacyService get defaultInstance =>
      _defaultInstance ??= PrivacyService();

  @visibleForTesting
  static void resetDefaultInstance() {
    _defaultInstance = null;
  }

  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  // In-memory fallback for anonymous/offline or unauthenticated student sessions
  PrivacySettingsModel _inMemorySettings = const PrivacySettingsModel(
    hideRealName: true,
    maskStudentId: true,
    allowAnonymousNotes: true,
    currentPseudonym: 'SilentPanda42',
    passcode: 'STU-8821',
  );

  final StreamController<PrivacySettingsModel> _settingsStreamController =
      StreamController<PrivacySettingsModel>.broadcast();

  FirebaseFirestore? get _effectiveFirestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _effectiveAuth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Returns the current signed-in user's UID or fallback anonymous identifier.
  String? get currentUid => _effectiveAuth?.currentUser?.uid;

  /// Returns the document reference for `users/{uid}/privacy/settings`.
  DocumentReference<Map<String, dynamic>>? _privacyDoc(String uid) =>
      _effectiveFirestore
          ?.collection('users')
          .doc(uid)
          .collection('privacy')
          .doc('settings');

  /// READ: Fetches privacy settings for a user from Firestore (`users/{uid}/privacy`).
  /// Falls back to local in-memory settings when user is anonymous or offline.
  Future<PrivacySettingsModel> getPrivacySettings([String? uid]) async {
    final targetUid = uid ?? currentUid;
    if (targetUid == null || targetUid.isEmpty) {
      return _inMemorySettings;
    }

    try {
      final doc = await _privacyDoc(targetUid)?.get();
      if (doc != null && doc.exists && doc.data() != null) {
        final loaded = PrivacySettingsModel.fromJson(doc.data());
        _inMemorySettings = loaded;
        return loaded;
      }

      // Check fallback location in users/{uid} root document
      final firestore = _effectiveFirestore;
      if (firestore != null) {
        final userDoc = await firestore.collection('users').doc(targetUid).get();
        final userData = userDoc.data();
        if (userData != null && userData['privacy'] is Map<String, dynamic>) {
          final loaded = PrivacySettingsModel.fromJson(
            userData['privacy'] as Map<String, dynamic>,
          );
          _inMemorySettings = loaded;
          return loaded;
        }
      }

      return _inMemorySettings;
    } catch (e) {
      debugPrint('PrivacyService.getPrivacySettings fallback error: $e');
      return _inMemorySettings;
    }
  }

  /// Alias for [getPrivacySettings].
  Future<PrivacySettingsModel> fetchPrivacySettings([String? uid]) =>
      getPrivacySettings(uid);

  /// UPDATE / CREATE: Saves user privacy settings to Firestore (`users/{uid}/privacy`).
  /// Gracefully persists to in-memory state when running anonymously or offline.
  Future<void> savePrivacySettings(
    PrivacySettingsModel settings, {
    String? uid,
  }) async {
    _inMemorySettings = settings;
    _settingsStreamController.add(settings);

    final targetUid = uid ?? currentUid;
    if (targetUid == null || targetUid.isEmpty) {
      // In anonymous mode without backend auth, update succeeded in local storage
      return;
    }

    final docRef = _privacyDoc(targetUid);
    if (docRef == null) return;

    try {
      final now = FieldValue.serverTimestamp();
      final data = {
        ...settings.toFirestore(),
        'updatedAt': now,
      };

      // Primary write to subcollection users/{uid}/privacy/settings
      await docRef.set(data, SetOptions(merge: true));

      // Optional sync to user document
      try {
        await _effectiveFirestore?.collection('users').doc(targetUid).update({
          'privacy': settings.toFirestore(),
          'updatedAt': now,
        });
      } catch (_) {
        // Ignore if user root document is restricted
      }
    } catch (e) {
      debugPrint('PrivacyService.savePrivacySettings remote error: $e');
    }
  }

  /// Alias for [savePrivacySettings].
  Future<void> updatePrivacySettings(
    PrivacySettingsModel settings, {
    String? uid,
  }) =>
      savePrivacySettings(settings, uid: uid);

  /// DELETE / RESET: Resets privacy settings to default confidential settings.
  Future<void> resetPrivacySettings([String? uid]) async {
    const defaultSettings = PrivacySettingsModel(
      hideRealName: true,
      maskStudentId: true,
      allowAnonymousNotes: true,
      biometricLock: false,
      currentPseudonym: 'SilentPanda42',
      passcode: 'STU-8821',
    );
    await savePrivacySettings(defaultSettings, uid: uid);
  }

  /// Reactive stream for user privacy settings.
  Stream<PrivacySettingsModel> privacySettingsStream([String? uid]) {
    final targetUid = uid ?? currentUid;
    if (targetUid == null || targetUid.isEmpty) {
      return Stream<PrivacySettingsModel>.multi((controller) {
        controller.add(_inMemorySettings);
        final sub = _settingsStreamController.stream.listen(
          controller.add,
          onError: controller.addError,
        );
        controller.onCancel = () => sub.cancel();
      });
    }

    final doc = _privacyDoc(targetUid);
    if (doc == null) {
      return Stream<PrivacySettingsModel>.multi((controller) {
        controller.add(_inMemorySettings);
        final sub = _settingsStreamController.stream.listen(
          controller.add,
          onError: controller.addError,
        );
        controller.onCancel = () => sub.cancel();
      });
    }

    return doc.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return _inMemorySettings;
      }
      final loaded = PrivacySettingsModel.fromJson(snapshot.data());
      _inMemorySettings = loaded;
      return loaded;
    });
  }

  /// Instance method proxy for [generateRandomPseudonym].
  String createPseudonym({Random? random}) =>
      generateRandomPseudonym(random: random);

  /// Instance method proxy for [generatePasscode].
  String createPasscode({String prefix = 'STU-', Random? random}) =>
      generatePasscode(prefix: prefix, random: random);

  void dispose() {
    _settingsStreamController.close();
  }
}

/// Represents user privacy and confidentiality settings for MindCare Wellness.
@immutable
class PrivacySettingsModel {
  const PrivacySettingsModel({
    this.hideRealName = false,
    this.maskStudentId = false,
    this.allowAnonymousNotes = true,
    this.biometricLock = false,
    this.currentPseudonym = '',
    this.passcode = '',
  });

  /// When true, real student name is withheld from counselor views.
  final bool hideRealName;

  /// When true, university student ID number is masked (e.g. STU-***-89).
  final bool maskStudentId;

  /// When true, allows student notes/journals to remain unlinked to identifying records.
  final bool allowAnonymousNotes;

  /// When true, biometric or passcode authentication is required to access sensitive views.
  final bool biometricLock;

  /// The active anonymous alias/pseudonym chosen by the student (e.g. "CalmBreeze").
  final String currentPseudonym;

  /// 4-6 digit privacy passcode used to access confidential sessions or verify anonymous bookings.
  final String passcode;

  /// Default privacy configuration instance.
  static const empty = PrivacySettingsModel();

  /// Creates a [PrivacySettingsModel] from a JSON map with strict null-safety.
  factory PrivacySettingsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PrivacySettingsModel();
    return PrivacySettingsModel(
      hideRealName: json['hideRealName'] as bool? ?? false,
      maskStudentId: json['maskStudentId'] as bool? ?? false,
      allowAnonymousNotes: json['allowAnonymousNotes'] as bool? ?? true,
      biometricLock: json['biometricLock'] as bool? ?? false,
      currentPseudonym: json['currentPseudonym'] as String? ?? '',
      passcode: json['passcode'] as String? ?? '',
    );
  }

  /// Creates a [PrivacySettingsModel] from a Cloud Firestore [DocumentSnapshot].
  factory PrivacySettingsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return PrivacySettingsModel.fromJson(snapshot.data());
  }

  /// Serializes the model into a standard JSON map.
  Map<String, dynamic> toJson() {
    return {
      'hideRealName': hideRealName,
      'maskStudentId': maskStudentId,
      'allowAnonymousNotes': allowAnonymousNotes,
      'biometricLock': biometricLock,
      'currentPseudonym': currentPseudonym,
      'passcode': passcode,
    };
  }

  /// Serializes the model into a Firestore-compatible document data map.
  Map<String, dynamic> toFirestore() => toJson();

  /// Returns an updated copy with modified fields.
  PrivacySettingsModel copyWith({
    bool? hideRealName,
    bool? maskStudentId,
    bool? allowAnonymousNotes,
    bool? biometricLock,
    String? currentPseudonym,
    String? passcode,
  }) {
    return PrivacySettingsModel(
      hideRealName: hideRealName ?? this.hideRealName,
      maskStudentId: maskStudentId ?? this.maskStudentId,
      allowAnonymousNotes: allowAnonymousNotes ?? this.allowAnonymousNotes,
      biometricLock: biometricLock ?? this.biometricLock,
      currentPseudonym: currentPseudonym ?? this.currentPseudonym,
      passcode: passcode ?? this.passcode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacySettingsModel &&
          runtimeType == other.runtimeType &&
          hideRealName == other.hideRealName &&
          maskStudentId == other.maskStudentId &&
          allowAnonymousNotes == other.allowAnonymousNotes &&
          biometricLock == other.biometricLock &&
          currentPseudonym == other.currentPseudonym &&
          passcode == other.passcode;

  @override
  int get hashCode => Object.hash(
        hideRealName,
        maskStudentId,
        allowAnonymousNotes,
        biometricLock,
        currentPseudonym,
        passcode,
      );

  @override
  String toString() {
    return 'PrivacySettingsModel('
        'hideRealName: $hideRealName, '
        'maskStudentId: $maskStudentId, '
        'allowAnonymousNotes: $allowAnonymousNotes, '
        'biometricLock: $biometricLock, '
        'currentPseudonym: $currentPseudonym, '
        'passcode: ${passcode.isNotEmpty ? '***' : ''})';
  }
}
