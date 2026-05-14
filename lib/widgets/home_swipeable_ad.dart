import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

class HomeSwipeableAd extends StatefulWidget {
  final AdService adService;
  final String screenId;
  final Duration refreshInterval;
  final EdgeInsetsGeometry? margin;

  HomeSwipeableAd({
    super.key,
    required this.adService,
    required this.screenId,
    this.refreshInterval =
        const Duration(seconds: 30), // Refresh banner ad every 30 seconds
    this.margin,
  }) : assert(screenId.isNotEmpty, 'screenId cannot be empty');

  @override
  State<HomeSwipeableAd> createState() => _HomeSwipeableAdState();
}

class _HomeSwipeableAdState extends State<HomeSwipeableAd> {
  late PageController _pageController;
  bool _isBannerAdLoading = false;
  bool _isBannerAdLoaded = false;
  Widget? _bannerAdWidget;
  Timer? _bannerAdTimer;

  @override
  void initState() {
    super.initState();
    // Initialize page controller with initial page
    _pageController = PageController(initialPage: 0);

    // Load only Banner Ad
    _loadBannerAd();

    // Start timers
    _startBannerAdAutoRefresh();
  }

  void _startBannerAdAutoRefresh() {
    _bannerAdTimer?.cancel();
    _bannerAdTimer = Timer.periodic(
      const Duration(minutes: 1), // Refresh banner every minute
      (_) {
        if (mounted) {
          _isBannerAdLoaded = false;
          _loadBannerAd();
        }
      },
    );
  }

  @override
  void dispose() {
    _bannerAdTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildBannerPlaceholder(String message) {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    // Using withAlpha instead of withOpacity for better precision
    final iconColor = onSurfaceVariant.withAlpha((255 * 0.5).round());
    final textColor = onSurfaceVariant.withAlpha((255 * 0.7).round());

    return Container(
      height: 360, // Match native ad height
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000), // 10% black opacity
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.ad_units,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Advertisement',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed native ad loading as requested


  // Removed native ad loading as requested


  Future<void> _loadBannerAd() async {
    if (_isBannerAdLoading || _isBannerAdLoaded) return;

    _isBannerAdLoading = true;
    if (mounted) setState(() {});

    try {
      // Get the banner ad unit ID from AdService
      final bannerAdUnitId = widget.adService.getBannerAdUnitId();

      if (bannerAdUnitId == null || bannerAdUnitId.isEmpty) {
        throw Exception('Banner ad unit ID not available');
      }

      // Create and load the banner ad
      final bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.mediumRectangle, // 300x250 banner
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _bannerAdWidget = Container(
                  height: 390, // Height for banner container
                  margin:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: AdWidget(ad: ad as BannerAd),
                );
                _isBannerAdLoaded = true;
              });
            }
            _startBannerAdAutoRefresh();
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (mounted) {
              setState(() {
                _bannerAdWidget = null;
                _isBannerAdLoaded = false;
              });
            }
          },
          onAdImpression: (ad) {
            // AdMob banner ad impression
          },
        ),
      );

      // Load the ad
      await bannerAd.load();
    } catch (e) {
      if (mounted) {
        setState(() {
          _bannerAdWidget = _buildBannerPlaceholder('Ad failed to load');
          _isBannerAdLoaded = false;
        });
      }
    } finally {
      _isBannerAdLoading = false;
      if (mounted) setState(() {});
    }
  }

  // Auto-swipe and refresh timers removed or simplified for single ad


  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [];
    // Add only banner ad
    if (_bannerAdWidget != null) {
      pages.add(
        Container(
          height: 360,
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1A000000), // 10% black opacity
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _bannerAdWidget!,
        ),
      );
    } else {
      pages.add(_buildBannerPlaceholder(_isBannerAdLoading ? 'Loading ad...' : 'Loading ad...'));
    }

    return Container(
      width: double.infinity,
      margin: widget.margin ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          SizedBox(
            height: 392,
            child: pages[0], // Show the single banner directly
          ),
        ],
      ),
    );
  }
}

