import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/emergency_model.dart';

class EmergencyRepository {
  final DioClient _client;

  EmergencyRepository({required DioClient client}) : _client = client;

  /// POST /emergency/incident
  Future<EmergencyIncident> sendIncident(EmergencyIncident incident) async {
    final response = await _client.post(
      ApiConstants.emergency,
      data: incident.toJson(),
    );
    return EmergencyIncident.fromJson(response.data);
  }
}
