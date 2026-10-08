import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CounselorProfile {
  const CounselorProfile({required this.user, required this.details});

  final Map<String, dynamic> user;
  final Map<String, dynamic> details;

  String get name => user['fullName'] as String? ?? 'Counselor';
  String get department =>
      details['department'] as String? ?? 'University Counseling Unit';
  String get professionalRole =>
      details['professionalRole'] as String? ?? 'University Counselor';
  String? get imageUrl =>
      user['profileImageUrl'] as String? ?? user['profileImage'] as String?;
}

class CounselorAppointment {
  const CounselorAppointment({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  String get status => data['status'] as String? ?? 'pending';
  String get studentId =>
      data['studentId'] as String? ?? data['userId'] as String? ?? '';
  String get counselorId => data['counselorId'] as String? ?? '';
  String get sessionType =>
      data['sessionType'] as String? ??
      data['type'] as String? ??
      'Counseling session';
  String get reason => data['reason'] as String? ?? 'Counseling session';
  String? get location => data['location'] as String?;
  String? get meetingLink => data['meetingLink'] as String?;
  String? get mood =>
      data['mood'] as String? ?? data['studentMood'] as String?;
  int? get moodScore =>
      (data['moodScore'] as num?)?.toInt() ??
      (data['studentMoodScore'] as num?)?.toInt();
  String get studentAlias =>
      data['studentAlias'] as String? ??
      data['anonymousId'] as String? ??
      (studentId.isEmpty
          ? 'Anonymous student'
          : 'Student #${studentId.length > 6 ? studentId.substring(0, 6) : studentId}');
  DateTime? get startAt => _date(data['startAt'] ?? data['appointmentDate']);
  DateTime? get endAt => _date(data['endAt']);

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Represents a counselor profile in MindCare Wellness.
@immutable
class CounselorModel {
  const CounselorModel({
    required this.id,
    required this.name,
    this.title = '',
    this.location = '',
    this.rating = '0.0',
    this.reviewCount = 0,
    this.image = '',
    this.tags = const <String>[],
    this.availableSlots = const <String>[],
    this.isConfidentialSupported = true,
  });

  /// Unique identifier of the counselor.
  final String id;

  /// Full name of the counselor.
  final String name;

  /// Professional designation or department (e.g. "Senior Psychologist").
  final String title;

  /// Physical or office location (e.g. "Campus Health Center, Rm 204").
  final String location;

  /// Safe display location fallback.
  String get displayLocation =>
      location.isNotEmpty ? location : 'Campus Health Center';

  /// Average rating as a formatted string (e.g. "4.9").
  final String rating;

  /// Total count of reviews received.
  final int reviewCount;

  /// Image URL or asset path for the counselor's profile picture.
  final String image;

  /// Tags/specialization labels (e.g. ["Anxiety", "Academic Stress", "Depression"]).
  final List<String> tags;

  /// Available booking time slots (e.g. ["09:00 AM", "11:30 AM", "02:00 PM"]).
  final List<String> availableSlots;

  /// Indicates whether this counselor supports confidential and anonymous sessions.
  final bool isConfidentialSupported;

  /// Creates a [CounselorModel] from a JSON map with strict null-safety and fallback logic.
  factory CounselorModel.fromJson(
    Map<String, dynamic>? json, {
    String? id,
  }) {
    if (json == null) {
      return CounselorModel(
        id: id ?? '',
        name: '',
        title: '',
        rating: '0.0',
        reviewCount: 0,
        image: '',
        tags: const <String>[],
        availableSlots: const <String>[],
        isConfidentialSupported: true,
      );
    }

    final rawTags = json['tags'] ?? json['specializations'];
    final List<String> tagsList = (rawTags is List)
        ? rawTags
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    final rawSlots = json['availableSlots'] ?? json['slots'];
    final List<String> slotsList = (rawSlots is List)
        ? rawSlots
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    return CounselorModel(
      id: id ?? (json['id'] as String? ?? json['uid'] as String? ?? ''),
      name: json['name'] as String? ?? json['fullName'] as String? ?? '',
      title: json['title'] as String? ?? json['department'] as String? ?? '',
      location: json['location'] as String? ?? json['room'] as String? ?? '',
      rating: json['rating']?.toString() ?? '0.0',
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      image: json['image'] as String? ??
          (json['profileImageUrl'] as String? ??
              json['profileImage'] as String? ??
              ''),
      tags: List.unmodifiable(tagsList),
      availableSlots: List.unmodifiable(slotsList),
      isConfidentialSupported:
          json['isConfidentialSupported'] as bool? ?? true,
    );
  }

  /// Creates a [CounselorModel] from a Cloud Firestore [DocumentSnapshot].
  factory CounselorModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return CounselorModel.fromJson(snapshot.data(), id: snapshot.id);
  }

  /// Serializes the model into a standard JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      if (location.isNotEmpty) 'location': location,
      'rating': rating,
      'reviewCount': reviewCount,
      'image': image,
      'tags': tags,
      'availableSlots': availableSlots,
      'isConfidentialSupported': isConfidentialSupported,
    };
  }

  /// Serializes the model into a Firestore-compatible document data map.
  Map<String, dynamic> toFirestore() => toJson();

