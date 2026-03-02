import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/supabase_constants.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/emergency/data/repositories/emergency_repository.dart';
import 'features/emergency/presentation/providers/emergency_provider.dart';
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/qr/presentation/providers/qr_provider.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  // ── Supabase ────────────────────────────────────────────────────────────
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  // ── Repositories (all use Supabase client internally) ──────────────────
  final authRepo = AuthRepository();
  final profileRepo = ProfileRepository();
  final emergencyRepo = EmergencyRepository();

  runApp(
    MultiProvider(
      providers: [
        // Auth
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(repository: authRepo)..checkAuthStatus(),
        ),

        // Profile
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(repository: profileRepo),
        ),

        // QR
        ChangeNotifierProvider<QrProvider>(create: (_) => QrProvider()),

        // Emergency
        ChangeNotifierProvider<EmergencyProvider>(
          create:
              (_) => EmergencyProvider(
                repository: emergencyRepo,
                profileRepository: profileRepo,
              ),
        ),
      ],
      child: const MediQRApp(),
    ),
  );
}
