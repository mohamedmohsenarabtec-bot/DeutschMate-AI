import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/models/lesson.dart';
import '../../../core/theme/app_theme.dart';
import '../application/learning_controller.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({
    required this.controller,
    required this.strings,
    super.key,
  });
  final LearningController controller;
  final AppStrings strings;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _index = 0;
  bool _complete = false;

  Future<void> _advance() async {
    if (_index < Lesson.greetings.words.length - 1) {
      setState(() => _index++);
      return;
    }
    await widget.controller.completeLesson(Lesson.greetings.id);
    if (mounted) setState(() => _complete = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final word = Lesson.greetings.words[_index];
    final translation = s.isArabic ? word.arabic : word.english;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          s.text('lessons'),
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text('${Lesson.greetings.level} · ${s.text('greetingsLesson')}'),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.text('greetingsLesson'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${_complete ? Lesson.greetings.words.length : _index + 1}/${Lesson.greetings.words.length}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _complete
                      ? 1
                      : (_index + 1) / Lesson.greetings.words.length,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 34),
                Center(
                  child: Text(
                    _complete ? '✓' : word.german,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.brand,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _complete ? s.text('lessonDone') : translation,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!_complete) ...[
                  const SizedBox(height: 24),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: .4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        word.example,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _complete ? null : _advance,
                  icon: Icon(
                    _complete
                        ? Icons.check
                        : _index == Lesson.greetings.words.length - 1
                        ? Icons.flag_outlined
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    _complete
                        ? s.text('lessonDone')
                        : _index == Lesson.greetings.words.length - 1
                        ? s.text('finish')
                        : s.text('next'),
                  ),
                ),
                if (_complete) ...[
                  const SizedBox(height: 10),
                  Text(
                    s.text('lessonComplete'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          s.text('reviewedNote'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
