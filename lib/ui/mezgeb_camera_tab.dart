import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_controller.dart';
import 'mezgeb_shared_widgets.dart';

class CameraTab extends StatefulWidget {
  const CameraTab({super.key, required this.controller});

  final AppController controller;

  @override
  State<CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<CameraTab>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // ─── Cameras / lenses ──────────────────────────────────────────────────
  List<CameraDescription> _backCameras = [];
  List<CameraDescription> _frontCameras = [];
  bool _usingFront = false;
  int _lensIndex = 0;

  CameraController? _camera;
  bool _initializing = false;
  bool _capturing = false;
  bool _disposed = false;
  int _openTicket = 0;
  int _openAttempts = 0;
  Timer? _retryTimer;
  String? _cameraError;

  // ─── Zoom ──────────────────────────────────────────────────────────────
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  double _pinchBaseZoom = 1.0;
  bool _zoomInFlight = false;
  double? _pendingZoom;
  final ValueNotifier<double> _zoomN = ValueNotifier<double>(1.0);
  final ValueNotifier<bool> _bubbleVisible = ValueNotifier<bool>(false);
  Timer? _bubbleHideTimer;

  // ─── Focus ─────────────────────────────────────────────────────────────
  final ValueNotifier<Offset?> _focusPointN = ValueNotifier<Offset?>(null);
  Timer? _focusHideTimer;

  // ─── Flash ─────────────────────────────────────────────────────────────
  FlashMode _flash = FlashMode.off;

