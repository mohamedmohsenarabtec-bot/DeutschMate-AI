import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deutschmate_ai/core/data/learning_repository.dart';
import 'package:deutschmate_ai/core/localization/app_strings.dart';
import 'package:deutschmate_ai/features/account/application/account_gateway.dart';
import 'package:deutschmate_ai/features/account/presentation/account_panel.dart';
import 'package:deutschmate_ai/features/learning/application/learning_controller.dart';

void main() {
  testWidgets('guest state is clearly described as device-local', (
    tester,
  ) async {
    final controller = LearningController(
      repository: MemoryLearningRepository(),
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountPanel(
            strings: const AppStrings('ar'),
            controller: controller,
          ),
        ),
      ),
    );

    expect(
      find.textContaining('تقدّمك محفوظ على هذا الجهاز فقط'),
      findsOneWidget,
    );
  });

  testWidgets('signup waits for email confirmation when session is absent', (
    tester,
  ) async {
    final gateway = _FakeAccountGateway();
    final controller = LearningController(
      repository: MemoryLearningRepository(),
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AccountPanel(
              strings: const AppStrings('en'),
              controller: controller,
              gateway: gateway,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('New account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Layla');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'layla@example.test',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'long-enough-password',
    );
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(gateway.signUpCalls, 1);
    expect(find.textContaining('Verify your email'), findsOneWidget);
    expect(gateway.currentSession, isNull);
  });

  testWidgets('password recovery updates only the authenticated session', (
    tester,
  ) async {
    final gateway = _FakeAccountGateway()
      ..session = const AccountSession(
        userId: 'recovery-user',
        email: 'learner@example.test',
        isPasswordRecovery: true,
      );
    final controller = LearningController(
      repository: MemoryLearningRepository(),
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccountPanel(
            strings: const AppStrings('en'),
            controller: controller,
            gateway: gateway,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'a-new-secure-password');
    await tester.tap(find.text('Save new password'));
    await tester.pumpAndSettle();

    expect(gateway.updatedPassword, isTrue);
    expect(find.text('Password updated.'), findsOneWidget);
  });
}

class _FakeAccountGateway implements AccountGateway {
  final _changes = StreamController<AccountSession?>.broadcast();
  AccountSession? session;
  int signUpCalls = 0;
  bool updatedPassword = false;

  @override
  AccountSession? get currentSession => session;

  @override
  Stream<AccountSession?> get sessionChanges => _changes.stream;

  @override
  Future<AccountActionResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    signUpCalls++;
    return const AccountActionResult(emailConfirmationRequired: true);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    session = AccountSession(userId: 'signed-in-user', email: email);
    _changes.add(session);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> updatePassword(String password) async {
    updatedPassword = true;
  }

  @override
  Future<void> signOut() async {
    session = null;
    _changes.add(null);
  }
}
