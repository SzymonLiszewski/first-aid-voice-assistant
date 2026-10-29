import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/ui/demo_banner.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({
    super.key,
    required this.onStart,
    required this.onOpenSettings,
  });

  final VoidCallback onStart;

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 44).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const DemoBanner(),
                    const SizedBox(height: 28),
                    const _Header(),
                    const SizedBox(height: 20),
                    const _DemoSteps(),
                    const Spacer(),
                    const SizedBox(height: 20),
                    _StartButton(onPressed: onStart),
                    const SizedBox(height: 12),
                    const Text(
                      'W prawdziwym zagrożeniu życia dzwoń pod 112.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFE2E2E5)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: onOpenSettings,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            minimumSize: const Size(44, 44),
                          ),
                          icon: const Icon(Icons.settings_outlined, size: 20),
                          label: const Text(
                            'Ustawienia',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Text(
                          'DEMO · v0.1',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.monitor_heart_outlined,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Asystent pierwszej pomocy',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.text),
        ),
        const SizedBox(height: 8),
        const Text(
          'To demo sprawdza, czy rozmowa głosowa z asystentem działa od początku do końca.',
          style: TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF4A4A4A)),
        ),
      ],
    );
  }
}

class _DemoSteps extends StatelessWidget {
  const _DemoSteps();

  static const _steps = [
    ('Rozpoznawanie mowy', 'Whisper na telefonie zamienia mowę na tekst'),
    ('Odpowiedź modelu', 'tekst trafia na serwer, model językowy odpowiada'),
    ('Odpowiedź głosowa', 'odpowiedź jest czytana na głos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          for (final (index, (title, subtitle)) in _steps.indexed) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      icon: const Icon(Icons.mic_none_rounded, size: 26),
      label: const Text('Rozpocznij rozmowę testową'),
    );
  }
}
