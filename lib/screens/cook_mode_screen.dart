import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/recipe_model.dart';
import '../services/timer_notification_service.dart';

/// Full-screen, one-step-at-a-time cooking view. PageView is the single
/// source of truth for "which step is current" — later phases (timer,
/// text-to-speech, voice commands) all hook into onPageChanged so every
/// entry point (swipe, tap, voice) drives the same "arrived at step N"
/// behavior instead of duplicating it per input method.
class CookModeScreen extends StatefulWidget {
  final Recipe recipe;

  const CookModeScreen({super.key, required this.recipe});

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  late final List<StepItem> _steps;
  late final PageController _pageController;
  int _currentIndex = 0;

  // Timer — a single global banner shown across all steps, deliberately
  // decoupled from _currentIndex/the PageView (starting a timer and
  // swiping to another step should not affect it).
  static const int _timerNotificationId = 9001;
  static const Color _successGreen = Color(0xFF7EC850);
  static const Color _alertRed = Color(0xFFE54B4B);

  Timer? _uiTickTimer;
  DateTime? _timerEndAt;
  Duration? _pausedRemaining;
  bool _timerJustFinished = false;
  bool _requestedNotificationPermission = false;

  // Text-to-speech — speaks each step on arrival; "repeat" re-speaks the
  // current step. Kept separate from the mic (see phase 6) so the app
  // never listens while it's talking.
  final FlutterTts _tts = FlutterTts();
  bool _ttsEnabled = true;
  bool _isSpeaking = false;
  Timer? _speechDebounce;

