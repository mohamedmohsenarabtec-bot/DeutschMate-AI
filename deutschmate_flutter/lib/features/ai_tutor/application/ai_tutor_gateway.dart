import 'package:supabase_flutter/supabase_flutter.dart';

class AiTutorReply {
  const AiTutorReply({required this.conversationId, required this.text});

  final String conversationId;
  final String text;
}

abstract interface class AiTutorGateway {
  bool get isAuthenticated;

  Future<AiTutorReply> sendMessage({
    required String message,
    required String locale,
    required String cefrLevel,
    required String task,
    String? conversationId,
  });
}

class SupabaseAiTutorGateway implements AiTutorGateway {
  SupabaseAiTutorGateway(this._client);

  final SupabaseClient _client;

  @override
  bool get isAuthenticated => _client.auth.currentUser != null;

  @override
  Future<AiTutorReply> sendMessage({
    required String message,
    required String locale,
    required String cefrLevel,
    required String task,
    String? conversationId,
  }) async {
    if (!isAuthenticated) {
      throw const AiTutorRequestException('sign_in_required');
    }
    try {
      final response = await _client.functions.invoke(
        'ai-tutor',
        body: {
          'message': message,
          'locale': locale,
          'cefrLevel': cefrLevel,
          'task': task,
          ...?conversationId == null
              ? null
              : {'conversationId': conversationId},
        },
      );
      if (response.status < 200 || response.status >= 300) {
        throw AiTutorRequestException(_readErrorCode(response.data));
      }
      final data = response.data;
      if (data is! Map ||
          data['conversationId'] is! String ||
          data['reply'] is! String) {
        throw const AiTutorRequestException('invalid_response');
      }
      return AiTutorReply(
        conversationId: data['conversationId'] as String,
        text: data['reply'] as String,
      );
    } on AiTutorRequestException {
      rethrow;
    } on FunctionException catch (error) {
      throw AiTutorRequestException(_readErrorCode(error.details));
    } catch (_) {
      throw const AiTutorRequestException('temporarily_unavailable');
    }
  }

  String _readErrorCode(Object? details) {
    if (details is Map && details['error'] is String) {
      return details['error'] as String;
    }
    return 'temporarily_unavailable';
  }
}

class AiTutorRequestException implements Exception {
  const AiTutorRequestException(this.code);

  final String code;
}
