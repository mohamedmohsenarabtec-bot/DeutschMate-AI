import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/models/lesson.dart';
import '../../../core/theme/app_theme.dart';
import '../application/learning_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.controller,
    required this.strings,
    required this.onStartLesson,
    required this.onPractice,
    super.key,
  });

  final LearningController controller;
  final AppStrings strings;
  final VoidCallback onStartLesson;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = controller.dueCards().length;
    final weekly = controller.sessionsThisWeek();
    final name = controller.learnerName.isEmpty
        ? strings.text('welcomeName')
        : '${strings.text('welcomeName')}${strings.isArabic ? '، ' : ', '}${controller.learnerName}';
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
      children: [
        Text(
          strings.text('yourLearning'),
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppTheme.brand,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          strings.text('greeting'),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 700 ? 3 : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                  width: width,
                  icon: Icons.local_fire_department_outlined,
                  color: const Color(0xFFE99445),
                  label: strings.text('streak'),
                  value: '${controller.currentStreak()}',
                  suffix: strings.text('days'),
                ),
                _StatCard(
                  width: width,
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF6B68B5),
                  label: strings.text('lessonsDone'),
                  value: '${controller.completedLessonCount}',
                  suffix: ' / 24',
                ),
                _StatCard(
                  width: width,
                  icon: Icons.calendar_month_outlined,
                  color: AppTheme.brand,
                  label: strings.text('weeklyProgress'),
                  value: '$weekly',
                  suffix:
                      ' / ${controller.weeklyGoal} ${strings.text('sessions')}',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 27),
        Row(
          children: [
            Expanded(
              child: Text(
                strings.text('learningPath'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _LevelPill(
              label: Lesson.greetings.level,
              text: strings.text('starterLevel'),
            ),
          ],
        ),
        const SizedBox(height: 13),
        _LessonCard(
          strings: strings,
          completed: controller.completedLessons.contains(Lesson.greetings.id),
          onTap: onStartLesson,
        ),
        const SizedBox(height: 24),
        Text(
          strings.text('practice'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > 670
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PracticeCard(
                  width: width,
                  icon: Icons.style_outlined,
                  title: strings.text('reviewWords'),
                  detail: '$due ${strings.text('dueWords')}',
                  color: const Color(0xFF5C9C79),
                  onTap: onPractice,
                ),
                _PracticeCard(
                  width: width,
                  icon: Icons.quiz_outlined,
                  title: strings.text('quiz'),
                  detail: strings.text('quizDescription'),
                  color: const Color(0xFF7470BB),
                  onTap: onPractice,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.auto_awesome_outlined),
            ),
            title: Text(
              strings.text('sampleTutor'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(strings.text('sampleTutorNote')),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${strings.text('a1Content')} · ${strings.text('reviewedNote')}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.suffix,
  });
  final double width;
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$value$suffix',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.label, required this.text});
  final String label;
  final String text;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppTheme.brand.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Text(
        '$label · $text',
        style: const TextStyle(
          color: AppTheme.brand,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.strings,
    required this.completed,
    required this.onTap,
  });
  final AppStrings strings;
  final bool completed;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.waving_hand_outlined, color: AppTheme.brand),
              const SizedBox(width: 8),
              Text(
                strings.text('greetingsLesson'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            strings.text('lessonDescription'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            '◷  ${Lesson.greetings.durationMinutes} ${strings.text('minutes')}     ▱  ${Lesson.greetings.words.length} ${strings.text('activities')}     ✧  +20 XP',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 17),
          FilledButton.icon(
            onPressed: onTap,
            icon: Icon(completed ? Icons.replay : Icons.play_arrow_rounded),
            label: Text(
              completed
                  ? strings.text('continueLesson')
                  : strings.text('startLesson'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.detail,
    required this.color,
    required this.onTap,
  });
  final double width;
  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                foregroundColor: color,
                child: Icon(icon),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    ),
  );
}
