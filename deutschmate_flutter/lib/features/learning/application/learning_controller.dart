import 'package:flutter/foundation.dart';

import '../../../core/data/learning_repository.dart';
import '../../../core/models/vocabulary_card.dart';

class ReviewProgress {
  const ReviewProgress({
    this.intervalDays = 0,
    this.nextDue,
    this.correctReviews = 0,
    this.totalReviews = 0,
  });

  final int intervalDays;
  final DateTime? nextDue;
  final int correctReviews;
  final int totalReviews;

  factory ReviewProgress.fromJson(Object? value) {
    if (value is! Map) return const ReviewProgress();
    return ReviewProgress(
      intervalDays: (value['intervalDays'] as num?)?.toInt() ?? 0,
      nextDue: DateTime.tryParse(value['nextDue'] as String? ?? ''),
      correctReviews: (value['correctReviews'] as num?)?.toInt() ?? 0,
      totalReviews: (value['totalReviews'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() => {
    'intervalDays': intervalDays,
    'nextDue': nextDue?.toIso8601String(),
    'correctReviews': correctReviews,
    'totalReviews': totalReviews,
  };
}

class LearningController extends ChangeNotifier {
  LearningController({required this._repository, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final LearningRepository _repository;
  final DateTime Function() _clock;
  int _loadGeneration = 0;
  String localeCode = 'ar';
  String learnerName = '';
  int weeklyGoal = 3;
  bool isDark = false;
  bool persistenceWarning = false;
  final Set<String> completedLessons = {};
  final List<DateTime> studySessions = [];
  final Map<String, ReviewProgress> reviews = {};

  Future<void> load() async {
    final generation = ++_loadGeneration;
    localeCode = 'ar';
    learnerName = '';
    weeklyGoal = 3;
    isDark = false;
    completedLessons.clear();
    studySessions.clear();
    reviews.clear();
    persistenceWarning = false;
    notifyListeners();
    try {
      final data = await _repository.load();
      if (generation != _loadGeneration) return;
      if (data != null) {
        localeCode = data['localeCode'] as String? ?? 'ar';
        if (!['ar', 'de', 'en'].contains(localeCode)) localeCode = 'ar';
        learnerName = data['learnerName'] as String? ?? '';
        weeklyGoal = (data['weeklyGoal'] as num?)?.toInt() ?? 3;
        if (![3, 5, 7].contains(weeklyGoal)) weeklyGoal = 3;
        isDark = data['isDark'] as bool? ?? false;
        completedLessons.addAll(
          (data['completedLessons'] as List? ?? const []).whereType<String>(),
        );
        studySessions.addAll(
          (data['studySessions'] as List? ?? const [])
              .whereType<String>()
              .map(DateTime.tryParse)
              .whereType<DateTime>(),
        );
        final savedReviews = data['reviews'];
        if (savedReviews is Map) {
          for (final entry in savedReviews.entries) {
            if (entry.key is String) {
              reviews[entry.key as String] = ReviewProgress.fromJson(
                entry.value,
              );
            }
          }
        }
      }
    } catch (_) {
      if (generation != _loadGeneration) return;
      persistenceWarning = true;
    }
    if (generation != _loadGeneration) return;
    notifyListeners();
  }

  Future<void> setLocale(String value) async {
    if (!['ar', 'de', 'en'].contains(value)) return;
    localeCode = value;
    await _saveAndNotify();
  }

  Future<void> setTheme(bool value) async {
    isDark = value;
    await _saveAndNotify();
  }

  Future<void> updateProfile({required String name, required int goal}) async {
    learnerName = name.trim();
    weeklyGoal = [3, 5, 7].contains(goal) ? goal : 3;
    await _saveAndNotify();
  }

  Future<void> completeLesson(String lessonId) async {
    if (completedLessons.add(lessonId)) _recordSession();
    await _saveAndNotify();
  }

  Future<void> recordPracticeSession() async {
    _recordSession();
    await _saveAndNotify();
  }

  void _recordSession() => studySessions.add(_clock());

  List<VocabularyCard> dueCards([DateTime? at]) {
    final now = at ?? _clock();
    return VocabularyCard.reviewDeck
        .where((card) {
          final due = reviews[card.id]?.nextDue;
          return due == null || !due.isAfter(now);
        })
        .toList(growable: false);
  }

  Future<void> reviewCard(
    String cardId, {
    required bool remembered,
    DateTime? at,
  }) async {
    final now = at ?? _clock();
    final previous = reviews[cardId] ?? const ReviewProgress();
    final interval = remembered
        ? (previous.intervalDays < 1 ? 1 : previous.intervalDays * 2)
        : 0;
    reviews[cardId] = ReviewProgress(
      intervalDays: interval,
      nextDue: now.add(
        remembered ? Duration(days: interval) : const Duration(minutes: 10),
      ),
      correctReviews: previous.correctReviews + (remembered ? 1 : 0),
      totalReviews: previous.totalReviews + 1,
    );
    await _saveAndNotify();
  }

  int get completedLessonCount => completedLessons.length;

  int sessionsThisWeek([DateTime? at]) {
    final now = at ?? _clock();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return studySessions
        .where((session) => !session.isBefore(startOfWeek))
        .where((session) => !session.isAfter(now))
        .length;
  }

  int currentStreak([DateTime? at]) {
    final now = at ?? _clock();
    final studyDays = studySessions
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();
    var day = DateTime(now.year, now.month, now.day);
    if (!studyDays.contains(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (studyDays.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _saveAndNotify() async {
    try {
      await _repository.save({
        'localeCode': localeCode,
        'learnerName': learnerName,
        'weeklyGoal': weeklyGoal,
        'isDark': isDark,
        'completedLessons': completedLessons.toList(),
        'studySessions': studySessions
            .map((date) => date.toIso8601String())
            .toList(),
        'reviews': reviews.map((key, value) => MapEntry(key, value.toJson())),
      });
      persistenceWarning = false;
    } catch (_) {
      persistenceWarning = true;
    }
    notifyListeners();
  }
}
