import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

/// Avatar options – emoji-based, no image assets needed.
const List<String> kAvatarEmojis = [
  '🧑',
  '👨',
  '👩',
  '👨‍⚕️',
  '👩‍⚕️',
  '🧔',
  '👶',
  '🤖',
  '🦸',
  '🧑‍💻',
  '🧑‍🎓',
  '🧑‍🔬',
];

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  static const routeName = '/account';

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameCtrl = TextEditingController();
  bool _nameDirty = false;
  bool _saving = false;
  bool _resetSent = false;
  int _selectedAvatar = 0;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl.text = auth.user?.name ?? '';
    final profile = context.read<ProfileProvider>().profile;
    _selectedAvatar = profile.avatarIndex;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAvatar(int index) async {
    setState(() => _selectedAvatar = index);
    final provider = context.read<ProfileProvider>();
    final updated = provider.profile.copyWith(avatarIndex: index);
    await provider.saveProfile(updated);
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final provider = context.read<ProfileProvider>();
      await sb.Supabase.instance.client.auth.updateUser(
        sb.UserAttributes(data: {'full_name': name}),
      );
      // Also update profile
      final updated = provider.profile.copyWith(fullName: name);
      await provider.saveProfile(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Name updated!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() => _nameDirty = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _resetPassword() async {
    final email = sb.Supabase.instance.client.auth.currentUser?.email;
    if (email == null) return;

    try {
      await sb.Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        setState(() => _resetSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.email, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Password reset link sent to $email')),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final email =
        sb.Supabase.instance.client.auth.currentUser?.email ?? 'No email';

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar Section ──────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        kAvatarEmojis[_selectedAvatar],
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auth.user?.name ?? 'User',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Choose Avatar ───────────────────────────────────────
            Text(
              'Choose Avatar',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(kAvatarEmojis.length, (i) {
                final isSelected = _selectedAvatar == i;
                return GestureDetector(
                  onTap: () => _saveAvatar(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        kAvatarEmojis[i],
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const Divider(height: 40),

            // ── Edit Name ───────────────────────────────────────────
            Text(
              'Display Name',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    onChanged: (_) {
                      if (!_nameDirty) setState(() => _nameDirty = true);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.edit_outlined, size: 20),
                    ),
                  ),
                ),
                if (_nameDirty) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _saveName,
                    child:
                        _saving
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Save'),
                  ),
                ],
              ],
            ),

            const Divider(height: 40),

            // ── Forgot Password ─────────────────────────────────────
            Text(
              'Security',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Reset Password'),
                subtitle: Text(
                  _resetSent
                      ? 'Check your email for the reset link'
                      : 'Send a password reset link to your email',
                  style: theme.textTheme.bodySmall,
                ),
                trailing:
                    _resetSent
                        ? const Icon(Icons.check, color: Colors.green)
                        : const Icon(Icons.chevron_right),
                onTap: _resetSent ? null : _resetPassword,
              ),
            ),

            const SizedBox(height: 24),

            // ── Logout ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}
