import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../calendar/ethiopian_calendar.dart';
import '../domain/models.dart';
import 'app_controller.dart';
import 'mezgeb_shared_widgets.dart';
import 'mezgeb_theme.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  bool _zoomHandled = false;
  final Set<String> _selectedPhotoIds = {};

  bool get _selectingPhotos => _selectedPhotoIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final timelineItems = controller.photos;
    final visibleItems = _visibleDayItems(controller, timelineItems);
    final selectedItems = visibleItems
        .where((item) => _selectedPhotoIds.contains(item.id))
        .toList(growable: false);
    return GestureDetector(
      onScaleUpdate: (details) {
        if (_selectingPhotos) return;
        if (_zoomHandled) return;
        if (details.scale < 0.86) {
          _zoomHandled = true;
          controller.zoomOutTimeline();
        } else if (details.scale > 1.14 &&
            controller.timelineMode == TimelineMode.gallery) {
          _zoomHandled = true;
          controller.zoomInTimeline();
        }
      },
      onScaleEnd: (_) => _zoomHandled = false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        child: Column(
          children: [
            Header(
              title: _selectingPhotos
                  ? '${_selectedPhotoIds.length} selected'
                  : _timelineTitle(controller),
              subtitle: _selectingPhotos
                  ? 'Choose an action'
                  : '${timelineItems.length} private photos',
              action: _selectingPhotos
                  ? _PhotoSelectionActions(
                      onAddToAlbum: () =>
                          _addSelectedPhotosToAlbum(selectedItems),
                      onShare: () => _shareSelectedPhotos(selectedItems),
                      onDelete: () => _deleteSelectedPhotos(selectedItems),
                      onCancel: _clearPhotoSelection,
                    )
                  : _TimelineMenu(controller: controller),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: timelineItems.isEmpty
                  ? const EmptyState(
                      title: 'No private photos yet',
                      body: 'Take a photo or import photos from your gallery.',
                    )
                  : switch (controller.timelineLevel) {
                      TimelineLevel.years => YearGrid(controller: controller),
                      TimelineLevel.months => MonthGrid(controller: controller),
                      TimelineLevel.days => GroupedTimelineGallery(
                        controller: controller,
                        items: visibleItems,
                        selectedIds: _selectedPhotoIds,
                        onOpen: (item) => showViewer(
                          context,
                          controller,
                          item,
                          items: visibleItems,
                          selectedIds: _selectedPhotoIds,
                          onSelectionChanged: _replacePhotoSelection,
                        ),
                        onToggleSelection: _togglePhotoSelection,
                      ),
                    },
            ),
          ],
        ),
      ),
    );
  }

  String _timelineTitle(AppController controller) {
    if (controller.timelineMode == TimelineMode.folders) {
      return switch (controller.timelineLevel) {
        TimelineLevel.years => 'Year Folders',
        TimelineLevel.months => '${controller.selectedYear}',
        TimelineLevel.days =>
          '${EthiopianCalendar.monthName(controller.selectedMonth ?? 1)} ${controller.selectedYear}',
      };
    }
    return switch (controller.timelineLevel) {
      TimelineLevel.days =>
        controller.selectedYear == null
            ? 'Recent Photos'
            : '${EthiopianCalendar.monthName(controller.selectedMonth ?? 1)} ${controller.selectedYear}',
      TimelineLevel.months => 'Months',
      TimelineLevel.years => 'Years',
    };
  }

  List<VaultItem> _visibleDayItems(
    AppController controller,
    List<VaultItem> timelineItems,
  ) {
    if (controller.selectedYear == null || controller.selectedMonth == null) {
      return timelineItems;
    }
    return timelineItems.where((item) {
      final date = item.ethiopianDate;
      return date.year == controller.selectedYear &&
          date.month == controller.selectedMonth;
    }).toList();
  }

  void _togglePhotoSelection(VaultItem item) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedPhotoIds.add(item.id)) {
        _selectedPhotoIds.remove(item.id);
      }
    });
  }

  void _clearPhotoSelection() {
    setState(_selectedPhotoIds.clear);
  }

  void _replacePhotoSelection(Set<String> selectedIds) {
    setState(() {
      _selectedPhotoIds
        ..clear()
        ..addAll(selectedIds);
    });
  }

  Future<void> _shareSelectedPhotos(List<VaultItem> selectedItems) async {
    if (selectedItems.isEmpty) return;
    await shareVaultItems(context, widget.controller, selectedItems);
    if (mounted) _clearPhotoSelection();
  }

  Future<void> _addSelectedPhotosToAlbum(List<VaultItem> selectedItems) async {
    if (selectedItems.isEmpty) return;
    final album = await chooseAlbumDialog(context, widget.controller.albums);
    if (!mounted) return;
    if (album == null) return;
    final added = await addItemsToAlbumWithConflictCheck(
      context: context,
      controller: widget.controller,
      items: selectedItems,
      targetAlbum: album,
    );
    if (mounted && added) _clearPhotoSelection();
  }

  Future<void> _deleteSelectedPhotos(List<VaultItem> selectedItems) async {
    if (selectedItems.isEmpty) return;
    final ok = await _confirmDeletePhotos(context, selectedItems.length);
    if (!ok) return;
    await widget.controller.deleteItems(selectedItems);
    if (mounted) _clearPhotoSelection();
  }
}

