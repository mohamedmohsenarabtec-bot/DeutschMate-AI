import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/localization/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/account/application/account_gateway.dart';
import 'features/ai_tutor/application/ai_tutor_gateway.dart';
import 'features/learning/application/learning_controller.dart';
import 'features/learning/presentation/app_shell.dart';
import 'features/learning/presentation/dashboard_screen.dart';
import 'features/learning/presentation/lesson_screen.dart';
import 'features/learning/presentation/practice_screen.dart';
import 'features/learning/presentation/settings_screen.dart';

class DeutschMateApp extends StatefulWidget {
  const DeutschMateApp({
    required this.controller,
    this.accountGateway,
    this.aiTutorGateway,
    super.key,
  });

  final LearningController controller;
  final AccountGateway? accountGateway;
  final AiTutorGateway? aiTutorGateway;

  @override
  State<DeutschMateApp> createState() => _DeutschMateAppState();
}

class _DeutschMateAppState extends State<DeutschMateApp> {
  Widget _localized(Widget Function(AppStrings strings) build) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => build(AppStrings(widget.controller.localeCode)),
    );
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    refreshListenable: widget.controller,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final index = switch (state.uri.path) {
            '/lessons' => 1,
            '/practice' => 2,
            '/settings' => 3,
            _ => 0,
          };
          return _localized(
            (strings) => AppShell(
              controller: widget.controller,
              strings: strings,
              selectedIndex: index,
              child: child,
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => _localized(
              (strings) => DashboardScreen(
                controller: widget.controller,
                strings: strings,
                onStartLesson: () => context.go('/lessons'),
                onPractice: () => context.go('/practice'),
              ),
            ),
          ),
          GoRoute(
            path: '/lessons',
            builder: (context, state) => _localized(
              (strings) =>
                  LessonScreen(controller: widget.controller, strings: strings),
            ),
          ),
          GoRoute(
            path: '/practice',
            builder: (context, state) => _localized(
              (strings) => PracticeScreen(
                controller: widget.controller,
                strings: strings,
                aiTutorGateway: widget.aiTutorGateway,
              ),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => _localized(
              (strings) => SettingsScreen(
                controller: widget.controller,
                strings: strings,
                accountGateway: widget.accountGateway,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/auth-callback',
        redirect: (context, state) => '/settings',
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final locale = Locale(widget.controller.localeCode);
        return MaterialApp.router(
          title: 'DeutschMate AI',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [Locale('ar'), Locale('de'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: widget.controller.isDark
              ? ThemeMode.dark
              : ThemeMode.light,
          routerConfig: _router,
          builder: (context, child) => Directionality(
            textDirection: widget.controller.localeCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
