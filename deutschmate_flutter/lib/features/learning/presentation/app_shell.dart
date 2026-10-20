import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../application/learning_controller.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.controller,
    required this.strings,
    required this.selectedIndex,
    required this.child,
    super.key,
  });

  final LearningController controller;
  final AppStrings strings;
  final int selectedIndex;
  final Widget child;

  void _navigate(BuildContext context, int index) {
    const locations = ['/', '/lessons', '/practice', '/settings'];
    context.go(locations[index]);
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.space_dashboard_outlined),
        selectedIcon: const Icon(Icons.space_dashboard),
        label: strings.text('home'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.menu_book_outlined),
        selectedIcon: const Icon(Icons.menu_book),
        label: strings.text('lessons'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.style_outlined),
        selectedIcon: const Icon(Icons.style),
        label: strings.text('practice'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.tune_outlined),
        selectedIcon: const Icon(Icons.tune),
        label: strings.text('settings'),
      ),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.brand,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Text(
                'D',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              strings.text('appName'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: strings.text('language'),
            initialValue: controller.localeCode,
            onSelected: controller.setLocale,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'ar', child: Text('العربية')),
              PopupMenuItem(value: 'de', child: Text('Deutsch')),
              PopupMenuItem(value: 'en', child: Text('English')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text(controller.localeCode.toUpperCase())),
            ),
          ),
          IconButton(
            tooltip: strings.text('theme'),
            onPressed: () => controller.setTheme(!controller.isDark),
            icon: Icon(
              controller.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) => _navigate(context, value),
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map(
                    (item) => NavigationRailDestination(
                      icon: item.icon,
                      selectedIcon: item.selectedIcon,
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),
          Expanded(
            child: Column(
              children: [
                if (controller.persistenceWarning)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            strings.text('storageWarning'),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (value) => _navigate(context, value),
              destinations: destinations,
            ),
    );
  }
}
