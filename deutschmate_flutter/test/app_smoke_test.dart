import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deutschmate_ai/app.dart';
import 'package:deutschmate_ai/core/data/learning_repository.dart';
import 'package:deutschmate_ai/features/learning/application/learning_controller.dart';

void main() {
  testWidgets('opens the Arabic RTL learning dashboard', (tester) async {
    final controller = LearningController(
      repository: MemoryLearningRepository(),
    );
    await controller.load();
    await tester.pumpWidget(DeutschMateApp(controller: controller));

    expect(find.text('DeutschMate AI'), findsOneWidget);
    expect(find.text('طريقك إلى الطلاقة'), findsOneWidget);
    expect(find.text('التعارف والتحية'), findsOneWidget);
    expect(find.text('ابدأ الدرس'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('طريقك إلى الطلاقة'))),
      TextDirection.rtl,
    );
  });

  testWidgets('can switch to German and navigate to the lesson', (
    tester,
  ) async {
    final controller = LearningController(
      repository: MemoryLearningRepository(),
    );
    await controller.load();
    await tester.pumpWidget(DeutschMateApp(controller: controller));
    await tester.tap(find.text('AR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch').first);
    await tester.pumpAndSettle();

    expect(find.text('Dein Weg zur Sprachsicherheit'), findsOneWidget);
    expect(
      Directionality.of(
        tester.element(find.text('Dein Weg zur Sprachsicherheit')),
      ),
      TextDirection.ltr,
    );
    await tester.tap(find.text('Lektionen').first);
    await tester.pumpAndSettle();
    expect(find.text('Begrüßung und Kennenlernen'), findsOneWidget);
  });

  testWidgets('completes the four-word A1 lesson and saves progress', (
    tester,
  ) async {
    final controller = LearningController(
      repository: MemoryLearningRepository(),
    );
    await controller.load();
    await tester.pumpWidget(DeutschMateApp(controller: controller));

    await tester.ensureVisible(find.text('ابدأ الدرس'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ابدأ الدرس'));
    await tester.pumpAndSettle();
    for (var index = 0; index < 3; index++) {
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('إنهاء الدرس'));
    await tester.pumpAndSettle();

    expect(controller.completedLessons, contains('greetings'));
    expect(controller.completedLessonCount, 1);
    expect(controller.studySessions, hasLength(1));
    expect(find.text('أحسنت! أتممت الدرس وحُفظ تقدّمك.'), findsOneWidget);
  });

  testWidgets('grammar quiz explains an error and shows its score', (
    tester,
  ) async {
    final controller = LearningController(
      repository: MemoryLearningRepository(),
    );
    await controller.load();
    await tester.pumpWidget(DeutschMateApp(controller: controller));

    await tester.tap(find.text('التدريب').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تحدّي القواعد').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Die Name'));
    await tester.pumpAndSettle();
    expect(find.text('الإجابة الصحيحة: Der Name'), findsOneWidget);
    expect(find.text('كلمة Name مذكّر: der Name.'), findsOneWidget);

    await tester.ensureVisible(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Die Frau'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('نتيجتك'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('نتيجتك'));
    await tester.pumpAndSettle();
    expect(find.text('1 من 2'), findsOneWidget);
    expect(controller.studySessions, hasLength(1));
  });
}
