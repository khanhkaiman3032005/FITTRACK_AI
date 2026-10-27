import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack_ai/services/trained_intent_classifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Low-information text abstains rather than guessing', () async {
    expect(await TrainedIntentClassifier.classify('a'), isNull);
  });
}
