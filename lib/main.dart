import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

import 'data/settings_service.dart';
import 'security/security_service.dart';
import 'ui/app_controller.dart';
import 'ui/mezgeb_intro_montage.dart';
import 'ui/mezgeb_screens.dart';
import 'ui/mezgeb_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(_preferHighRefreshRate());
  final controller = AppController(
    security: SecurityService(),
    settings: SettingsService(),
  );
  runApp(MezgebApp(controller: controller));
}

Future<void> _preferHighRefreshRate() async {
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (_) {
    // Some devices do not expose display mode controls.
  }
}

class MezgebApp extends StatefulWidget {
  const MezgebApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<MezgebApp> createState() => _MezgebAppState();
}

class _MezgebAppState extends State<MezgebApp> with WidgetsBindingObserver {
  bool _showIntro = false;
  bool _introPreferenceLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.controller.initialize());
    unawaited(_loadIntroPreference());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.controller.lockIfConfigured();
    }
  }

  Future<void> _loadIntroPreference() async {
    final introSeen = await widget.controller.settings.introSeen();
    if (!mounted) return;
    setState(() {
      _showIntro = !introSeen;
      _introPreferenceLoaded = true;
    });
  }

  Future<void> _finishIntro() async {
    setState(() => _showIntro = false);
    await widget.controller.settings.setIntroSeen(true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Mezgeb',
          debugShowCheckedModeBanner: false,
          theme: MezgebThemes.themeAuto(
            widget.controller.themeId,
            widget.controller.warmNightEnabled,
          ),
          home: _introPreferenceLoaded && _showIntro
              ? MezgebIntroMontage(onFinished: _finishIntro)
              : MezgebHome(controller: widget.controller),
        );
      },
    );
  }
}
