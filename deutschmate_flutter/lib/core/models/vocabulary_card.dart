class VocabularyCard {
  const VocabularyCard({
    required this.id,
    required this.german,
    required this.arabic,
    required this.english,
    required this.example,
  });

  final String id;
  final String german;
  final String arabic;
  final String english;
  final String example;

  static const reviewDeck = <VocabularyCard>[
    VocabularyCard(
      id: 'guten_morgen',
      german: 'Guten Morgen',
      arabic: 'صباح الخير',
      english: 'Good morning',
      example: 'Guten Morgen, wie geht es dir?',
    ),
    VocabularyCard(
      id: 'danke',
      german: 'Danke',
      arabic: 'شكرًا',
      english: 'Thank you',
      example: 'Danke für deine Hilfe.',
    ),
    VocabularyCard(
      id: 'bitte',
      german: 'Bitte',
      arabic: 'من فضلك / عفوًا',
      english: 'Please / You’re welcome',
      example: 'Ein Wasser, bitte.',
    ),
    VocabularyCard(
      id: 'auf_wiedersehen',
      german: 'Auf Wiedersehen',
      arabic: 'إلى اللقاء',
      english: 'Goodbye',
      example: 'Auf Wiedersehen und bis morgen!',
    ),
  ];
}
