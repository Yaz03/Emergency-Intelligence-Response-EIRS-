import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/network/dio_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/emergency/data/repositories/emergency_repository.dart';
import 'features/emergency/presentation/providers/emergency_provider.dart';
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/qr/presentation/providers/qr_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Core services ───────────────────────────────────────────────────────
  final secureStorage = SecureStorageService();
  final dioClient = DioClient(storage: secureStorage);

  // ── Repositories ────────────────────────────────────────────────────────
  final authRepo = AuthRepository(client: dioClient);
  final profileRepo = ProfileRepository(client: dioClient);
  final emergencyRepo = EmergencyRepository(client: dioClient);

  runApp(
    MultiProvider(
      providers: [
        // Auth
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            repository: authRepo,
            storage: secureStorage,
          )..checkAuthStatus(),
        ),

        // Profile
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(repository: profileRepo),
        ),

        // QR
        ChangeNotifierProvider<QrProvider>(
          create: (_) => QrProvider(storage: secureStorage),
        ),

        // Emergency
        ChangeNotifierProvider<EmergencyProvider>(
          create: (_) => EmergencyProvider(repository: emergencyRepo),
        ),
      ],
      child: const MediQRApp(),
    ),
  );
}
