import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/profile_model.dart';

/// Data-layer repository for the profile – uses Supabase Database.
class ProfileRepository {
  final sb.SupabaseClient _client;

  ProfileRepository({sb.SupabaseClient? client})
    : _client = client ?? sb.Supabase.instance.client;

  /// Fetch the current user's profile.
  Future<ProfileModel> getProfile() async {
    final userId = _client.auth.currentUser!.id;
    final data =
        await _client
            .from('profiles')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

    if (data == null) {
      return ProfileModel.empty();
    }
    return ProfileModel.fromJson(data);
  }

  /// Create or update the current user's profile (upsert).
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    final userId = _client.auth.currentUser!.id;
    final json = profile.toJson();
    json['user_id'] = userId;

    final data =
        await _client
            .from('profiles')
            .upsert(json, onConflict: 'user_id')
            .select()
            .single();

    return ProfileModel.fromJson(data);
  }
}
