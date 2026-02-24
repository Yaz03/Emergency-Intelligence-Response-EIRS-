import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final TextEditingController _notesCtrl;
  late final TextEditingController _ecNameCtrl;
  late final TextEditingController _ecPhoneCtrl;
  late final TextEditingController _ecRelationCtrl;
  late final TextEditingController _ec2NameCtrl;
  late final TextEditingController _ec2PhoneCtrl;
  late final TextEditingController _ec2RelationCtrl;
  String? _selectedBloodGroup;
  bool _initialized = false;
  bool _showContact2 = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _dobCtrl = TextEditingController();
    _allergiesCtrl = TextEditingController();
    _medicationsCtrl = TextEditingController();
    _conditionsCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _ecNameCtrl = TextEditingController();
    _ecPhoneCtrl = TextEditingController();
    _ecRelationCtrl = TextEditingController();
    _ec2NameCtrl = TextEditingController();
    _ec2PhoneCtrl = TextEditingController();
    _ec2RelationCtrl = TextEditingController();

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
    _notesCtrl.dispose();
    _ecNameCtrl.dispose();
    _ecPhoneCtrl.dispose();
    _ecRelationCtrl.dispose();
    _ec2NameCtrl.dispose();
    _ec2PhoneCtrl.dispose();
    _ec2RelationCtrl.dispose();
    super.dispose();
  }

  void _populateFields(ProfileModel profile) {
    if (_initialized) return;
    _nameCtrl.text = profile.fullName;
    _dobCtrl.text = profile.dateOfBirth;
    _allergiesCtrl.text = profile.allergies;
    _medicationsCtrl.text = profile.medications;
    _conditionsCtrl.text = profile.medicalConditions;
    _notesCtrl.text = profile.medicalNotes;
    _ecNameCtrl.text = profile.emergencyContactName;
    _ecPhoneCtrl.text = profile.emergencyContactPhone;
    _ecRelationCtrl.text = profile.emergencyContactRelation;
    _ec2NameCtrl.text = profile.emergencyContact2Name;
    _ec2PhoneCtrl.text = profile.emergencyContact2Phone;
    _ec2RelationCtrl.text = profile.emergencyContact2Relation;
    _selectedBloodGroup =
        profile.bloodGroup.isNotEmpty ? profile.bloodGroup : null;
    _showContact2 =
        profile.emergencyContact2Name.isNotEmpty ||
        profile.emergencyContact2Phone.isNotEmpty;
    _initialized = true;
  }

  // ── Date Picker ───────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseDob() ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'SELECT DATE OF BIRTH',
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  DateTime? _parseDob() {
    final text = _dobCtrl.text.trim();
    if (text.isEmpty) return null;
    try {
      // Try DD/MM/YYYY
      if (text.contains('/')) {
        final parts = text.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      // Try YYYY-MM-DD (legacy)
      return DateTime.parse(text);
    } catch (_) {
      return null;
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ProfileModel(
      fullName: _nameCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text.trim(),
      bloodGroup: _selectedBloodGroup ?? '',
      allergies: _allergiesCtrl.text.trim(),
      medications: _medicationsCtrl.text.trim(),
      medicalConditions: _conditionsCtrl.text.trim(),
      medicalNotes: _notesCtrl.text.trim(),
      emergencyContactName: _ecNameCtrl.text.trim(),
      emergencyContactPhone: _ecPhoneCtrl.text.trim(),
      emergencyContactRelation: _ecRelationCtrl.text.trim(),
      emergencyContact2Name: _ec2NameCtrl.text.trim(),
      emergencyContact2Phone: _ec2PhoneCtrl.text.trim(),
      emergencyContact2Relation: _ec2RelationCtrl.text.trim(),
    );

    final success = await context.read<ProfileProvider>().saveProfile(profile);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              success
                  ? 'Profile saved successfully!'
                  : 'Failed to save profile',
            ),
          ],
        ),
        backgroundColor:
            success ? Colors.green : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    if (profileProvider.status == ProfileStatus.loaded) {
      _populateFields(profileProvider.profile);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Medical Profile')),
      body:
          profileProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Personal Info ───────────────────────────────────
                      _SectionHeader(
                        title: 'Personal Information',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        prefixIcon: Icons.badge_outlined,
                        validator: Validators.name,
                      ),

                      // DOB with date picker + auto-format
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _dobCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator:
                              (v) => Validators.required(v, 'Date of Birth'),
                          inputFormatters: [_DateInputFormatter()],
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            hintText: 'DD/MM/YYYY',
                            prefixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.date_range, size: 20),
                              onPressed: _pickDate,
                            ),
                          ),
                        ),
                      ),

                      BloodGroupDropdown(
                        initialValue: _selectedBloodGroup,
                        onChanged:
                            (v) => setState(() => _selectedBloodGroup = v),
                      ),

                      const Divider(height: 32),

                      // ── Medical Info ────────────────────────────────────
                      _SectionHeader(
                        title: 'Medical Information',
                        icon: Icons.medical_services_outlined,
                      ),
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

                      // Medical Notes (optional, multiline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _notesCtrl,
                          maxLines: 4,
                          minLines: 2,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            labelText: 'Medical Notes (Optional)',
                            hintText:
                                'Any additional medical details, past surgeries, special instructions…',
                            prefixIcon: Icon(Icons.notes_outlined, size: 20),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),

                      const Divider(height: 32),

                      // ── Emergency Contact 1 ────────────────────────────
                      _SectionHeader(
                        title: 'Emergency Contact',
                        icon: Icons.emergency_outlined,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Optional – but highly recommended',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AuthTextField(
                        controller: _ecNameCtrl,
                        label: 'Contact Name',
                        prefixIcon: Icons.person_outline,
                      ),
                      AuthTextField(
                        controller: _ecPhoneCtrl,
                        label: 'Contact Phone',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      AuthTextField(
                        controller: _ecRelationCtrl,
                        label: 'Relationship',
                        hint: 'e.g. Spouse, Parent',
                        prefixIcon: Icons.people_outline,
                      ),

                      // ── Emergency Contact 2 (toggle) ───────────────────
                      if (!_showContact2)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: OutlinedButton.icon(
                            onPressed:
                                () => setState(() => _showContact2 = true),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Another Contact'),
                          ),
                        ),

                      if (_showContact2) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _SectionHeader(
                              title: 'Emergency Contact 2',
                              icon: Icons.emergency_outlined,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showContact2 = false;
                                  _ec2NameCtrl.clear();
                                  _ec2PhoneCtrl.clear();
                                  _ec2RelationCtrl.clear();
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AuthTextField(
                          controller: _ec2NameCtrl,
                          label: 'Contact Name',
                          prefixIcon: Icons.person_outline,
                        ),
                        AuthTextField(
                          controller: _ec2PhoneCtrl,
                          label: 'Contact Phone',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        AuthTextField(
                          controller: _ec2RelationCtrl,
                          label: 'Relationship',
                          hint: 'e.g. Sibling, Friend',
                          prefixIcon: Icons.people_outline,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ── Save ────────────────────────────────────────────
                      ElevatedButton(
                        onPressed: profileProvider.isSaving ? null : _save,
                        child:
                            profileProvider.isSaving
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

// ── Section Header ──────────────────────────────────────────────────────────

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

// ── Date Input Formatter (auto-inserts slashes as DD/MM/YYYY) ───────────────

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only allow digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 8 digits (DDMMYYYY)
    final limited =
        digitsOnly.length > 8 ? digitsOnly.substring(0, 8) : digitsOnly;

    final buffer = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(limited[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