class _TimelineMenu extends StatelessWidget {
  const _TimelineMenu({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final canGoBack =
        controller.timelineLevel != TimelineLevel.days ||
        controller.selectedYear != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canGoBack)
          IconButton(
            onPressed: controller.returnTowardRecentTimeline,
            icon: const Icon(Icons.arrow_back),
          ),
        PopupMenuButton<TimelineMode>(
          icon: const Icon(Icons.more_vert),
          onSelected: controller.setTimelineMode,
          itemBuilder: (context) => [
            CheckedPopupMenuItem(
              value: TimelineMode.gallery,
              checked: controller.timelineMode == TimelineMode.gallery,
              child: const Text('Gallery style'),
            ),
            CheckedPopupMenuItem(
              value: TimelineMode.folders,
              checked: controller.timelineMode == TimelineMode.folders,
              child: const Text('Year folders'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhotoSelectionActions extends StatelessWidget {
  const _PhotoSelectionActions({
    required this.onAddToAlbum,
    required this.onShare,
    required this.onDelete,
    required this.onCancel,
  });

  final VoidCallback onAddToAlbum;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onAddToAlbum,
          icon: const Icon(Icons.drive_file_move_outline),
        ),
        IconButton(onPressed: onShare, icon: const Icon(Icons.ios_share)),
        IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
        IconButton(onPressed: onCancel, icon: const Icon(Icons.close)),
      ],
    );
  }
}

class YearGrid extends StatelessWidget {
  const YearGrid({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final groups = <int, List<VaultItem>>{};
    for (final item in controller.photos) {
      groups.putIfAbsent(item.ethiopianDate.year, () => []).add(item);
    }
    final years = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .82,
      ),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final items = groups[year]!;
        return SummaryCard(
          title: '$year',
          subtitle: '${items.length} items',
          item: items.first,
          controller: controller,
          onTap: () => controller.openYear(year),
        );
      },
    );
  }
}

class MonthGrid extends StatelessWidget {
  const MonthGrid({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<VaultItem>>{};
    for (final item in controller.photos) {
      final date = item.ethiopianDate;
      if (controller.timelineMode == TimelineMode.folders &&
          controller.selectedYear != null &&
          date.year != controller.selectedYear) {
        continue;
      }
      groups.putIfAbsent('${date.year}-${date.month}', () => []).add(item);
    }
    final months =
        groups.entries.map((entry) {
          final parts = entry.key.split('-');
          return (
            year: int.parse(parts[0]),
            month: int.parse(parts[1]),
            items: entry.value,
          );
        }).toList()..sort((a, b) {
          final byYear = b.year.compareTo(a.year);
          if (byYear != 0) return byYear;
          return b.month.compareTo(a.month);
        });

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .82,
      ),
      itemCount: months.length,
      itemBuilder: (context, index) {
        final month = months[index];
        return SummaryCard(
          title: EthiopianCalendar.monthName(month.month),
          subtitle: '${month.year} - ${month.items.length} items',
          item: month.items.first,
          controller: controller,
          onTap: () => controller.openMonthGroup(month.year, month.month),
        );
      },
    );
  }
}

class ItemGrid extends StatelessWidget {
  const ItemGrid({super.key, required this.controller, required this.items});

  final AppController controller;
  final List<VaultItem> items;

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final item = sorted[index];
        return GestureDetector(
          onTap: () => showViewer(context, controller, item),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: VaultPreview(item: item, controller: controller),
          ),
        );
      },
    );
  }
}

class GroupedTimelineGallery extends StatelessWidget {
  const GroupedTimelineGallery({
    super.key,
    required this.controller,
    required this.items,
    this.selectedIds = const {},
    this.onOpen,
    this.onToggleSelection,
  });

  final AppController controller;
  final List<VaultItem> items;
  final Set<String> selectedIds;
  final ValueChanged<VaultItem>? onOpen;
  final ValueChanged<VaultItem>? onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<VaultItem>>{};
    for (final item in items) {
      final date = item.ethiopianDate;
      final key = '${date.year}-${date.month}-${date.day}';
      groups.putIfAbsent(key, () => []).add(item);
    }
    final days =
        groups.entries.map((entry) {
          final parts = entry.key.split('-');
          final dayItems = [...entry.value]
            ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
          return (
            year: int.parse(parts[0]),
            month: int.parse(parts[1]),
            day: int.parse(parts[2]),
            items: dayItems,
          );
        }).toList()..sort((a, b) {
          final byYear = b.year.compareTo(a.year);
          if (byYear != 0) return byYear;
          final byMonth = b.month.compareTo(a.month);
          if (byMonth != 0) return byMonth;
          return b.day.compareTo(a.day);
        });

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 92),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: days.length,
      separatorBuilder: (context, index) => const SizedBox(height: 26),
      itemBuilder: (context, index) {
        final day = days[index];
        return _TimelineDaySection(
          controller: controller,
          title: _dayTitle(day.year, day.month, day.day),
          items: day.items,
          selectedIds: selectedIds,
          onOpen: onOpen,
          onToggleSelection: onToggleSelection,
        );
      },
    );
  }

  String _dayTitle(int year, int month, int day) {
    final monthName = EthiopianCalendar.monthName(month);
    final currentYear = EthiopianCalendar.fromGregorian(DateTime.now()).year;
    if (year == currentYear) return '$day $monthName';
    return '$day $monthName $year';
  }
}

