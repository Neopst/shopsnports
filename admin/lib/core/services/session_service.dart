// lib/core/services/session_service.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session timeout duration (30 minutes)
const Duration defaultSessionTimeout = Duration(minutes: 30);

/// Warning before logout (5 minutes)
const Duration sessionWarningDuration = Duration(minutes: 5);

/// Session state
enum SessionState { active, warning, expired }

/// Session service that manages user session timeout
class SessionService extends Notifier<SessionState> {
  Timer? _idleTimer;
  Timer? _warningTimer;
  late final Duration _timeoutDuration;
  late final Duration _warningDuration;

  @override
  SessionState build() {
    _timeoutDuration = ref.watch(sessionTimeoutProvider);
    _warningDuration = ref.watch(sessionWarningDurationProvider);
    _resetIdleTimer();
    return SessionState.active;
  }

  /// Called when user interacts with the app
  void resetSession() {
    _cancelTimers();
    state = SessionState.active;
    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _cancelTimers();

    // Set timer for warning
    _warningTimer = Timer(_timeoutDuration - _warningDuration, () {
      state = SessionState.warning;
    });

    // Set timer for session expiration
    _idleTimer = Timer(_timeoutDuration, () {
      state = SessionState.expired;
    });
  }

  void _cancelTimers() {
    _idleTimer?.cancel();
    _warningTimer?.cancel();
    _idleTimer = null;
    _warningTimer = null;
  }

  @override
  void dispose() {
    _cancelTimers();
  }
}

/// Provider for session timeout configuration
final sessionTimeoutProvider = Provider<Duration>((ref) => defaultSessionTimeout);

/// Provider for session warning duration
final sessionWarningDurationProvider = Provider<Duration>((ref) => sessionWarningDuration);

/// Global session service provider
final sessionServiceProvider = NotifierProvider<SessionService, SessionState>(
  SessionService.new,
);