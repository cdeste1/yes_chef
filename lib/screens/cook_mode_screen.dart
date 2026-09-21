import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/recipe_model.dart';
import '../services/timer_notification_service.dart';
import '../services/voice_settings_service.dart';

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

  // Voice commands — always-on while _continuousMode is true: the mic
  // re-listens automatically after every session ends (silence, platform
  // session-length cap, etc.) and after every TTS utterance finishes.
  // _speech is lazily created on first use so the mic/speech-recognition
  // permission prompt is contextual, not blind at launch. Never listens
  // while _isSpeaking (the app shouldn't hear itself) — listening resumes
  // once TTS's completion handler fires.
  stt.SpeechToText? _speech;
  bool _speechInitialized = false;
  bool _isListening = false;
  bool _continuousMode = true;

  @override
  void initState() {
    super.initState();
    _steps = widget.recipe.steps;
    _pageController = PageController();
    WakelockPlus.enable();
    // Await init before the first speak() so the completion handler (which
    // is what kicks off continuous listening) is registered in time —
    // otherwise the very first utterance can finish before anything is
    // listening for its completion.
    _initTts().then((_) {
      if (mounted) _speakCurrentStep();
    });
  }

  Future<void> _initTts() async {
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
    );

    final savedVoice = await VoiceSettingsService.getSavedVoice();
    if (savedVoice != null) {
      try {
        await _tts.setVoice(savedVoice);
      } catch (e) {
        // Saved voice no longer exists on this device/OS update — fall
        // back to the platform default rather than failing to speak at all.
      }
    }

    _tts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
      // Yield the mic immediately if a listen session was still open (e.g.
      // the user swiped to a new step mid-listen) so the app never hears
      // its own narration. Set _isListening false ourselves rather than
      // waiting for the plugin's stop() callback — same reasoning as above.
      if (_isListening) {
        _speech?.stop();
        if (mounted) setState(() => _isListening = false);
      }
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
      _maybeResumeListening();
    });
    _tts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
      _maybeResumeListening();
    });
  }

  Future<void> _speakCurrentStep() async {
    if (!_ttsEnabled) {
      _maybeResumeListening();
      return;
    }
    try {
      await _tts.stop();
      await _tts.speak(_steps[_currentIndex].instruction);
    } catch (e) {
      // Some devices (mostly certain Android OEM builds) ship with no TTS
      // engine installed. Degrade silently rather than repeatedly throwing.
      if (mounted) setState(() => _ttsEnabled = false);
      _maybeResumeListening();
    }
  }

  void _toggleMute() {
    setState(() => _ttsEnabled = !_ttsEnabled);
    if (!_ttsEnabled) _tts.stop();
  }

  Future<void> _showVoicePicker() async {
    List<dynamic> raw;
    try {
      raw = (await _tts.getVoices) as List<dynamic>;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load voices on this device.")),
      );
      return;
    }

    final voices = raw
        .map((v) => Map<String, String>.from(
            (v as Map).map((k, val) => MapEntry(k.toString(), val.toString()))))
        .where((v) => (v['locale'] ?? '').toLowerCase().startsWith('en'))
        .toList();

    if (!mounted) return;
    if (voices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No English voices found on this device.')),
      );
      return;
    }

    // iOS voices include a 'gender' field (Android's don't); where it's
    // available, only show voices identified as Man/Woman — iOS also ships
    // a long tail of novelty voices (Bells, Bubbles, etc.) with no gender
    // set, which is exactly the "gimmicky" set to hide. If nothing on this
    // device reports a gender at all (Android), fall back to the full list
    // rather than filtering everything away.
    String? genderGroupOf(Map<String, String> v) {
      final g = (v['gender'] ?? '').toLowerCase();
      if (g == 'male') return 'Man';
      if (g == 'female') return 'Woman';
      return null;
    }

    final hasAnyGenderData = voices.any((v) => genderGroupOf(v) != null);
    final displayVoices =
        hasAnyGenderData ? voices.where((v) => genderGroupOf(v) != null).toList() : voices;

    // Higher-quality (less robotic) voices first within each group. iOS
    // ships "default" quality on-device but "enhanced"/"premium" versions
    // of the same voices are a free download in iOS Settings.
    const qualityRank = {'premium': 0, 'enhanced': 1, 'default': 2};
    int qualityOf(Map<String, String> v) =>
        qualityRank[(v['quality'] ?? '').toLowerCase()] ?? 3;
    displayVoices.sort((a, b) => qualityOf(a).compareTo(qualityOf(b)));

    final groups = <String, List<Map<String, String>>>{};
    for (final v in displayVoices) {
      groups.putIfAbsent(genderGroupOf(v) ?? 'Voices', () => []).add(v);
    }
    const groupOrder = ['Woman', 'Man', 'Voices'];

    // If nothing better than "default" quality is installed, there's a free
    // fix: iOS ships higher-quality (Enhanced/Premium) versions of its
    // voices as an optional download, not on-device by default.
    final hasBetterThanDefault = displayVoices.any(
        (v) => (v['quality'] ?? '').toLowerCase() != 'default' && v['quality'] != null);
    final showQualityTip = displayVoices.any((v) => v['quality'] != null) && !hasBetterThanDefault;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Choose a voice',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await _tts.clearVoice();
                await VoiceSettingsService.clearVoice();
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              child: const Text('Reset to device default'),
            ),
            if (showQualityTip)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'These sound more robotic than they could — go to Settings → '
                  'Accessibility → Spoken Content → Voices and download an '
                  '"Enhanced" or "Premium" voice for a much more natural sound, '
                  'then come back here to pick it.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ),
            for (final groupName in groupOrder)
              if (groups[groupName]?.isNotEmpty ?? false) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(groupName,
                      style: const TextStyle(
                          color: Color(0xFFF58220), fontWeight: FontWeight.bold)),
                ),
                for (final v in groups[groupName]!)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(v['name'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      [
                        v['locale'] ?? '',
                        if ((v['quality'] ?? '').toLowerCase() == 'premium') 'Premium',
                        if ((v['quality'] ?? '').toLowerCase() == 'enhanced') 'Enhanced',
                      ].join(' · '),
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.white70),
                      tooltip: 'Preview',
                      onPressed: () async {
                        await _tts.setVoice(v);
                        await _tts.speak('Hello! This is how I sound.');
                      },
                    ),
                    onTap: () async {
                      await _tts.setVoice(v);
                      await VoiceSettingsService.saveVoice(
                          v['name'] ?? '', v['locale'] ?? '');
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
              ],
          ],
        ),
      ),
    );
  }

  // ── Voice commands ────────────────────────────────────────────────────
  //
  // Continuous mode works by re-listening after every session naturally
  // ends — speech_to_text sessions are capped by the platform (~1 minute
  // on-device on iOS), so "always on" is really "always restarting."
  // _maybeResumeListening() is the single place that decides whether to
  // kick off the next session, called from every place a session could
  // have just ended: onStatus, onError, and TTS finishing/being skipped.

  void _maybeResumeListening() {
    if (_continuousMode && !_isSpeaking && !_isListening && mounted) {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_isSpeaking || _isListening || !_continuousMode) return;

    _speech ??= stt.SpeechToText();
    if (!_speechInitialized) {
      _speechInitialized = await _speech!.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
            _maybeResumeListening();
          }
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _isListening = false);
          _maybeResumeListening();
        },
      );
    }

    if (!_speechInitialized) {
      if (!mounted) return;
      setState(() => _continuousMode = false);
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
          // Don't wait on onStatus to confirm the session ended — on some
          // platform/version combos it doesn't fire reliably after repeated
          // start/stop cycles, which left the mic permanently "stuck"
          // listening (blocking _maybeResumeListening's guard forever)
          // after the very first recognized command.
          if (mounted) setState(() => _isListening = false);
          _handleVoiceCommand(result.recognizedWords);
          _maybeResumeListening();
        }
      },
      listenOptions: stt.SpeechListenOptions(
        // Stay comfortably under iOS's on-device session cap (~60s); the
        // status callback restarts a fresh session right after this ends.
        listenFor: const Duration(seconds: 55),
        pauseFor: const Duration(seconds: 4),
        cancelOnError: true,
        partialResults: false,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  void _toggleContinuousListening() {
    setState(() => _continuousMode = !_continuousMode);
    if (_continuousMode) {
      _maybeResumeListening();
    } else {
      _speech?.stop();
      setState(() => _isListening = false);
    }
  }

  static const Map<String, int> _spokenNumbers = {
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14,
    'fifteen': 15, 'twenty': 20, 'thirty': 30, 'forty': 40,
    'forty-five': 45, 'sixty': 60,
  };

  /// Extracts the first number in [text], as a digit ("5") or a common
  /// spoken word ("five") — speech engines usually transcribe numbers as
  /// digits already, but this is a cheap fallback for when they don't.
  int? _extractNumber(String text) {
    final digitMatch = RegExp(r'\d+').firstMatch(text);
    if (digitMatch != null) return int.tryParse(digitMatch.group(0)!);
    for (final entry in _spokenNumbers.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  void _handleVoiceCommand(String heard) {
    final n = heard.toLowerCase().trim();
    if (n.contains('timer')) {
      if (n.contains('cancel') || n.contains('stop') || n.contains('clear')) {
        _cancelTimer();
        return;
      }
      final value = _extractNumber(n);
      if (value != null && value > 0) {
        final isSeconds = n.contains('second') || n.contains('sec');
        _startTimer(isSeconds ? Duration(seconds: value) : Duration(minutes: value));
      }
      return;
    }
    if (n.contains('next')) {
      _goNext();
    } else if (n.contains('back') || n.contains('previous')) {
      _goBack();
    } else if (n.contains('repeat') || n.contains('again')) {
      _speakCurrentStep();
    }
    // Unmatched speech is ignored silently — with the mic always on, most
    // recognized phrases will just be ambient kitchen conversation, and a
    // toast for every one of those would be constant noise.
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
            icon: const Icon(Icons.record_voice_over),
            tooltip: 'Choose voice',
            onPressed: _showVoicePicker,
          ),
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
                    message: !_continuousMode
                        ? 'Voice control off — tap to turn on'
                        : (_isListening
                            ? 'Listening for "next", "back", "repeat", "timer 5 minutes"…'
                            : 'Voice control on — tap to turn off'),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: RawMaterialButton(
                        shape: const CircleBorder(),
                        fillColor: !_continuousMode
                            ? Colors.grey
                            : (_isListening ? _successGreen : const Color(0xFFF58220)),
                        onPressed: _toggleContinuousListening,
                        child: Icon(
                          !_continuousMode
                              ? Icons.mic_off
                              : (_isListening ? Icons.mic : Icons.mic_none),
                          color: Colors.white,
                        ),
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