class _TimelineDaySection extends StatelessWidget {
  const _TimelineDaySection({
    required this.controller,
    required this.title,
    required this.items,
    required this.selectedIds,
    this.onOpen,
    this.onToggleSelection,
  });

  final AppController controller;
  final String title;
  final List<VaultItem> items;
  final Set<String> selectedIds;
  final ValueChanged<VaultItem>? onOpen;
  final ValueChanged<VaultItem>? onToggleSelection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 2.0;
        final columns = constraints.maxWidth >= 760
            ? 5
            : constraints.maxWidth >= 520
            ? 4
            : 3;
        final tileSize =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final item in items)
                  SizedBox.square(
                    dimension: tileSize,
                    child: _TimelineThumbnail(
                      controller: controller,
                      item: item,
                      selected: selectedIds.contains(item.id),
                      selecting: selectedIds.isNotEmpty,
                      onOpen: onOpen,
                      onToggleSelection: onToggleSelection,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TimelineThumbnail extends StatelessWidget {
  const _TimelineThumbnail({
    required this.controller,
    required this.item,
    required this.selected,
    required this.selecting,
    this.onOpen,
    this.onToggleSelection,
  });

  final AppController controller;
  final VaultItem item;
  final bool selected;
  final bool selecting;
  final ValueChanged<VaultItem>? onOpen;
  final ValueChanged<VaultItem>? onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        if (selecting) {
          onToggleSelection?.call(item);
        } else if (onOpen != null) {
          onOpen!(item);
        } else {
          showViewer(context, controller, item);
        }
      },
      onLongPress: () => onToggleSelection?.call(item),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2.4 : 0.7,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: VaultPreview(item: item, controller: controller),
            ),
            if (selected)
              ColoredBox(color: scheme.primary.withValues(alpha: 0.24)),
            if (selecting)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? scheme.primary : Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 5),
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

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.item,
    required this.controller,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VaultItem item;
  final AppController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: VaultPreview(item: item, controller: controller),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  Album? _openAlbum;
  Future<List<VaultItem>>? _albumItemsFuture;
  final Set<String> _selectedAlbumIds = {};

  bool get _selectingAlbums => _selectedAlbumIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final openAlbum = _openAlbum;
    if (openAlbum != null) {
      return _AlbumDetailScreen(
        controller: widget.controller,
        album: openAlbum,
        itemsFuture: _albumItemsFuture!,
        onBack: _closeAlbum,
      );
    }

    final selectedAlbums = widget.controller.albums
        .where((album) => _selectedAlbumIds.contains(album.id))
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        children: [
          Header(
            title: _selectingAlbums
                ? '${_selectedAlbumIds.length} selected'
                : 'Albums',
            subtitle: _selectingAlbums
                ? 'Choose an action'
                : '${widget.controller.albums.length} collections',
            action: _selectingAlbums
                ? _AlbumSelectionActions(
                    onShare: () => _shareSelectedAlbums(selectedAlbums),
                    onDelete: () => _deleteSelectedAlbums(selectedAlbums),
                    onCancel: _clearAlbumSelection,
                  )
                : IconButton(
                    onPressed: () =>
                        showCreateAlbumDialog(context, widget.controller),
                    icon: const Icon(Icons.add),
                  ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: widget.controller.albums.isEmpty
                ? const EmptyState(
                    title: 'No albums yet',
                    body:
                        'Create albums for receipts, trips, and private documents.',
                  )
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: .82,
                        ),
                    itemCount: widget.controller.albums.length,
                    itemBuilder: (context, index) {
                      final album = widget.controller.albums[index];
                      final selected = _selectedAlbumIds.contains(album.id);
                      return _AlbumCard(
                        controller: widget.controller,
                        album: album,
                        selected: selected,
                        selecting: _selectingAlbums,
                        onTap: () {
                          if (_selectingAlbums) {
                            _toggleAlbumSelection(album);
                          } else {
                            _openAlbumDetail(album);
                          }
                        },
                        onLongPress: () => _toggleAlbumSelection(album),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openAlbumDetail(Album album) {
    setState(() {
      _openAlbum = album;
      _albumItemsFuture = widget.controller.loadAlbumItems(album.id);
    });
  }

  void _closeAlbum() {
    setState(() {
      _openAlbum = null;
      _albumItemsFuture = null;
    });
  }

  void _toggleAlbumSelection(Album album) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedAlbumIds.add(album.id)) {
        _selectedAlbumIds.remove(album.id);
      }
    });
  }

  void _clearAlbumSelection() {
    setState(_selectedAlbumIds.clear);
  }

  Future<void> _deleteSelectedAlbums(List<Album> selectedAlbums) async {
    if (selectedAlbums.isEmpty) return;
    final ok = await _confirmDeleteAlbums(context, selectedAlbums.length);
    if (!ok) return;
    await widget.controller.deleteAlbums(selectedAlbums);
    if (mounted) _clearAlbumSelection();
  }

  Future<void> _shareSelectedAlbums(List<Album> selectedAlbums) async {
    if (selectedAlbums.isEmpty) return;
    final byId = <String, VaultItem>{};
    for (final album in selectedAlbums) {
      final items = await widget.controller.loadAlbumItems(album.id);
      for (final item in items) {
        byId[item.id] = item;
      }
    }
    if (!mounted) return;
    await shareVaultItems(context, widget.controller, byId.values.toList());
    if (mounted) _clearAlbumSelection();
  }
}

