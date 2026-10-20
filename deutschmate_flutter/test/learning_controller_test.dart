import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

import 'package:deutschmate_ai/core/data/learning_repository.dart';
import 'package:deutschmate_ai/features/learning/application/learning_controller.dart';

void main() {
  group('LearningController', () {
    late MemoryLearningRepository repository;
    late DateTime now;
    late LearningController controller;

    setUp(() {
      repository = MemoryLearningRepository();
      now = DateTime(2026, 10, 20, 9);
      controller = LearningController(repository: repository, clock: () => now);
    });

    test('a missed card is due again after ten minutes', () async {
      await controller.reviewCard('danke', remembered: false);
      expect(controller.reviews['danke']?.intervalDays, 0);
      expect(
        controller.reviews['danke']?.nextDue,
        now.add(const Duration(minutes: 10)),
      );
      expect(controller.reviews['danke']?.correctReviews, 0);
    });

    test('remembered cards use one day then double their interval', () async {
      await controller.reviewCard('danke', remembered: true);
      expect(controller.reviews['danke']?.intervalDays, 1);
      expect(
        controller.reviews['danke']?.nextDue,
        now.add(const Duration(days: 1)),
      );

      now = now.add(const Duration(days: 1));
      await controller.reviewCard('danke', remembered: true);
      expect(controller.reviews['danke']?.intervalDays, 2);
      expect(
        controller.reviews['danke']?.nextDue,
        now.add(const Duration(days: 2)),
      );
    });

    test('lesson completion is persisted and does not double count', () async {
      await controller.load();
      await controller.completeLesson('greetings');
      await controller.completeLesson('greetings');

      expect(controller.completedLessonCount, 1);
      expect(controller.studySessions, hasLength(1));
      expect(repository.value?['completedLessons'], ['greetings']);

      final restored = LearningController(
        repository: repository,
        clock: () => now,
      );
      await restored.load();
      expect(restored.completedLessonCount, 1);
      expect(restored.studySessions, hasLength(1));
    });

    test('only due vocabulary cards are returned', () async {
      await controller.reviewCard('danke', remembered: true);
      expect(controller.dueCards(), hasLength(3));
      now = now.add(const Duration(days: 1));
      expect(controller.dueCards(), hasLength(4));
    });

    test('invalid saved locale and goal use safe defaults', () async {
      repository.value = {'localeCode': 'xx', 'weeklyGoal': 8};
      await controller.load();
      expect(controller.localeCode, 'ar');
      expect(controller.weeklyGoal, 3);
    });

    test('weekly sessions and current streak follow study dates', () async {
      await controller.recordPracticeSession();
      expect(controller.sessionsThisWeek(), 1);
      expect(controller.currentStreak(), 1);

      now = now.add(const Duration(days: 1));
      expect(controller.currentStreak(), 1);
      expect(controller.sessionsThisWeek(), 1);

      now = now.add(const Duration(days: 1));
      expect(controller.currentStreak(), 0);
    });

    test('settings survive restoring the controller', () async {
      await controller.updateProfile(name: ' Layla ', goal: 5);
      await controller.setLocale('de');
      await controller.setTheme(true);

      final restored = LearningController(
        repository: repository,
        clock: () => now,
      );
      await restored.load();
      expect(restored.learnerName, 'Layla');
      expect(restored.weeklyGoal, 5);
      expect(restored.localeCode, 'de');
      expect(restored.isDark, isTrue);
    });

    test(
      'storage errors keep the app usable and set a warning state',
      () async {
        final unsafe = LearningController(
          repository: _FailingLearningRepository(),
          clock: () => now,
        );

        await expectLater(unsafe.load(), completes);
        expect(unsafe.persistenceWarning, isTrue);
        await expectLater(unsafe.completeLesson('greetings'), completes);
        expect(unsafe.completedLessonCount, 1);
        expect(unsafe.persistenceWarning, isTrue);
      },
    );

    test('guest progress and each account stay in separate stores', () async {
      final local = MemoryLearningRepository()
        ..value = {'learnerName': 'Guest'};
      final cloud = _FakeCloudLearningStore();
      final repository = AccountScopedLearningRepository(
        local: local,
        cloud: cloud,
      );

      expect((await repository.load())?['learnerName'], 'Guest');
      cloud.userId = 'user-a';
      expect(await repository.load(), isNull);
      await repository.save({'learnerName': 'Alice'});
      cloud.userId = 'user-b';
      expect(await repository.load(), isNull);
      await repository.save({'learnerName': 'Bilal'});
      cloud.userId = 'user-a';
      expect((await repository.load())?['learnerName'], 'Alice');
      cloud.userId = null;
      expect((await repository.load())?['learnerName'], 'Guest');
    });

    test(
      'loading a different account clears prior in-memory progress',
      () async {
        final cloud = _FakeCloudLearningStore()..userId = 'user-a';
        cloud.rows['user-a'] = {'learnerName': 'Alice'};
        final repository = AccountScopedLearningRepository(
          local: MemoryLearningRepository()..value = {'learnerName': 'Guest'},
          cloud: cloud,
        );
        final scopedController = LearningController(repository: repository);
        await scopedController.load();
        expect(scopedController.learnerName, 'Alice');

        cloud.userId = 'user-b';
        await scopedController.load();
        expect(scopedController.learnerName, isEmpty);
      },
    );

    test(
      'a slower old-account load cannot replace the current account',
      () async {
        final delayed = _DelayedLearningRepository();
        final scopedController = LearningController(repository: delayed);
        final oldLoad = scopedController.load();
        delayed.loads[0].complete({'learnerName': 'Alice'});
        await oldLoad;

        final staleLoad = scopedController.load();
        final currentLoad = scopedController.load();
        delayed.loads[2].complete({'learnerName': 'Bilal'});
        await currentLoad;
        delayed.loads[1].complete({'learnerName': 'Alice'});
        await staleLoad;

        expect(scopedController.learnerName, 'Bilal');
      },
    );
  });
}

class _FailingLearningRepository implements LearningRepository {
  @override
  Future<Map<String, Object?>?> load() async => throw StateError('offline');

  @override
  Future<void> save(Map<String, Object?> state) async =>
      throw StateError('read only');
}

class _FakeCloudLearningStore implements CloudLearningStore {
  @override
  String? userId;
  final Map<String, Map<String, Object?>> rows = {};

  @override
  Future<Map<String, Object?>?> load() async =>
      userId == null ? null : rows[userId!];

  @override
  Future<void> save(Map<String, Object?> state) async {
    final id = userId;
    if (id == null) throw StateError('No authenticated user');
    rows[id] = Map<String, Object?>.from(state);
  }
}

class _DelayedLearningRepository implements LearningRepository {
  final loads = <Completer<Map<String, Object?>?>>[
    Completer<Map<String, Object?>?>(),
    Completer<Map<String, Object?>?>(),
    Completer<Map<String, Object?>?>(),
  ];
  int _index = 0;

  Completer<Map<String, Object?>?> get nextLoad => loads[_index++];

  @override
  Future<Map<String, Object?>?> load() => nextLoad.future;

  @override
  Future<void> save(Map<String, Object?> state) async {}
}