  // ─── Shutter flash overlay ─────────────────────────────────────────────
  late final AnimationController _shutterFlash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _openTicket++;
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _bubbleHideTimer?.cancel();
    _focusHideTimer?.cancel();
    _zoomN.dispose();
    _bubbleVisible.dispose();
    _focusPointN.dispose();
    _shutterFlash.dispose();
    _camera?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _openTicket++;
      camera?.dispose();
      _camera = null;
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      if (_backCameras.isEmpty && _frontCameras.isEmpty) {
        unawaited(_bootstrap());
      } else if (camera == null || !camera.value.isInitialized) {
        _scheduleCameraOpen(const Duration(milliseconds: 120));
      }
    }
  }

  // ─── Bootstrap ─────────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    try {
      final cameras = await availableCameras();
      if (!mounted || _disposed) return;
      _backCameras = cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();
      _frontCameras = cameras
          .where((c) => c.lensDirection == CameraLensDirection.front)
          .toList();
      if (_backCameras.isEmpty && _frontCameras.isEmpty) {
        setState(() => _cameraError = 'No camera found on this device.');
        return;
      }
      if (_backCameras.isEmpty) _usingFront = true;
      _openAttempts = 0;
      _scheduleCameraOpen(const Duration(milliseconds: 40));
    } catch (e) {
      if (mounted && !_disposed) {
        setState(() => _cameraError = 'Camera could not start: $e');
      }
    }
  }

  void _scheduleCameraOpen(Duration delay) {
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!_disposed && mounted) unawaited(_openCamera());
    });
  }

  List<CameraDescription> get _activeList =>
      _usingFront ? _frontCameras : _backCameras;

  Future<void> _openCamera() async {
    if (_initializing || _disposed) return;
    final ticket = ++_openTicket;
    _initializing = true;
    if (mounted) {
      setState(() {
        _cameraError = null;
      });
    }

    final old = _camera;
    _camera = null;
    try {
      await old?.dispose();
    } catch (_) {}

    try {
      final list = _activeList;
      if (list.isEmpty) {
        _cameraError = 'No ${_usingFront ? "front" : "back"} camera available.';
        return;
      }
      _lensIndex = _lensIndex.clamp(0, list.length - 1);
      final desc = list[_lensIndex];

      final ctrl = CameraController(
        desc,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (_disposed || ticket != _openTicket) {
        await ctrl.dispose();
        return;
      }

      try {
        _minZoom = await ctrl.getMinZoomLevel();
        _maxZoom = await ctrl.getMaxZoomLevel();
      } catch (_) {
        _minZoom = 1.0;
        _maxZoom = 1.0;
      }
      _currentZoom = _minZoom;
      _zoomN.value = _currentZoom;

      try {
        await ctrl.setFlashMode(_flash);
      } catch (_) {}

      if (_disposed || ticket != _openTicket) {
        await ctrl.dispose();
        return;
      }
      _camera = ctrl;
      _cameraError = null;
      _openAttempts = 0;
    } catch (e) {
      if (!_disposed && ticket == _openTicket && _openAttempts < 2) {
        _openAttempts++;
        _scheduleCameraOpen(Duration(milliseconds: 220 * _openAttempts));
      } else {
        _cameraError = 'Camera could not start: $e';
      }
    } finally {
      if (ticket == _openTicket) _initializing = false;
      if (mounted && !_disposed) setState(() {});
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────

  Future<void> _switchLens(int index) async {
    if (index == _lensIndex) return;
    HapticFeedback.selectionClick();
    _lensIndex = index;
    await _openCamera();
  }

  Future<void> _swapFrontBack() async {
    if (_backCameras.isEmpty || _frontCameras.isEmpty) return;
    HapticFeedback.selectionClick();
    _usingFront = !_usingFront;
    _lensIndex = 0;
    await _openCamera();
  }

  Future<void> _cycleFlash() async {
    final camera = _camera;
    if (camera == null) return;
    HapticFeedback.selectionClick();
    _flash = switch (_flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      _ => FlashMode.off,
    };
    try {
      await camera.setFlashMode(_flash);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _applyZoom(double zoom) async {
    final camera = _camera;
    if (camera == null) return;
    final clamped = zoom.clamp(_minZoom, _maxZoom).toDouble();
    if ((clamped - _currentZoom).abs() < 0.005) return;
    _currentZoom = clamped;
    _zoomN.value = clamped;
    _flashBubble();

    // Coalesce zoom updates so the plugin isn't backed up mid-pinch.
    if (_zoomInFlight) {
      _pendingZoom = clamped;
      return;
    }
    _zoomInFlight = true;
    try {
      await camera.setZoomLevel(clamped);
      while (_pendingZoom != null) {
        final next = _pendingZoom!;
        _pendingZoom = null;
        try {
          await camera.setZoomLevel(next);
        } catch (_) {}
      }
    } catch (_) {}
    _zoomInFlight = false;
  }

  void _flashBubble() {
    _bubbleVisible.value = true;
    _bubbleHideTimer?.cancel();
    _bubbleHideTimer = Timer(const Duration(milliseconds: 900), () {
      _bubbleVisible.value = false;
    });
  }

  Future<void> _handleFocusTap(Offset localPos, Size size) async {
    final camera = _camera;
    if (camera == null) return;
    HapticFeedback.selectionClick();
    _focusPointN.value = localPos;
    _focusHideTimer?.cancel();
    _focusHideTimer = Timer(const Duration(milliseconds: 900), () {
      _focusPointN.value = null;
    });
    final xNorm = (localPos.dx / size.width).clamp(0.0, 1.0);
    final yNorm = (localPos.dy / size.height).clamp(0.0, 1.0);
    try {
      await camera.setFocusPoint(Offset(xNorm, yNorm));
      await camera.setExposurePoint(Offset(xNorm, yNorm));
    } catch (_) {}
  }

  Future<void> _takePhoto() async {
    final camera = _camera;
    if (camera == null || _capturing || camera.value.isTakingPicture) {
      return;
    }
    setState(() => _capturing = true);
    HapticFeedback.mediumImpact();
    _shutterFlash.forward(from: 0).then((_) => _shutterFlash.reverse());
    try {
      final shot = await camera.takePicture();
      final bytes = await shot.readAsBytes();
      final name = 'Mezgeb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await widget.controller.importCapturedPhoto(name: name, bytes: bytes);
      final tmp = File(shot.path);
      if (await tmp.exists()) await tmp.delete();
    } catch (e) {
      widget.controller.setError('Camera failed: $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_cameraError != null) return _errorPanel(context);
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      return _CameraWarmupShell(capturing: _capturing, onShutter: _openCamera);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Stack(
          fit: StackFit.expand,
          children: [
            // ─── Preview + gesture layer ─────────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (details) {
                _pinchBaseZoom = _currentZoom;
              },
              onScaleUpdate: (details) {
                if (details.pointerCount >= 2) {
                  _applyZoom(_pinchBaseZoom * details.scale);
                }
              },
              onTapUp: (details) =>
                  _handleFocusTap(details.localPosition, size),
              child: RepaintBoundary(
                child: ColoredBox(
                  color: Colors.black,
                  child: _PreviewCover(camera: camera),
                ),
              ),
            ),

            // ─── Shutter flash overlay ──────────────────────────────
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _shutterFlash,
                builder: (context, _) => Opacity(
                  opacity: _shutterFlash.value * 0.65,
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
            ),

            // ─── Focus reticle ──────────────────────────────────────
            ValueListenableBuilder<Offset?>(
              valueListenable: _focusPointN,
              builder: (context, point, _) {
                if (point == null) return const SizedBox.shrink();
                return _FocusReticle(position: point);
              },
            ),

            // ─── Zoom bubble ────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 200,
              child: _ZoomBubble(zoomN: _zoomN, visibleN: _bubbleVisible),
            ),

            // ─── Top bar ────────────────────────────────────────────
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _TopBar(
                flash: _flash,
                onFlashTap: _cycleFlash,
                canSwap: _backCameras.isNotEmpty && _frontCameras.isNotEmpty,
                onSwapTap: _swapFrontBack,
              ),
            ),

            // ─── Bottom controls ────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _BottomControls(
                lensCount: _activeList.length,
                lensIndex: _lensIndex,
                onLensTap: _switchLens,
                zoomN: _zoomN,
                minZoom: _minZoom,
                maxZoom: _maxZoom,
                onQuickZoom: (v) {
                  HapticFeedback.selectionClick();
                  _applyZoom(v);
                },
                capturing: _capturing,
                onShutter: _takePhoto,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _errorPanel(BuildContext context) {
    return CenterPanel(
      children: [
        Icon(
          Icons.no_photography_outlined,
          size: 54,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Camera unavailable',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(_cameraError ?? 'Could not open the camera.'),
      ],
    );
  }
}

class _CameraWarmupShell extends StatelessWidget {
  const _CameraWarmupShell({required this.capturing, required this.onShutter});

  final bool capturing;
  final VoidCallback onShutter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DisabledCircleButton(icon: Icons.flash_off),
                _DisabledCircleButton(icon: Icons.cameraswitch_rounded),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Getting camera ready',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Shutter(capturing: capturing, onTap: onShutter),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DisabledCircleButton extends StatelessWidget {
  const _DisabledCircleButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.32),
          size: 20,
        ),
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════════════
// Preview
// ═══════════════════════════════════════════════════════════════════════

class _PreviewCover extends StatelessWidget {
  const _PreviewCover({required this.camera});
  final CameraController camera;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = camera.value.previewSize;
        if (previewSize == null) return CameraPreview(camera);

        final isPortrait = constraints.maxHeight >= constraints.maxWidth;
        final w = isPortrait ? previewSize.height : previewSize.width;
        final h = isPortrait ? previewSize.width : previewSize.height;

        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(width: w, height: h, child: CameraPreview(camera)),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Top bar (flash + camera swap)
// ═══════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.flash,
    required this.onFlashTap,
    required this.canSwap,
    required this.onSwapTap,
  });

  final FlashMode flash;
  final VoidCallback onFlashTap;
  final bool canSwap;
  final VoidCallback onSwapTap;

  IconData get _flashIcon => switch (flash) {
    FlashMode.off => Icons.flash_off,
    FlashMode.auto => Icons.flash_auto,
    FlashMode.always => Icons.flash_on,
    _ => Icons.flash_off,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CircleButton(icon: _flashIcon, onTap: onFlashTap),
        if (canSwap)
          _CircleButton(icon: Icons.cameraswitch_rounded, onTap: onSwapTap),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Zoom bubble (fades in during pinch/pill tap)
// ═══════════════════════════════════════════════════════════════════════

class _ZoomBubble extends StatelessWidget {
  const _ZoomBubble({required this.zoomN, required this.visibleN});
  final ValueNotifier<double> zoomN;
  final ValueNotifier<bool> visibleN;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ValueListenableBuilder<bool>(
        valueListenable: visibleN,
        builder: (context, visible, _) => AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          opacity: visible ? 1.0 : 0.0,
          child: ValueListenableBuilder<double>(
            valueListenable: zoomN,
            builder: (context, zoom, _) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${zoom.toStringAsFixed(1)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Focus reticle
// ═══════════════════════════════════════════════════════════════════════

class _FocusReticle extends StatelessWidget {
  const _FocusReticle({required this.position});
  final Offset position;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - 34,
      top: position.dy - 34,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 1.4, end: 1.0),
          builder: (context, scale, _) => Transform.scale(
            scale: scale,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 1.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Bottom controls (zoom pills + shutter)
// ═══════════════════════════════════════════════════════════════════════

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.lensCount,
    required this.lensIndex,
    required this.onLensTap,
    required this.zoomN,
    required this.minZoom,
    required this.maxZoom,
    required this.onQuickZoom,
    required this.capturing,
    required this.onShutter,
  });

  final int lensCount;
  final int lensIndex;
  final ValueChanged<int> onLensTap;
  final ValueNotifier<double> zoomN;
  final double minZoom;
  final double maxZoom;
  final ValueChanged<double> onQuickZoom;
  final bool capturing;
  final VoidCallback onShutter;

  /// Digital-zoom presets that fall inside [minZoom, maxZoom].
  List<double> _zoomPresets() {
    const candidates = [1.0, 2.0, 5.0, 10.0];
    return candidates.where((v) => v >= minZoom && v <= maxZoom).toList();
  }

  @override
  Widget build(BuildContext context) {
    final presets = _zoomPresets();
    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Physical-lens picker (only if multiple back cameras exist)
          if (lensCount > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LensPills(
                count: lensCount,
                current: lensIndex,
                onTap: onLensTap,
              ),
            ),
          // Digital-zoom presets
          if (presets.length >= 2)
            _ZoomPills(presets: presets, zoomN: zoomN, onTap: onQuickZoom),
          const SizedBox(height: 16),
          _Shutter(capturing: capturing, onTap: onShutter),
        ],
      ),
    );
  }
}

class _LensPills extends StatelessWidget {
  const _LensPills({
    required this.count,
    required this.current,
    required this.onTap,
  });

  final int count;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final selected = i == current;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: selected ? 40 : 34,
              height: selected ? 40 : 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.08),
              ),
              alignment: Alignment.center,
              child: Text(
                'L${i + 1}',
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: selected ? 12 : 11,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ZoomPills extends StatelessWidget {
  const _ZoomPills({
    required this.presets,
    required this.zoomN,
    required this.onTap,
  });

  final List<double> presets;
  final ValueNotifier<double> zoomN;
  final ValueChanged<double> onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: zoomN,
      builder: (context, zoom, _) {
        // "Active" pill is the highest preset <= current zoom.
        double active = presets.first;
        for (final v in presets) {
          if (zoom + 0.05 >= v) active = v;
        }
        return Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: presets.map((v) {
              final selected = v == active;
              return GestureDetector(
                onTap: () => onTap(v),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 14 : 10,
                    vertical: selected ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(20),
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Text(
                    selected
                        ? '${zoom.toStringAsFixed(zoom < 10 ? 1 : 0)}x'
                        : '${v.toInt()}x',
                    style: TextStyle(
                      color: selected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({required this.capturing, required this.onTap});
  final bool capturing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        width: capturing ? 68 : 78,
        height: capturing ? 68 : 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.white70, width: 5),
        ),
        child: capturing
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.camera_alt, color: Colors.black, size: 30),
      ),
    );
  }
}
