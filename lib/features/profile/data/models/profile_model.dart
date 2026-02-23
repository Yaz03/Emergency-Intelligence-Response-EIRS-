class ProfileModel {
  final String? id;
  final String fullName;
  final String dateOfBirth;
  final String bloodGroup;
  final String allergies;
  final String medications;
  final String medicalConditions;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelation;

  const ProfileModel({
    this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.bloodGroup,
    required this.allergies,
    required this.medications,
    required this.medicalConditions,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.emergencyContactRelation,
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
      emergencyContactName: json['emergency_contact_name'] ?? '',
      emergencyContactPhone: json['emergency_contact_phone'] ?? '',
      emergencyContactRelation: json['emergency_contact_relation'] ?? '',
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
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'emergency_contact_relation': emergencyContactRelation,
      };

  ProfileModel copyWith({
    String? id,
    String? fullName,
    String? dateOfBirth,
    String? bloodGroup,
    String? allergies,
    String? medications,
    String? medicalConditions,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation: emergencyContactRelation ?? this.emergencyContactRelation,
    );
  }

  static ProfileModel empty() => const ProfileModel(
        fullName: '',
        dateOfBirth: '',
        bloodGroup: '',
        allergies: '',
        medications: '',
        medicalConditions: '',
        emergencyContactName: '',
        emergencyContactPhone: '',
        emergencyContactRelation: '',
      );
}
