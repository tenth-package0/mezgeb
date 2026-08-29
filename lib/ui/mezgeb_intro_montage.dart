import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Personalized intro montage for Eskinder — plays once on first launch.
/// Every glyph and the CTA are custom-painted; no icon fonts, no emoji.
class MezgebIntroMontage extends StatefulWidget {
  const MezgebIntroMontage({super.key, this.onFinished, this.autoPlay = true});

  final VoidCallback? onFinished;
  final bool autoPlay;

  @override
  State<MezgebIntroMontage> createState() => _MezgebIntroMontageState();
}

enum _Glyph { heart, mosaic, shutter, calendar, fingerprint }

class _MezgebIntroMontageState extends State<MezgebIntroMontage>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _ambient;   // slow bg drift + orbits
  late final AnimationController _entrance;  // per-slide staggered entrance
  late final AnimationController _shimmer;   // greeting + CTA shine sweep
  Timer? _autoTimer;
  int _page = 0;

  static const _slides = [
    _IntroSlide(
      kicker: 'ሰላም',
      title: 'እስክንድር',
      subtitle: 'ይህ መተግበሪያ ለአንተ ብቻ የተሰራ ነው።\nከልብ በፍቅር።',
      glyph: _Glyph.heart,
      special: true,
    ),
    _IntroSlide(
      kicker: 'እንኳን ደህና መጣህ',
      title: 'መዝገብ',
      subtitle: 'የግል የፎቶ መዝገብህ —\nምስጢርህ እዚህ ደህና ነው።',
      glyph: _Glyph.mosaic,
    ),
    _IntroSlide(
      kicker: 'ፈጣን ካሜራ',
      title: 'ክፈት። አንሳ። ቀጥል።',
      subtitle: 'ካሜራው ወዲያው ይከፈታል፤\nፎቶህ ቀጥታ ወደ መዝገብ ይገባል።',
      glyph: _Glyph.shutter,
    ),
    _IntroSlide(
      kicker: 'የኢትዮጵያ አቆጣጠር',
      title: 'መስከረም እስከ ጳጉሜ',
      subtitle: 'ፎቶዎችህ በዓመትና በወር\nበኢትዮጵያ አቆጣጠር ተደራጅተዋል።',
      glyph: _Glyph.calendar,
    ),
    _IntroSlide(
      kicker: 'ሚስጥራዊ ጥበቃ',
      title: 'በአሻራህ የተቆለፈ',
      subtitle: 'ያለ አንተ ማንም አይከፍተውም —\nበአሻራና በፒን የተጠበቀ።',
      glyph: _Glyph.fingerprint,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    if (widget.autoPlay) _startAutoPlay();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    _ambient.dispose();
    _entrance.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(milliseconds: 3600), (_) {
      if (!mounted) return;
      if (_page >= _slides.length - 1) {
        _finish();
        return;
      }
      _pageController.nextPage(
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _finish() {
    _autoTimer?.cancel();
    HapticFeedback.mediumImpact();
    widget.onFinished?.call();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page == _slides.length - 1) {
      _finish();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          // ─── Ambient animated background ────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambient,
              builder: (context, _) => CustomPaint(
                painter: _AmbientPainter(
                  primary: scheme.primary,
                  secondary: scheme.secondary,
                  progress: _ambient.value,
                  slideIndex: _page,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ─── Skip ───────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isLast ? 0 : 1,
                      child: TextButton(
                        onPressed: isLast ? null : _finish,
                        child: const Text('ዝለል'),
                      ),
                    ),
                  ),
                ),
                // ─── Slides ─────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) {
                      setState(() => _page = index);
                      _entrance.forward(from: 0);
                      HapticFeedback.selectionClick();
                    },
                    itemBuilder: (context, index) => _IntroSlideView(
                      slide: _slides[index],
                      ambient: _ambient,
                      entrance: _entrance,
                      shimmer: _shimmer,
                    ),
                  ),
                ),
                // ─── Dots + CTA ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Column(
                    children: [
                      _IntroDots(count: _slides.length, current: _page),
                      const SizedBox(height: 22),
                      _IntroCta(
                        label: isLast ? 'መዝገብን ጀምር' : 'ቀጥል',
                        emphasized: isLast,
                        shimmer: _shimmer,
                        ambient: _ambient,
                        onTap: _next,
                      ),
                    ],
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

// ═════════════════════════════════════════════════════════════════════════
// Slide model + view
// ═════════════════════════════════════════════════════════════════════════

class _IntroSlide {
  const _IntroSlide({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.glyph,
    this.special = false,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final _Glyph glyph;
  final bool special;
}

class _IntroSlideView extends StatelessWidget {
  const _IntroSlideView({
    required this.slide,
    required this.ambient,
    required this.entrance,
    required this.shimmer,
  });

  final _IntroSlide slide;
  final Animation<double> ambient;
  final Animation<double> entrance;
  final Animation<double> shimmer;

  /// Staggered entrance: each element animates in a delayed window.
  Animation<double> _window(double start, double end) => CurvedAnimation(
    parent: entrance,
    curve: Interval(start, end, curve: Curves.easeOutCubic),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconAnim = _window(0.0, 0.55);
    final kickerAnim = _window(0.18, 0.62);
    final titleAnim = _window(0.30, 0.78);
    final subtitleAnim = _window(0.45, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ─── Hero glyph with orbiting ring ────────────────────────
          _Enter(
            animation: iconAnim,
            slideOffset: 0.10,
            child: SizedBox(
              width: 190,
              height: 190,
              child: AnimatedBuilder(
                animation: ambient,
                builder: (context, child) => CustomPaint(
                  painter: _OrbitRingPainter(
                    color: scheme.primary,
                    progress: ambient.value,
                  ),
                  child: child,
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: ambient,
                    builder: (context, child) {
                      // gentle breathing
                      final t =
                          math.sin(ambient.value * math.pi * 2 * 3.5) * 0.5 +
                              0.5;
                      return Transform.scale(
                        scale: 1 + t * 0.035,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            scheme.primary.withValues(alpha: 0.22),
                            scheme.primary.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.35),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.22),
                            blurRadius: 44,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: AnimatedBuilder(
                        animation: ambient,
                        builder: (context, _) => CustomPaint(
                          painter: _GlyphPainter(
                            glyph: slide.glyph,
                            color: scheme.primary,
                            progress: ambient.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // ─── Kicker ───────────────────────────────────────────────
          _Enter(
            animation: kickerAnim,
            slideOffset: 0.35,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                slide.kicker,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Title (with shimmer on the special slide) ────────────
          _Enter(
            animation: titleAnim,
            slideOffset: 0.35,
            child: slide.special
                ? AnimatedBuilder(
              animation: shimmer,
              builder: (context, _) => ShaderMask(
                shaderCallback: (bounds) {
                  final dx = (shimmer.value * 2.4 - 0.7) * bounds.width;
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      scheme.onSurface,
                      scheme.primary,
                      scheme.onSurface,
                    ],
                    stops: const [0.32, 0.5, 0.68],
                    transform: _SlideGradientTransform(dx),
                  ).createShader(bounds);
                },
                child: Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: Colors.white,
                  ),
                ),
              ),
            )
                : Text(
              slide.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ─── Subtitle ─────────────────────────────────────────────
          _Enter(
            animation: subtitleAnim,
            slideOffset: 0.35,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                slide.subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fade + slide-up entrance wrapper.
class _Enter extends StatelessWidget {
  const _Enter({
    required this.animation,
    required this.child,
    this.slideOffset = 0.25,
  });

  final Animation<double> animation;
  final Widget child;
  final double slideOffset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, (1 - animation.value) * 34 * slideOffset * 4),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  const _SlideGradientTransform(this.dx);
  final double dx;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Custom CTA button — gradient, shine sweep, animated arrow, press scale
// ═════════════════════════════════════════════════════════════════════════

class _IntroCta extends StatefulWidget {
  const _IntroCta({
    required this.label,
    required this.emphasized,
    required this.shimmer,
    required this.ambient,
    required this.onTap,
  });

  final String label;
  final bool emphasized;
  final Animation<double> shimmer;
  final Animation<double> ambient;
  final VoidCallback onTap;

  @override
  State<_IntroCta> createState() => _IntroCtaState();
}

class _IntroCtaState extends State<_IntroCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blend = Color.lerp(scheme.primary, scheme.secondary, 0.45)!;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.shimmer, widget.ambient]),
          builder: (context, _) {
            // breathing glow, stronger when emphasized
            final breath =
                math.sin(widget.ambient.value * math.pi * 2 * 3) * 0.5 + 0.5;
            final glow = widget.emphasized ? 0.30 + breath * 0.18 : 0.14;
            return Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [scheme.primary, blend],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: glow),
                    blurRadius: 26,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // diagonal shine sweeping across the pill
                  CustomPaint(
                    painter: _ShinePainter(
                      progress: widget.shimmer.value,
                      color: Colors.white,
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.35),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Text(
                            widget.label,
                            key: ValueKey(widget.label),
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // custom arrow that nudges forward in a loop
                        SizedBox(
                          width: 18,
                          height: 14,
                          child: CustomPaint(
                            painter: _ArrowPainter(
                              color: scheme.onPrimary,
                              nudge: math.sin(
                                widget.ambient.value *
                                    math.pi *
                                    2 *
                                    4,
                              ) *
                                  0.5 +
                                  0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Diagonal light band sweeping left→right across the CTA.
class _ShinePainter extends CustomPainter {
  const _ShinePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final x = (progress * 1.9 - 0.45) * size.width;
    final band = Path()
      ..moveTo(x - 26, size.height + 6)
      ..lineTo(x + 6, -6)
      ..lineTo(x + 30, -6)
      ..lineTo(x - 2, size.height + 6)
      ..close();
    canvas.drawPath(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(x - 26, 0, 56, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant _ShinePainter old) =>
      old.progress != progress || old.color != color;
}

/// Hand-drawn forward arrow (shaft + head) with a horizontal nudge loop.
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color, required this.nudge});
  final Color color;
  final double nudge;

  @override
  void paint(Canvas canvas, Size size) {
    final dx = nudge * 2.4;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final midY = size.height / 2;
    // shaft
    canvas.drawLine(
      Offset(1 + dx * 0.4, midY),
      Offset(size.width - 4 + dx, midY),
      paint,
    );
    // head
    final head = Path()
      ..moveTo(size.width - 9 + dx, midY - 5)
      ..lineTo(size.width - 3.5 + dx, midY)
      ..lineTo(size.width - 9 + dx, midY + 5);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) =>
      old.nudge != nudge || old.color != color;
}

// ═════════════════════════════════════════════════════════════════════════
// Per-slide hero glyphs — all custom-painted, all animated
// ═════════════════════════════════════════════════════════════════════════

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({
    required this.glyph,
    required this.color,
    required this.progress,
  });

  final _Glyph glyph;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    switch (glyph) {
      case _Glyph.heart:
        _paintHeart(canvas, size);
      case _Glyph.mosaic:
        _paintMosaic(canvas, size);
      case _Glyph.shutter:
        _paintShutter(canvas, size);
      case _Glyph.calendar:
        _paintCalendarRing(canvas, size);
      case _Glyph.fingerprint:
        _paintFingerprint(canvas, size);
    }
  }

  /// Beating heart with expanding pulse ring.
  void _paintHeart(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // heartbeat: two quick beats then rest (like a real pulse)
    final cycle = (progress * 7) % 1.0;
    double beat = 0;
    if (cycle < 0.12) {
      beat = math.sin(cycle / 0.12 * math.pi);
    } else if (cycle < 0.26) {
      beat = math.sin((cycle - 0.14) / 0.12 * math.pi) * 0.6;
    }
    final scale = 1 + beat * 0.10;

    // pulse ring expanding outward on each beat
    final ringT = (cycle / 0.6).clamp(0.0, 1.0);
    if (ringT < 1) {
      canvas.drawCircle(
        center,
        22 + ringT * 26,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = color.withValues(alpha: (1 - ringT) * 0.30),
      );
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);

    final w = 40.0;
    final h = 36.0;
    final top = center.dy - h * 0.32;
    final path = Path()
      ..moveTo(center.dx, center.dy + h * 0.45)
      ..cubicTo(
        center.dx - w * 0.62, center.dy + h * 0.05,
        center.dx - w * 0.55, top - h * 0.28,
        center.dx, top + h * 0.10,
      )
      ..cubicTo(
        center.dx + w * 0.55, top - h * 0.28,
        center.dx + w * 0.62, center.dy + h * 0.05,
        center.dx, center.dy + h * 0.45,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = color.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.restore();
  }

  /// 3x3 vault mosaic; tiles light up in a scanning sequence.
  void _paintMosaic(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const tile = 13.0;
    const gap = 4.0;
    const span = tile * 3 + gap * 2;
    final origin = Offset(center.dx - span / 2, center.dy - span / 2);
    final active = (progress * 9 * 2) % 9;
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        final i = row * 3 + col;
        final d = (i - active).abs();
        final near = math.min(d, 9 - d);
        final lit = (1 - near / 2.5).clamp(0.0, 1.0);
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            origin.dx + col * (tile + gap),
            origin.dy + row * (tile + gap),
            tile,
            tile,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(
          rect,
          Paint()..color = color.withValues(alpha: 0.14 + lit * 0.55),
        );
      }
    }
  }

  /// Camera shutter iris — six blades slowly rotating around a center.
  void _paintShutter(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rot = progress * math.pi * 2 * 0.6;
    const blades = 6;
    const outer = 26.0;
    const inner = 9.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = color;
    // outer ring
    canvas.drawCircle(
      center,
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = color.withValues(alpha: 0.45),
    );
    // blades: chords from ring toward center
    for (var i = 0; i < blades; i++) {
      final a = rot + (i / blades) * math.pi * 2;
      final tip = Offset(
        center.dx + inner * math.cos(a + 1.1),
        center.dy + inner * math.sin(a + 1.1),
      );
      final base = Offset(
        center.dx + outer * math.cos(a),
        center.dy + outer * math.sin(a),
      );
      canvas.drawLine(base, tip, paint);
    }
    // center aperture dot
    canvas.drawCircle(
      center,
      2.4,
      Paint()..color = color.withValues(alpha: 0.9),
    );
  }

  /// 13 dots in a ring — Ethiopian months — with a traveling glow.
  void _paintCalendarRing(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 24.0;
    const count = 13;
    final active = (progress * count * 2) % count;
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (i / count) * math.pi * 2;
      final d = (i - active).abs();
      final near = math.min(d, count - d);
      final lit = (1 - near / 2).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        2.2 + lit * 1.6,
        Paint()..color = color.withValues(alpha: 0.28 + lit * 0.65),
      );
    }
    // small center marker
    canvas.drawCircle(
      center,
      2.0,
      Paint()..color = color.withValues(alpha: 0.5),
    );
  }

  /// Fingerprint arcs breathing open and closed.
  void _paintFingerprint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 3);
    final breath = math.sin(progress * math.pi * 2 * 2.5) * 0.5 + 0.5;
    final sweep = math.pi * (1.0 + breath * 0.35);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = color;
    for (var i = 0; i < 4; i++) {
      final radius = 6.0 + i * 6.0;
      paint.color = color.withValues(alpha: 0.9 - i * 0.16);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 - sweep / 2,
        sweep,
        false,
        paint,
      );
    }
    canvas.drawCircle(center, 2.0, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.progress != progress || old.color != color || old.glyph != glyph;
}

// ═════════════════════════════════════════════════════════════════════════
// Dots
// ═════════════════════════════════════════════════════════════════════════

class _IntroDots extends StatelessWidget {
  const _IntroDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: selected ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
              colors: [
                scheme.primary,
                scheme.primary.withValues(alpha: 0.65),
              ],
            )
                : null,
            color:
            selected ? null : scheme.onSurface.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Painters
// ═════════════════════════════════════════════════════════════════════════

/// Slow-drifting ambient background: soft gradient blobs + floating
/// particles + faint arcs. Composition shifts subtly per slide.
class _AmbientPainter extends CustomPainter {
  const _AmbientPainter({
    required this.primary,
    required this.secondary,
    required this.progress,
    required this.slideIndex,
  });

  final Color primary;
  final Color secondary;
  final double progress;
  final int slideIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;
    final shift = slideIndex * 0.8;

    // Soft gradient blobs
    void blob(Offset center, double radius, Color color, double alpha) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    blob(
      Offset(
        size.width * (0.18 + 0.06 * math.sin(t * 0.7 + shift)),
        size.height * (0.16 + 0.05 * math.cos(t * 0.5 + shift)),
      ),
      size.width * 0.55,
      primary,
      0.10,
    );
    blob(
      Offset(
        size.width * (0.85 + 0.05 * math.cos(t * 0.6 + shift)),
        size.height * (0.72 + 0.05 * math.sin(t * 0.8 + shift)),
      ),
      size.width * 0.6,
      secondary,
      0.07,
    );
    blob(
      Offset(
        size.width * (0.7 + 0.07 * math.sin(t * 0.4 + shift + 2)),
        size.height * (0.25 + 0.06 * math.cos(t * 0.9 + shift + 1)),
      ),
      size.width * 0.4,
      primary,
      0.06,
    );

    // Floating particles
    final particlePaint = Paint();
    final rng = math.Random(7); // fixed seed: stable positions
    for (var i = 0; i < 26; i++) {
      final baseX = rng.nextDouble();
      final baseY = rng.nextDouble();
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final sizeR = 1.0 + rng.nextDouble() * 2.2;
      final y = (baseY + progress * speed) % 1.1 - 0.05;
      final x = baseX + 0.02 * math.sin(t * speed * 2 + i);
      final fade =
      (math.sin((y + 0.05) / 1.1 * math.pi)).clamp(0.0, 1.0);
      particlePaint.color =
          primary.withValues(alpha: 0.14 * fade);
      canvas.drawCircle(
        Offset(x * size.width, (1 - y) * size.height),
        sizeR,
        particlePaint,
      );
    }

    // Faint sweeping arcs
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = primary.withValues(alpha: 0.05);
    final center = Offset(size.width * 0.5, size.height * 0.40);
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 150.0 + i * 70),
        t * (0.4 + i * 0.12) + i,
        math.pi * 1.2,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter old) =>
      old.progress != progress ||
          old.slideIndex != slideIndex ||
          old.primary != primary;
}

/// Dashed orbiting ring + comet dot around the hero glyph.
class _OrbitRingPainter extends CustomPainter {
  const _OrbitRingPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;
    final t = progress * math.pi * 2;

    // dashed ring
    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.28);
    const dashCount = 40;
    for (var i = 0; i < dashCount; i++) {
      final start = (i / dashCount) * math.pi * 2 + t * 0.35;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        math.pi * 2 / dashCount * 0.45,
        false,
        dashPaint,
      );
    }

    // comet dot + trail
    final angle = t * 1.4;
    final dotPos = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    for (var i = 5; i >= 1; i--) {
      final trailAngle = angle - i * 0.09;
      final trailPos = Offset(
        center.dx + radius * math.cos(trailAngle),
        center.dy + radius * math.sin(trailAngle),
      );
      canvas.drawCircle(
        trailPos,
        3.0 - i * 0.4,
        Paint()..color = color.withValues(alpha: 0.30 - i * 0.05),
      );
    }
    canvas.drawCircle(
      dotPos,
      3.4,
      Paint()..color = color.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter old) =>
      old.progress != progress || old.color != color;
}