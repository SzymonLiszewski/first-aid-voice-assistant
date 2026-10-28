import 'package:first_aid_voice_assistant/ui/conversation/view_models/conversation_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/services.dart';

void main() {
  late FakeSpeechInput input;
  late ConversationViewModel viewModel;

  setUp(() {
    input = FakeSpeechInput();
    viewModel = ConversationViewModel(input: input);
  });

  test('is ready after the model is prepared', () async {
    await viewModel.initialize();

    expect(viewModel.status, ConversationStatus.ready);
    expect(viewModel.modelLabel, 'Parakeet v3');
  });

  test('reports the model download progress', () async {
    input.downloadSteps = [0.1, 0.5, 1.0];
    final progress = <double?>[];
    viewModel.addListener(() => progress.add(viewModel.downloadProgress));

    await viewModel.initialize();

    expect(progress, containsAllInOrder([0.1, 0.5, 1.0]));
    expect(viewModel.downloadProgress, isNull);
    expect(viewModel.status, ConversationStatus.ready);
  });

  test('fails with a message when the model cannot be prepared', () async {
    input.prepareError = Exception('no network');

    await viewModel.initialize();

    expect(viewModel.status, ConversationStatus.failed);
    expect(viewModel.message, isNotNull);
    expect(viewModel.canRecord, isFalse);
  });

  test('the first tap starts recording and the second one stops it', () async {
    await viewModel.initialize();

    await viewModel.toggleRecording();
    expect(viewModel.isRecording, isTrue);
    expect(input.listening, isTrue);

    await viewModel.toggleRecording();
    expect(viewModel.status, ConversationStatus.ready);
    expect(input.listening, isFalse);
    expect(viewModel.utterances.single.text, 'Kolega nie oddycha');
  });

  test('adds every utterance as soon as it is recognised', () async {
    await viewModel.initialize();
    await viewModel.toggleRecording();

    input.emitUtterance('Uciskam klatkę');
    input.emitUtterance('Podłączam AED');
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.isRecording, isTrue);
    expect(viewModel.utterances.map((u) => u.text), [
      'Uciskam klatkę',
      'Podłączam AED',
    ]);
  });

  test(
    'shows the partial text while recording and clears it afterwards',
    () async {
      await viewModel.initialize();
      await viewModel.toggleRecording();

      input.emitPartial('Kolega nie');
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.partialText, 'Kolega nie');

      await viewModel.toggleRecording();
      expect(viewModel.partialText, isEmpty);
    },
  );

  test('shows a message when no speech was recognised', () async {
    input.text = '';
    await viewModel.initialize();

    await viewModel.toggleRecording();
    await viewModel.toggleRecording();

    expect(viewModel.utterances, isEmpty);
    expect(viewModel.message, isNotNull);
  });

  test('stays usable after a recognition error', () async {
    input.finishError = Exception('decoder failed');
    await viewModel.initialize();

    await viewModel.toggleRecording();
    await viewModel.toggleRecording();

    expect(viewModel.utterances, isEmpty);
    expect(viewModel.status, ConversationStatus.ready);
    expect(viewModel.message, isNotNull);
  });

  test('ignores taps while recording is starting', () async {
    await viewModel.initialize();

    final starting = viewModel.toggleRecording();
    await viewModel.toggleRecording();
    await starting;

    expect(viewModel.isRecording, isTrue);
  });

  test('does not record without microphone access', () async {
    input.permission = false;
    await viewModel.initialize();

    await viewModel.toggleRecording();

    expect(viewModel.status, ConversationStatus.ready);
    expect(input.listening, isFalse);
    expect(viewModel.message, contains('mikrofonu'));
  });
}
