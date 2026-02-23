import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/auth_response.dart';
import '../models/user_model.dart';

/// Data-layer repository that talks to Supabase Auth.
class AuthRepository {
  final sb.SupabaseClient _client;

  AuthRepository({sb.SupabaseClient? client})
    : _client = client ?? sb.Supabase.instance.client;

  /// Register with email + password.
  /// Stores the user's name in Supabase Auth metadata.
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, if (phone != null) 'phone': phone},
    );

    final session = res.session;
    final user = res.user;

    if (user == null) {
      throw sb.AuthException(
        'Registration failed. Please check your email for confirmation.',
      );
    }

    return AuthResponse(
      accessToken: session?.accessToken ?? '',
      refreshToken: session?.refreshToken ?? '',
      user: UserModel(
        id: user.id,
        name: user.userMetadata?['name'] ?? name,
        email: user.email ?? email,
        phone: user.userMetadata?['phone'] ?? phone,
      ),
    );
  }

  /// Log in with email + password.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final session = res.session!;
    final user = res.user!;

    return AuthResponse(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      user: UserModel(
        id: user.id,
        name: user.userMetadata?['name'] ?? '',
        email: user.email ?? email,
        phone: user.userMetadata?['phone'],
      ),
    );
  }

  /// Sign out the current user.
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Get the currently authenticated user, or null.
  UserModel? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return UserModel(
      id: user.id,
      name: user.userMetadata?['name'] ?? '',
      email: user.email ?? '',
      phone: user.userMetadata?['phone'],
    );
  }

  /// Whether there is an active session.
  bool get hasSession => _client.auth.currentSession != null;
}
