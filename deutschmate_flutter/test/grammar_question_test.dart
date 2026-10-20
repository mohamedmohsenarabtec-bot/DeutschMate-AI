import 'package:flutter_test/flutter_test.dart';

import 'package:deutschmate_ai/core/models/grammar_question.dart';

void main() {
  test('starter grammar quiz scores correct answers', () {
    expect(GrammarQuestion.score(['Der Name', 'Die Frau']), 2);
    expect(GrammarQuestion.score(['Die Name', 'Die Frau']), 1);
    expect(GrammarQuestion.score([null, 'Der Frau']), 0);
  });

  test('score accepts incomplete answer lists safely', () {
    expect(GrammarQuestion.score(['Der Name']), 1);
    expect(GrammarQuestion.score([]), 0);
  });
}
