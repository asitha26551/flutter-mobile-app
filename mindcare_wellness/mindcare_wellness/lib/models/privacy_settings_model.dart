import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