class _AlbumSelectionActions extends StatelessWidget {
  const _AlbumSelectionActions({
    required this.onShare,
    required this.onDelete,
    required this.onCancel,
  });

  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(onPressed: onShare, icon: const Icon(Icons.ios_share)),
        IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
        IconButton(onPressed: onCancel, icon: const Icon(Icons.close)),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({
    required this.controller,
    required this.album,
    required this.selected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
  });

  final AppController controller;
  final Album album;
  final bool selected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _AlbumCoverPreview(
                      controller: controller,
                      album: album,
                      selected: selected,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text('${album.itemCount} items'),
                ],
              ),
            ),
            if (selected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    border: Border.all(color: scheme.primary, width: 2.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            if (selecting)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlbumCoverPreview extends StatelessWidget {
  const _AlbumCoverPreview({
    required this.controller,
    required this.album,
    required this.selected,
  });

  final AppController controller;
  final Album album;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (album.itemCount == 0) {
      return PlaceholderTile(
        icon: selected ? Icons.check_circle : Icons.folder_outlined,
      );
    }
    return FutureBuilder<List<VaultItem>>(
      future: controller.loadAlbumItems(album.id),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <VaultItem>[];
        if (items.isEmpty) {
          return const PlaceholderTile(icon: Icons.folder_outlined);
        }
        final previewItems = items.take(4).toList(growable: false);
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GridView.count(
            crossAxisCount: previewItems.length == 1 ? 1 : 2,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            children: [
              for (final item in previewItems)
                VaultPreview(item: item, controller: controller),
            ],
          ),
        );
      },
    );
  }
}

class _AlbumDetailScreen extends StatelessWidget {
  const _AlbumDetailScreen({
    required this.controller,
    required this.album,
    required this.itemsFuture,
    required this.onBack,
  });

