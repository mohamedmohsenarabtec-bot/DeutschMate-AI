import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deutschmate_ai/core/localization/app_strings.dart';
import 'package:deutschmate_ai/features/ai_tutor/application/ai_tutor_gateway.dart';
import 'package:deutschmate_ai/features/ai_tutor/presentation/ai_tutor_panel.dart';

void main() {
  testWidgets('unconfigured tutor is identified as disconnected', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AiTutorPanel(strings: AppStrings('en'))),
      ),
    );

    expect(find.textContaining('is not connected yet'), findsOneWidget);
    expect(find.byTooltip('Send'), findsOneWidget);
  });

  testWidgets('authenticated learner can send a levelled tutoring request', (
    tester,
  ) async {
    final gateway = _FakeAiTutorGateway();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiTutorPanel(strings: const AppStrings('ar'), gateway: gateway),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Warum heißt es der Name?');
    await tester.tap(find.byTooltip('إرسال'));
    await tester.pumpAndSettle();

    expect(gateway.sentMessage, 'Warum heißt es der Name?');
    expect(gateway.sentLocale, 'ar');
    expect(gateway.sentLevel, 'a1');
    expect(find.text('Der Name ist maskulin.'), findsOneWidget);
    expect(find.text('Warum heißt es der Name?'), findsOneWidget);
  });

  testWidgets('guest learner is asked to sign in without calling the service', (
    tester,
  ) async {
    final gateway = _FakeAiTutorGateway()..isLoggedIn = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiTutorPanel(strings: const AppStrings('en'), gateway: gateway),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Explain articles.');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sign in to use the tutor'), findsOneWidget);
    expect(gateway.calls, 0);
  });
}

class _FakeAiTutorGateway implements AiTutorGateway {
  bool isLoggedIn = true;
  int calls = 0;
  String? sentMessage;
  String? sentLocale;
  String? sentLevel;

  @override
  bool get isAuthenticated => isLoggedIn;

  @override
  Future<AiTutorReply> sendMessage({
    required String message,
    required String locale,
    required String cefrLevel,
    required String task,
    String? conversationId,
  }) async {
    calls++;
    sentMessage = message;
    sentLocale = locale;
    sentLevel = cefrLevel;
    return const AiTutorReply(
      conversationId: '10000000-0000-4000-8000-000000000001',
      text: 'Der Name ist maskulin.',
    );
  }
}
