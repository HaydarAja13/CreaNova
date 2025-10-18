// lib/widgets/article_carousel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/article_item.dart';
import '../pages/main_features/home_screen.dart'; // sesuaikan path AppColors milikmu

class ArticleCarousel extends StatefulWidget {
  const ArticleCarousel({
    super.key,
    required this.items,
    this.height = 180,
    this.viewportFraction = .92,
    this.onTap,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.autoPlayAnimationDuration = const Duration(milliseconds: 500),
    this.autoPlayCurve = Curves.easeOutCubic,
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 8), // jarak antar slide
  });

  final List<ArticleItem> items;
  final double height;
  final double viewportFraction;
  final void Function(ArticleItem item)? onTap;

  // Auto-slide options
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;
  final Curve autoPlayCurve;

  // Spacing antar item
  final EdgeInsetsGeometry itemPadding;

  @override
  State<ArticleCarousel> createState() => _ArticleCarouselState();
}

class _ArticleCarouselState extends State<ArticleCarousel> {
  late final PageController _pc;
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pc = PageController(viewportFraction: widget.viewportFraction);
    _pc.addListener(_pageListener);
    if (widget.autoPlay && widget.items.length > 1) _startAutoPlay();
  }

  void _pageListener() {
    final p = _pc.page?.round() ?? 0;
    if (p != _page) setState(() => _page = p);
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted || widget.items.isEmpty) return;
      final next = (_page + 1) % widget.items.length;
      _pc.animateToPage(
        next,
        duration: widget.autoPlayAnimationDuration,
        curve: widget.autoPlayCurve,
      );
    });
  }

  void _pauseAndResume() {
    // hentikan saat user swipe, lalu lanjutkan lagi setelah 3s
    _timer?.cancel();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || !widget.autoPlay) return;
      _startAutoPlay();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc
      ..removeListener(_pageListener)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is UserScrollNotification) _pauseAndResume();
              return false;
            },
            child: PageView.builder(
              controller: _pc,
              itemCount: items.length,
              itemBuilder: (_, i) => Padding(
                padding: widget.itemPadding, // <- jarak antar item
                child: _ArticleSlide(
                  item: items[i],
                  onTap: widget.onTap,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _DotsIndicator(length: items.length, index: _page),
      ],
    );
  }
}

class _ArticleSlide extends StatelessWidget {
  const _ArticleSlide({required this.item, this.onTap});
  final ArticleItem item;
  final void Function(ArticleItem item)? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFE8EEE6)),
            ),
          ),
          // Dark overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
          ),
          // Badge "Terbaru"
          if (item.isNew)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.kGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Terbaru',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          // Bottom content
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.article_outlined,
                              color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(item.source,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(width: 12),
                          const Icon(Icons.calendar_today_outlined,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          Text(item.date,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => onTap?.call(item),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.arrow_forward, color: AppColors.kGreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.length, required this.index});
  final int length;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 10 : 8,
          height: active ? 10 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.kGreen : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
