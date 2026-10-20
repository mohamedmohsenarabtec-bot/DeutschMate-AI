class LessonWord {
  const LessonWord({
    required this.german,
    required this.arabic,
    required this.english,
    required this.example,
  });

  final String german;
  final String arabic;
  final String english;
  final String example;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.level,
    required this.words,
    this.durationMinutes = 15,
  });

  final String id;
  final String title;
  final String level;
  final int durationMinutes;
  final List<LessonWord> words;

  static const greetings = Lesson(
    id: 'greetings',
    title: 'التعارف والتحية',
    level: 'A1',
    words: [
      LessonWord(
        german: 'Hallo',
        arabic: 'مرحبًا',
        english: 'Hello',
        example: 'Hallo, ich heiße Lina.',
      ),
      LessonWord(
        german: 'Ich heiße …',
        arabic: 'اسمي …',
        english: 'My name is …',
        example: 'Ich heiße Omar.',
      ),
      LessonWord(
        german: 'Wie geht es dir?',
        arabic: 'كيف حالك؟',
        english: 'How are you?',
        example: 'Hallo! Wie geht es dir?',
      ),
      LessonWord(
        german: 'Freut mich',
        arabic: 'سعيد بلقائك',
        english: 'Nice to meet you',
        example: 'Freut mich, dich kennenzulernen.',
      ),
    ],
  );
}
