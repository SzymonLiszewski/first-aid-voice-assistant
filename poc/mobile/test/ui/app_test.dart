import 'package:first_aid_voice_assistant/config/dependencies.dart';
import 'package:first_aid_voice_assistant/data/repositories/assistant_repository.dart';
import 'package:first_aid_voice_assistant/domain/models/voice_engine.dart';
import 'package:first_aid_voice_assistant/ui/core/app.dart';
import 'package:first_aid_voice_assistant/ui/conversation/view_models/conversation_view_model.dart';
import 'package:first_aid_voice_assistant/domain/models/speech_engine.dart';
import 'package:first_aid_voice_assistant/data/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/services.dart';

/// Phone-sized test screen (390 × 844 logical pixels, as in the mockups).
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// The start screen scrolls when its content is taller than the screen.
Future<void> tapOnStartScreen(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  late SettingsRepository settings;

  setUp(() async {
    settings = await SettingsRepository.load(MemoryStore());
  });

  late FakeChatSocket socket;
  late List<FakeSpeechOutput> outputs;

  setUp(() {
    socket = FakeChatSocket();
    outputs = [];
  });

  FakeSpeechOutput speechOutput(VoiceEngine voice) {
    final output = FakeSpeechOutput(label: voice.title);
    outputs.add(output);
    return output;
  }

  Widget app() => FirstAidApp(
    dependencies: AppDependencies(
      settings: settings,
      modelStore: FakeModelStore({SpeechEngine.parakeet}),
      createConversationViewModel: () => ConversationViewModel(
        input: FakeSpeechInput(engine: settings.speechEngine),
        output: speechOutput(settings.voiceEngine),
        assistant: AssistantRepository(
          socket: socket,
          serverUri: () => settings.chatUri,
        ),
        clock: () => DateTime(2026, 10, 27, 14, 21, 3),
      ),
      createSpeechOutput: speechOutput,
    ),
  );

  testWidgets('start screen says it is a demo', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(app());

    expect(find.text('WERSJA DEMONSTRACYJNA'), findsOneWidget);
    expect(find.text('Asystent pierwszej pomocy'), findsOneWidget);
    expect(find.text('Rozpocznij rozmowę testową'), findsOneWidget);
  });

  testWidgets('start button opens the test conversation', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(app());

    await tapOnStartScreen(tester, 'Rozpocznij rozmowę testową');

    expect(find.text('Rozmowa testowa'), findsOneWidget);
    expect(find.text('Parakeet v3 · Głos systemowy · gotowe'), findsOneWidget);
  });

  testWidgets('tapping to start and to stop shows the recognised text', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(app());
    await tapOnStartScreen(tester, 'Rozpocznij rozmowę testową');

    await tester.tap(find.bySemanticsLabel('Zacznij mówić'));
    await tester.pumpAndSettle();
    expect(find.text('Naciśnij, aby zakończyć'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Zakończ mówienie'));
    await tester.pumpAndSettle();

    expect(find.text('Kolega nie oddycha'), findsOneWidget);
    expect(find.text('Poczekaj, aż asystent skończy'), findsOneWidget);
  });

  testWidgets('the answer appears while it is read aloud', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(app());
    await tapOnStartScreen(tester, 'Rozpocznij rozmowę testową');
    await tester.tap(find.bySemanticsLabel('Zacznij mówić'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Zakończ mówienie'));
    await tester.pumpAndSettle();

    socket.connection!.delta('Zadzwoń pod sto dwanaście. ');
    await tester.pumpAndSettle();

    expect(find.text('Zadzwoń pod sto dwanaście. '), findsOneWidget);
    expect(outputs.single.spoken, ['Zadzwoń pod sto dwanaście.']);
    expect(find.text('Przerwij'), findsOneWidget);

    socket.connection!.done('Zadzwoń pod sto dwanaście.');
    await tester.pumpAndSettle();
    expect(find.text('głos po 1,0 s · model 0,1 s'), findsOneWidget);
    expect(find.text('Przerwij'), findsNothing);
    expect(find.text('Naciśnij i mów'), findsOneWidget);
  });

  testWidgets('the voice and the server are set in the settings', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(app());
    await tapOnStartScreen(tester, 'Ustawienia');

    final settingsList = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Piper – Gosia'),
      200,
      scrollable: settingsList,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Piper – Gosia'));
    await tester.pumpAndSettle();
    expect(settings.voiceEngine, VoiceEngine.piperGosia);

    await tester.scrollUntilVisible(
      find.text('Odsłuchaj głos'),
      200,
      scrollable: settingsList,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Odsłuchaj głos'));
    await tester.pumpAndSettle();
    expect(outputs.last.label, 'Piper – Gosia');
    expect(outputs.last.spoken, isNotEmpty);
    expect(outputs.last.disposed, isTrue);

    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: settingsList,
    );
    await tester.enterText(find.byType(TextField), '192.168.1.20:8000');
    await tester.pumpAndSettle();
    expect(settings.serverAddress, '192.168.1.20:8000');
    expect(
      find.text('Połączenie: ws://192.168.1.20:8000/v1/chat'),
      findsOneWidget,
    );
  });

  testWidgets('the model chosen in the settings is used in the conversation', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(app());

    await tapOnStartScreen(tester, 'Ustawienia');
    expect(find.text('pobrany'), findsOneWidget);
    await tester.ensureVisible(find.text('Whisper small'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Whisper small'));
    await tester.pumpAndSettle();
    expect(settings.speechEngine, SpeechEngine.whisperSmall);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapOnStartScreen(tester, 'Rozpocznij rozmowę testową');

    expect(
      find.text('Whisper small · Głos systemowy · gotowe'),
      findsOneWidget,
    );
  });
}
