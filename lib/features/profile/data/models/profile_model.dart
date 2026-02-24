class ProfileModel {
  final String? id;
  final String fullName;
  final String dateOfBirth;
  final String bloodGroup;
  final String allergies;
  final String medications;
  final String medicalConditions;
  final String medicalNotes;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelation;
  final String emergencyContact2Name;
  final String emergencyContact2Phone;
  final String emergencyContact2Relation;
  final int avatarIndex;

  const ProfileModel({
    this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.bloodGroup,
    required this.allergies,
    required this.medications,
    required this.medicalConditions,
    this.medicalNotes = '',
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.emergencyContactRelation,
    this.emergencyContact2Name = '',
    this.emergencyContact2Phone = '',
    this.emergencyContact2Relation = '',
    this.avatarIndex = 0,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString(),
      fullName: json['full_name'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      bloodGroup: json['blood_group'] ?? '',
      allergies: json['allergies'] ?? '',
      medications: json['medications'] ?? '',
      medicalConditions: json['medical_conditions'] ?? '',
      medicalNotes: json['medical_notes'] ?? '',
      emergencyContactName: json['emergency_contact_name'] ?? '',
      emergencyContactPhone: json['emergency_contact_phone'] ?? '',
      emergencyContactRelation: json['emergency_contact_relation'] ?? '',
      emergencyContact2Name: json['emergency_contact_2_name'] ?? '',
      emergencyContact2Phone: json['emergency_contact_2_phone'] ?? '',
      emergencyContact2Relation: json['emergency_contact_2_relation'] ?? '',
      avatarIndex: json['avatar_index'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'full_name': fullName,
    'date_of_birth': dateOfBirth,
    'blood_group': bloodGroup,
    'allergies': allergies,
    'medications': medications,
    'medical_conditions': medicalConditions,
    'medical_notes': medicalNotes,
    'emergency_contact_name': emergencyContactName,
    'emergency_contact_phone': emergencyContactPhone,
    'emergency_contact_relation': emergencyContactRelation,
    'emergency_contact_2_name': emergencyContact2Name,
    'emergency_contact_2_phone': emergencyContact2Phone,
    'emergency_contact_2_relation': emergencyContact2Relation,
    'avatar_index': avatarIndex,
  };

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? dateOfBirth,
    String? bloodGroup,
    String? allergies,
    String? medications,
    String? medicalConditions,
    String? medicalNotes,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? emergencyContact2Name,
    String? emergencyContact2Phone,
    String? emergencyContact2Relation,
    int? avatarIndex,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      emergencyContact2Name:
          emergencyContact2Name ?? this.emergencyContact2Name,
      emergencyContact2Phone:
          emergencyContact2Phone ?? this.emergencyContact2Phone,
      emergencyContact2Relation:
          emergencyContact2Relation ?? this.emergencyContact2Relation,
      avatarIndex: avatarIndex ?? this.avatarIndex,
    );
  }

  static ProfileModel empty() => const ProfileModel(
    fullName: '',
    dateOfBirth: '',
    bloodGroup: '',
    allergies: '',
    medications: '',
    medicalConditions: '',
    medicalNotes: '',
    emergencyContactName: '',
    emergencyContactPhone: '',
    emergencyContactRelation: '',
    emergencyContact2Name: '',
    emergencyContact2Phone: '',
    emergencyContact2Relation: '',
    avatarIndex: 0,
  );
}
