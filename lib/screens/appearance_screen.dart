// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/daily_publication.dart';
import '../models/edition.dart';
import '../models/edition_access_policy.dart';
import '../services/bookmark_service.dart';
import '../services/edition_service.dart';
import '../services/haptic_service.dart';
import '../services/widget_sync_service.dart';
import '../theme/interface_theme.dart';
import '../widgets/edition_background.dart';
import '../widgets/entitlement_scope.dart';
import '../widgets/publication_view.dart';
import 'pro_screen.dart';

class AppearanceScreen extends StatefulWidget {
  AppearanceScreen({
    EditionService? editionService,
    BookmarkService? bookmarkService,
    this.previewPublication,
    WidgetSyncService? widgetSyncService,
    super.key,
  }) : editionService = editionService ?? EditionService(),
       bookmarkService = bookmarkService ?? BookmarkService(),
       widgetSyncService = widgetSyncService ?? WidgetSyncService();

  final EditionService editionService;
  final BookmarkService bookmarkService;
  final WidgetSyncService widgetSyncService;
  final DailyPublication? previewPublication;

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  Edition selectedEdition = Editions.library;
  bool _previewIsBookmarked = false;
  OverlayEntry? _previewOverlay;
  GlobalKey<_EditionFullScreenPreviewState>? _previewKey;

  @override
  void initState() {
    super.initState();
    _restoreSelection();
    _restorePreviewBookmarkState();
  }

  @override
  void dispose() {
    _removePreviewImmediately();
    super.dispose();
  }

  Future<void> _restorePreviewBookmarkState() async {
    try {
      final isBookmarked = await widget.bookmarkService.isSaved(
        widget.previewPublication?.id,
      );
      if (mounted) setState(() => _previewIsBookmarked = isBookmarked);
    } catch (error) {
      debugPrint('Error loading preview bookmark state: $error');
    }
  }

