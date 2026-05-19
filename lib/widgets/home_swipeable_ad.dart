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
  bool _isBannerAdLoading = false;
  bool _isBannerAdLoaded = false;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();

    // Load only Banner Ad
    _loadBannerAd();

    // AdMob refreshes eligible inventory internally; avoid recreating platform
    // views aggressively because it can exhaust ImageReader buffers on devices.
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Widget _buildBannerPlaceholder(String message) {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    // Using withAlpha instead of withOpacity for better precision
    final iconColor = onSurfaceVariant.withAlpha((255 * 0.5).round());
    final textColor = onSurfaceVariant.withAlpha((255 * 0.7).round());

    return Container(
      height: 260, // Match native ad height
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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

  Future<void> _loadBannerAd() async {
    if (_isBannerAdLoading || _isBannerAdLoaded) return;

    if (!widget.adService.isInitialized) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _loadBannerAd();
      });
      return;
    }

    _isBannerAdLoading = true;
    if (mounted) setState(() {});

    try {
      // Get the banner ad unit ID from AdService
      final bannerAdUnitId =
          widget.adService.getBannerAdUnitId(slot: AdSlots.homeBanner2);

      if (bannerAdUnitId == null || bannerAdUnitId.isEmpty) {
        throw Exception('Banner ad unit ID not available');
      }

      // Create and load the banner ad
      _bannerAd?.dispose();
      _bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.mediumRectangle, // 300x250 banner
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isBannerAdLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (identical(_bannerAd, ad)) {
              _bannerAd = null;
            }
            if (mounted) {
              setState(() {
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
      await _bannerAd?.load();
    } catch (e) {
      _bannerAd?.dispose();
      _bannerAd = null;
      if (mounted) {
        setState(() {
          _isBannerAdLoaded = false;
        });
      }
    } finally {
      _isBannerAdLoading = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: widget.margin ??
          const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 270,
            child: Container(
              height: 260,
              width: double.infinity,
              padding: const EdgeInsets.all(4),
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
              child: _isBannerAdLoaded && _bannerAd != null
                  ? Center(
                      child: AdWidget(ad: _bannerAd!),
                    )
                  : _buildBannerPlaceholder(
                      _isBannerAdLoading ? 'Loading ad...' : 'Loading ad...',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
