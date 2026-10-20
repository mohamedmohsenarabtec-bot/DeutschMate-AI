class GrammarQuestion {
  const GrammarQuestion({
    required this.noun,
    required this.correct,
    required this.choices,
    required this.explanationArabic,
    required this.explanationEnglish,
    required this.explanationGerman,
  });

  final String noun;
  final String correct;
  final List<String> choices;
  final String explanationArabic;
  final String explanationEnglish;
  final String explanationGerman;

  static const starterQuiz = <GrammarQuestion>[
    GrammarQuestion(
      noun: 'Name',
      correct: 'Der Name',
      choices: ['Der Name', 'Die Name', 'Das Name'],
      explanationArabic: 'كلمة Name مذكّر: der Name.',
      explanationEnglish: 'Name is masculine: der Name.',
      explanationGerman: 'Name ist maskulin: der Name.',
    ),
    GrammarQuestion(
      noun: 'Frau',
      correct: 'Die Frau',
      choices: ['Die Frau', 'Der Frau', 'Das Frau'],
      explanationArabic: 'كلمة Frau مؤنث: die Frau.',
      explanationEnglish: 'Frau is feminine: die Frau.',
      explanationGerman: 'Frau ist feminin: die Frau.',
    ),
  ];

  static int score(List<String?> answers) {
    var result = 0;
    for (
      var index = 0;
      index < starterQuiz.length && index < answers.length;
      index++
    ) {
      if (answers[index] == starterQuiz[index].correct) result++;
    }
    return result;
  }
}
