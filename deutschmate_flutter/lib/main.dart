import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/data/learning_repository.dart';
import 'features/account/application/account_gateway.dart';
import 'features/ai_tutor/application/ai_tutor_gateway.dart';
import 'features/learning/application/learning_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  AccountGateway? accountGateway;
  AiTutorGateway? aiTutorGateway;
  LearningRepository repository = SharedPreferencesLearningRepository();
  if (supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
    final client = Supabase.instance.client;
    accountGateway = SupabaseAccountGateway(client);
    aiTutorGateway = SupabaseAiTutorGateway(client);
    repository = AccountScopedLearningRepository(
      local: repository,
      cloud: SupabaseCloudLearningStore(client),
    );
  }
  final controller = LearningController(repository: repository);
  await controller.load();
  runApp(
    DeutschMateApp(
      controller: controller,
      accountGateway: accountGateway,
      aiTutorGateway: aiTutorGateway,
    ),
  );
}
