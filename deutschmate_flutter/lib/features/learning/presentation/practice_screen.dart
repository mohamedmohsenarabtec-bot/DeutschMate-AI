import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/models/grammar_question.dart';
import '../../../core/models/vocabulary_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../ai_tutor/application/ai_tutor_gateway.dart';
import '../../ai_tutor/presentation/ai_tutor_panel.dart';
import '../application/learning_controller.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({
    required this.controller,
    required this.strings,
    this.aiTutorGateway,
    super.key,
  });
  final LearningController controller;
  final AppStrings strings;
  final AiTutorGateway? aiTutorGateway;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.text('practice'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                TabBar(
                  tabs: [
                    Tab(text: s.text('reviewWords')),
                    Tab(text: s.text('quiz')),
                    Tab(text: s.text('aiTutor')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _VocabularyReview(controller: controller, strings: s),
                _GrammarQuiz(controller: controller, strings: s),
                AiTutorPanel(strings: s, gateway: aiTutorGateway),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VocabularyReview extends StatefulWidget {
  const _VocabularyReview({required this.controller, required this.strings});
  final LearningController controller;
  final AppStrings strings;

  @override
  State<_VocabularyReview> createState() => _VocabularyReviewState();
}

class _VocabularyReviewState extends State<_VocabularyReview> {
  bool _revealed = false;
  int _reviewed = 0;

  Future<void> _rate(bool remembered, VocabularyCard card) async {
    await widget.controller.reviewCard(card.id, remembered: remembered);
    if (widget.controller.dueCards().isEmpty) {
      await widget.controller.recordPracticeSession();
    }
    if (mounted) {
      setState(() {
        _revealed = false;
        _reviewed++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.controller.dueCards();
    final s = widget.strings;
    if (cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 52,
                color: AppTheme.brand,
              ),
              const SizedBox(height: 14),
              Text(
                s.text('noDueWords'),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (_reviewed > 0) ...[
                const SizedBox(height: 8),
                Text('${s.text('reviewWords')}: $_reviewed'),
              ],
            ],
          ),
        ),
      );
    }
    final card = cards.first;
    final meaning = s.isArabic ? card.arabic : card.english;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          '${s.text('dueWords')} · ${cards.length}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  card.german,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.brand,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                if (_revealed) ...[
                  Text(
                    meaning,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    card.example,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _rate(false, card),
                        icon: const Icon(Icons.replay),
                        label: Text(s.text('again')),
                      ),
                      FilledButton.icon(
                        onPressed: () => _rate(true, card),
                        icon: const Icon(Icons.check),
                        label: Text(s.text('remembered')),
                      ),
                    ],
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: () => setState(() => _revealed = true),
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(s.text('reveal')),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GrammarQuiz extends StatefulWidget {
  const _GrammarQuiz({required this.controller, required this.strings});
  final LearningController controller;
  final AppStrings strings;

  @override
  State<_GrammarQuiz> createState() => _GrammarQuizState();
}

class _GrammarQuizState extends State<_GrammarQuiz> {
  int _index = 0;
  final List<String?> _answers = [];
  String? _selected;
  bool _answered = false;
  bool _finished = false;

  String _explanation(GrammarQuestion question) => widget.strings.isArabic
      ? question.explanationArabic
      : widget.strings.isGerman
      ? question.explanationGerman
      : question.explanationEnglish;

  Future<void> _next() async {
    if (_index == GrammarQuestion.starterQuiz.length - 1) {
      await widget.controller.recordPracticeSession();
      if (mounted) setState(() => _finished = true);
    } else {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final questions = GrammarQuestion.starterQuiz;
    if (_finished) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: AppTheme.brand,
                ),
                const SizedBox(height: 12),
                Text(
                  s.text('quizResult'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${GrammarQuestion.score(_answers)} ${s.text('of')} ${questions.length}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => setState(() {
                    _finished = false;
                    _index = 0;
                    _answers.clear();
                    _selected = null;
                    _answered = false;
                  }),
                  child: Text(s.text('beginQuiz')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final question = questions[_index];
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          '${s.text('quiz')} · ${_index + 1}/${questions.length}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (_index + 1) / questions.length,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.isArabic
                      ? 'اختر أداة التعريف الصحيحة:'
                      : s.isGerman
                      ? 'Wähle den richtigen Artikel:'
                      : 'Choose the correct article:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '___ ${question.noun}',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                ...question.choices.map((choice) {
                  final isCorrect = choice == question.correct;
                  final isSelected = choice == _selected;
                  final color = !_answered || !isSelected
                      ? null
                      : isCorrect
                      ? AppTheme.brand.withValues(alpha: .14)
                      : Theme.of(context).colorScheme.errorContainer;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(backgroundColor: color),
                      onPressed: _answered
                          ? null
                          : () => setState(() {
                              _selected = choice;
                              _answered = true;
                              _answers.add(choice);
                            }),
                      child: Text(choice, textDirection: TextDirection.ltr),
                    ),
                  );
                }),
                if (_answered) ...[
                  const SizedBox(height: 8),
                  Text(
                    _selected == question.correct
                        ? s.text('correct')
                        : '${s.text('incorrect')}: ${question.correct}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _selected == question.correct
                          ? AppTheme.brand
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_explanation(question)),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                      _index == questions.length - 1
                          ? s.text('quizResult')
                          : s.text('next'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
