import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../application/ai_tutor_gateway.dart';

class _TutorLine {
  const _TutorLine(this.text, {required this.fromTutor});

  final String text;
  final bool fromTutor;
}

class AiTutorPanel extends StatefulWidget {
  const AiTutorPanel({required this.strings, this.gateway, super.key});

  final AppStrings strings;
  final AiTutorGateway? gateway;

  @override
  State<AiTutorPanel> createState() => _AiTutorPanelState();
}

class _AiTutorPanelState extends State<AiTutorPanel> {
  final _input = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_TutorLine>[];
  String? _conversationId;
  String _level = 'a1';
  String _task = 'tutor';
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _input.text.trim();
    if (message.isEmpty || _sending) return;
    final s = widget.strings;
    final gateway = widget.gateway;
    if (gateway == null) {
      setState(() => _error = 'aiNotConfigured');
      return;
    }
    if (!gateway.isAuthenticated) {
      setState(() => _error = 'aiSignInRequired');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
      _messages.add(_TutorLine(message, fromTutor: false));
      _input.clear();
    });
    _scrollToEnd();
    try {
      final reply = await gateway.sendMessage(
        message: message,
        locale: s.localeCode,
        cefrLevel: _level,
        task: _task,
        conversationId: _conversationId,
      );
      if (!mounted) return;
      setState(() {
        _conversationId = reply.conversationId;
        _messages.add(_TutorLine(reply.text, fromTutor: true));
      });
      _scrollToEnd();
    } on AiTutorRequestException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _input.text = message;
        _error = switch (error.code) {
          'sign_in_required' => 'aiSignInRequired',
          'daily_limit' => 'aiDailyLimit',
          'rate_limited' => 'aiRateLimited',
          _ => 'aiUnavailable',
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _input.text = message;
        _error = 'aiUnavailable';
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _level,
                  decoration: InputDecoration(
                    labelText: s.text('level'),
                    isDense: true,
                  ),
                  items: const ['a1', 'a2', 'b1', 'b2', 'c1', 'c2']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: _sending
                      ? null
                      : (value) {
                          if (value != null) setState(() => _level = value);
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _task,
                  decoration: InputDecoration(
                    labelText: s.text('tutorTask'),
                    isDense: true,
                  ),
                  items: [
                    _taskItem(s, 'tutor', 'taskTutor'),
                    _taskItem(s, 'grammar', 'taskGrammar'),
                    _taskItem(s, 'vocabulary', 'taskVocabulary'),
                    _taskItem(s, 'correction', 'taskCorrection'),
                    _taskItem(s, 'exercise', 'taskExercise'),
                    _taskItem(s, 'writing_feedback', 'taskWriting'),
                    _taskItem(s, 'roleplay', 'taskRoleplay'),
                    _taskItem(s, 'study_plan', 'taskStudyPlan'),
                  ],
                  onChanged: _sending
                      ? null
                      : (value) {
                          if (value != null) setState(() => _task = value);
                        },
                ),
              ),
            ],
          ),
        ),
        if (widget.gateway == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Text(
              s.text('aiNotConfigured'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else if (!widget.gateway!.isAuthenticated)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Text(
              s.text('aiSignInRequired'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Text(
                      s.text('aiWelcome'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final item = _messages[index];
                    final color = item.fromTutor
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.primaryContainer;
                    return Align(
                      alignment: item.fromTutor
                          ? AlignmentDirectional.centerStart
                          : AlignmentDirectional.centerEnd,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Card(
                          color: color,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: SelectableText(item.text),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_sending)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: LinearProgressIndicator(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: Text(
              s.text(_error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 4000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: s.text('askTutor'),
                    counterText: '',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: s.text('send'),
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<String> _taskItem(
    AppStrings s,
    String value,
    String label,
  ) => DropdownMenuItem(value: value, child: Text(s.text(label)));
}
