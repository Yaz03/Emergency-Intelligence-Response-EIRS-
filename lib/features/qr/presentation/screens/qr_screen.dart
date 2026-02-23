import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/qr_provider.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QrProvider>().generateQrData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrProvider = context.watch<QrProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medical QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh QR',
            onPressed: qrProvider.isLoading ? null : () => qrProvider.refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Full Screen',
            onPressed: qrProvider.hasData
                ? () => _showFullScreen(context, qrProvider.encryptedPatientId!)
                : null,
          ),
        ],
      ),
      body: Center(
        child: qrProvider.isLoading
            ? const CircularProgressIndicator()
            : qrProvider.hasData
                ? _buildQrCard(context, qrProvider.encryptedPatientId!)
                : _buildEmptyState(theme),
      ),
    );
  }

  Widget _buildQrCard(BuildContext context, String data) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan this code',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Present this QR to medical staff for instant access to your medical ID.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 220,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0D6EFD),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _showFullScreen(context, data),
                icon: const Icon(Icons.fullscreen),
                label: const Text('View Full Screen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.qr_code_2, size: 80, color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 16),
        Text(
          'No QR data available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.read<QrProvider>().refresh(),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  void _showFullScreen(BuildContext context, String data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenQr(data: data),
      ),
    );
  }
}

// ── Full‑screen QR overlay ──────────────────────────────────────────────────

class _FullScreenQr extends StatelessWidget {
  final String data;

  const _FullScreenQr({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('Medical QR Code'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: MediaQuery.of(context).size.width * 0.8,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF0D6EFD),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
      ),
    );
  }
}
