import 'package:flutter/material.dart';

// ═════════════════════════════════════════════════════════════════════════
// Theme spec
// ═════════════════════════════════════════════════════════════════════════

/// A single theme's raw palette. Every theme uses the same shape so the
/// picker can render a live preview for every one of them.
class MezgebThemeSpec {
  const MezgebThemeSpec({
    required this.id,
    required this.name,
    required this.tagline,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.outline,
  });

  final String id;
  final String name;
  final String tagline;
  final Brightness brightness;

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color outline;

  bool get isDark => brightness == Brightness.dark;
}

// ═════════════════════════════════════════════════════════════════════════
// Theme catalog + engine
// ═════════════════════════════════════════════════════════════════════════

class MezgebThemes {
  MezgebThemes._();

  static const int _warmStartMinutes = 18 * 60 + 30; // 18:30
  static const int _warmEndMinutes = 6 * 60 + 30; //  6:30

  static const List<String> lightIds = [
    'paper',
    'bone',
    'cloud',
    'linen',
    'fog',
    'sage',
    'blush',
  ];
  static const List<String> darkIds = [
    'carbon',
    'slate',
    'zinc',
    'onyx',
    'stone',
    'ink',
    'bronze',
    'steel',
    'espresso',
    'obsidian',
  ];
  static const List<String> vividIds = ['emerald', 'rose_noir', 'cyberpunk'];

