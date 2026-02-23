import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

/// Dropdown for selecting blood group with consistent styling.
class BloodGroupDropdown extends StatelessWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const BloodGroupDropdown({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: initialValue != null && initialValue!.isNotEmpty ? initialValue : null,
        decoration: const InputDecoration(
          labelText: 'Blood Group',
          prefixIcon: Icon(Icons.bloodtype_outlined, size: 20),
        ),
        items: AppConstants.bloodGroups.map((group) {
          return DropdownMenuItem(value: group, child: Text(group));
        }).toList(),
        onChanged: onChanged,
        validator: (val) =>
            val == null || val.isEmpty ? 'Please select blood group' : null,
        dropdownColor: theme.colorScheme.surfaceContainer,
      ),
    );
  }
}
