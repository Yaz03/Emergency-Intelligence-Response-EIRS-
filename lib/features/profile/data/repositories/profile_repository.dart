import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/profile_model.dart';

/// Data‑layer repository for the profile endpoints.
class ProfileRepository {
  final DioClient _client;

  ProfileRepository({required DioClient client}) : _client = client;

  /// GET /profile
  Future<ProfileModel> getProfile() async {
    final response = await _client.get(ApiConstants.profile);
    return ProfileModel.fromJson(response.data);
  }

  /// PUT /profile/update
  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    final response = await _client.put(
      ApiConstants.profileUpdate,
      data: profile.toJson(),
    );
    return ProfileModel.fromJson(response.data);
  }
}
