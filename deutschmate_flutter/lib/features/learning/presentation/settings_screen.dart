import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../account/application/account_gateway.dart';
import '../../account/presentation/account_panel.dart';
import '../application/learning_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.controller,
    required this.strings,
    this.accountGateway,
    super.key,
  });
  final LearningController controller;
  final AppStrings strings;
  final AccountGateway? accountGateway;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.controller.learnerName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = widget.strings;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          s.text('settings'),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        AccountPanel(strings: s, controller: c, gateway: widget.accountGateway),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.text('profile'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  maxLength: 50,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: s.text('preferredName'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: c.weeklyGoal,
                  decoration: InputDecoration(
                    labelText: s.text('weeklyGoal'),
                    prefixIcon: const Icon(Icons.flag_outlined),
                  ),
                  items: [3, 5, 7]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value ${s.text('sessions')}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      await c.updateProfile(
                        name: _nameController.text,
                        goal: value,
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => c.updateProfile(
                    name: _nameController.text,
                    goal: c.weeklyGoal,
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(s.text('save')),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.translate),
                title: Text(s.text('language')),
                trailing: DropdownButton<String>(
                  value: c.localeCode,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value != null) c.setLocale(value);
                  },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: Text(s.text('theme')),
                value: c.isDark,
                onChanged: c.setTheme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          s.text('reviewedNote'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
