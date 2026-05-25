import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session timeout configuration
class SessionConfig {
  final Duration timeoutDuration;
  final Duration warningDuration;

  const SessionConfig({
    this.timeoutDuration = const Duration(hours: 1),
    this.warningDuration = const Duration(minutes: 5),
  });
}

/// Session state
enum SessionState { active, warning, expired }

/// Session manager - handles automatic session timeout
class SessionManager {
  final SessionConfig config;
  Timer? _activityTimer;
  Timer? _warningTimer;
  DateTime? _lastActivity;
  SessionState _state = SessionState.active;

  final _sessionStateController = StreamController<SessionState>.broadcast();
  Stream<SessionState> get sessionStateStream => _sessionStateController.stream;

  SessionState get state => _state;
  Duration get remainingTime {
    if (_lastActivity == null) return config.timeoutDuration;
    final elapsed = DateTime.now().difference(_lastActivity!);
    final remaining = config.timeoutDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  SessionManager({this.config = const SessionConfig()});

  /// Start the session manager
  void start() {
    _resetActivity();
    _scheduleActivityCheck();
  }

  /// Stop the session manager
  void stop() {
    _activityTimer?.cancel();
    _warningTimer?.cancel();
    _activityTimer = null;
    _warningTimer = null;
  }

  /// Record user activity - call this on any user interaction
  void recordActivity() {
    if (_state == SessionState.expired) return;
    _resetActivity();
  }

  /// Extend session (e.g., user clicks "Stay Logged In")
  void extendSession() {
    if (_state == SessionState.expired) return;
    _resetActivity();
  }

  void _resetActivity() {
    _lastActivity = DateTime.now();
    if (_state == SessionState.warning) {
      _state = SessionState.active;
      _sessionStateController.add(_state);
    }
    _scheduleActivityCheck();
  }

  void _scheduleActivityCheck() {
    _activityTimer?.cancel();
    _warningTimer?.cancel();

    // Schedule warning before timeout
    final warningOffset = config.timeoutDuration - config.warningDuration;
    _warningTimer = Timer(warningOffset, () {
      if (_state != SessionState.expired) {
        _state = SessionState.warning;
        _sessionStateController.add(_state);
      }
    });

    // Schedule expiration
    _activityTimer = Timer(config.timeoutDuration, () {
      _state = SessionState.expired;
      _sessionStateController.add(_state);
    });
  }

  /// Check if session is still valid
  bool get isSessionValid {
    if (_lastActivity == null) return false;
    final elapsed = DateTime.now().difference(_lastActivity!);
    return elapsed < config.timeoutDuration;
  }

  void dispose() {
    stop();
    _sessionStateController.close();
  }
}

/// Session timeout provider
final sessionConfigProvider = Provider<SessionConfig>((ref) {
  return const SessionConfig(
    timeoutDuration: Duration(hours: 1),
    warningDuration: Duration(minutes: 5),
  );
});

/// Session manager provider
final sessionManagerProvider = Provider<SessionManager>((ref) {
  final config = ref.watch(sessionConfigProvider);
  final manager = SessionManager(config: config);

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

/// Session state stream provider
final sessionStateProvider = StreamProvider<SessionState>((ref) {
  final manager = ref.watch(sessionManagerProvider);
  return manager.sessionStateStream;
});

/// Inactivity detector widget - wraps app to track activity
class SessionInactivityWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const SessionInactivityWrapper({super.key, required this.child});

  @override
  ConsumerState<SessionInactivityWrapper> createState() =>
      _SessionInactivityWrapperState();
}

class _SessionInactivityWrapperState
    extends ConsumerState<SessionInactivityWrapper> {
  @override
  void initState() {
    super.initState();
    // Start session tracking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final manager = ref.read(sessionManagerProvider);
      manager.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionStateProvider);

    return Listener(
      onPointerDown: (_) => _onActivity(),
      onPointerMove: (_) => _onActivity(),
      onPointerUp: (_) => _onActivity(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }

  void _onActivity() {
    final manager = ref.read(sessionManagerProvider);
    manager.recordActivity();
  }
}

/// Show session timeout warning dialog
Future<bool> showSessionTimeoutDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _SessionTimeoutDialog(),
  );
  return result ?? false;
}

class _SessionTimeoutDialog extends StatelessWidget {
  const _SessionTimeoutDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Session Expiring'),
      content: const Text(
        'Your session is about to expire due to inactivity. '
        'Would you like to stay logged in?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Log Out'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Stay Logged In'),
        ),
      ],
    );
  }
}