  final AppController controller;
  final Album album;
  final Future<List<VaultItem>> itemsFuture;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        children: [
          Header(
            title: album.name,
            subtitle: '${album.itemCount} items',
            action: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<VaultItem>>(
              future: itemsFuture,
              builder: (context, snapshot) {
                final items = snapshot.data;
                if (items == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'Album is empty',
                    body: 'Open a photo and add it to this album.',
                  );
                }
                return GroupedTimelineGallery(
                  controller: controller,
                  items: items,
                  onOpen: (item) =>
                      showViewer(context, controller, item, items: items),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// Settings — custom-drawn, no stock icons, no emoji
// ═════════════════════════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  /// Slow shared clock that drives every idle animation on this screen.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final scheme = Theme.of(context).colorScheme;
    final currentSpec = MezgebThemes.specFor(controller.themeId);

    final sections = <Widget>[
      _GreetingCard(ambient: _ambient),
      const SizedBox(height: 20),

      const _SectionLabel('Appearance'),
      _SettingsCard(
        children: [
          _SettingsRow(
            glyph: _ThemeOrb(
              ambient: _ambient,
              a: currentSpec.primary,
              b: currentSpec.secondary,
            ),
            title: currentSpec.name,
            subtitle: currentSpec.tagline,
            showChevron: true,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ThemePickerScreen(
                    currentThemeId: controller.themeId,
                    onSelected: (id) => controller.setTheme(id),
                    warmNightEnabled: controller.warmNightEnabled,
                    onWarmNightChanged: controller.setWarmNight,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      const SizedBox(height: 20),

      const _SectionLabel('Security'),
      _SettingsCard(
        children: [
          _SettingsRow(
            glyph: _FingerprintGlyph(
              active: controller.biometricEnabled,
              color: scheme.primary,
            ),
            title: 'Biometric unlock',
            subtitle: 'Fingerprint or device authentication',
            trailing: Switch(
              value: controller.biometricEnabled,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                controller.setBiometricEnabled(v);
              },
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              controller.setBiometricEnabled(!controller.biometricEnabled);
            },
          ),
          const _RowDivider(),
          _SettingsRow(
            glyph: _PinDotsGlyph(ambient: _ambient, color: scheme.primary),
            title: 'Change PIN',
            subtitle: 'Update your fallback vault lock',
            showChevron: true,
            onTap: () {
              HapticFeedback.selectionClick();
              showChangePinDialog(context, controller);
            },
          ),
          const _RowDivider(),
          _SettingsRow(
            glyph: _PhotoSlashGlyph(
              slashed: controller.deleteOriginals,
              color: scheme.primary,
            ),
            title: 'Delete original after import',
            subtitle: 'Off by default — gallery files stay safe',
            trailing: Switch(
              value: controller.deleteOriginals,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                controller.setDeleteOriginals(v);
              },
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              controller.setDeleteOriginals(!controller.deleteOriginals);
            },
          ),
        ],
      ),
      const SizedBox(height: 20),

      const _SectionLabel('Vault'),
      Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Stored items',
              child: _CountUpText(
                value: controller.items.length,
                style: _statValueStyle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Storage used',
              child: Text(
                formatBytes(controller.storageUsedBytes),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _statValueStyle,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _StatCard(
              label: '13 months of the year',
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CustomPaint(
                      painter: _MonthRingPainter(
                        color: scheme.primary,
                        ambient: _ambient,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ኢትዮጵያዊ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _statValueStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: _StatCard(
              label: 'No network calls',
              child: Text(
                'Offline',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _statValueStyle,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 28),

      Center(
        child: Column(
          children: [
            Text(
              'መዝገብ',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'ለእስክንድር በፍቅር የተሰራ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 96),
      itemCount: sections.length,
      itemBuilder: (context, index) =>
          _StaggeredEntry(index: index, child: sections[index]),
    );
  }
}

const _statValueStyle = TextStyle(
  fontWeight: FontWeight.w800,
  fontSize: 17,
  letterSpacing: -0.2,
);

// ─── Greeting card — woven-line painter + orbiting monogram ─────────────

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.ambient});
  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ethToday = EthiopianCalendar.formatDate(DateTime.now());
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.14),
              scheme.primary.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.20)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            // flowing woven lines in the background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: ambient,
                builder: (context, _) => CustomPaint(
                  painter: _WeavePainter(
                    color: scheme.primary,
                    progress: ambient.value,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Row(
                children: [
                  // monogram with orbiting comet ring
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: AnimatedBuilder(
                      animation: ambient,
                      builder: (context, child) => CustomPaint(
                        painter: _MonogramOrbitPainter(
                          color: scheme.primary,
                          progress: ambient.value,
                        ),
                        child: child,
                      ),
                      child: Center(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                scheme.primary,
                                Color.lerp(
                                  scheme.primary,
                                  scheme.secondary,
                                  0.6,
                                )!,
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'እ',
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ሰላም እስክንድር',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ethToday,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three drifting sine curves — quiet, woven texture.
class _WeavePainter extends CustomPainter {
  const _WeavePainter({required this.color, required this.progress});
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * math.pi * 2;
    for (var line = 0; line < 3; line++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = color.withValues(alpha: 0.07 + line * 0.02);
      final path = Path();
      final baseY = size.height * (0.30 + line * 0.22);
      final amp = 7.0 + line * 3;
      final phase = t * (0.6 + line * 0.25) + line * 1.9;
      for (double x = -10; x <= size.width + 10; x += 4) {
        final y = baseY + math.sin(x / 46 + phase) * amp;
        if (x <= -10 + 0.5) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeavePainter old) =>
      old.progress != progress || old.color != color;
}

/// Thin ring with a comet dot orbiting the monogram.
class _MonogramOrbitPainter extends CustomPainter {
  const _MonogramOrbitPainter({required this.color, required this.progress});
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.48;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = color.withValues(alpha: 0.22),
    );
    final angle = progress * math.pi * 2 * 2.0;
    for (var i = 4; i >= 1; i--) {
      final a = angle - i * 0.12;
      canvas.drawCircle(
        Offset(
          center.dx + radius * math.cos(a),
          center.dy + radius * math.sin(a),
        ),
        2.2 - i * 0.35,
        Paint()..color = color.withValues(alpha: 0.32 - i * 0.06),
      );
    }
    canvas.drawCircle(
      Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      ),
      2.6,
      Paint()..color = color.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _MonogramOrbitPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Custom glyphs (leading elements) ───────────────────────────────────

const double _glyphBox = 38;

/// Breathing dual-tone orb painted from the current theme's own colors.
class _ThemeOrb extends StatelessWidget {
  const _ThemeOrb({required this.ambient, required this.a, required this.b});
  final Animation<double> ambient;
  final Color a;
  final Color b;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _glyphBox,
      height: _glyphBox,
      child: AnimatedBuilder(
        animation: ambient,
        builder: (context, _) {
          final t = math.sin(ambient.value * math.pi * 2 * 2.2) * 0.5 + 0.5;
          return Center(
            child: Container(
              width: 26 + t * 2.5,
              height: 26 + t * 2.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  transform: GradientRotation(
                    ambient.value * math.pi * 2 * 0.5,
                  ),
                  colors: [a, b, a],
                ),
                boxShadow: [
                  BoxShadow(
                    color: a.withValues(alpha: 0.30 + t * 0.12),
                    blurRadius: 10 + t * 5,
                    spreadRadius: -1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Fingerprint drawn as concentric arcs; arcs draw in/out when toggled.
class _FingerprintGlyph extends StatelessWidget {
  const _FingerprintGlyph({required this.active, required this.color});
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _glyphBox,
      height: _glyphBox,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: active ? 1 : 0.35),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          painter: _FingerprintPainter(color: color, progress: t),
        ),
      ),
    );
  }
}

class _FingerprintPainter extends CustomPainter {
  const _FingerprintPainter({required this.color, required this.progress});
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.25 + progress * 0.75);
    // three nested arcs opening upward, sweep grows with progress
    for (var i = 0; i < 3; i++) {
      final radius = 5.0 + i * 4.5;
      final sweep = (math.pi * 1.25) * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 - sweep / 2,
        sweep,
        false,
        paint,
      );
    }
    // core dot
    canvas.drawCircle(
      center,
      1.6,
      Paint()..color = color.withValues(alpha: 0.35 + progress * 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant _FingerprintPainter old) =>
      old.progress != progress || old.color != color;
}

/// Four PIN dots; a highlight travels across them on the ambient clock.
class _PinDotsGlyph extends StatelessWidget {
  const _PinDotsGlyph({required this.ambient, required this.color});
  final Animation<double> ambient;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _glyphBox,
      height: _glyphBox,
      child: AnimatedBuilder(
        animation: ambient,
        builder: (context, _) => CustomPaint(
          painter: _PinDotsPainter(color: color, progress: ambient.value),
        ),
      ),
    );
  }
}

class _PinDotsPainter extends CustomPainter {
  const _PinDotsPainter({required this.color, required this.progress});
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    const count = 4;
    final active = (progress * 3.2 * count) % (count + 2); // pause at end
    for (var i = 0; i < count; i++) {
      final cx = size.width * (0.18 + i * 0.21);
      final isLit = i <= active && active < count + 0.5;
      canvas.drawCircle(
        Offset(cx, cy),
        isLit ? 3.0 : 2.4,
        Paint()..color = color.withValues(alpha: isLit ? 0.9 : 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PinDotsPainter old) =>
      old.progress != progress || old.color != color;
}

/// Photo frame glyph; a slash draws across it when "delete original" is on.
class _PhotoSlashGlyph extends StatelessWidget {
  const _PhotoSlashGlyph({required this.slashed, required this.color});
  final bool slashed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _glyphBox,
      height: _glyphBox,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: slashed ? 1 : 0),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => CustomPaint(
          painter: _PhotoSlashPainter(color: color, slash: t),
        ),
      ),
    );
  }
}

class _PhotoSlashPainter extends CustomPainter {
  const _PhotoSlashPainter({required this.color, required this.slash});
  final Color color;
  final double slash;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.85);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 22,
        height: 18,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, stroke);
    // mountains inside the frame
    final r = rect.outerRect.deflate(3);
    final mountains = Path()
      ..moveTo(r.left, r.bottom)
      ..lineTo(r.left + r.width * 0.36, r.top + r.height * 0.38)
      ..lineTo(r.left + r.width * 0.56, r.bottom - r.height * 0.30)
      ..lineTo(r.left + r.width * 0.74, r.top + r.height * 0.52)
      ..lineTo(r.right, r.bottom);
    canvas.drawPath(
      mountains,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.55),
    );
    // animated slash
    if (slash > 0) {
      final o = rect.outerRect.inflate(3);
      final start = Offset(o.left, o.top);
      final end = Offset(o.right, o.bottom);
      final current = Offset.lerp(start, end, slash)!;
      canvas.drawLine(
        start,
        current,
        Paint()
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PhotoSlashPainter old) =>
      old.slash != slash || old.color != color;
}

/// 13 dots in a ring — the 13 Ethiopian months; one dot glows in sequence.
class _MonthRingPainter extends CustomPainter {
  _MonthRingPainter({required this.color, required this.ambient})
    : super(repaint: ambient);
  final Color color;
  final Animation<double> ambient;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    const count = 13;
    final active = (ambient.value * count * 2) % count;
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (i / count) * math.pi * 2;
      final d = (i - active).abs();
      final near = math.min(d, count - d);
      final lit = (1 - (near / 2)).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        1.3 + lit * 0.9,
        Paint()..color = color.withValues(alpha: 0.25 + lit * 0.65),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MonthRingPainter old) => false;
}

// ─── Rows, cards, labels ────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.55)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 66,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.45),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.glyph,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  final Widget glyph;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            glyph,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else if (showChevron) ...[
              const SizedBox(width: 8),
              // custom chevron: two short strokes, no icon font
              SizedBox(
                width: 16,
                height: 16,
                child: CustomPaint(
                  painter: _ChevronPainter(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = color;
    final path = Path()
      ..moveTo(size.width * 0.35, size.height * 0.22)
      ..lineTo(size.width * 0.68, size.height * 0.5)
      ..lineTo(size.width * 0.35, size.height * 0.78);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter old) => old.color != color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated count-up number for stats.
class _CountUpText extends StatelessWidget {
  const _CountUpText({required this.value, required this.style});
  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => Text(
        t.round().toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}

/// Snappy staggered fade+slide entrance for settings sections.
class _StaggeredEntry extends StatelessWidget {
  const _StaggeredEntry({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 45).clamp(0, 360)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

void showCreateAlbumDialog(BuildContext context, AppController controller) {
  final input = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Create album'),
      content: TextField(
        controller: input,
        decoration: const InputDecoration(labelText: 'Album name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            controller.createAlbum(input.text);
            Navigator.pop(context);
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}

Future<Album?> chooseAlbumDialog(BuildContext context, List<Album> albums) {
  if (albums.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create an album first.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return Future.value(null);
  }
  return showDialog<Album>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add to album'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: albums.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final album = albums[index];
            return ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(
                album.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('${album.itemCount} items'),
              onTap: () => Navigator.pop(context, album),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

enum _AlbumConflictChoice { move, cancel, keepBoth }

Future<bool> addItemsToAlbumWithConflictCheck({
  required BuildContext context,
  required AppController controller,
  required List<VaultItem> items,
  required Album targetAlbum,
}) async {
  final uniqueItems = {for (final item in items) item.id: item}.values.toList();
  if (uniqueItems.isEmpty) return false;

  final conflicts = <VaultItem, List<Album>>{};
  for (final item in uniqueItems) {
    final existingAlbums = await controller.loadAlbumsForItem(item.id);
    final otherAlbums = existingAlbums
        .where((album) => album.id != targetAlbum.id)
        .toList(growable: false);
    if (otherAlbums.isNotEmpty) conflicts[item] = otherAlbums;
  }

  if (!context.mounted) return false;
  final choice = conflicts.isEmpty
      ? _AlbumConflictChoice.keepBoth
      : await _showAlbumConflictDialog(
          context,
          conflicts: conflicts,
          targetAlbum: targetAlbum,
        );

  if (choice == null || choice == _AlbumConflictChoice.cancel) return false;
  if (choice == _AlbumConflictChoice.move) {
    await controller.moveItemsToAlbum(
      itemsToMove: uniqueItems,
      albumId: targetAlbum.id,
    );
  } else {
    await controller.addItemsToAlbum(
      itemsToAdd: uniqueItems,
      albumId: targetAlbum.id,
    );
  }

  if (context.mounted) {
    showAddedToAlbumSnackBar(context, targetAlbum.name, uniqueItems.length);
  }
  return true;
}

Future<_AlbumConflictChoice?> _showAlbumConflictDialog(
  BuildContext context, {
  required Map<VaultItem, List<Album>> conflicts,
  required Album targetAlbum,
}) {
  final conflictCount = conflicts.length;
  final albumNames = conflicts.values
      .expand((albums) => albums)
      .map((album) => album.name)
      .toSet()
      .take(3)
      .join(', ');
  return showDialog<_AlbumConflictChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        conflictCount == 1
            ? 'Photo already in album'
            : '$conflictCount photos already in albums',
      ),
      content: Text(
        conflictCount == 1
            ? "This photo is already in '$albumNames'. Move it to '${targetAlbum.name}'?"
            : "Some selected photos are already in '$albumNames'. Move them to '${targetAlbum.name}'?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _AlbumConflictChoice.cancel),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, _AlbumConflictChoice.keepBoth),
          child: const Text('Keep in both'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _AlbumConflictChoice.move),
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}

void showAddedToAlbumSnackBar(
  BuildContext context,
  String albumName,
  int count,
) {
  final label = count == 1 ? 'photo' : 'photos';
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text("Added $count $label to '$albumName'"),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
      ),
    );
}

Future<void> shareVaultItems(
  BuildContext context,
  AppController controller,
  List<VaultItem> items,
) async {
  if (items.isEmpty) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final tempDir = await getTemporaryDirectory();
    final files = <XFile>[];
    for (final item in items) {
      final bytes = await controller.previewBytes(item);
      if (bytes == null) continue;
      final safeName = item.displayName.isEmpty
          ? 'mezgeb_${item.id}.jpg'
          : item.displayName;
      final tempFile = File(p.join(tempDir.path, safeName));
      await tempFile.writeAsBytes(bytes, flush: true);
      files.add(XFile(tempFile.path, mimeType: item.mimeType));
    }
    if (files.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not decrypt selected photos to share.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await SharePlus.instance.share(ShareParams(files: files));
    Future.delayed(const Duration(seconds: 30), () async {
      for (final file in files) {
        try {
          final tempFile = File(file.path);
          if (await tempFile.exists()) await tempFile.delete();
        } catch (_) {}
      }
    });
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Share failed: $e'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

void showChangePinDialog(BuildContext context, AppController controller) {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final canSave =
            current.text.length >= 4 &&
            next.text.length >= 4 &&
            next.text == confirm.text;
        return AlertDialog(
          title: const Text('Change PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SecureField(
                controller: current,
                label: 'Current PIN',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              SecureField(
                controller: next,
                label: 'New PIN',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              SecureField(
                controller: confirm,
                label: 'Confirm new PIN',
                onChanged: (_) => setState(() {}),
              ),
              if (controller.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  controller.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: canSave
                  ? () async {
                      if (await controller.changePin(current.text, next.text) &&
                          context.mounted) {
                        Navigator.pop(context);
                      } else {
                        setState(() {});
                      }
                    }
                  : null,
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════
// Photo viewer (modern gallery-style)
// ═════════════════════════════════════════════════════════════════════════

void showViewer(
  BuildContext context,
  AppController controller,
  VaultItem item, {
  List<VaultItem>? items,
  Set<String> selectedIds = const {},
  ValueChanged<Set<String>>? onSelectionChanged,
}) {
  final viewerItems = items ?? controller.photos;
  if (viewerItems.isEmpty) return;
  final initialIndex = viewerItems.indexWhere((entry) => entry.id == item.id);
  final pageController = PageController(
    initialPage: initialIndex < 0 ? 0 : initialIndex,
  );
  var currentIndex = initialIndex < 0 ? 0 : initialIndex;
  final viewerSelectedIds = {...selectedIds};
  var detailSelecting = viewerSelectedIds.isNotEmpty;
  var tapCount = 0;
  Timer? tapTimer;
  controller.selectItem(viewerItems[currentIndex]);

  showDialog<void>(
    context: context,
    useSafeArea: false,
    barrierColor: Colors.black,
    builder: (dialogContext) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: StatefulBuilder(
        builder: (context, setState) {
          final visibleItem = viewerItems[currentIndex];
          final ethDate = EthiopianCalendar.formatDate(visibleItem.capturedAt);
          final time = _clockString(visibleItem.capturedAt);

          void publishSelection() {
            onSelectionChanged?.call({...viewerSelectedIds});
          }

          void toggleDetailSelection(VaultItem target) {
            HapticFeedback.selectionClick();
            setState(() {
              detailSelecting = true;
              if (!viewerSelectedIds.add(target.id)) {
                viewerSelectedIds.remove(target.id);
                detailSelecting = viewerSelectedIds.isNotEmpty;
              }
            });
            publishSelection();
          }

          void exitSelectionToTimeline() {
            tapTimer?.cancel();
            publishSelection();
            controller.selectItem(null);
            Navigator.pop(context);
          }

          void handlePhotoTap() {
            tapCount++;
            tapTimer?.cancel();
            tapTimer = Timer(const Duration(milliseconds: 360), () {
              final count = tapCount;
              tapCount = 0;
              if (!context.mounted) return;
              if (count >= 4 && detailSelecting) {
                exitSelectionToTimeline();
              } else if (count >= 3) {
                toggleDetailSelection(visibleItem);
              } else if (count == 2 && detailSelecting) {
                toggleDetailSelection(visibleItem);
              }
            });
          }

          Future<void> handleShare() async {
            HapticFeedback.selectionClick();
            final messenger = ScaffoldMessenger.of(context);
            try {
              final bytes = await controller.previewBytes(visibleItem);
              if (bytes == null) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Could not decrypt this file to share.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              final tempDir = await getTemporaryDirectory();
              final safeName = visibleItem.displayName.isEmpty
                  ? 'mezgeb_${visibleItem.id}.jpg'
                  : visibleItem.displayName;
              final tempFile = File(p.join(tempDir.path, safeName));
              await tempFile.writeAsBytes(bytes, flush: true);
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(tempFile.path, mimeType: visibleItem.mimeType)],
                ),
              );
              // Best-effort cleanup — OS may still need the file briefly.
              Future.delayed(const Duration(seconds: 30), () async {
                try {
                  if (await tempFile.exists()) await tempFile.delete();
                } catch (_) {}
              });
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Share failed: $e'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }

          Future<void> handleDelete() async {
            HapticFeedback.selectionClick();
            final ok = await _confirmDelete(context);
            if (!ok) return;
            controller.selectItem(visibleItem);
            await controller.deleteSelectedItem();
            if (context.mounted) Navigator.pop(context);
          }

          Future<void> handleAddToAlbum(
            String albumId,
            String albumName,
          ) async {
            HapticFeedback.selectionClick();
            final targetAlbum = Album(
              id: albumId,
              name: albumName,
              createdAt: DateTime.now(),
              itemCount: 0,
            );
            await addItemsToAlbumWithConflictCheck(
              context: context,
              controller: controller,
              items: [visibleItem],
              targetAlbum: targetAlbum,
            );
          }

          return Stack(
            children: [
              // ─── Photo pager ────────────────────────────────────────
              Positioned.fill(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: viewerItems.length,
                  onPageChanged: (index) {
                    setState(() => currentIndex = index);
                    controller.selectItem(viewerItems[index]);
                  },
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: handlePhotoTap,
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 5,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VaultPreview(
                                item: viewerItems[index],
                                controller: controller,
                                fit: BoxFit.contain,
                              ),
                              if (detailSelecting &&
                                  viewerSelectedIds.contains(
                                    viewerItems[index].id,
                                  ))
                                Positioned(
                                  top: 92,
                                  right: 20,
                                  child: _ViewerSelectionBadge(
                                    selectedCount: viewerSelectedIds.length,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Top overlay (date + controls) ──────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 22),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _ViewerButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () {
                              controller.selectItem(null);
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ethDate,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  time,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _ViewerButton(
                            icon: Icons.ios_share_rounded,
                            onTap: handleShare,
                          ),
                          const SizedBox(width: 8),
                          _ViewerButton(
                            icon: Icons.delete_outline_rounded,
                            onTap: handleDelete,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Bottom overlay (metadata + album chips) ────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 26, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            visibleItem.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentIndex + 1} of ${viewerItems.length}   ·   ${formatBytes(visibleItem.sizeBytes)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (controller.albums.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 36,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: controller.albums.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (context, i) {
                                  final album = controller.albums[i];
                                  return Material(
                                    color: Colors.white.withValues(alpha: 0.13),
                                    borderRadius: BorderRadius.circular(20),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () => handleAddToAlbum(
                                        album.id,
                                        album.name,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.add_rounded,
                                              size: 14,
                                              color: Colors.white70,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              album.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  ).then((_) {
    tapTimer?.cancel();
    controller.selectItem(null);
  });
}

/// Small circular translucent button used in the photo viewer top bar.
class _ViewerButton extends StatelessWidget {
  const _ViewerButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ViewerSelectionBadge extends StatelessWidget {
  const _ViewerSelectionBadge({required this.selectedCount});

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              '$selectedCount',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _clockString(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

Future<bool> _confirmDelete(BuildContext context) async {
  return _confirmDeletePhotos(context, 1);
}

Future<bool> _confirmDeletePhotos(BuildContext context, int count) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(count == 1 ? 'Delete photo?' : 'Delete $count photos?'),
      content: Text(
        count == 1
            ? 'This will remove the encrypted photo from your vault. This cannot be undone.'
            : 'This will remove the selected encrypted photos from your vault. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> _confirmDeleteAlbums(BuildContext context, int count) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(count == 1 ? 'Delete album?' : 'Delete $count albums?'),
      content: Text(
        count == 1
            ? 'This deletes the album grouping only. Photos stay in your vault.'
            : 'This deletes the selected album groupings only. Photos stay in your vault.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
