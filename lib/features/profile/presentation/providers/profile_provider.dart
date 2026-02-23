import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';

enum ProfileStatus { initial, loading, loaded, saving, error }

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileStatus _status = ProfileStatus.initial;
  ProfileModel _profile = ProfileModel.empty();
  String? _errorMessage;

  ProfileProvider({required ProfileRepository repository})
      : _repository = repository;

  // ── Getters ─────────────────────────────────────────────────────────────
  ProfileStatus get status => _status;
  ProfileModel get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ProfileStatus.loading;
  bool get isSaving => _status == ProfileStatus.saving;

  // ── Fetch Profile ───────────────────────────────────────────────────────
  Future<void> fetchProfile() async {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _profile = await _repository.getProfile();
      _status = ProfileStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = ProfileStatus.error;
    } catch (_) {
      _errorMessage = 'Failed to load profile';
      _status = ProfileStatus.error;
    }
    notifyListeners();
  }

  // ── Save / Update Profile ──────────────────────────────────────────────
  Future<bool> saveProfile(ProfileModel profile) async {
    _status = ProfileStatus.saving;
    _errorMessage = null;
    notifyListeners();
    try {
      _profile = await _repository.updateProfile(profile);
      _status = ProfileStatus.loaded;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = ProfileStatus.error;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to save profile';
      _status = ProfileStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Update local state without persisting (for form binding).
  void updateLocal(ProfileModel profile) {
    _profile = profile;
    notifyListeners();
  }
}
