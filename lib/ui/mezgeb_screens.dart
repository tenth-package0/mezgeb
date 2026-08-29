import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'mezgeb_camera_tab.dart';
import 'mezgeb_library_screens.dart';
import 'mezgeb_shared_widgets.dart';

class MezgebHome extends StatelessWidget {
  const MezgebHome({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    late final Widget child;
    late final String stateKey;
    if (controller.loading) {
      child = VaultShell(controller: controller);
      stateKey = 'vault-loading';
    } else if (controller.firstRun) {
      child = OnboardingScreen(controller: controller);
      stateKey = 'onboarding';
    } else {
      child = VaultShell(controller: controller);
      stateKey = 'vault';
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final pin = TextEditingController();
  final confirm = TextEditingController();

  @override
  void dispose() {
    pin.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = pin.text.length >= 4 && pin.text == confirm.text;
    return CenterPanel(
      children: [
        Icon(
          Icons.lock_outline,
          size: 46,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 18),
        Text(
          'Mezgeb',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          'Create your private vault lock.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 26),
        SecureField(
          controller: pin,
          label: 'PIN',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        SecureField(
          controller: confirm,
          label: 'Confirm PIN',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: canCreate
              ? () => widget.controller.createPin(pin.text)
              : null,
          icon: const Icon(Icons.check),
          label: const Text('Create Vault'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        ),
      ],
    );
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final pin = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.biometricEnabled) {
        widget.controller.unlockWithBiometrics();
      }
    });
  }

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CenterPanel(
      children: [
        Icon(
          Icons.fingerprint,
          size: 54,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 18),
        Text(
          'Vault Locked',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Text('Authenticate to open Mezgeb.'),
        const SizedBox(height: 26),
        SecureField(
          controller: pin,
          label: 'PIN',
          onChanged: (_) {
            widget.controller.clearError();
            setState(() {});
          },
        ),
        if (widget.controller.error != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.controller.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: pin.text.length >= 4
              ? () => widget.controller.unlockWithPin(pin.text)
              : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: const Text('Unlock'),
        ),
        TextButton.icon(
          onPressed: widget.controller.unlockWithBiometrics,
          icon: const Icon(Icons.fingerprint),
          label: const Text('Use biometrics'),
        ),
      ],
    );
  }
}

class VaultShell extends StatelessWidget {
  const VaultShell({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final protectedPage = controller.unlocked
        ? switch (controller.selectedTab) {
            1 => TimelineScreen(controller: controller),
            2 => AlbumsScreen(controller: controller),
            3 => SettingsScreen(controller: controller),
            _ => CameraTab(controller: controller),
          }
        : LockScreen(controller: controller);
    final pages = [
      CameraTab(controller: controller),
      protectedPage,
      protectedPage,
      protectedPage,
    ];
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(controller.selectedTab),
                child: pages[controller.selectedTab],
              ),
            ),
            if (controller.importing) const ImportOverlay(),
          ],
        ),
      ),
      floatingActionButton: controller.selectedTab == 1 && controller.unlocked
          ? FloatingActionButton.extended(
              onPressed: controller.importing ? null : controller.importPhotos,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Import Photos'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.selectedTab,
        onDestinationSelected: controller.setSelectedTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.photo_camera_outlined),
            selectedIcon: Icon(Icons.photo_camera),
            label: 'Camera',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Timeline',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Albums',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