  void _showPreview(Edition edition) {
    _removePreviewImmediately();
    final overlay = Overlay.of(context);
    final reduceAnimations =
        InterfaceThemeScope.controllerOf(context).settings.reduceAnimations ||
        MediaQuery.of(context).disableAnimations;
    final key = GlobalKey<_EditionFullScreenPreviewState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: _EditionFullScreenPreview(
          key: key,
          publication:
              widget.previewPublication ?? DailyPublication.localFallback,
          edition: edition,
          isBookmarked: _previewIsBookmarked,
          reduceAnimations: reduceAnimations,
          onDismissed: () => _removePreviewEntry(entry),
        ),
      ),
    );
    _previewKey = key;
    _previewOverlay = entry;
    overlay.insert(entry);
  }

  void _hidePreview() {
    final entry = _previewOverlay;
    if (entry == null) return;
    final state = _previewKey?.currentState;
    if (state == null) {
      _removePreviewEntry(entry);
      return;
    }
    state.dismiss();
  }

  void _removePreviewEntry(OverlayEntry entry) {
    if (_previewOverlay != entry) return;
    entry.remove();
    _previewOverlay = null;
    _previewKey = null;
  }

  void _removePreviewImmediately() {
    _previewOverlay?.remove();
    _previewOverlay = null;
    _previewKey = null;
  }

  Future<void> _restoreSelection() async {
    final edition = await widget.editionService.loadSelectedEdition();
    if (mounted) setState(() => selectedEdition = edition);
  }

  Future<void> _select(Edition edition, {required bool isPro}) async {
    if (!EditionAccessPolicy.canSelect(edition, isPro: isPro)) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ProScreen(backTooltip: 'Back to Appearance'),
        ),
      );
      return;
    }
    if (selectedEdition.id == edition.id) return;
    HapticService.selection(
      enabled:
          InterfaceThemeScope.controllerOf(
            context,
          ).settings.hapticFeedbackEnabled,
    );
    setState(() => selectedEdition = edition);
    try {
      await widget.editionService.selectEdition(edition);
    } catch (error) {
      debugPrint('Error saving Edition: $error');
      await _restoreSelection();
      return;
    }
    try {
      await widget.widgetSyncService.syncEdition(
        EditionAccessPolicy.effectiveFor(edition, isPro: isPro),
      );
    } catch (error) {
      debugPrint('Error updating widget Edition: $error');
    }
  }

  Future<void> _selectInterfaceColor(InterfaceColor color) async {
    final controller = InterfaceThemeScope.controllerOf(context);
    if (controller.settings.interfaceColor == color) return;
    HapticService.selection(
      enabled: controller.settings.hapticFeedbackEnabled,
    );
    try {
      await controller.update(
        controller.settings.copyWith(interfaceColor: color),
      );
    } catch (error) {
      debugPrint('Error saving Theme Colour: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = EntitlementScope.maybeControllerOf(context)?.isPro ?? false;
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    final effectiveEdition = EditionAccessPolicy.effectiveFor(
      selectedEdition,
      isPro: isPro,
    );
    return Scaffold(
      backgroundColor: InterfaceThemeScope.maybePaletteOf(context).background,
      body: InterfaceSafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 22),
              child: SizedBox(
                height: 74,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Back to menu',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          CupertinoIcons.back,
                          color: InterfaceThemeScope.maybePaletteOf(
                            context,
                          ).primary,
                          size: 26,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Appearance',
                          style: TextStyle(
                            color: InterfaceThemeScope.maybePaletteOf(
                              context,
                            ).primary,
                            fontFamily: 'NotoSerifJP',
                            fontSize: 31,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Choose your Diurnus Edition',
                          style: TextStyle(
                            color: InterfaceThemeScope.maybePaletteOf(
                              context,
                            ).secondary,
                            fontFamily: 'Figtree',
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                key: Key('appearance-edition-list'),
                padding: EdgeInsets.fromLTRB(24, 0, 24, 30),
                children: [
                  _ThemeColorSelector(
                    selected: InterfaceThemeScope.controllerOf(
                      context,
                    ).settings.interfaceColor,
                    onSelected: _selectInterfaceColor,
                  ),
                  SizedBox(height: 22),
                  Row(
                    children: [
                      Text(
                        'Tap to select · Hold to preview',
                        style: TextStyle(
                          color: palette.secondary,
                          fontFamily: 'Figtree',
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.visibility_outlined,
                        color: palette.accent,
                        size: 19,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 12.0;
                      final cardWidth =
                          (constraints.maxWidth - (spacing * 2)) / 3;
                      final previewHeight = cardWidth / 0.58;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: Editions.all.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: 18,
                          mainAxisExtent: previewHeight + 32,
                        ),
                        itemBuilder: (context, index) {
                          final edition = Editions.all[index];
                          final previewEdition = resolveInterfaceColorEdition(
                            edition,
                            palette,
                          );
                          final locked = !EditionAccessPolicy.canSelect(
                            edition,
                            isPro: isPro,
                          );
                          return _EditionCard(
                            edition: previewEdition,
                            selected: effectiveEdition.id == edition.id,
                            locked: locked,
                            onTap: () => _select(edition, isPro: isPro),
                            onPreviewStart: () => _showPreview(previewEdition),
                            onPreviewEnd: _hidePreview,
                          );
                        },
                      );
                    },
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

class _EditionFullScreenPreview extends StatefulWidget {
  const _EditionFullScreenPreview({
    required this.publication,
    required this.edition,
    required this.isBookmarked,
    required this.reduceAnimations,
    required this.onDismissed,
    super.key,
  });

  final DailyPublication publication;
  final Edition edition;
  final bool isBookmarked;
  final bool reduceAnimations;
  final VoidCallback onDismissed;

  @override
  State<_EditionFullScreenPreview> createState() =>
      _EditionFullScreenPreviewState();
}

class _EditionFullScreenPreviewState
    extends State<_EditionFullScreenPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.reduceAnimations
          ? Duration.zero
          : const Duration(milliseconds: 240),
      reverseDuration: widget.reduceAnimations
          ? Duration.zero
          : const Duration(milliseconds: 120),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _controller.forward();
  }

  Future<void> dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: AbsorbPointer(
      child: ExcludeSemantics(
        child: PublicationView(
          publication: widget.publication,
          edition: widget.edition,
          isBookmarked: widget.isBookmarked,
          onBookmarkToggle: null,
        ),
      ),
    ),
  );
}

class _EditionCard extends StatelessWidget {
  _EditionCard({
    required this.edition,
    required this.selected,
    required this.onTap,
    required this.onPreviewStart,
    required this.onPreviewEnd,
    required this.locked,
  });

  final Edition edition;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onPreviewStart;
  final VoidCallback onPreviewEnd;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${edition.name} Edition',
      child: RawGestureDetector(
        key: Key('edition-${edition.id}'),
        behavior: HitTestBehavior.opaque,
        gestures: {
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                () => TapGestureRecognizer(),
                (recognizer) => recognizer.onTap = onTap,
              ),
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(
                  duration: const Duration(milliseconds: 275),
                ),
                (recognizer) {
                  recognizer.onLongPressStart = (_) => onPreviewStart();
                  recognizer.onLongPressEnd = (_) => onPreviewEnd();
                  recognizer.onLongPressCancel = onPreviewEnd;
                },
              ),
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 0.58,
              child: AnimatedContainer(
                key: Key('edition-selection-${edition.id}'),
                duration: Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? edition.accentColor
                        : InterfaceThemeScope.maybePaletteOf(
                            context,
                          ).divider.withValues(alpha: 0.42),
                    width: selected ? 1.25 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.75),
                  child: EditionBackground(
                    edition: edition,
                    child: _EditionPreviewContent(edition: edition),
                  ),
                ),
              ),
            ),
            SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    edition.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? InterfaceThemeScope.maybePaletteOf(context).primary
                          : InterfaceThemeScope.maybePaletteOf(
                              context,
                            ).primary.withValues(alpha: 0.6),
                      fontFamily: 'NotoSerifJP',
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (locked) ...[
                  SizedBox(width: 5),
                  Container(
                    key: Key('edition-lock-${edition.id}'),
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: InterfaceThemeScope.maybePaletteOf(
                          context,
                        ).accent.withValues(alpha: 0.7),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'PRO',
                      style: TextStyle(
                        color: InterfaceThemeScope.maybePaletteOf(context).accent,
                        fontFamily: 'Figtree',
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditionPreviewContent extends StatelessWidget {
  const _EditionPreviewContent({required this.edition});

  final Edition edition;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 12, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(width: 32, height: 2, color: edition.accentColor),
          SizedBox(height: 6),
          Text(
            'Aa',
            style: TextStyle(
              color: edition.primaryTextColor,
              fontFamily: 'NotoSerifJP',
              fontSize: 27,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 8),
          Container(height: 1, color: edition.accentColor.withValues(alpha: 0.7)),
          SizedBox(height: 7),
          _PreviewLine(color: edition.secondaryTextColor, widthFactor: 0.92),
          SizedBox(height: 4),
          _PreviewLine(color: edition.mutedTextColor, widthFactor: 0.72),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.color, required this.widthFactor});

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: widthFactor,
    alignment: Alignment.centerLeft,
    child: Container(
      height: 1,
      color: color.withValues(alpha: 0.55),
    ),
  );
}

class _ThemeColorSelector extends StatelessWidget {
  const _ThemeColorSelector({
    required this.selected,
    required this.onSelected,
  });

  final InterfaceColor selected;
  final ValueChanged<InterfaceColor> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    return Container(
      padding: EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.7),
        border: Border.all(color: palette.divider.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Colour',
                  style: TextStyle(
                    color: palette.secondary,
                    fontFamily: 'Figtree',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _interfaceColorLabel(selected),
                  style: TextStyle(
                    color: palette.primary,
                    fontFamily: 'NotoSerifJP',
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          for (final color in InterfaceColor.values) ...[
            if (color != InterfaceColor.values.first) SizedBox(width: 6),
            Semantics(
              button: true,
              selected: color == selected,
              label: _interfaceColorLabel(color),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(color),
                child: Padding(
                  padding: EdgeInsets.all(3),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 150),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: InterfacePalette.forColor(color).background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: color == selected
                            ? palette.accent
                            : palette.divider.withValues(alpha: 0.5),
                        width: color == selected ? 1.5 : 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _interfaceColorLabel(InterfaceColor color) => switch (color) {
  InterfaceColor.evergreen => 'Evergreen',
  InterfaceColor.charcoal => 'Charcoal',
  InterfaceColor.navy => 'Navy',
  InterfaceColor.oxblood => 'Oxblood',
  InterfaceColor.slate => 'Slate',
  InterfaceColor.paper => 'Paper',
};
