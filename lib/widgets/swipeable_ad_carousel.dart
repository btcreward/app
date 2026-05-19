import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

/// A swipeable carousel that displays native and banner ads with consistent styling
class SwipeableAdCarousel extends StatefulWidget {
  final AdService adService;
  final String screenId;
  final Duration bannerAdRefreshInterval;
  final EdgeInsetsGeometry? margin;

  SwipeableAdCarousel({
    super.key,
    required this.adService,
    required this.screenId,
    this.bannerAdRefreshInterval = const Duration(seconds: 30),
    this.margin,
  }) : assert(screenId.isNotEmpty, 'screenId must not be empty');

  @override
  State<SwipeableAdCarousel> createState() => _SwipeableAdCarouselState();
}

class _SwipeableAdCarouselState extends State<SwipeableAdCarousel> {
  // Controllers and timers
  Timer? _bannerAdRefreshTimer;

  // Banner ad state
  BannerAd? _bannerAd;
  bool _isBannerAdLoading = false;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    // Load only Banner Ad
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAdRefreshTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  // Removed native ad loading as requested

  String get _bannerSlot {
    switch (widget.screenId) {
      case 'contract_screen':
        return AdSlots.contractBanner1;
      default:
        return '${widget.screenId}_banner_1';
    }
  }

  Future<void> _loadBannerAd() async {
    if (_isBannerAdLoading || _isBannerAdLoaded) return;

    setState(() {
      _isBannerAdLoading = true;
    });

    try {
      final bannerAdUnitId =
          widget.adService.getBannerAdUnitId(slot: _bannerSlot);

      if (bannerAdUnitId == null || bannerAdUnitId.isEmpty) {
        throw Exception('Banner ad unit ID not available');
      }

      _bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.mediumRectangle,
        request: AdRequest(),
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
            if (mounted) {
              setState(() {
                _bannerAd = null;
                _isBannerAdLoaded = false;
              });
            }
          },
          onAdImpression: (ad) {
            // Banner ad impression
          },
        ),
      );

      await _bannerAd?.load();
    } catch (e) {
      if (mounted) {
        setState(() {
          _bannerAd = null;
          _isBannerAdLoaded = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBannerAdLoading = false;
        });
      }
    }
  }

  // Ad refresh timers removed or simplified for single ad

  // Unused methods removed

  Widget _buildFallbackBannerAd() {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final iconColor = onSurfaceVariant.withAlpha((255 * 0.5).round());
    final textColor = onSurfaceVariant.withAlpha((255 * 0.7).round());

    return Container(
      height: 260,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
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
              'Loading ad content...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show only banner ad
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
                  ? AdWidget(ad: _bannerAd!)
                  : _buildFallbackBannerAd(),
            ),
          ),
        ],
      ),
    );
  }
}
