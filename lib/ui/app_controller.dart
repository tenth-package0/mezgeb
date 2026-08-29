import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/settings_service.dart';
import '../data/vault_database.dart';
import '../data/vault_repository.dart';
import '../domain/models.dart';
import '../platform/android_file_picker.dart';
import '../security/security_service.dart';

class AppController extends ChangeNotifier {
  AppController({required this.security, required this.settings});

  final SecurityService security;
  final SettingsService settings;
  VaultRepository? _repository;
  Future<void>? _initialization;
  Timer? _warmNightTimer;
  final Map<String, Future<Uint8List?>> _previewCache = {};
  bool _externalActivityOpen = false;

  bool loading = true;
  bool firstRun = true;
  bool unlocked = false;
  bool importing = false;
  bool biometricEnabled = true;
  bool deleteOriginals = false;
  bool _warmNightEnabled = false;
  String themeId = 'one';
  String? error;
  int selectedTab = 0;
  int storageUsedBytes = 0;
  TimelineMode timelineMode = TimelineMode.gallery;
  TimelineLevel timelineLevel = TimelineLevel.days;
  int? selectedYear;
  int? selectedMonth;
  VaultItem? selectedItem;
  List<VaultItem> items = [];
  List<Album> albums = [];

  bool get warmNightEnabled => _warmNightEnabled;
  List<VaultItem> get photos =>
      items.where((item) => item.isImage).toList(growable: false);

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    final db = await VaultDatabase.open(await security.databasePassphrase());
    _repository = VaultRepository(database: db, security: security);
    firstRun = !await security.hasPin();
    unlocked = firstRun;
    biometricEnabled = await security.biometricEnabled();
    deleteOriginals = await settings.deleteOriginals();
    _warmNightEnabled = await settings.warmNight();
    themeId = await settings.themeId();
    _warmNightTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      if (_warmNightEnabled) notifyListeners();
    });
    await refresh();
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final repo = _repository;
    if (repo == null) return;
    items = await repo.loadItems();
    albums = await repo.loadAlbums();
    storageUsedBytes = await repo.storageUsedBytes();
    notifyListeners();
  }

  Future<void> createPin(String pin) async {
    await security.createPin(pin);
    firstRun = false;
    unlocked = true;
    biometricEnabled = await security.biometricEnabled();
    notifyListeners();
  }

  Future<void> unlockWithPin(String pin) async {
    if (await security.verifyPin(pin)) {
      unlocked = true;
      error = null;
    } else {
      error = 'That PIN did not match.';
    }
    notifyListeners();
  }

  Future<void> unlockWithBiometrics() async {
    try {
      if (await security.authenticateWithBiometrics()) unlocked = true;
    } catch (_) {
      error = 'Biometric unlock was not available.';
    }
    notifyListeners();
  }

  void lockIfConfigured() {
    if (!firstRun && !_externalActivityOpen) {
      unlocked = false;
      selectedTab = 0;
      notifyListeners();
    }
  }

  Future<bool> changePin(String currentPin, String nextPin) async {
    final changed = await security.changePin(currentPin, nextPin);
    error = changed ? null : 'Current PIN did not match.';
    notifyListeners();
    return changed;
  }

  Future<void> setTheme(String id) async {
    themeId = id;
    await settings.setThemeId(id);
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    biometricEnabled = value;
    await security.setBiometricEnabled(value);
    notifyListeners();
  }

  Future<void> setDeleteOriginals(bool value) async {
    deleteOriginals = value;
    await settings.setDeleteOriginals(value);
    notifyListeners();
  }

  Future<void> setWarmNight(bool value) async {
    _warmNightEnabled = value;
    await settings.setWarmNight(value);
    notifyListeners();
  }

  Future<void> importFiles() => _importFromPicker(AndroidFilePicker.pickFiles);

  Future<void> importPhotos() =>
      _importFromPicker(AndroidFilePicker.pickPhotos);

  Future<void> _importFromPicker(
    Future<List<PickedVaultFile>> Function() pick,
  ) async {
    await initialize();
    final repo = _repository;
    if (repo == null) return;
    _externalActivityOpen = true;
    final files = await pick().whenComplete(() {
      _externalActivityOpen = false;
    });
    if (files.isEmpty) return;
    importing = true;
    notifyListeners();
    try {
      await repo.importPickedFiles(
        files: files,
        deleteOriginals: deleteOriginals,
      );
      error = null;
      _previewCache.clear();
      await refresh();
    } catch (exception) {
      error = 'Import failed: $exception';
    } finally {
      importing = false;
      notifyListeners();
    }
  }

  Future<void> importCapturedPhoto({
    required String name,
    required Uint8List bytes,
  }) async {
    await initialize();
    final repo = _repository;
    if (repo == null) return;
    importing = true;
    notifyListeners();
    try {
      final capturedAt = DateTime.now();
      await repo.importPickedFiles(
        files: [
          PickedVaultFile(
            name: name,
            bytes: bytes,
            mimeType: 'image/jpeg',
            capturedAt: capturedAt,
          ),
        ],
        deleteOriginals: false,
      );
      error = null;
      _previewCache.clear();
      await refresh();
    } catch (exception) {
      error = 'Camera import failed: $exception';
    } finally {
      importing = false;
      notifyListeners();
    }
  }

  Future<Uint8List?> previewBytes(VaultItem item) async {
    if (!item.isImage) return null;
    final repo = _repository;
    if (repo == null) return null;
    return _previewCache.putIfAbsent(item.id, () => repo.decryptItem(item));
  }

  Future<List<VaultItem>> loadAlbumItems(String albumId) async {
    await initialize();
    return await _repository?.loadItemsForAlbum(albumId) ?? [];
  }

  Future<List<Album>> loadAlbumsForItem(String itemId) async {
    await initialize();
    return await _repository?.loadAlbumsForItem(itemId) ?? [];
  }

  Future<void> createAlbum(String name) async {
    if (name.trim().isEmpty) return;
    await _repository?.createAlbum(name);
    await refresh();
  }

  Future<void> deleteAlbum(String albumId) async {
    await _repository?.deleteAlbum(albumId);
    await refresh();
  }

  Future<void> deleteAlbums(Iterable<Album> albumsToDelete) async {
    for (final album in albumsToDelete) {
      await _repository?.deleteAlbum(album.id);
    }
    await refresh();
  }

  Future<void> addSelectedItemToAlbum(String albumId) async {
    final item = selectedItem;
    if (item == null) return;
    await _repository?.addItemToAlbum(item.id, albumId);
    await refresh();
  }

  Future<void> addItemsToAlbum({
    required Iterable<VaultItem> itemsToAdd,
    required String albumId,
  }) async {
    for (final item in itemsToAdd) {
      await _repository?.addItemToAlbum(item.id, albumId);
    }
    await refresh();
  }

  Future<void> moveItemsToAlbum({
    required Iterable<VaultItem> itemsToMove,
    required String albumId,
  }) async {
    for (final item in itemsToMove) {
      await _repository?.moveItemToAlbum(item.id, albumId);
    }
    await refresh();
  }

  Future<void> deleteSelectedItem() async {
    final item = selectedItem;
    if (item == null) return;
    await _repository?.deleteItem(item);
    _previewCache.remove(item.id);
    selectedItem = null;
    await refresh();
  }

  Future<void> deleteItems(Iterable<VaultItem> itemsToDelete) async {
    final items = itemsToDelete.toList(growable: false);
    await _repository?.deleteItems(items);
    for (final item in items) {
      _previewCache.remove(item.id);
    }
    selectedItem = null;
    await refresh();
  }

  void openYear(int year) {
    selectedYear = year;
    selectedMonth = null;
    timelineLevel = TimelineLevel.months;
    notifyListeners();
  }

  void openMonth(int month) {
    if (selectedYear == null) return;
    openMonthGroup(selectedYear!, month);
  }

  void openMonthGroup(int year, int month) {
    selectedYear = year;
    selectedMonth = month;
    timelineLevel = TimelineLevel.days;
    notifyListeners();
  }

  void zoomOutTimeline() {
    switch (timelineLevel) {
      case TimelineLevel.days:
        timelineLevel = TimelineLevel.months;
        selectedMonth = null;
      case TimelineLevel.months:
        timelineLevel = TimelineLevel.years;
        selectedYear = null;
      case TimelineLevel.years:
        break;
    }
    notifyListeners();
  }

  void zoomInTimeline() {
    switch (timelineLevel) {
      case TimelineLevel.years:
        timelineLevel = TimelineLevel.months;
      case TimelineLevel.months:
        timelineLevel = TimelineLevel.days;
      case TimelineLevel.days:
        break;
    }
    selectedYear = null;
    selectedMonth = null;
    notifyListeners();
  }

  void returnTowardRecentTimeline() {
    if (timelineMode == TimelineMode.folders) {
      zoomOutTimeline();
      return;
    }
    selectedYear = null;
    selectedMonth = null;
    switch (timelineLevel) {
      case TimelineLevel.years:
        timelineLevel = TimelineLevel.months;
      case TimelineLevel.months:
      case TimelineLevel.days:
        timelineLevel = TimelineLevel.days;
    }
    notifyListeners();
  }

  void setTimelineMode(TimelineMode mode) {
    timelineMode = mode;
    selectedYear = null;
    selectedMonth = null;
    timelineLevel = mode == TimelineMode.gallery
        ? TimelineLevel.days
        : TimelineLevel.years;
    notifyListeners();
  }

  void selectItem(VaultItem? item) {
    selectedItem = item;
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  void setError(String message) {
    error = message;
    notifyListeners();
  }

  void setSelectedTab(int index) {
    selectedTab = index;
    notifyListeners();
  }

  @override
  void dispose() {
    _warmNightTimer?.cancel();
    super.dispose();
  }
}