  static const List<MezgebThemeSpec> all = [
    // ─── Light — modern monotones ─────────────────────────────────────────
    MezgebThemeSpec(
      id: 'paper',
      name: 'Paper',
      tagline: 'Pure white, ink black',
      brightness: Brightness.light,
      background: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFF5F5F5),
      primary: Color(0xFF171717),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF525252),
      onSurface: Color(0xFF171717),
      onSurfaceMuted: Color(0xFF737373),
      outline: Color(0xFFE5E5E5),
    ),
    MezgebThemeSpec(
      id: 'bone',
      name: 'Bone',
      tagline: 'Warm off-white, charcoal',
      brightness: Brightness.light,
      background: Color(0xFFFAFAF7),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFF4F1EA),
      primary: Color(0xFF292524),
      onPrimary: Color(0xFFFAFAF7),
      secondary: Color(0xFF78716C),
      onSurface: Color(0xFF1C1917),
      onSurfaceMuted: Color(0xFFA8A29E),
      outline: Color(0xFFE7E5E4),
    ),
    MezgebThemeSpec(
      id: 'cloud',
      name: 'Cloud',
      tagline: 'Cool light, slate accent',
      brightness: Brightness.light,
      background: Color(0xFFF1F5F9),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFE2E8F0),
      primary: Color(0xFF334155),
      onPrimary: Color(0xFFF8FAFC),
      secondary: Color(0xFF64748B),
      onSurface: Color(0xFF0F172A),
      onSurfaceMuted: Color(0xFF64748B),
      outline: Color(0xFFCBD5E1),
    ),
    MezgebThemeSpec(
      id: 'linen',
      name: 'Linen',
      tagline: 'Cream paper, warm ink',
      brightness: Brightness.light,
      background: Color(0xFFF5F1E8),
      surface: Color(0xFFFBF7EE),
      surfaceElevated: Color(0xFFEBE3D0),
      primary: Color(0xFF44403C),
      onPrimary: Color(0xFFFBF7EE),
      secondary: Color(0xFF78716C),
      onSurface: Color(0xFF1C1917),
      onSurfaceMuted: Color(0xFF78716C),
      outline: Color(0xFFD6CDB8),
    ),
    MezgebThemeSpec(
      id: 'fog',
      name: 'Fog',
      tagline: 'Cool grey, indigo dusk',
      brightness: Brightness.light,
      background: Color(0xFFF4F5F7),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFE7EAF0),
      primary: Color(0xFF4C5AAA),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF6B7280),
      onSurface: Color(0xFF191C22),
      onSurfaceMuted: Color(0xFF6E7480),
      outline: Color(0xFFD8DCE5),
    ),
    MezgebThemeSpec(
      id: 'sage',
      name: 'Sage',
      tagline: 'Pale sage, deep forest',
      brightness: Brightness.light,
      background: Color(0xFFF1F5F0),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFE1E8DE),
      primary: Color(0xFF3F6B4A),
      onPrimary: Color(0xFFF1F5F0),
      secondary: Color(0xFF6B8271),
      onSurface: Color(0xFF17251C),
      onSurfaceMuted: Color(0xFF6B8271),
      outline: Color(0xFFD5DFD1),
    ),
    MezgebThemeSpec(
      id: 'blush',
      name: 'Blush',
      tagline: 'Peach cream, terracotta',
      brightness: Brightness.light,
      background: Color(0xFFFBF3ED),
      surface: Color(0xFFFFFAF5),
      surfaceElevated: Color(0xFFF1E4D8),
      primary: Color(0xFF7A3F1F),
      onPrimary: Color(0xFFFBF3ED),
      secondary: Color(0xFFA67C5B),
      onSurface: Color(0xFF2D1810),
      onSurfaceMuted: Color(0xFF9B7B60),
      outline: Color(0xFFE5D2BE),
    ),

    // ─── Dark — monotone / near-monotone modern ───────────────────────────
    MezgebThemeSpec(
      id: 'carbon',
      name: 'Carbon',
      tagline: 'Pure grayscale, silver accent',
      brightness: Brightness.dark,
      background: Color(0xFF0A0A0A),
      surface: Color(0xFF141414),
      surfaceElevated: Color(0xFF1E1E1E),
      primary: Color(0xFFF5F5F5),
      onPrimary: Color(0xFF0A0A0A),
      secondary: Color(0xFF737373),
      onSurface: Color(0xFFFAFAFA),
      onSurfaceMuted: Color(0xFF737373),
      outline: Color(0xFF262626),
    ),
    MezgebThemeSpec(
      id: 'slate',
      name: 'Slate',
      tagline: 'Cool slate monotone',
      brightness: Brightness.dark,
      background: Color(0xFF0F172A),
      surface: Color(0xFF1E293B),
      surfaceElevated: Color(0xFF334155),
      primary: Color(0xFF94A3B8),
      onPrimary: Color(0xFF0F172A),
      secondary: Color(0xFF64748B),
      onSurface: Color(0xFFF1F5F9),
      onSurfaceMuted: Color(0xFF94A3B8),
      outline: Color(0xFF334155),
    ),
    MezgebThemeSpec(
      id: 'zinc',
      name: 'Zinc',
      tagline: 'Warm neutral grey',
      brightness: Brightness.dark,
      background: Color(0xFF18181B),
      surface: Color(0xFF27272A),
      surfaceElevated: Color(0xFF3F3F46),
      primary: Color(0xFFE4E4E7),
      onPrimary: Color(0xFF18181B),
      secondary: Color(0xFFA1A1AA),
      onSurface: Color(0xFFFAFAFA),
      onSurfaceMuted: Color(0xFFA1A1AA),
      outline: Color(0xFF3F3F46),
    ),
    MezgebThemeSpec(
      id: 'onyx',
      name: 'Onyx',
      tagline: 'Near-black, pearl highlight',
      brightness: Brightness.dark,
      background: Color(0xFF0C0A09),
      surface: Color(0xFF1C1917),
      surfaceElevated: Color(0xFF292524),
      primary: Color(0xFFE7E5E4),
      onPrimary: Color(0xFF0C0A09),
      secondary: Color(0xFF78716C),
      onSurface: Color(0xFFFAFAF9),
      onSurfaceMuted: Color(0xFF78716C),
      outline: Color(0xFF292524),
    ),
    MezgebThemeSpec(
      id: 'stone',
      name: 'Stone',
      tagline: 'Warm mid-grey, amber cream',
      brightness: Brightness.dark,
      background: Color(0xFF1C1917),
      surface: Color(0xFF292524),
      surfaceElevated: Color(0xFF3B3532),
      primary: Color(0xFFFBBF77),
      onPrimary: Color(0xFF2D1F13),
      secondary: Color(0xFFA8A29E),
      onSurface: Color(0xFFFEF3E4),
      onSurfaceMuted: Color(0xFFB8ADA5),
      outline: Color(0xFF44403C),
    ),
    MezgebThemeSpec(
      id: 'ink',
      name: 'Ink',
      tagline: 'Deep blue-black, off-white',
      brightness: Brightness.dark,
      background: Color(0xFF030712),
      surface: Color(0xFF0F172A),
      surfaceElevated: Color(0xFF1E293B),
      primary: Color(0xFFF8FAFC),
      onPrimary: Color(0xFF030712),
      secondary: Color(0xFF64748B),
      onSurface: Color(0xFFF1F5F9),
      onSurfaceMuted: Color(0xFF64748B),
      outline: Color(0xFF1E293B),
    ),
    MezgebThemeSpec(
      id: 'bronze',
      name: 'Bronze',
      tagline: 'Warm brown, copper glow',
      brightness: Brightness.dark,
      background: Color(0xFF1A120B),
      surface: Color(0xFF2A1D12),
      surfaceElevated: Color(0xFF3A2818),
      primary: Color(0xFFCD7F32),
      onPrimary: Color(0xFF1A0A00),
      secondary: Color(0xFF8B6F47),
      onSurface: Color(0xFFF5E6D3),
      onSurfaceMuted: Color(0xFFA08D75),
      outline: Color(0xFF3A2818),
    ),
    MezgebThemeSpec(
      id: 'steel',
      name: 'Steel',
      tagline: 'Cool blue-steel, chrome',
      brightness: Brightness.dark,
      background: Color(0xFF0C1420),
      surface: Color(0xFF172131),
      surfaceElevated: Color(0xFF253244),
      primary: Color(0xFF9CAFC7),
      onPrimary: Color(0xFF0C1420),
      secondary: Color(0xFF6B7A8F),
      onSurface: Color(0xFFE5EDF6),
      onSurfaceMuted: Color(0xFF8695AB),
      outline: Color(0xFF253244),
    ),
    MezgebThemeSpec(
      id: 'espresso',
      name: 'Espresso',
      tagline: 'Dark coffee, cream',
      brightness: Brightness.dark,
      background: Color(0xFF1A0F08),
      surface: Color(0xFF241611),
      surfaceElevated: Color(0xFF30201A),
      primary: Color(0xFFD4A574),
      onPrimary: Color(0xFF1A0F08),
      secondary: Color(0xFF8B6F5A),
      onSurface: Color(0xFFF0E5D8),
      onSurfaceMuted: Color(0xFF9C8A78),
      outline: Color(0xFF30201A),
    ),
    MezgebThemeSpec(
      id: 'obsidian',
      name: 'Obsidian',
      tagline: 'Pure OLED black, indigo pop',
      brightness: Brightness.dark,
      background: Color(0xFF000000),
      surface: Color(0xFF0A0A0A),
      surfaceElevated: Color(0xFF171717),
      primary: Color(0xFF818CF8),
      onPrimary: Color(0xFF0F0530),
      secondary: Color(0xFF6366F1),
      onSurface: Color(0xFFF5F5F5),
      onSurfaceMuted: Color(0xFF737373),
      outline: Color(0xFF171717),
    ),

    // ─── Vivid ────────────────────────────────────────────────────────────
    MezgebThemeSpec(
      id: 'emerald',
      name: 'Emerald',
      tagline: 'Deep forest, emerald bloom',
      brightness: Brightness.dark,
      background: Color(0xFF051510),
      surface: Color(0xFF0B1F18),
      surfaceElevated: Color(0xFF142822),
      primary: Color(0xFF34D399),
      onPrimary: Color(0xFF041610),
      secondary: Color(0xFF6EE7B7),
      onSurface: Color(0xFFECFDF5),
      onSurfaceMuted: Color(0xFF6B8E82),
      outline: Color(0xFF1C332C),
    ),
    MezgebThemeSpec(
      id: 'rose_noir',
      name: 'Rose Noir',
      tagline: 'Dark plum, dusty rose',
      brightness: Brightness.dark,
      background: Color(0xFF1C1418),
      surface: Color(0xFF251A20),
      surfaceElevated: Color(0xFF2E2028),
      primary: Color(0xFFE8A5B8),
      onPrimary: Color(0xFF2B121C),
      secondary: Color(0xFFF0C6D3),
      onSurface: Color(0xFFF3E6EB),
      onSurfaceMuted: Color(0xFFA08691),
      outline: Color(0xFF3A2A32),
    ),
    MezgebThemeSpec(
      id: 'cyberpunk',
      name: 'Cyberpunk',
      tagline: 'Neon magenta on black',
      brightness: Brightness.dark,
      background: Color(0xFF000000),
      surface: Color(0xFF0C000E),
      surfaceElevated: Color(0xFF1A0022),
      primary: Color(0xFFFF2E88),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF00E5FF),
      onSurface: Color(0xFFF5E6F1),
      onSurfaceMuted: Color(0xFF9E7D95),
      outline: Color(0xFF2A0033),
    ),
  ];

  static MezgebThemeSpec specFor(String id) {
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }

  // ─── Warm-night engine ──────────────────────────────────────────────────

  /// True when local time is >= 18:30 or before 06:30.
  static bool get isNight {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    return minutes >= _warmStartMinutes || minutes < _warmEndMinutes;
  }

  /// Sepia-style warm shift: cuts blue, gently boosts red. Strength 1.0
  /// is meant to be noticeable.
  static MezgebThemeSpec applyWarmShift(
    MezgebThemeSpec s, {
    double strength = 1.0,
  }) {
    Color w(Color c, {double str = 1.0}) {
      final k = (strength * str).clamp(0.0, 1.0);
      return Color.from(
        alpha: c.a,
        red: (c.r + (1.0 - c.r) * 0.12 * k).clamp(0.0, 1.0),
        green: (c.g * (1.0 - 0.06 * k)).clamp(0.0, 1.0),
        blue: (c.b * (1.0 - 0.42 * k)).clamp(0.0, 1.0),
      );
    }

    return MezgebThemeSpec(
      id: s.id,
      name: s.name,
      tagline: s.tagline,
      brightness: s.brightness,
      background: w(s.background),
      surface: w(s.surface),
      surfaceElevated: w(s.surfaceElevated),
      primary: w(s.primary),
      onPrimary: w(s.onPrimary, str: 0.4),
      secondary: w(s.secondary),
      onSurface: w(s.onSurface, str: 0.35),
      onSurfaceMuted: w(s.onSurfaceMuted, str: 0.5),
      outline: w(s.outline),
    );
  }

  /// Build ThemeData for [id]. Pass [warmNight]: true to force the shift.
  static ThemeData theme(String id, {bool warmNight = false}) {
    var spec = specFor(id);
    if (warmNight) spec = applyWarmShift(spec);
    return _buildTheme(spec);
  }

  /// Preferred entry point from MaterialApp: applies warm shift only when
  /// [warmNightEnabled] is true AND the clock says it is night.
  static ThemeData themeAuto(String id, bool warmNightEnabled) {
    return theme(id, warmNight: warmNightEnabled && isNight);
  }

  // ─── ThemeData builder ──────────────────────────────────────────────────

  static ThemeData _buildTheme(MezgebThemeSpec s) {
    final scheme = ColorScheme(
      brightness: s.brightness,
      primary: s.primary,
      onPrimary: s.onPrimary,
      secondary: s.secondary,
      onSecondary: s.onPrimary,
      error: const Color(0xFFE5484D),
      onError: Colors.white,
      surface: s.surface,
      onSurface: s.onSurface,
      surfaceContainerHighest: s.surfaceElevated,
      surfaceContainerHigh: s.surfaceElevated,
      surfaceContainer: s.surface,
      outline: s.outline,
      outlineVariant: s.outline.withValues(alpha: 0.55),
      onSurfaceVariant: s.onSurfaceMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: s.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: s.background,
      canvasColor: s.background,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _buildTextTheme(s.onSurface, s.onSurfaceMuted),
      appBarTheme: AppBarTheme(
        backgroundColor: s.background,
        foregroundColor: s.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: s.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: s.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: s.outline.withValues(alpha: 0.6)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: s.onSurfaceMuted,
        textColor: s.onSurface,
        tileColor: s.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: s.outline.withValues(alpha: 0.6),
        thickness: 0.5,
      ),
      iconTheme: IconThemeData(color: s.onSurface, size: 22),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: s.surface,
        indicatorColor: s.primary.withValues(alpha: 0.16),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: s.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? s.primary
                : s.onSurfaceMuted,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: s.primary,
          foregroundColor: s.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: s.primary,
          foregroundColor: s.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: s.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? s.primary
              : s.onSurfaceMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? s.primary.withValues(alpha: 0.35)
              : s.outline,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: s.outline),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: s.surfaceElevated,
        contentTextStyle: TextStyle(color: s.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color body, Color muted) {
    return TextTheme(
      displayLarge: TextStyle(
        color: body,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        color: body,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      displaySmall: TextStyle(
        color: body,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineLarge: TextStyle(
        color: body,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        color: body,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      headlineSmall: TextStyle(color: body, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(
        color: body,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      titleMedium: TextStyle(color: body, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(color: body, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: body, fontSize: 15, height: 1.4),
      bodyMedium: TextStyle(color: body, fontSize: 14, height: 1.4),
      bodySmall: TextStyle(color: muted, fontSize: 12, height: 1.3),
      labelLarge: TextStyle(color: body, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(color: muted, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(
        color: muted,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Picker screen
// ═════════════════════════════════════════════════════════════════════════

class ThemePickerScreen extends StatelessWidget {
  const ThemePickerScreen({
    super.key,
    required this.currentThemeId,
    required this.onSelected,
    required this.warmNightEnabled,
    required this.onWarmNightChanged,
  });

  final String currentThemeId;
  final ValueChanged<String> onSelected;
  final bool warmNightEnabled;
  final ValueChanged<bool> onWarmNightChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _WarmNightCard(
            enabled: warmNightEnabled,
            onChanged: onWarmNightChanged,
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Light',
            subtitle: 'Bright, paper-like surfaces',
          ),
          const SizedBox(height: 12),
          _ThemeGrid(
            ids: MezgebThemes.lightIds,
            currentThemeId: currentThemeId,
            warmPreview: warmNightEnabled,
            onSelected: onSelected,
          ),
          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'Dark',
            subtitle: 'Monotone & near-monotone modern palettes',
          ),
          const SizedBox(height: 12),
          _ThemeGrid(
            ids: MezgebThemes.darkIds,
            currentThemeId: currentThemeId,
            warmPreview: warmNightEnabled,
            onSelected: onSelected,
          ),
          const SizedBox(height: 28),
          const _SectionHeader(
            title: 'Vivid',
            subtitle: 'High-contrast & OLED-friendly',
          ),
          const SizedBox(height: 12),
          _ThemeGrid(
            ids: MezgebThemes.vividIds,
            currentThemeId: currentThemeId,
            warmPreview: warmNightEnabled,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}

class _WarmNightCard extends StatelessWidget {
  const _WarmNightCard({required this.enabled, required this.onChanged});
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentlyActive = enabled && MezgebThemes.isNight;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: currentlyActive
              ? [const Color(0xFFB25E1E), const Color(0xFF8B3A0F)]
              : [scheme.surfaceContainerHighest, scheme.surface],
        ),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentlyActive
                  ? Colors.white.withValues(alpha: 0.18)
                  : scheme.primary.withValues(alpha: 0.14),
            ),
            child: Icon(
              currentlyActive
                  ? Icons.nightlight_round
                  : Icons.wb_twilight_rounded,
              color: currentlyActive ? Colors.white : scheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto warm at night',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: currentlyActive ? Colors.white : scheme.onSurface,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentlyActive
                      ? 'On now — reducing blue light'
                      : enabled
                      ? 'Scheduled — kicks in at 6:30 PM'
                      : 'Shift warmer after 6:30 PM',
                  style: TextStyle(
                    fontSize: 12,
                    color: currentlyActive
                        ? Colors.white.withValues(alpha: 0.85)
                        : scheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.titleLarge),
          const SizedBox(height: 2),
          Text(subtitle, style: t.bodySmall),
        ],
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({
    required this.ids,
    required this.currentThemeId,
    required this.warmPreview,
    required this.onSelected,
  });

  final List<String> ids;
  final String currentThemeId;
  final bool warmPreview;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ids.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, i) {
        var spec = MezgebThemes.specFor(ids[i]);
        if (warmPreview) {
          spec = MezgebThemes.applyWarmShift(spec, strength: 0.85);
        }
        return _ThemePreviewCard(
          spec: spec,
          selected: spec.id == currentThemeId,
          onTap: () => onSelected(spec.id),
        );
      },
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final MezgebThemeSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: spec.primary.withValues(alpha: 0.35),
                  blurRadius: 22,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: spec.background,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                width: selected ? 2 : 1,
                color: selected ? spec.primary : spec.outline,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniPreview(spec: spec),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spec.name,
                        style: TextStyle(
                          color: spec.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: selected ? 1.0 : 0.0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: spec.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: spec.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  spec.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: spec.onSurfaceMuted,
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPreview extends StatelessWidget {
  const _MiniPreview({required this.spec});
  final MezgebThemeSpec spec;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: Container(
        decoration: BoxDecoration(
          color: spec.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: spec.outline),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 6,
                  width: 34,
                  decoration: BoxDecoration(
                    color: spec.onSurface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 8,
                  width: 8,
                  decoration: BoxDecoration(
                    color: spec.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: spec.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 4,
                      width: 44,
                      decoration: BoxDecoration(
                        color: spec.onSurface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          height: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: spec.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Container(
                            height: 3,
                            width: 18,
                            decoration: BoxDecoration(
                              color: spec.onPrimary,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          height: 16,
                          width: 26,
                          decoration: BoxDecoration(
                            color: spec.secondary.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
