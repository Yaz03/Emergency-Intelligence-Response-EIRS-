import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../data/models/emergency_model.dart';
import '../../data/repositories/emergency_repository.dart';

enum EmergencyStatus { idle, locating, sending, sent, error }

class EmergencyProvider extends ChangeNotifier {
  final EmergencyRepository _repository;

  EmergencyStatus _status = EmergencyStatus.idle;
  String? _errorMessage;
  EmergencyIncident? _lastIncident;

  EmergencyProvider({required EmergencyRepository repository})
      : _repository = repository;

  // ── Getters ─────────────────────────────────────────────────────────────
  EmergencyStatus get status => _status;
  String? get errorMessage => _errorMessage;
  EmergencyIncident? get lastIncident => _lastIncident;
  bool get isBusy =>
      _status == EmergencyStatus.locating || _status == EmergencyStatus.sending;

  // ── Trigger Emergency ──────────────────────────────────────────────────
  Future<bool> triggerEmergency({String? notes}) async {
    _errorMessage = null;

    // 1. Get GPS location
    _status = EmergencyStatus.locating;
    notifyListeners();

    Position position;
    try {
      position = await _determinePosition();
    } catch (e) {
      _setError('Failed to get location: $e');
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
      _status = EmergencyStatus.sent;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Failed to send emergency: $e');
      return false;
    }
  }

  void reset() {
    _status = EmergencyStatus.idle;
    _errorMessage = null;
    _lastIncident = null;
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
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
