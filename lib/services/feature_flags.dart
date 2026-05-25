import 'dart:async';

/// Very small feature-flag helper used for experiment gating.
///
/// This is intentionally lightweight: it provides an in-memory map that can
/// be initialized from remote-config later. For now it's safe to use during
/// development and can be replaced with Firebase Remote Config or a feature
/// flag service in a follow-up change.
class FeatureFlags {
  FeatureFlags._internal();
  static final FeatureFlags instance = FeatureFlags._internal();

  final Map<String, dynamic> _flags = {
    // Default variants / flags
    'product_cta_variant': 'control', // or 'minimal_cta'
    // Demo defaults (can be toggled remotely later)
    'checkout_flow_variant': 'single_page', // or 'multi_step'
    'show_progress_indicator': true,
  };

  Future<void> init() async {
    // Placeholder: load remote config or other source here if available.
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }

  String getString(String key, [String defaultValue = '']) {
    final v = _flags[key];
    if (v == null) return defaultValue;
    return v.toString();
  }

  bool isEnabled(String key, {bool defaultValue = false}) {
    final v = _flags[key];
    if (v is bool) return v;
    return defaultValue;
  }

  void set(String key, dynamic value) => _flags[key] = value;
}
