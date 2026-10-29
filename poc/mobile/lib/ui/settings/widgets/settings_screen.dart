import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/speech_output.dart';
import '../../../data/services/model_store.dart';
import '../../../domain/models/speech_engine.dart';
import '../../../domain/models/voice_engine.dart';
import '../view_models/voice_check_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.modelStore,
    required this.createSpeechOutput,
  });

  final SettingsRepository settings;
  final ModelStore modelStore;
  final SpeechOutput Function(VoiceEngine voice) createSpeechOutput;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Set<ModelPackage> _downloaded = {};
  late final TextEditingController _serverAddress = TextEditingController(
    text: widget.settings.serverAddress,
  );
  late final VoiceCheckViewModel _voiceCheck = VoiceCheckViewModel(
    createOutput: widget.createSpeechOutput,
  );

  @override
  void initState() {
    super.initState();
    _loadDownloaded();
  }

  @override
  void dispose() {
    _serverAddress.dispose();
    _voiceCheck.dispose();
    super.dispose();
  }

  Future<void> _loadDownloaded() async {
    final downloaded = <ModelPackage>{
      for (final ModelPackage package in [
        ...SpeechEngine.values,
        ...VoiceEngine.values,
      ])
        if (package.files.isNotEmpty &&
            await widget.modelStore.isDownloaded(package))
          package,
    };
    if (mounted) setState(() => _downloaded = downloaded);
  }

  Future<void> _checkVoice() async {
    await _voiceCheck.check(widget.settings.voiceEngine);
    await _loadDownloaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ustawienia',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.settings,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _Section(
                title: 'Rozpoznawanie mowy',
                children: [
                  const Text(
                    'Wszystkie silniki działają na telefonie, bez internetu. '
                    'Wybierz, który porównujesz w rozmowie testowej.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<SpeechEngine>(
                    groupValue: widget.settings.speechEngine,
                    onChanged: (engine) {
                      if (engine != null) {
                        widget.settings.setSpeechEngine(engine);
                      }
                    },
                    child: Column(
                      children: [
                        for (final engine in SpeechEngine.values)
                          RadioListTile<SpeechEngine>(
                            value: engine,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.primary,
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    engine.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (_downloaded.contains(engine)) ...[
                                  const SizedBox(width: 8),
                                  const _DownloadedChip(),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              '${engine.library} · ${engine.sizeLabel} · ${engine.description}',
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Wybrany model pobierze się przy następnym otwarciu rozmowy testowej '
                    '(tylko raz). Duże modele najlepiej pobierać przez Wi-Fi.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Głos asystenta',
                children: [
                  const Text(
                    'Odpowiedź jest czytana zdanie po zdaniu, już w trakcie jej '
                    'generowania. Oba głosy działają na telefonie.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<VoiceEngine>(
                    groupValue: widget.settings.voiceEngine,
                    onChanged: (voice) {
                      if (voice != null) widget.settings.setVoiceEngine(voice);
                    },
                    child: Column(
                      children: [
                        for (final voice in VoiceEngine.values)
                          RadioListTile<VoiceEngine>(
                            value: voice,
                            contentPadding: EdgeInsets.zero,
                            activeColor: AppColors.primary,
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    voice.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (_downloaded.contains(voice)) ...[
                                  const SizedBox(width: 8),
                                  const _DownloadedChip(),
                                ],
                              ],
                            ),
                            subtitle: Text(
                              '${voice.library} · ${voice.sizeLabel} · ${voice.description}',
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _VoiceCheck(viewModel: _voiceCheck, onCheck: _checkVoice),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Serwer asystenta',
                children: [
                  TextField(
                    controller: _serverAddress,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    onChanged: widget.settings.setServerAddress,
                    decoration: InputDecoration(
                      labelText: 'Adres serwera',
                      helperText: widget.settings.chatUri == null
                          ? null
                          : 'Połączenie: ${widget.settings.chatUri}',
                      errorText: widget.settings.chatUri == null
                          ? 'Nieprawidłowy adres'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Emulator Androida: http://10.0.2.2:8000. Telefon: adres komputera '
                    'w tej samej sieci Wi-Fi, np. http://192.168.1.20:8000.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Wersja demonstracyjna · v0.1\nPrototyp badawczy, nie jest wyrobem medycznym.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _VoiceCheck extends StatelessWidget {
  const _VoiceCheck({required this.viewModel, required this.onCheck});

  final VoiceCheckViewModel viewModel;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final progress = viewModel.progress;
        final status = switch (viewModel.status) {
          VoiceCheckStatus.preparing =>
            progress == null
                ? 'Przygotowanie głosu…'
                : 'Pobieranie głosu: ${(progress * 100).floor()}%',
          VoiceCheckStatus.speaking => 'Odtwarzanie…',
          VoiceCheckStatus.failed => viewModel.message ?? '',
          VoiceCheckStatus.idle => '',
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: viewModel.isBusy ? null : onCheck,
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Odsłuchaj głos'),
            ),
            if (viewModel.status == VoiceCheckStatus.preparing &&
                progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                color: AppColors.primary,
              ),
            ],
            if (status.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                status,
                style: TextStyle(
                  fontSize: 13,
                  color: viewModel.status == VoiceCheckStatus.failed
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DownloadedChip extends StatelessWidget {
  const _DownloadedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2E7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'pobrany',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1B5E20),
        ),
      ),
    );
  }
}
