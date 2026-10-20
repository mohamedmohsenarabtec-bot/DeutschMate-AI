import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountSession {
  const AccountSession({
    required this.userId,
    required this.email,
    this.isPasswordRecovery = false,
  });

  final String userId;
  final String email;
  final bool isPasswordRecovery;
}

class AccountActionResult {
  const AccountActionResult({this.emailConfirmationRequired = false});

  final bool emailConfirmationRequired;
}

abstract interface class AccountGateway {
  AccountSession? get currentSession;
  Stream<AccountSession?> get sessionChanges;

  Future<AccountActionResult> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signIn({required String email, required String password});
  Future<void> sendPasswordReset(String email);
  Future<void> updatePassword(String password);
  Future<void> signOut();
}

class SupabaseAccountGateway implements AccountGateway {
  SupabaseAccountGateway(this._client);

  final SupabaseClient _client;

  AccountSession? _mapSession(
    Session? session, {
    bool isPasswordRecovery = false,
  }) {
    final user = session?.user;
    if (user == null) return null;
    return AccountSession(
      userId: user.id,
      email: user.email ?? '',
      isPasswordRecovery: isPasswordRecovery,
    );
  }

  @override
  AccountSession? get currentSession =>
      _mapSession(_client.auth.currentSession);

  @override
  Stream<AccountSession?> get sessionChanges =>
      _client.auth.onAuthStateChange.map(
        (state) => _mapSession(
          state.session,
          isPasswordRecovery: state.event == AuthChangeEvent.passwordRecovery,
        ),
      );

  @override
  Future<AccountActionResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
      emailRedirectTo: _redirectUrl,
    );
    return AccountActionResult(
      emailConfirmationRequired: response.session == null,
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> sendPasswordReset(String email) => _client.auth
      .resetPasswordForEmail(email.trim(), redirectTo: _redirectUrl);

  @override
  Future<void> updatePassword(String password) =>
      _client.auth.updateUser(UserAttributes(password: password));

  @override
  Future<void> signOut() => _client.auth.signOut();

  String get _redirectUrl => kIsWeb
      ? '${Uri.base.origin}/auth-callback'
      : 'com.deutschmate.app://login-callback/auth-callback';
}
