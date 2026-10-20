import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class LearningRepository {
  Future<Map<String, Object?>?> load();
  Future<void> save(Map<String, Object?> state);
}

class SharedPreferencesLearningRepository implements LearningRepository {
  static const _storageKey = 'deutschmate_flutter:learning:v1';

  @override
  Future<Map<String, Object?>?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final json = preferences.getString(_storageKey);
    if (json == null) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      await preferences.remove(_storageKey);
    }
    return null;
  }

  @override
  Future<void> save(Map<String, Object?> state) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, jsonEncode(state));
  }
}

abstract interface class CloudLearningStore {
  String? get userId;
  Future<Map<String, Object?>?> load();
  Future<void> save(Map<String, Object?> state);
}

/// Keeps anonymous progress in this browser/device and authenticated progress
/// in the signed-in user's RLS-protected row.
class AccountScopedLearningRepository implements LearningRepository {
  AccountScopedLearningRepository({required this.local, required this.cloud});

  final LearningRepository local;
  final CloudLearningStore cloud;

  @override
  Future<Map<String, Object?>?> load() =>
      cloud.userId == null ? local.load() : cloud.load();

  @override
  Future<void> save(Map<String, Object?> state) =>
      cloud.userId == null ? local.save(state) : cloud.save(state);
}

class SupabaseCloudLearningStore implements CloudLearningStore {
  SupabaseCloudLearningStore(this._client);

  final SupabaseClient _client;

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<Map<String, Object?>?> load() async {
    final id = userId;
    if (id == null) throw StateError('Cloud learning requires a session.');
    final row = await _client
        .from('student_progress')
        .select('state')
        .eq('user_id', id)
        .maybeSingle();
    final state = row?['state'];
    return state is Map ? Map<String, Object?>.from(state) : null;
  }

  @override
  Future<void> save(Map<String, Object?> state) async {
    final id = userId;
    if (id == null) throw StateError('Cloud learning requires a session.');
    final name = (state['learnerName'] as String? ?? '').trim();
    final locale = state['localeCode'] as String? ?? 'ar';
    await _client
        .from('profiles')
        .update({
          'display_name': name.length <= 50 ? name : name.substring(0, 50),
          'preferred_locale': ['ar', 'de', 'en'].contains(locale)
              ? locale
              : 'ar',
        })
        .eq('id', id);
    await _client.from('student_progress').upsert({
      'user_id': id,
      'state': state,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

class MemoryLearningRepository implements LearningRepository {
  Map<String, Object?>? value;

  @override
  Future<Map<String, Object?>?> load() async => value;

  @override
  Future<void> save(Map<String, Object?> state) async {
    value = Map<String, Object?>.from(state);
  }
}