  // Voice commands — push-to-talk: tap the mic, speak one command, it
  // auto-stops after a pause. Lazily created on first tap so the
  // mic/speech-recognition permission prompt is contextual, not blind at
  // launch. Never listens while _isSpeaking (the app shouldn't hear itself).
  stt.SpeechToText? _speech;
  bool _speechInitialized = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _steps = widget.recipe.steps;
    _pageController = PageController();
    WakelockPlus.enable();
    _initTts();
    _speakCurrentStep();
  }

  Future<void> _initTts() async {
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
    );
    _tts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _speakCurrentStep() async {
    if (!_ttsEnabled) return;
    try {
      await _tts.stop();
      await _tts.speak(_steps[_currentIndex].instruction);
    } catch (e) {
      // Some devices (mostly certain Android OEM builds) ship with no TTS
      // engine installed. Degrade silently rather than repeatedly throwing.
      if (mounted) setState(() => _ttsEnabled = false);
    }
  }

  void _toggleMute() {
    setState(() => _ttsEnabled = !_ttsEnabled);
    if (!_ttsEnabled) _tts.stop();
  }

  // ── Voice commands ────────────────────────────────────────────────────

  Future<void> _startListening() async {
    if (_isSpeaking || _isListening) return;

    _speech ??= stt.SpeechToText();
    if (!_speechInitialized) {
      _speechInitialized = await _speech!.initialize(
        onStatus: (status) {
          if ((status == 'notListening' || status == 'done') && mounted) {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          if (mounted) setState(() => _isListening = false);
        },
      );
    }

    if (!_speechInitialized) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Voice control isn't available — check microphone/speech permissions."),
        ),
      );
      return;
    }

    setState(() => _isListening = true);
    await _speech!.listen(
      onResult: (result) {
        if (result.finalResult) {
          _handleVoiceCommand(result.recognizedWords);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        partialResults: false,
      ),
    );
  }

  void _stopListening() {
    _speech?.stop();
    setState(() => _isListening = false);
  }

  void _handleVoiceCommand(String heard) {
    setState(() => _isListening = false);
    final n = heard.toLowerCase().trim();
    if (n.contains('next')) {
      _goNext();
    } else if (n.contains('back') || n.contains('previous')) {
      _goBack();
    } else if (n.contains('repeat') || n.contains('again')) {
      _speakCurrentStep();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Didn\'t catch that ("$heard") — try "next", "back", or "repeat".')),
      );
    }
  }

  @override
  void dispose() {
    // Only the local UI tick is cancelled here — the scheduled OS
    // notification is the source of truth for "did the timer finish"
    // and stays scheduled even if this screen goes away.
    _uiTickTimer?.cancel();
    _speechDebounce?.cancel();
    _tts.stop();
    _speech?.stop();
    WakelockPlus.disable();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    // Debounced so a fast multi-swipe only speaks the step actually landed on.
    _speechDebounce?.cancel();
    _speechDebounce = Timer(const Duration(milliseconds: 250), _speakCurrentStep);
  }

  void _goNext() {
    if (_currentIndex >= _steps.length - 1) {
      Navigator.pop(context);
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goBack() {
    if (_currentIndex == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // ── Timer ──────────────────────────────────────────────────────────────

  Duration? get _timerRemaining {
    if (_timerEndAt == null) return null;
    final remaining = _timerEndAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _startTimer(Duration duration) async {
    if (!_requestedNotificationPermission) {
      await TimerNotificationService.requestPermission();
      _requestedNotificationPermission = true;
    }
    await TimerNotificationService.cancel(_timerNotificationId);

    setState(() {
      _timerEndAt = DateTime.now().add(duration);
      _pausedRemaining = null;
      _timerJustFinished = false;
    });

    await TimerNotificationService.scheduleTimerComplete(
      id: _timerNotificationId,
      stepLabel: 'Step ${_currentIndex + 1}: ${_steps[_currentIndex].instruction}',
      remaining: duration,
    );

    _uiTickTimer?.cancel();
    _uiTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _timerRemaining;
      if (remaining == Duration.zero) {
        _uiTickTimer?.cancel();
        HapticFeedback.heavyImpact();
        setState(() => _timerJustFinished = true);
      } else {
        setState(() {});
      }
    });
  }

  void _pauseTimer() {
    final remaining = _timerRemaining;
    if (remaining == null) return;
    _uiTickTimer?.cancel();
    TimerNotificationService.cancel(_timerNotificationId);
    setState(() {
      _pausedRemaining = remaining;
      _timerEndAt = null;
    });
  }

  Future<void> _resumeTimer() async {
    final paused = _pausedRemaining;
    if (paused == null) return;
    await _startTimer(paused);
  }

  Future<void> _cancelTimer() async {
    _uiTickTimer?.cancel();
    await TimerNotificationService.cancel(_timerNotificationId);
    if (!mounted) return;
    setState(() {
      _timerEndAt = null;
      _pausedRemaining = null;
      _timerJustFinished = false;
    });
  }

  Future<void> _showTimerPicker() async {
    const presets = [1, 3, 5, 10, 15, 20, 30];
    // If the recipe data specifies a duration for this step, offer it as a
    // suggestion — never auto-started, just a convenient chip.
    final suggestedSeconds = _steps[_currentIndex].durationSeconds;
    final customController = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Start a timer',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (suggestedSeconds != null)
                  ActionChip(
                    label: Text('Suggested: ${_formatDuration(Duration(seconds: suggestedSeconds))}'),
                    backgroundColor: _successGreen.withValues(alpha: 0.2),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _startTimer(Duration(seconds: suggestedSeconds));
                    },
                  ),
                ...presets.map((m) => ActionChip(
                      label: Text('$m min'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _startTimer(Duration(minutes: m));
                      },
                    )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: customController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Custom minutes'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final minutes = int.tryParse(customController.text.trim());
                    if (minutes == null || minutes <= 0) return;
                    Navigator.pop(sheetContext);
                    _startTimer(Duration(minutes: minutes));
                  },
                  child: const Text('Start'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerControlRow({
    required String label,
    required Color color,
    required VoidCallback onPrimary,
    required IconData primaryIcon,
    required VoidCallback onCancel,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          IconButton(icon: Icon(primaryIcon, color: color), onPressed: onPrimary),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBanner() {
    if (_timerJustFinished) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration:
            BoxDecoration(color: _alertRed, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Expanded(
              child: Text("Time's up!",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: _cancelTimer,
              child: const Text('Dismiss', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_pausedRemaining != null) {
      return _timerControlRow(
        label: 'Paused — ${_formatDuration(_pausedRemaining!)}',
        color: Colors.grey,
        onPrimary: _resumeTimer,
        primaryIcon: Icons.play_arrow,
        onCancel: _cancelTimer,
      );
    }
    final remaining = _timerRemaining;
    if (remaining != null) {
      return _timerControlRow(
        label: _formatDuration(remaining),
        color: _successGreen,
        onPrimary: _pauseTimer,
        primaryIcon: Icons.pause,
        onCancel: _cancelTimer,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.timer_outlined),
        label: const Text('Start Timer'),
        onPressed: _showTimerPicker,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentIndex == _steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Text(widget.recipe.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(_isSpeaking
                ? Icons.volume_up
                : (_ttsEnabled ? Icons.volume_up_outlined : Icons.volume_off)),
            tooltip: _ttsEnabled ? 'Mute narration' : 'Unmute narration',
            onPressed: _toggleMute,
          ),
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: 'Repeat step',
            onPressed: _speakCurrentStep,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Step ${_currentIndex + 1} of ${_steps.length}',
                style: const TextStyle(
                  color: Color(0xFFF58220),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            _buildTimerBanner(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _steps.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Center(
                    child: Text(
                      _steps[index].instruction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentIndex == 0 ? null : _goBack,
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Tooltip(
                    message: _isListening
                        ? 'Listening…'
                        : 'Say "next", "back", or "repeat"',
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: RawMaterialButton(
                        shape: const CircleBorder(),
                        fillColor: _isListening
                            ? _alertRed
                            : const Color(0xFFF58220),
                        onPressed:
                            _isSpeaking ? null : (_isListening ? _stopListening : _startListening),
                        child: Icon(_isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _goNext,
                      child: Text(isLastStep ? 'Finish' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
