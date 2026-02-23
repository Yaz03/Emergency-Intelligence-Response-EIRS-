class EmergencyIncident {
  final String? id;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String? notes;
  final String status;

  const EmergencyIncident({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.notes,
    this.status = 'triggered',
  });

  factory EmergencyIncident.fromJson(Map<String, dynamic> json) {
    return EmergencyIncident(
      id: json['id']?.toString(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? '',
      notes: json['notes'],
      status: json['status'] ?? 'triggered',
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
        if (notes != null) 'notes': notes,
        'status': status,
      };
}
