import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsnports/providers/user_providers.dart';

/// Clean, robust multi-slide promotional splash screen.
/// - 2 slides, auto-advance every 5 seconds
/// - 600ms transition animation
/// - Clickable dots (tap to jump)
/// - Previous / Next / Skip controls
/// - Pure branding - no embedded CTAs
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  final PageController _pc = PageController();
  Timer? _timer;
  int _page = 0;
  static const int _total = 2;
  static const Duration _visible = Duration(seconds: 5);
  static const Duration _anim = Duration(milliseconds: 600);
  static const double _mediaHeight = 340.0;
  late final AnimationController _shimmerController;
  late final AnimationController _blinkController;
  final Set<int> _loadedPages = {};
  bool _hasCheckedReturning = false;

  @override
  void initState() {
    super.initState();
    _shimmerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _blinkController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  Future<void> _checkReturningUser() async {
    if (_hasCheckedReturning) return;
    _hasCheckedReturning = true;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenSplash = prefs.getBool('has_seen_splash') ?? false;

    if (hasSeenSplash) {
      if (!mounted) return;
      _navigateHome();
    } else {
      if (!mounted) return;
      await prefs.setBool('has_seen_splash', true);
      _startAutoAdvance();
    }
  }

  void _startAutoAdvance() {
    _timer?.cancel();
    _timer = Timer.periodic(_visible, (_) => _advance());
  }

  void _stopAutoAdvance() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _advance() async {
    final next = (_page + 1) % _total;
    if (next == 0 && _page == _total - 1) {
      _navigateHome();
      return;
    }
    if (!mounted) return;
    try {
      await _pc.animateToPage(next, duration: _anim, curve: Curves.easeInOut);
    } catch (_) {}
  }

  void _onPageChanged(int p) {
    setState(() => _page = p);
  }

  void _navigateHome() {
    if (!mounted) return;
    _stopAutoAdvance();

    final user = ref.read(currentUserProvider);

    if (user != null) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/landing');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    _shimmerController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  Widget _buildSlide({
    required int index,
    required String asset,
    required String title,
    required String body,
  }) {
    final theme = Theme.of(context);

    Widget mediaWidget() {
      final lower = asset.toLowerCase();
      if (lower.endsWith('.json') || lower.endsWith('.lottie')) {
        try {
          return SizedBox(
            height: _mediaHeight,
            child: AnimatedOpacity(
              opacity: _loadedPages.contains(index) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut,
              child: Lottie.asset(
                asset,
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
                onLoaded: (_) {
                  if (!_loadedPages.contains(index)) {
                    setState(() => _loadedPages.add(index));
                  }
                },
              ),
            ),
          );
        } catch (e) {
          return SizedBox(
            height: _mediaHeight,
            child: Icon(
              Icons.animation,
              size: _mediaHeight / 2,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          );
        }
      }

      return SizedBox(
        height: _mediaHeight,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (frame == null && !wasSynchronouslyLoaded) {
              return const AnimatedOpacity(
                opacity: 0.0,
                duration: Duration(milliseconds: 450),
                child: SizedBox.shrink(),
              );
            }
            if (!_loadedPages.contains(index)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _loadedPages.add(index));
              });
            }
            return AnimatedOpacity(
              opacity: _loadedPages.contains(index) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut,
              child: child,
            );
          },
          errorBuilder: (_, __, ___) => Icon(
            Icons.store,
            size: _mediaHeight / 2,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        _stopAutoAdvance();
        final next = (_page + 1) % _total;
        if (next == 0 && _page == _total - 1) {
          _navigateHome();
          return;
        }
        if (!mounted) return;
        await _pc.animateToPage(next, duration: _anim, curve: Curves.easeInOut);
        _startAutoAdvance();
      },
      onTapDown: (_) => _stopAutoAdvance(),
      onTapUp: (_) => _startAutoAdvance(),
      onTapCancel: () => _startAutoAdvance(),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                mediaWidget(),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: SizedBox(
                    key: ValueKey(title + _page.toString()),
                    width: double.infinity,
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        final shimmerPos = _shimmerController.value;
                        final p = theme.colorScheme.primary;
                        final pr = (p.r * 255).round();
                        final pg = (p.g * 255).round();
                        final pb = (p.b * 255).round();
                        return ShaderMask(
                          shaderCallback: (rect) {
                            return LinearGradient(
                              colors: [
                                Color.fromRGBO(pr, pg, pb, 0.0),
                                Color.fromRGBO(pr, pg, pb, 0.6),
                                Color.fromRGBO(pr, pg, pb, 0.0),
                              ],
                              stops: [
                                (shimmerPos - 0.25).clamp(0.0, 1.0),
                                shimmerPos.clamp(0.0, 1.0),
                                (shimmerPos + 0.25).clamp(0.0, 1.0),
                              ],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                              fontSize: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: SizedBox(
                    key: ValueKey(body + _page.toString()),
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_total, (i) {
        final active = i == _page;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                _stopAutoAdvance();
                if (!mounted) return;
                await _pc.animateToPage(i,
                    duration: _anim, curve: Curves.easeInOut);
                _startAutoAdvance();
              },
              child: Container(
                width: active ? 22 : 16,
                height: active ? 22 : 16,
                decoration: BoxDecoration(
                  color: active
                      ? primary
                      : Color.fromRGBO(
                          (primary.r * 255).round(),
                          (primary.g * 255).round(),
                          (primary.b * 255).round(),
                          0.45,
                        ),
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? [
                          const BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ]
                      : null,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedReturning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkReturningUser();
      });
    }

    final slides = [
      _buildSlide(
        index: 0,
        asset: 'assets/images/logo.png',
        title: 'Welcome to ShopsNSports',
        body: 'Your one-stop marketplace connecting buyers, sellers, and shippers worldwide. Shop smarter, sell faster, ship anywhere.',
      ),
      _buildSlide(
        index: 1,
        asset: 'assets/animations/ecommerce.json',
        title: 'Shop with Confidence',
        body: 'Browse thousands of quality products with secure checkout, real-time tracking, and buyer protection. Great deals from trusted vendors.',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _stopAutoAdvance(),
              onPointerUp: (_) => _startAutoAdvance(),
              child: PageView(
                controller: _pc,
                onPageChanged: _onPageChanged,
                children: slides,
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: TextButton(
                onPressed: () async {
                  _stopAutoAdvance();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('has_seen_splash', true);
                  if (!mounted) return;
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: const Text('Skip »'),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 18,
              child: TextButton(
                onPressed: () async {
                  _stopAutoAdvance();
                  if (!mounted) return;
                  final prev = _page > 0 ? _page - 1 : 0;
                  await _pc.animateToPage(prev,
                      duration: _anim, curve: Curves.easeInOut);
                  _startAutoAdvance();
                },
                child: const Text('« Previous'),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(child: _buildDots()),
            ),
            Positioned(
              right: 12,
              bottom: 18,
              child: TextButton(
                onPressed: () async {
                  _stopAutoAdvance();
                  if (_page == _total - 1) {
                    _navigateHome();
                    return;
                  }
                  final next = _page + 1;
                  if (!mounted) return;
                  await _pc.animateToPage(next,
                      duration: _anim, curve: Curves.easeInOut);
                  _startAutoAdvance();
                },
                child: const Text('Next »'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}