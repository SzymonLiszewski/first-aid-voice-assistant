import 'package:first_aid_voice_assistant/config/dependencies.dart';
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

  Widget app() => FirstAidApp(
    dependencies: AppDependencies(
      settings: settings,
      modelStore: FakeModelStore({SpeechEngine.parakeet}),
      createConversationViewModel: (engine) =>
          ConversationViewModel(input: FakeSpeechInput(engine: engine)),
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
    expect(find.text('Parakeet v3 · gotowy'), findsOneWidget);
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
    expect(find.text('Naciśnij i mów'), findsOneWidget);
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

    expect(find.text('Whisper small · gotowy'), findsOneWidget);
  });
}
