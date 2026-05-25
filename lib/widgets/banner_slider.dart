import 'package:flutter/material.dart' hide Banner;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/banners_service.dart';

/// Provider for active banners from Firebase
final activeBannersProvider = FutureProvider<List<Banner>>((ref) {
  return BannersService().getActiveBanners();
});

/// Stream of active banners for real-time updates
final activeBannersStreamProvider = StreamProvider<List<Banner>>((ref) {
  return BannersService().watchActiveBanners();
});

/// Cache for resolved Firebase Storage URLs to avoid repeated lookups
final _urlResolutionCache = <String, String>{};

/// Helper to resolve Firebase Storage paths to download URLs with caching
Future<String> _resolveImageUrl(String imageUrl) async {
  if (_urlResolutionCache.containsKey(imageUrl)) {
    return _urlResolutionCache[imageUrl]!;
  }

  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    _urlResolutionCache[imageUrl] = imageUrl;
    return imageUrl;
  }

  if (imageUrl.startsWith('banners/') ||
      imageUrl.startsWith('images/') ||
      imageUrl.contains('/')) {
    try {
      final ref = FirebaseStorage.instance.ref().child(imageUrl);
      final url = await ref.getDownloadURL();
      _urlResolutionCache[imageUrl] = url;
      return url;
    } catch (e) {
      return imageUrl;
    }
  }

  return imageUrl;
}

class BannerSlider extends ConsumerStatefulWidget {
  final String placement;
  final bool useLiveData;
  final bool showPlaceholderWhenEmpty;

  const BannerSlider({
    super.key,
    this.placement = 'home',
    this.useLiveData = true,
    this.showPlaceholderWhenEmpty = true,
  });

  @override
  ConsumerState<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends ConsumerState<BannerSlider> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    if (!widget.useLiveData) {
      return const SizedBox.shrink();
    }

    return ref.watch(activeBannersStreamProvider).when(
          data: (banners) {
            if (banners.isEmpty) {
              if (widget.showPlaceholderWhenEmpty) {
                return _buildEmptyPlaceholder();
              }
              return const SizedBox.shrink();
            }
            return _BannerSliderContent(
              banners: banners,
              controller: _controller,
              currentIndex: _current,
              onPageChanged: (index) {
                setState(() => _current = index);
              },
            );
          },
          loading: () => _buildLoadingPlaceholder(),
          error: (error, stack) {
            if (widget.showPlaceholderWhenEmpty) {
              return _buildErrorPlaceholder(error.toString());
            }
            return const SizedBox.shrink();
          },
        );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No banners available',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Add banners in admin dashboard',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(String error) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red.shade400),
            const SizedBox(height: 8),
            Text(
              'Failed to load banners',
              style: TextStyle(color: Colors.red.shade400, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              error.length > 50 ? '${error.substring(0, 50)}...' : error,
              style: TextStyle(color: Colors.red.shade300, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == 0
                    ? Colors.orange
                    : const Color.fromRGBO(255, 165, 0, 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BannerSliderContent extends StatefulWidget {
  final List<Banner> banners;
  final CarouselSliderController controller;
  final int currentIndex;
  final Function(int) onPageChanged;

  const _BannerSliderContent({
    required this.banners,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  State<_BannerSliderContent> createState() => _BannerSliderContentState();
}

class _BannerSliderContentState extends State<_BannerSliderContent> {
  final Map<int, String> _resolvedUrls = {};
  final Set<int> _loadedImages = {};
  bool _allImagesPreloaded = false;

  @override
  void initState() {
    super.initState();
    _preloadAllImages();
  }

  Future<void> _preloadAllImages() async {
    final futures = <Future>[];

    for (int i = 0; i < widget.banners.length; i++) {
      futures.add(_preloadBanner(i));
    }

    try {
      await Future.wait(futures).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return [];
        },
      );
    } catch (e) {
      // Silently fail - continue with available images
    }

    if (mounted) {
      setState(() {
        _allImagesPreloaded = true;
      });
    }
  }

  Future<void> _preloadBanner(int index) async {
    final banner = widget.banners[index];

    try {
      final url = await _resolveImageUrl(banner.imageUrl).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          return banner.imageUrl;
        },
      );

      if (mounted) {
        setState(() {
          _resolvedUrls[index] = url;
        });
      }

      if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
        final precache = CachedNetworkImageProvider(url);
        // ignore: unused_local_variable
        final stream = precache.resolve(ImageConfiguration.empty);
      }
    } catch (e) {
      // Silently fail - banner will show without preloading
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannerCount = widget.banners.length;

    return Column(
      children: [
        _allImagesPreloaded
            ? CarouselSlider.builder(
                carouselController: widget.controller,
                itemCount: bannerCount,
                itemBuilder: (context, index, realIndex) {
                  final banner = widget.banners[index];
                  final imageUrl = _resolvedUrls[index] ?? '';
                  final isLoaded = _loadedImages.contains(index);

                  return _BannerItem(
                    banner: banner,
                    imageUrl: imageUrl,
                    isLoaded: isLoaded,
                    onLoadComplete: () {
                      if (mounted) {
                        setState(() {
                          _loadedImages.add(index);
                        });
                      }
                    },
                  );
                },
                options: CarouselOptions(
                  height: 160,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 5),
                  autoPlayAnimationDuration:
                      const Duration(milliseconds: 800),
                  viewportFraction: 0.92,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: bannerCount > 1,
                  pauseAutoPlayOnTouch: true,
                  pauseAutoPlayOnManualNavigate: true,
                  onPageChanged: (index, reason) {
                    widget.onPageChanged(index);
                  },
                ),
              )
            : _buildPreloadingIndicator(),
        const SizedBox(height: 8),
        if (bannerCount > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              bannerCount,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.currentIndex == index
                      ? Colors.orange
                      : const Color.fromRGBO(255, 165, 0, 0.4),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreloadingIndicator() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.orange,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading banners...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerItem extends StatefulWidget {
  final Banner banner;
  final String imageUrl;
  final bool isLoaded;
  final VoidCallback onLoadComplete;

  const _BannerItem({
    required this.banner,
    required this.imageUrl,
    required this.isLoaded,
    required this.onLoadComplete,
  });

  @override
  State<_BannerItem> createState() => _BannerItemState();
}

class _BannerItemState extends State<_BannerItem> {
  bool _imageLoaded = false;

  @override
  void didUpdateWidget(_BannerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl.isNotEmpty && !_imageLoaded && widget.isLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onLoadComplete();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.banner.linkUrl != null && widget.banner.linkUrl!.isNotEmpty) {
          _handleBannerTap(context, widget.banner.linkUrl!);
        }
      },
      child: Stack(
        children: [
          if (!widget.isLoaded && widget.imageUrl.isEmpty)
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
              ),
            ),

          if (widget.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 160,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                  ),
                ),
                errorWidget: (context, error, stack) {
                  return Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.shade200,
                    ),
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                },
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 300),
              ),
            ),

          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color.fromRGBO(0, 0, 0, 0.5),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          if (widget.banner.title.isNotEmpty)
            Positioned(
              left: 16,
              bottom: 20,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.yellow, Colors.orange],
                    ).createShader(bounds),
                    child: Text(
                      widget.banner.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (widget.banner.subtitle != null && widget.banner.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Colors.grey],
                      ).createShader(bounds),
                      child: Text(
                        widget.banner.subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleBannerTap(BuildContext context, String linkUrl) {
    if (linkUrl.startsWith('http://') || linkUrl.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening: $linkUrl')),
      );
    }
  }
}