  /// Returns an updated copy with modified fields.
  CounselorModel copyWith({
    String? id,
    String? name,
    String? title,
    String? location,
    String? rating,
    int? reviewCount,
    String? image,
    List<String>? tags,
    List<String>? availableSlots,
    bool? isConfidentialSupported,
  }) {
    return CounselorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      image: image ?? this.image,
      tags: tags != null ? List.unmodifiable(tags) : this.tags,
      availableSlots: availableSlots != null
          ? List.unmodifiable(availableSlots)
          : this.availableSlots,
      isConfidentialSupported:
          isConfidentialSupported ?? this.isConfidentialSupported,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CounselorModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          title == other.title &&
          location == other.location &&
          rating == other.rating &&
          reviewCount == other.reviewCount &&
          image == other.image &&
          listEquals(tags, other.tags) &&
          listEquals(availableSlots, other.availableSlots) &&
          isConfidentialSupported == other.isConfidentialSupported;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        title,
        location,
        rating,
        reviewCount,
        image,
        Object.hashAll(tags),
        Object.hashAll(availableSlots),
        isConfidentialSupported,
      );

  @override
  String toString() {
    return 'CounselorModel('
        'id: $id, '
        'name: $name, '
        'title: $title, '
        'location: $location, '
        'rating: $rating, '
        'reviewCount: $reviewCount, '
        'image: $image, '
        'tags: $tags, '
        'availableSlots: $availableSlots, '
        'isConfidentialSupported: $isConfidentialSupported)';
  }

  /// Default list of verified student counselors.
  static const List<CounselorModel> defaultCounselors = [
    CounselorModel(
      id: 'counselor_neil',
      name: 'Dr. Neil Fernano',
      title: 'Senior Student Counselor',
      location: 'Campus Wellness Center, Rm 201',
      rating: '4.9',
      reviewCount: 135,
      image:
          'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&q=80&w=400',
      tags: ['Academic Stress', 'Anxiety', 'Student Support', 'Mindfulness'],
      availableSlots: [
        '09:30 AM',
        '11:00 AM',
        '02:00 PM',
        '03:30 PM',
      ],
      isConfidentialSupported: true,
    ),
    CounselorModel(
      id: 'counselor_kanthi',
      name: 'Ms. Kanthi Silva',
      title: 'Psychological Counselor',
      location: 'Student Care Pavilion, Suite 104',
      rating: '4.85',
      reviewCount: 118,
      image:
          'https://images.unsplash.com/photo-1594824813589-72c7a8848d7d?auto=format&fit=crop&q=80&w=400',
      tags: ['Depression', 'Psychological Counseling', 'Stress Management'],
      availableSlots: [
        '10:00 AM',
        '01:30 PM',
        '04:00 PM',
      ],
      isConfidentialSupported: true,
    ),
    CounselorModel(
      id: 'counselor_kasun',
      name: 'Mr. Kasun Fernando',
      title: 'Mental Health & Wellbeing Specialist',
      location: 'Counseling Wing, Rm 112',
      rating: '4.95',
      reviewCount: 140,
      image:
          'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=400',
      tags: ['Mental Health', 'Wellbeing', 'Crisis Support', 'Anxiety'],
      availableSlots: [
        '09:00 AM',
        '11:30 AM',
        '02:30 PM',
        '04:30 PM',
      ],
      isConfidentialSupported: true,
    ),
    CounselorModel(
      id: 'counselor_chaminda',
      name: 'Dr. Chaminda Weerasiriwardhana',
      title: 'Senior Counselor and Psychotherapist',
      location: 'Health Science Bldg, Rm 305',
      rating: '4.9',
      reviewCount: 156,
      image:
          'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=400',
      tags: ['Psychotherapy', 'Cognitive Behavioral Therapy', 'Academic Stress'],
      availableSlots: [
        '10:30 AM',
        '01:00 PM',
        '03:00 PM',
        '05:00 PM',
      ],
      isConfidentialSupported: true,
    ),
    CounselorModel(
      id: 'counselor_sayuri',
      name: 'Ms. Sayuri Perera',
      title: 'Psychological Counselor',
      location: 'Campus Wellness Center, Rm 208',
      rating: '4.8',
      reviewCount: 92,
      image:
          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=400',
      tags: ['Psychological Counseling', 'Mindfulness', 'Sleep Disruption'],
      availableSlots: [
        '09:30 AM',
        '11:00 AM',
        '01:30 PM',
        '03:30 PM',
      ],
      isConfidentialSupported: true,
    ),
    CounselorModel(
      id: 'counselor_anuradha',
      name: 'Ms. Anuradha Herath',
      title: 'Mental Health & Wellbeing Specialist',
      location: 'Student Care Pavilion, Rm 215',
      rating: '4.9',
      reviewCount: 104,
      image:
          'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&q=80&w=400',
      tags: ['Mental Health', 'Wellbeing Specialist', 'General Check-in'],
      availableSlots: [
        '10:00 AM',
        '12:00 PM',
        '02:30 PM',
        '04:00 PM',
      ],
      isConfidentialSupported: true,
    ),
  ];
}
