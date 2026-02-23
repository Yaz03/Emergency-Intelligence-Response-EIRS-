import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/emergency_model.dart';

class EmergencyRepository {
  final sb.SupabaseClient _client;

  EmergencyRepository({sb.SupabaseClient? client})
    : _client = client ?? sb.Supabase.instance.client;

  /// Insert an emergency incident into the `emergency_incidents` table.
  Future<EmergencyIncident> sendIncident(EmergencyIncident incident) async {
    final userId = _client.auth.currentUser!.id;
    final json = incident.toJson();
    json['user_id'] = userId;

    final data =
        await _client
            .from('emergency_incidents')
            .insert(json)
            .select()
            .single();

    return EmergencyIncident.fromJson(data);
  }
}
