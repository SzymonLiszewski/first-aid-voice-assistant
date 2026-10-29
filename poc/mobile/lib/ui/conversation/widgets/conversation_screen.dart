import 'package:flutter/material.dart';

import '../../core/themes/theme.dart';
import '../../core/ui/demo_banner.dart';
import '../../../domain/models/conversation_entry.dart';
import '../../../domain/models/utterance.dart';
import '../../../utils/format.dart';
import '../view_models/conversation_view_model.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.createViewModel});

  final ConversationViewModel Function() createViewModel;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late final ConversationViewModel _viewModel = widget.createViewModel();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_scrollToNewest);
    _viewModel.initialize();
  }

  void _scrollToNewest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _viewModel.removeListener(_scrollToNewest);
    _viewModel.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool get _showsPartial =>
      _viewModel.partialText.isNotEmpty &&
      (_viewModel.status == ConversationStatus.recording ||
          _viewModel.status == ConversationStatus.transcribing);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rozmowa testowa',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: const [DemoBadge(), SizedBox(width: 16)],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              children: [
                _ModelStatus(viewModel: _viewModel),
                const SizedBox(height: 12),
                Expanded(
                  child: _viewModel.entries.isEmpty && !_showsPartial
                      ? const _EmptyConversation()
                      : ListView.separated(
                          controller: _scroll,
                          itemCount:
                              _viewModel.entries.length +
                              (_showsPartial ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => i < _viewModel.entries.length
                              ? switch (_viewModel.entries[i]) {
                                  UserMessage(:final utterance) => _UserBubble(
                                    utterance: utterance,
                                  ),
                                  final AssistantMessage answer =>
                                    _AssistantBubble(answer: answer),
                                }
                              : _PartialBubble(text: _viewModel.partialText),
                        ),
                ),
                const SizedBox(height: 12),
                _StatusLine(viewModel: _viewModel),
                const SizedBox(height: 12),
                _TalkButton(viewModel: _viewModel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModelStatus extends StatelessWidget {
  const _ModelStatus({required this.viewModel});

  final ConversationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final preparing = viewModel.status == ConversationStatus.preparingModel;
    final failed = viewModel.status == ConversationStatus.failed;
    final (color, text) = switch (viewModel.status) {
      ConversationStatus.preparingModel => (
        AppColors.busy,
        viewModel.downloadProgress == null
            ? 'Przygotowanie: ${viewModel.preparingLabel}…'
            : 'Pobieranie: ${viewModel.preparingLabel} '
                  '${(viewModel.downloadProgress! * 100).floor()}% (tylko za pierwszym razem)',
      ),
      ConversationStatus.failed => (
        AppColors.primary,
        '${viewModel.preparingLabel} niedostępny',
      ),
      _ => (
        AppColors.ok,
        '${viewModel.modelLabel} · ${viewModel.voiceLabel} · gotowe',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (failed)
                TextButton(
                  onPressed: viewModel.initialize,
                  child: const Text('Ponów'),
                ),
            ],
          ),
          if (preparing) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: viewModel.downloadProgress,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'Naciśnij przycisk i mów po polsku.\nKażda wypowiedź pojawi się tutaj osobno, '
          'a asystent odpowie na głos.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.utterance});

  final Utterance utterance;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.userBubble,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                utterance.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatClock(utterance.endedAt)} · mowa ${formatSeconds(utterance.speechDuration)}'
              ' · tekst po ${formatSeconds(utterance.transcriptionDuration)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.answer});

  final AssistantMessage answer;

  @override
  Widget build(BuildContext context) {
    final failed = answer.state == AnswerState.failed;
    final interrupted = answer.state == AnswerState.interrupted;
    final details = [
      if (answer.firstSoundAfter != null)
        'głos po ${formatSeconds(answer.firstSoundAfter!)}',
      if (answer.firstTokenTime != null)
        'model ${formatSeconds(answer.firstTokenTime!)}',
      if (interrupted) 'przerwano',
    ];
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: failed ? AppColors.primarySoft : AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Text(
                answer.text.isEmpty ? '…' : answer.text,
                style: TextStyle(
                  color: interrupted ? AppColors.textSecondary : AppColors.text,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                details.join(' · '),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PartialBubble extends StatelessWidget {
  const _PartialBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.userBubble.withValues(alpha: 0.55),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.viewModel});

  final ConversationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final message = viewModel.message;
    final activity = viewModel.assistantActivity;
    final (text, color) = switch (viewModel.status) {
      _ when activity == AssistantActivity.speaking => (
        'Asystent mówi…',
        AppColors.ok,
      ),
      _ when activity == AssistantActivity.thinking => (
        'Asystent myśli…',
        AppColors.busy,
      ),
      ConversationStatus.recording => (
        'Słucham… gdy skończysz, mikrofon sam się wyłączy',
        AppColors.primary,
      ),
      ConversationStatus.transcribing => (
        'Kończę rozpoznawanie…',
        AppColors.busy,
      ),
      _ when message != null => (message, AppColors.textSecondary),
      _ => ('', AppColors.textSecondary),
    };
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Semantics(
              liveRegion: true,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
          if (activity != AssistantActivity.idle)
            TextButton(
              onPressed: viewModel.stopAnswer,
              child: const Text('Przerwij'),
            ),
        ],
      ),
    );
  }
}

class _TalkButton extends StatelessWidget {
  const _TalkButton({required this.viewModel});

  final ConversationViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final recording = viewModel.isRecording;
    final enabled = viewModel.canRecord || recording;
    return Column(
      children: [
        Semantics(
          button: true,
          enabled: enabled,
          label: recording ? 'Zakończ mówienie' : 'Zacznij mówić',
          child: GestureDetector(
            onTap: enabled ? viewModel.toggleRecording : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: recording ? 108 : 96,
              height: recording ? 108 : 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled ? AppColors.primary : const Color(0xFFBDBDC2),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                            alpha: recording ? 0.5 : 0.35,
                          ),
                          blurRadius: recording ? 28 : 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                recording ? Icons.stop_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          recording
              ? 'Naciśnij, aby zakończyć'
              : viewModel.assistantActivity == AssistantActivity.idle
              ? 'Naciśnij i mów'
              : 'Poczekaj, aż asystent skończy',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF444444),
          ),
        ),
      ],
    );
  }
}
