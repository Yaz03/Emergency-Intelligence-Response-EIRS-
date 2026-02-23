import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/widgets/auth_text_field.dart';
import '../../data/models/profile_model.dart';
import '../providers/profile_provider.dart';
import '../widgets/blood_group_dropdown.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _allergiesCtrl;
  late final TextEditingController _medicationsCtrl;
  late final TextEditingController _conditionsCtrl;
  late final TextEditingController _ecNameCtrl;
  late final TextEditingController _ecPhoneCtrl;
  late final TextEditingController _ecRelationCtrl;
  String? _selectedBloodGroup;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _dobCtrl = TextEditingController();
    _allergiesCtrl = TextEditingController();
    _medicationsCtrl = TextEditingController();
    _conditionsCtrl = TextEditingController();
    _ecNameCtrl = TextEditingController();
    _ecPhoneCtrl = TextEditingController();
    _ecRelationCtrl = TextEditingController();

    // Fetch profile on first load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationsCtrl.dispose();
    _conditionsCtrl.dispose();
    _ecNameCtrl.dispose();
    _ecPhoneCtrl.dispose();
    _ecRelationCtrl.dispose();
    super.dispose();
  }

  void _populateFields(ProfileModel profile) {
    if (_initialized) return;
    _nameCtrl.text = profile.fullName;
    _dobCtrl.text = profile.dateOfBirth;
    _allergiesCtrl.text = profile.allergies;
    _medicationsCtrl.text = profile.medications;
    _conditionsCtrl.text = profile.medicalConditions;
    _ecNameCtrl.text = profile.emergencyContactName;
    _ecPhoneCtrl.text = profile.emergencyContactPhone;
    _ecRelationCtrl.text = profile.emergencyContactRelation;
    _selectedBloodGroup = profile.bloodGroup.isNotEmpty ? profile.bloodGroup : null;
    _initialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ProfileModel(
      fullName: _nameCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
      bloodGroup: _selectedBloodGroup ?? '',
      allergies: _allergiesCtrl.text.trim(),
      medications: _medicationsCtrl.text.trim(),
      medicalConditions: _conditionsCtrl.text.trim(),
      emergencyContactName: _ecNameCtrl.text.trim(),
      emergencyContactPhone: _ecPhoneCtrl.text.trim(),
      emergencyContactRelation: _ecRelationCtrl.text.trim(),
    );

    final success = await context.read<ProfileProvider>().saveProfile(profile);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Profile saved successfully' : 'Failed to save profile'),
        backgroundColor:
            success ? Colors.green : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final profileProvider = context.watch<ProfileProvider>();

    // Populate fields when data is loaded.
    if (profileProvider.status == ProfileStatus.loaded) {
      _populateFields(profileProvider.profile);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Medical Profile')),
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Personal Info ─────────────────────────────────────
                    _SectionHeader(title: 'Personal Information', icon: Icons.person_outline),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      prefixIcon: Icons.badge_outlined,
                      validator: Validators.name,
                    ),
                    AuthTextField(
                      controller: _dobCtrl,
                      label: 'Date of Birth',
                      hint: 'YYYY-MM-DD',
                      prefixIcon: Icons.calendar_today_outlined,
                      validator: (v) => Validators.required(v, 'Date of Birth'),
                    ),
                    BloodGroupDropdown(
                      initialValue: _selectedBloodGroup,
                      onChanged: (v) => setState(() => _selectedBloodGroup = v),
                    ),

                    const Divider(height: 32),

                    // ── Medical Info ──────────────────────────────────────
                    _SectionHeader(title: 'Medical Information', icon: Icons.medical_services_outlined),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _allergiesCtrl,
                      label: 'Allergies',
                      hint: 'e.g. Penicillin, Peanuts',
                      prefixIcon: Icons.warning_amber_outlined,
                    ),
                    AuthTextField(
                      controller: _medicationsCtrl,
                      label: 'Current Medications',
                      prefixIcon: Icons.medication_outlined,
                    ),
                    AuthTextField(
                      controller: _conditionsCtrl,
                      label: 'Medical Conditions',
                      hint: 'e.g. Diabetes, Asthma',
                      prefixIcon: Icons.health_and_safety_outlined,
                    ),

                    const Divider(height: 32),

                    // ── Emergency Contact ────────────────────────────────
                    _SectionHeader(title: 'Emergency Contact', icon: Icons.emergency_outlined),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _ecNameCtrl,
                      label: 'Contact Name',
                      prefixIcon: Icons.person_outline,
                      validator: Validators.name,
                    ),
                    AuthTextField(
                      controller: _ecPhoneCtrl,
                      label: 'Contact Phone',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                    ),
                    AuthTextField(
                      controller: _ecRelationCtrl,
                      label: 'Relationship',
                      hint: 'e.g. Spouse, Parent',
                      prefixIcon: Icons.people_outline,
                      textInputAction: TextInputAction.done,
                      validator: (v) => Validators.required(v, 'Relationship'),
                    ),

                    const SizedBox(height: 24),

                    // ── Save ──────────────────────────────────────────────
                    ElevatedButton(
                      onPressed: profileProvider.isSaving ? null : _save,
                      child: profileProvider.isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Profile'),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
