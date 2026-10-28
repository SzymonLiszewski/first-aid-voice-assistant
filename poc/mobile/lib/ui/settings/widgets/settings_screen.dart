import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/services/model_store.dart';
import '../../../domain/models/speech_engine.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.modelStore,
  });

  final SettingsRepository settings;
  final ModelStore modelStore;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Set<SpeechEngine> _downloaded = {};

  @override
  void initState() {
    super.initState();
    _loadDownloaded();
  }

  Future<void> _loadDownloaded() async {
    final downloaded = <SpeechEngine>{
      for (final engine in SpeechEngine.values)
        if (await widget.modelStore.isDownloaded(engine)) engine,
    };
    if (mounted) setState(() => _downloaded = downloaded);
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
