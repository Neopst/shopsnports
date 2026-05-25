// ignore_for_file: prefer_const_constructors, unused_field

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shopsnports/services/notification_service.dart';
import 'package:shopsnports/models/shipping_request.dart';
import 'package:shopsnports/models/user.dart';
import 'package:shopsnports/models/enums.dart';
import 'package:shopsnports/models/app_banner.dart';
import 'package:shopsnports/models/news_ticker.dart';
import 'package:shopsnports/providers/user_providers.dart';
import 'package:shopsnports/providers/content_providers.dart';
import 'package:shopsnports/providers/user_stats_provider.dart';
import 'package:shopsnports/core/routing/app_routes.dart';
import 'package:shopsnports/core/theme/app_colors.dart';
import 'package:shopsnports/widgets/featured_services_carousel.dart';
import 'package:shopsnports/widgets/stats_cards.dart';
import 'package:shopsnports/widgets/main_scaffold.dart';
import 'package:shopsnports/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shopsnports/screens/shipping/qr_scanner_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final bool _isLoading = false;
  String? _errorMessage;
  bool _hasCheckedPermission = false;
  final TextEditingController _trackingController = TextEditingController();
  int _currentBannerIndex = 0;

  // controllers for auto‑scrolling
  late final PageController _bannerPageController;
  late final ScrollController _newsScrollController;
  Timer? _bannerTimer;
  Timer? _newsTimer;
  // cache resolved storage download URLs to avoid repeated lookups
  final Map<String, String> _resolvedImageUrls = {};

  // Banner carousel with 5 slides
  final List<BannerSlide> _bannerSlides = [
    BannerSlide(
      image: 'assets/images/1.jpg',
      title: 'Fast Shipping',
      subtitle: 'Deliver within 24 hours',
      color: Colors.blue,
    ),
    BannerSlide(
      image: 'assets/images/2.jpg',
      title: 'Affordable Rates',
      subtitle: 'Best prices in the market',
      color: Colors.teal,
    ),
    BannerSlide(
      image: 'assets/images/3.jpg',
      title: 'Track Live',
      subtitle: 'Real-time tracking updates',
      color: Colors.green,
    ),
    BannerSlide(
      image: 'assets/images/4.jpg',
      title: 'Affiliate Program',
      subtitle: 'Earn commissions today',
      color: Colors.orange,
    ),
    BannerSlide(
      image: 'assets/images/5.jpg',
      title: 'Secure Delivery',
      subtitle: 'Full insurance coverage',
      color: Colors.purple,
    ),
  ];

  // News ticker items
  final List<String> _newsItems = [
    '📢 New Express Service: Lagos to Abuja in 12 hours',
    '🎉 Refer a friend and earn ₦500 commission',
    '⚡ Weekend special: 30% off on all shipments',
    '🌍 Now delivering to 50+ cities nationwide',
    '💳 Payment plans available - 0% interest',
  ];

  @override
  void initState() {
    super.initState();

    // controllers for scrolling
    _bannerPageController = PageController();
    _newsScrollController = ScrollController();

    // Check push notification permission after a short delay
    Future.delayed(
        const Duration(seconds: 1), _checkPushNotificationPermission);

    // auto-advance banners every few seconds
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerPageController.hasClients && mounted) {
        final next = _currentBannerIndex + 1;
        _bannerPageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    // continuously scroll news ticker
    _newsTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_newsScrollController.hasClients && mounted) {
        final max = _newsScrollController.position.maxScrollExtent;
        final cur = _newsScrollController.offset;
        final target = cur + 1;
        if (target >= max) {
          _newsScrollController.jumpTo(0);
        } else {
          _newsScrollController.jumpTo(target);
        }
      }
    });
  }

  /// Check push notification permission and optionally request it.
  Future<void> _checkPushNotificationPermission() async {
    if (_hasCheckedPermission) return;
    _hasCheckedPermission = true;
    if (!mounted) return;

    // only show the dialog if we haven't asked previously
    final alreadyAsked = await NotificationService.instance.hasAskedForPermission();
    if (alreadyAsked) return;

    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.blue),
            SizedBox(width: 12),
            Text('Enable Notifications?'),
          ],
        ),
        content: const Text(
          'Stay updated with order status, special offers, and important updates. '
          'You can change this anytime in Settings.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              NotificationService.instance.markAsAsked();
              Navigator.of(context).pop(false);
            },
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (granted == true) {
      await NotificationService.instance.requestPermission();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Notifications enabled successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Resolve an image URL from Firebase Storage or return HTTP URL as-is.
  Future<String?> _resolveImageUrl(String imageUrl) async {
    if (imageUrl.isEmpty) return null;
    if (_resolvedImageUrls.containsKey(imageUrl)) {
      return _resolvedImageUrls[imageUrl];
    }
    try {
      if (imageUrl.startsWith('http')) {
        _resolvedImageUrls[imageUrl] = imageUrl;
        return imageUrl;
      }
      if (imageUrl.startsWith('gs://')) {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        final url = await ref.getDownloadURL();
        _resolvedImageUrls[imageUrl] = url;
        return url;
      }
      final ref = FirebaseStorage.instance.ref().child(imageUrl);
      final url = await ref.getDownloadURL();
      _resolvedImageUrls[imageUrl] = url;
      return url;
    } catch (e) {
      return null;
    }
  }

  /// Refresh handler for pull-to-refresh.
  Future<void> _onRefresh() async {
    // Invalidate provider caches to trigger a refetch on next build.
    // This is a simple no-op for now since providers auto-stream updates.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Get status color based on shipping status - THEMED WITH APP COLORS
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.successGreen;
      case 'in_transit':
      case 'intransit':
      case 'picked_up':
        return AppColors.primaryBlue;
      case 'on_hold':
      case 'pending':
        return AppColors.warningOrange;
      case 'cancelled':
      case 'exception':
        return AppColors.errorRed;
      default:
        return AppColors.grey;
    }
  }

  /// Build welcome bar with personalized greeting - DEEP BLUE THEMED
  Widget _buildWelcomeBar(AppUser? user) {
    final isRegistered = user != null;

    // Extract first name only (for "Welcome back, John" vs "Welcome back, John Doe")
    String getFirstName(String fullName) {
      return fullName.trim().split(' ')[0];
    }

    final name =
        isRegistered ? getFirstName(user.businessName ?? user.name) : 'Shipper';

    return Container(
      color: AppColors.primaryBlue,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '👋 ',
                style: TextStyle(fontSize: 18),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Login/Logout Button
              Consumer(
                builder: (context, ref, _) {
                  final currentUser = ref.watch(currentUserProvider);
                  final isLoggedIn = currentUser != null;

                  if (isLoggedIn) {
                    // Show logout button for logged in users
                    return TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Logout', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(authActionsProvider).signOut();
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  }

                  // Show Login/Sign Up buttons for guests
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/auth/signup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isRegistered ? '🚀 Ready to ship?' : '📦 Start shipping today',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// Build welcome bar for guest users (not logged in)
  Widget _buildGuestWelcomeBar() {
    return Container(
      color: AppColors.primaryBlue,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '👋 ',
                style: TextStyle(fontSize: 18),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Welcome to',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'ShopsNports',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '📦 Ship anything, anywhere — as a guest or registered user',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// Build enhanced banner carousel slider with Deep Blue/Yellow theme
  /// Fetches real data from Firestore banners collection
  Widget _buildBannerCarousel(List<AppBanner> banners) {
    // if Firestore returns no banners, fall back to the hardcoded slides so
    // the carousel always appears (useful during development or empty DB).
    final List<AppBanner> displayBanners = banners.isEmpty
        ? _bannerSlides.map((s) {
            return AppBanner(
              id: 'static_${s.title}',
              title: s.title,
              subtitle: s.subtitle,
              imageUrl: s.image,
              position: 'HOME_CAROUSEL',
              displayOrder: 0,
              isActive: true,
              startDate: Timestamp.fromDate(DateTime(2000)),
              endDate: Timestamp.fromDate(DateTime(2100)),
              impressions: 0,
              clicks: 0,
              createdAt: Timestamp.fromDate(DateTime.now()),
              updatedAt: Timestamp.fromDate(DateTime.now()),
              createdBy: 'system',
              updatedBy: 'system',
            );
          }).toList()
        : banners;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _bannerPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentBannerIndex = index % displayBanners.length;
                });
              },
              itemBuilder: (context, index) {
                final banner = displayBanners[index % displayBanners.length];
                return GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${banner.title} - Learn more'),
                        backgroundColor: AppColors.primaryBlue,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background image or gradient
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // always show gradient background in case image fails
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primaryBlue,
                                      AppColors.accentYellow,
                                    ],
                                  ),
                                ),
                              ),
                              if (banner.imageUrl.isNotEmpty) ...[
                                Positioned.fill(
                                  child: FutureBuilder<String?>(
                                    future: _resolveImageUrl(banner.imageUrl),
                                    builder: (context, snap) {
                                      if (snap.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        );
                                      }
                                      final resolved = snap.data;
                                      if (resolved == null ||
                                          resolved.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return CachedNetworkImage(
                                        imageUrl: resolved,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        placeholder: (context, url) => Container(
                                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: AppColors.primaryBlue.withValues(alpha: 0.5),
                                            child: const Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: Colors.white54,
                                                size: 32,
                                              ),
                                            ),
                                          );
                                        },
                                        fadeInDuration: const Duration(milliseconds: 300),
                                        memCacheWidth: 800,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Text overlay with dark scrim
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.5),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.accentYellow,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accentYellow
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: const Text(
                                    'Featured',
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      banner.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      banner.subtitle,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          // Enhanced carousel indicator dots with animation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              displayBanners.length,
              (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentBannerIndex == index ? 28 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: _currentBannerIndex == index
                        ? AppColors.primaryBlue
                        : AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build news ticker widget - DEEP BLUE THEMED
  /// Fetches real data from Firestore news_ticker collection
  Widget _buildNewsTicker(List<NewsTicker> newsItems) {
    return Container(
      color: AppColors.extraLightGrey,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        controller: _newsScrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.newspaper,
                    color: Colors.white,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'NEWS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (newsItems.isEmpty)
              Center(
                child: Text(
                  'No news available',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              SizedBox(
                height: 32,
                // switch to a scrollable Row instead of ListView to avoid
                // unbounded width inside a horizontal SingleChildScrollView
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(newsItems.length, (index) {
                      final newsItem = newsItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(newsItem.title),
                                  backgroundColor: AppColors.primaryBlue,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                            child: Center(
                              child: Text(
                                newsItem.getPreview(maxLength: 50),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build tracking bar hero section - DEEP BLUE THEMED
  Widget _buildTrackingBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.darkGrey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.local_shipping_outlined,
                    color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Track Shipment',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _trackingController,
              decoration: InputDecoration(
                hintText: 'AWB, Token, or BL Number',
                hintStyle: TextStyle(color: Colors.white60, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.accentYellow),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_2, color: Colors.white),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QRScannerScreen(),
                          ),
                        );
                        if (result != null && result['code'] != null && mounted) {
                          final code = result['code'] as String;
                          if (result['type'] == 'tracking') {
                            Navigator.of(context).pushNamed(
                              '/track-shipment',
                              arguments: {'tracking': code},
                            );
                          } else {
                            _trackingController.text = code;
                          }
                        }
                      },
                      tooltip: 'Scan QR/Barcode',
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward,
                          color: AppColors.accentYellow),
                      onPressed: () {
                        final trackingInput = _trackingController.text.trim();
                        if (trackingInput.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a tracking number'),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                        } else {
                          // Navigate to tracking detail screen
                          Navigator.of(context).pushNamed(
                            '/track-shipment',
                            arguments: {'tracking': trackingInput},
                          );
                        }
                      },
                      tooltip: 'Track Shipment',
                    ),
                  ],
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Build KPI Dashboard section - data from Firestore
  Widget _buildKpiDashboard() {
    final statsAsync = ref.watch(userStatsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Stats',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 12),
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Shipments',
                    value: stats.totalShipments.toString(),
                    icon: Icons.flight,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'In-Transit',
                    value: stats.inTransit.toString(),
                    icon: Icons.local_shipping,
                    color: AppColors.accentYellow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Delivered',
                    value: stats.delivered.toString(),
                    icon: Icons.check_circle,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Shipments',
                    value: '-',
                    icon: Icons.flight,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'In-Transit',
                    value: '-',
                    icon: Icons.local_shipping,
                    color: AppColors.accentYellow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Delivered',
                    value: '-',
                    icon: Icons.check_circle,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build Stats Cards Section - data from Firestore
  Widget _buildStatsCardsSection() {
    final statsAsync = ref.watch(userStatsProvider);

    return statsAsync.when(
      data: (stats) => StatsCardsSection(
        userStats: {
          'shipmentsCount': stats.totalShipments,
          'moneySaved': stats.totalSaved.round(),
          'commissions': 0, // Commissions are tracked separately in affiliate module
        },
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => StatsCardsSection(
        userStats: {
          'shipmentsCount': 0,
          'moneySaved': 0,
          'commissions': 0,
        },
      ),
    );
  }

  /// Build individual KPI card
  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Build guest upsell section - shown when user is not logged in
  Widget _buildGuestUpsellSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Register to track shipments card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.primaryBlue.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_add, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Create an Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sign up to track all your shipments, get quotes, and access exclusive features.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.signup),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Sign In'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Benefits row
          Row(
            children: [
              _buildGuestBenefit(Icons.local_shipping, 'Track Shipments'),
              const SizedBox(width: 12),
              _buildGuestBenefit(Icons.notifications, 'Get Notifications'),
              const SizedBox(width: 12),
              _buildGuestBenefit(Icons.history, 'View History'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestBenefit(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.extraLightGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryBlue),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.darkGrey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build quick action buttons - DEEP BLUE/YELLOW THEMED
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.flight_outlined,
                  label: 'Book Shipment',
                  color: AppColors.primaryBlue,
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.requestShipping);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.local_shipping_outlined,
                  label: 'Get Quote',
                  color: AppColors.accentYellow,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.quoteRequest);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.schedule,
                  label: 'Schedule Pickup',
                  color: AppColors.successGreen,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.pickupScheduling);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.person_add_outlined,
                  label: 'Become Affiliate',
                  color: AppColors.warningOrange,
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.affiliateIntro);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build active shipments section - DEEP BLUE THEMED
  /// TODO: Replace mock data with Firestore shippingRequests collection stream
  Widget _buildActiveShipments(AppUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Shipments',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/shipments');
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Consumer(
            builder: (context, ref, child) {
              final shipmentsAsync =
                  ref.watch(_activeShipmentsProvider(user.id));

              return shipmentsAsync.when(
                data: (shipments) {
                  if (shipments.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: AppColors.extraLightGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.lightGrey,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            size: 48,
                            color: AppColors.lightGrey,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No active shipments',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.requestShipping);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Book Your First Shipment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show first 3 shipments
                  return Column(
                    children: shipments.take(3).map((shipment) {
                      return _buildShipmentCard(shipment);
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                error: (err, stack) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Error loading shipments: $err',
                    style: const TextStyle(
                      color: AppColors.errorRed,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build individual shipment card - DEEP BLUE THEMED
  Widget _buildShipmentCard(ShippingRequest shipment) {
    final statusColor = _getStatusColor(shipment.status.displayName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGrey, width: 1),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AWB: ${shipment.mawbNumber ?? shipment.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${shipment.origin} ➔ ${shipment.destination}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  shipment.status.displayName,
                  style: const TextStyle(fontSize: 11, height: 1),
                ),
                backgroundColor: statusColor.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              borderRadius: BorderRadius.circular(3),
            ),
            child: LinearProgressIndicator(
              minHeight: 6,
              backgroundColor: AppColors.lightGrey,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Build alerts section (conditional)
  Widget _buildAlertsSection(AppUser user) {
    // TODO: Fetch real alerts from Firestore
    // For now, always hide alerts section
    return SizedBox.shrink();
  }

  /// Build individual action card
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Consumer(
      builder: (context, ref, child) {
        final userAsync = ref.watch(currentUserProvider);
        final user = userAsync;

        // Watch Firestore providers for banners and news
        final bannersAsync = ref.watch(activeBannersProvider);
        final newsAsync = ref.watch(publishedNewsProvider);

        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primaryBlue,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Welcome bar
              SliverToBoxAdapter(
                child: (user != null)
                    ? _buildWelcomeBar(user)
                    : _buildGuestWelcomeBar(),
              ),

              // Banner carousel slider
              SliverToBoxAdapter(
                child: bannersAsync.when(
                  data: (banners) {
                    return _buildBannerCarousel(banners);
                  },
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryBlue,
                            AppColors.accentYellow,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                  ),
                  error: (err, stack) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.extraLightGrey,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.lightGrey),
                      ),
                      child: Center(
                        child: Text(
                          'Unable to load banners',
                          style: TextStyle(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // News ticker
              SliverToBoxAdapter(
                child: newsAsync.when(
                  data: (newsItems) => _buildNewsTicker(newsItems),
                  loading: () => Container(
                    color: AppColors.extraLightGrey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: const Center(
                      child: SizedBox(
                        height: 32,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  error: (err, stack) => Container(
                    color: AppColors.extraLightGrey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Center(
                      child: Text(
                        'Unable to load news',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Tracking bar (hero section)
              SliverToBoxAdapter(
                child: _buildTrackingBar(),
              ),

              // Featured Services Carousel
              SliverToBoxAdapter(
                child: const FeaturedServicesCarousel(),
              ),

              // Stats/KPI Cards with Animations (registered users only)
              SliverToBoxAdapter(
                child: (user != null)
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Your Performance',
                                style:
                                    Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildStatsCardsSection(),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // KPI Dashboard (registered users only)
              SliverToBoxAdapter(
                child: (user != null)
                    ? _buildKpiDashboard()
                    : const SizedBox.shrink(),
              ),

              // Quick actions
              SliverToBoxAdapter(
                child: _buildQuickActions(),
              ),

              // Active shipments (registered users only)
              SliverToBoxAdapter(
                child: (user != null)
                    ? _buildActiveShipments(user)
                    : const SizedBox.shrink(),
              ),

              // Guest upsell section
              SliverToBoxAdapter(
                child: (user == null)
                    ? _buildGuestUpsellSection()
                    : const SizedBox.shrink(),
              ),

              // Alerts section
              SliverToBoxAdapter(
                child: (user != null)
                    ? _buildAlertsSection(user)
                    : const SizedBox.shrink(),
              ),

              // Bottom spacing
              SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Home screen uses MainScaffold for consistent navigation,
    // drawer and app bar styling.  Current index 0 corresponds to
    // the home tab in the bottom navigation (even if the bottom
    // bar is not shown here).
    return MainScaffold(
      currentIndex: 0,
      appBarTitle: "Shop's & Ports",
      body: Column(
        children: [
          Expanded(
            child: _buildHomeContent(),
          ),
        ],
      ),
    );
  }

  // drawer is handled by MainScaffold; legacy custom menu removed
}

/// Provider for active shipments (user's current shipments)
final _activeShipmentsProvider =
    FutureProvider.family<List<ShippingRequest>, String>((ref, userId) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('shippingRequests')
        .where('requesterId', isEqualTo: userId)
        .where('status', whereIn: [
          'approved',
          'inTransit',
        ])
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => ShippingRequest.fromMap(doc.data()))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Banner slide model with effects
class BannerSlide {
  final String image;
  final String title;
  final String subtitle;
  final Color color;

  BannerSlide({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
