import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localization/app_strings.dart';
import '../../learning/application/learning_controller.dart';
import '../application/account_gateway.dart';

enum _AccountMode { signIn, signUp, resetPassword, recovery }

class AccountPanel extends StatefulWidget {
  const AccountPanel({
    required this.strings,
    required this.controller,
    this.gateway,
    super.key,
  });

  final AppStrings strings;
  final LearningController controller;
  final AccountGateway? gateway;

  @override
  State<AccountPanel> createState() => _AccountPanelState();
}

class _AccountPanelState extends State<AccountPanel> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  StreamSubscription<AccountSession?>? _sessionSubscription;
  String? _previousUserId;
  String? _message;
  bool _messageIsError = false;
  bool _busy = false;
  _AccountMode _mode = _AccountMode.signIn;

  @override
  void initState() {
    super.initState();
    _previousUserId = widget.gateway?.currentSession?.userId;
    _sessionSubscription = widget.gateway?.sessionChanges.listen((session) {
      final userId = session?.userId;
      if (userId != _previousUserId) {
        _previousUserId = userId;
        widget.controller.load();
      }
    });
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit({bool recovery = false}) async {
    final mode = recovery ? _AccountMode.recovery : _mode;
    if (mode != _AccountMode.resetPassword &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (mode == _AccountMode.resetPassword &&
        (_email.text.trim().isEmpty || !_email.text.contains('@'))) {
      setState(() {
        _message = 'invalidEmail';
        _messageIsError = true;
      });
      return;
    }

    final gateway = widget.gateway;
    if (gateway == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      switch (mode) {
        case _AccountMode.signIn:
          await gateway.signIn(email: _email.text, password: _password.text);
          await widget.controller.load();
          _setMessage('signedIn', isError: false);
        case _AccountMode.signUp:
          final result = await gateway.signUp(
            email: _email.text,
            password: _password.text,
            displayName: _displayName.text,
          );
          if (result.emailConfirmationRequired) {
            _setMessage('verificationSent', isError: false);
          } else {
            await widget.controller.load();
            _setMessage('registered', isError: false);
          }
        case _AccountMode.resetPassword:
          await gateway.sendPasswordReset(_email.text);
          _setMessage('resetSent', isError: false);
        case _AccountMode.recovery:
          await gateway.updatePassword(_password.text);
          _setMessage('passwordUpdated', isError: false);
      }
    } catch (_) {
      _setMessage('accountError', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setMessage(String key, {required bool isError}) {
    if (!mounted) return;
    setState(() {
      _message = key;
      _messageIsError = isError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final gateway = widget.gateway;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.text('account'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (gateway == null)
              Text(s.text('cloudNotConfigured'))
            else
              StreamBuilder<AccountSession?>(
                stream: gateway.sessionChanges,
                initialData: gateway.currentSession,
                builder: (context, snapshot) {
                  final session = snapshot.data;
                  if (session?.isPasswordRecovery ?? false) {
                    return _buildForm(s, gateway, recovery: true);
                  }
                  if (session != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${s.text('signedInAs')} ${session.email}'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() {
                                    _busy = true;
                                    _message = null;
                                  });
                                  try {
                                    await gateway.signOut();
                                    await widget.controller.load();
                                    _setMessage('signedOut', isError: false);
                                  } catch (_) {
                                    _setMessage('accountError', isError: true);
                                  } finally {
                                    if (mounted) {
                                      setState(() => _busy = false);
                                    }
                                  }
                                },
                          icon: const Icon(Icons.logout),
                          label: Text(s.text('signOut')),
                        ),
                      ],
                    );
                  }
                  return _buildForm(s, gateway);
                },
              ),
            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(
                s.text(_message!),
                style: TextStyle(
                  color: _messageIsError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForm(
    AppStrings s,
    AccountGateway gateway, {
    bool recovery = false,
  }) {
    final mode = recovery ? _AccountMode.recovery : _mode;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (mode == _AccountMode.signUp) ...[
            TextFormField(
              controller: _displayName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: s.text('displayName'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) => (value?.trim().length ?? 0) < 2
                  ? s.text('invalidName')
                  : null,
            ),
            const SizedBox(height: 10),
          ],
          if (!recovery)
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: s.text('email'),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (value) => value != null && value.contains('@')
                  ? null
                  : s.text('invalidEmail'),
            ),
          if (mode != _AccountMode.resetPassword) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _password,
              obscureText: true,
              autofillHints: mode == _AccountMode.signIn
                  ? const [AutofillHints.password]
                  : const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: s.text(
                  mode == _AccountMode.recovery ? 'newPassword' : 'password',
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              validator: (value) => (value?.length ?? 0) >= 10
                  ? null
                  : s.text('passwordTooShort'),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : () => _submit(recovery: recovery),
            child: Text(
              s.text(switch (mode) {
                _AccountMode.signIn => 'signIn',
                _AccountMode.signUp => 'signUp',
                _AccountMode.resetPassword => 'sendReset',
                _AccountMode.recovery => 'updatePassword',
              }),
            ),
          ),
          if (!recovery)
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                if (mode != _AccountMode.signIn)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _mode = _AccountMode.signIn;
                            _message = null;
                          }),
                    child: Text(s.text('signIn')),
                  ),
                if (mode != _AccountMode.signUp)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _mode = _AccountMode.signUp;
                            _message = null;
                          }),
                    child: Text(s.text('createAccount')),
                  ),
                if (mode != _AccountMode.resetPassword)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _mode = _AccountMode.resetPassword;
                            _message = null;
                          }),
                    child: Text(s.text('forgotPassword')),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
