import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:url_launcher/url_launcher.dart';

import '../../../profile/data/repositories/profile_repository.dart';
import '../../data/models/emergency_model.dart';
import '../../data/repositories/emergency_repository.dart';

enum EmergencyStatus { idle, locating, sending, sent, error }

class EmergencyProvider extends ChangeNotifier {
  final EmergencyRepository _repository;
  final ProfileRepository _profileRepository;

  EmergencyStatus _status = EmergencyStatus.idle;
  String? _errorMessage;
  EmergencyIncident? _lastIncident;
  bool _smsSent = false;

  EmergencyProvider({
    required EmergencyRepository repository,
    required ProfileRepository profileRepository,
  }) : _repository = repository,
       _profileRepository = profileRepository;

  // ── Getters ─────────────────────────────────────────────────────────────
  EmergencyStatus get status => _status;
  String? get errorMessage => _errorMessage;
  EmergencyIncident? get lastIncident => _lastIncident;
  bool get smsSent => _smsSent;
  bool get isBusy =>
      _status == EmergencyStatus.locating || _status == EmergencyStatus.sending;

  // ── Trigger Emergency ──────────────────────────────────────────────────
  Future<bool> triggerEmergency({String? notes}) async {
    _errorMessage = null;
    _smsSent = false;

    // 1. Get GPS location
    _status = EmergencyStatus.locating;
    notifyListeners();

    Position position;
    try {
      position = await _determinePosition();
    } catch (e) {
      _setError('$e');
      return false;
    }

    // 2. Send incident to backend
    _status = EmergencyStatus.sending;
    notifyListeners();

    final incident = EmergencyIncident(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      notes: notes,
    );

    try {
      _lastIncident = await _repository.sendIncident(incident);

      // 3. Send SMS to emergency contact
      await _sendEmergencySms(position.latitude, position.longitude);

      _status = EmergencyStatus.sent;
      notifyListeners();
      return true;
    } on sb.PostgrestException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to send emergency: $e');
      return false;
    }
  }

  /// Send SMS to the emergency contact saved in the user's profile.
  Future<void> _sendEmergencySms(double lat, double lng) async {
    try {
      final profile = await _profileRepository.getProfile();

      final phone = profile.emergencyContactPhone;
      if (phone.isEmpty) {
        debugPrint('No emergency contact phone number saved in profile.');
        return;
      }

      final userName =
          profile.fullName.isNotEmpty ? profile.fullName : 'A MediQR user';
      final mapsLink = 'https://maps.google.com/?q=$lat,$lng';

      final message = Uri.encodeComponent(
        '🚨 EMERGENCY ALERT!\n\n'
        '$userName has triggered an emergency SOS.\n\n'
        '📍 Location: $mapsLink\n\n'
        'Please respond immediately.\n'
        '— Sent via Smart Medical ID',
      );

      final smsUri = Uri.parse('sms:$phone?body=$message');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        _smsSent = true;
      } else {
        debugPrint('Could not launch SMS app');
      }
    } catch (e) {
      debugPrint('SMS error: $e');
      // Don't fail the whole emergency for SMS issues
    }
  }

  void reset() {
    _status = EmergencyStatus.idle;
    _errorMessage = null;
    _lastIncident = null;
    _smsSent = false;
    notifyListeners();
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  void _setError(String msg) {
    _status = EmergencyStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable GPS in Settings and try again.';
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permission denied. Please allow location access to use Emergency SOS.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw 'Location permission is permanently denied. Please enable it in App Settings → Permissions.';
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
