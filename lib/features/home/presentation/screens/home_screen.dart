import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:eirs/features/auth/presentation/providers/auth_provider.dart';
import 'package:eirs/features/profile/presentation/screens/profile_screen.dart';
import 'package:eirs/features/qr/presentation/screens/qr_screen.dart';
import 'package:eirs/features/emergency/presentation/screens/emergency_screen.dart';
import 'package:eirs/features/account/presentation/screens/account_screen.dart';
import 'package:eirs/features/profile/presentation/providers/profile_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _DashboardPage(onTabSelected: _onTabSelected),
      const ProfileScreen(),
      const QrScreen(),
      const EmergencyScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            selectedIcon: Icon(Icons.qr_code_2),
            label: 'QR Code',
          ),
          NavigationDestination(
            icon: Icon(Icons.emergency_outlined),
            selectedIcon: Icon(Icons.emergency),
            label: 'Emergency',
          ),
        ],
      ),
    );
  }
}

// ── Dashboard (landing tab) ─────────────────────────────────────────────────

class _DashboardPage extends StatefulWidget {
  final ValueChanged<int> onTabSelected;

  const _DashboardPage({required this.onTabSelected});

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  bool _tutorialExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final avatarIndex = profileProvider.profile.avatarIndex;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EIRS'),
        actions: [
          // Avatar / Account button
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                ),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  kAvatarEmojis[avatarIndex],
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──────────────────────────────────────────────
            Text(
              'Welcome${auth.user?.name != null ? ', ${auth.user!.name}' : ''}! 👋',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your medical identity at a glance.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // ── How It Works Tutorial ─────────────────────────────────
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  InkWell(
                    onTap:
                        () => setState(
                          () => _tutorialExpanded = !_tutorialExpanded,
                        ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber.shade700,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'How It Works',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          AnimatedRotation(
                            turns: _tutorialExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(Icons.expand_more, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: const [
                          _TutorialStep(
                            step: '1',
                            icon: Icons.edit_note,
                            color: Colors.teal,
                            title: 'Fill Your Profile',
                            desc:
                                'Add your medical details — blood group, allergies, medications, and emergency contacts.',
                          ),
                          SizedBox(height: 12),
                          _TutorialStep(
                            step: '2',
                            icon: Icons.qr_code_2,
                            color: Colors.indigo,
                            title: 'Generate QR Code',
                            desc:
                                'A secure, time-limited QR code is created with your encrypted medical ID.',
                          ),
                          SizedBox(height: 12),
                          _TutorialStep(
                            step: '3',
                            icon: Icons.document_scanner_outlined,
                            color: Colors.blue,
                            title: 'Healthcare Scans',
                            desc:
                                'In an emergency, healthcare workers scan your QR to instantly access your medical info.',
                          ),
                          SizedBox(height: 12),
                          _TutorialStep(
                            step: '4',
                            icon: Icons.emergency,
                            color: Colors.red,
                            title: 'Emergency SOS',
                            desc:
                                'Press the SOS button to send GPS location and SMS alerts to your emergency contacts.',
                          ),
                        ],
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
                    crossFadeState:
                        _tutorialExpanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 250),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Quick Actions ─────────────────────────────────────────
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _QuickAction(
              icon: Icons.person_outline,
              title: 'Medical Profile',
              subtitle: 'View or edit your medical details',
              color: Colors.teal,
              onTap: () => widget.onTabSelected(1),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.qr_code_2,
              title: 'My QR Code',
              subtitle: 'Show your encrypted medical ID',
              color: Colors.indigo,
              onTap: () => widget.onTabSelected(2),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.emergency,
              title: 'Emergency SOS',
              subtitle: 'Send GPS alert to emergency contacts',
              color: Colors.red,
              onTap: () => widget.onTabSelected(3),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.account_circle_outlined,
              title: 'Account Settings',
              subtitle: 'Avatar, name, password reset',
              color: Colors.purple,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tutorial Step Widget ────────────────────────────────────────────────────

class _TutorialStep extends StatelessWidget {
  final String step;
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _TutorialStep({
    required this.step,
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Icon(icon, color: color, size: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step $step: $title',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Dashboard card ──────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
