import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/emergency_provider.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emergency = context.watch<EmergencyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Status icon ───────────────────────────────────────────
              _StatusIcon(status: emergency.status),
              const SizedBox(height: 24),

              // ── Title ─────────────────────────────────────────────────
              Text(
                _title(emergency.status),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _subtitle(emergency.status),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              if (emergency.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emergency.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // ── Emergency Button ──────────────────────────────────────
              if (emergency.status == EmergencyStatus.sent)
                OutlinedButton(
                  onPressed: () => emergency.reset(),
                  child: const Text('Reset'),
                )
              else
                SizedBox(
                  width: 200,
                  height: 200,
                  child: ElevatedButton(
                    onPressed: emergency.isBusy
                        ? null
                        : () => _triggerEmergency(context),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: AppTheme.emergencyRed,
                      foregroundColor: Colors.white,
                      elevation: emergency.isBusy ? 0 : 8,
                    ),
                    child: emergency.isBusy
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emergency_outlined, size: 48),
                              SizedBox(height: 8),
                              Text(
                                'SOS',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _triggerEmergency(BuildContext context) async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Emergency'),
        content: const Text(
          'This will send your current GPS location to emergency services. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emergencyRed,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final success = await context.read<EmergencyProvider>().triggerEmergency();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Emergency signal sent successfully!'
              : 'Failed to send emergency signal',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  String _title(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.idle:
        return 'Emergency Alert';
      case EmergencyStatus.locating:
        return 'Getting Location…';
      case EmergencyStatus.sending:
        return 'Sending Alert…';
      case EmergencyStatus.sent:
        return 'Alert Sent!';
      case EmergencyStatus.error:
        return 'Failed';
    }
  }

  String _subtitle(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.idle:
        return 'Press the SOS button to send your location to emergency contacts.';
      case EmergencyStatus.locating:
        return 'Acquiring your GPS coordinates…';
      case EmergencyStatus.sending:
        return 'Transmitting incident to emergency services…';
      case EmergencyStatus.sent:
        return 'Your emergency signal has been transmitted with your GPS location.';
      case EmergencyStatus.error:
        return 'Something went wrong. Please try again.';
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final EmergencyStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case EmergencyStatus.idle:
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
      case EmergencyStatus.locating:
        icon = Icons.my_location;
        color = Colors.blue;
      case EmergencyStatus.sending:
        icon = Icons.send;
        color = Colors.blue;
      case EmergencyStatus.sent:
        icon = Icons.check_circle;
        color = Colors.green;
      case EmergencyStatus.error:
        icon = Icons.error_outline;
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 48, color: color),
    );
  }
}
