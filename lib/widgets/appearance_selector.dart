import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/daily_publication.dart';
import '../models/edition.dart';
import '../models/edition_access_policy.dart';
import '../theme/interface_theme.dart';
import '../theme/motion_preferences.dart';
import 'edition_background.dart';
import 'publication_view.dart';

class AppearanceSelector extends StatefulWidget {
  const AppearanceSelector({
    required this.selectedColor,
    required this.selectedEdition,
    required this.isPro,
    required this.onColorSelected,
    required this.onEditionSelected,
    required this.onLockedEditionSelected,
    this.previewPublication,
    this.previewIsBookmarked = false,
    super.key,
  });

  final InterfaceColor selectedColor;
  final Edition selectedEdition;
  final bool isPro;
  final ValueChanged<InterfaceColor> onColorSelected;
  final ValueChanged<Edition> onEditionSelected;
  final ValueChanged<Edition> onLockedEditionSelected;
  final DailyPublication? previewPublication;
  final bool previewIsBookmarked;

  @override
  State<AppearanceSelector> createState() => _AppearanceSelectorState();
}

class _AppearanceSelectorState extends State<AppearanceSelector> {
  OverlayEntry? _previewOverlay;
  GlobalKey<_EditionFullScreenPreviewState>? _previewKey;

  @override
  void dispose() {
    _removePreviewImmediately();
    super.dispose();
  }

  void _showPreview(Edition edition, InterfacePalette palette) {
    _removePreviewImmediately();
    final reduceAnimations = reduceAnimationsOf(context);
    final key = GlobalKey<_EditionFullScreenPreviewState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: _EditionFullScreenPreview(
          key: key,
          publication:
              widget.previewPublication ?? DailyPublication.localFallback,
          edition: edition,
          interfacePalette: palette,
          isBookmarked: widget.previewIsBookmarked,
          reduceAnimations: reduceAnimations,
          onDismissed: () => _removePreviewEntry(entry),
        ),
      ),
    );
    _previewKey = key;
    _previewOverlay = entry;
    Overlay.of(context).insert(entry);
  }

  void _hidePreview() {
    final entry = _previewOverlay;
    if (entry == null) return;
    final state = _previewKey?.currentState;
    if (state == null) {
      _removePreviewEntry(entry);
    } else {
      state.dismiss();
    }
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

  @override
  Widget build(BuildContext context) {
    final palette = InterfacePalette.forColor(widget.selectedColor);
    final effectiveEdition = EditionAccessPolicy.effectiveFor(
      widget.selectedEdition,
      isPro: widget.isPro,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ThemeColorSelector(
          selected: widget.selectedColor,
          palette: palette,
          onSelected: widget.onColorSelected,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                'Tap to select · Hold to preview',
                style: TextStyle(
                  color: palette.secondary,
                  fontFamily: 'Figtree',
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.visibility_outlined, color: palette.accent, size: 19),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 12.0;
            final cardWidth = (constraints.maxWidth - (spacing * 2)) / 3;
            final previewHeight = cardWidth / 0.58;
            return GridView.builder(
              key: const Key('appearance-edition-grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                  isPro: widget.isPro,
                );
                return _EditionCard(
                  edition: previewEdition,
                  palette: palette,
                  selected: effectiveEdition.id == edition.id,
                  locked: locked,
                  onTap: () => locked
                      ? widget.onLockedEditionSelected(edition)
                      : widget.onEditionSelected(edition),
                  onPreviewStart: () => _showPreview(previewEdition, palette),
                  onPreviewEnd: _hidePreview,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class ThemeColorSelector extends StatelessWidget {
  const ThemeColorSelector({
    required this.selected,
    required this.palette,
    required this.onSelected,
    super.key,
  });

  final InterfaceColor selected;
  final InterfacePalette palette;
  final ValueChanged<InterfaceColor> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
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
                ),
              ),
              const SizedBox(height: 2),
              Text(
                interfaceColorLabel(selected),
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
          if (color != InterfaceColor.values.first) const SizedBox(width: 6),
          Semantics(
            button: true,
            selected: color == selected,
            label: interfaceColorLabel(color),
            child: GestureDetector(
              key: Key('interface-color-${color.name}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(color),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: AnimatedContainer(
                  duration: motionDurationOf(
                    context,
                    const Duration(milliseconds: 150),
                  ),
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

String interfaceColorLabel(InterfaceColor color) => switch (color) {
  InterfaceColor.evergreen => 'Evergreen',
  InterfaceColor.charcoal => 'Charcoal',
  InterfaceColor.navy => 'Navy',
  InterfaceColor.oxblood => 'Oxblood',
  InterfaceColor.slate => 'Slate',
  InterfaceColor.paper => 'Paper',
};

class _EditionFullScreenPreview extends StatefulWidget {
  const _EditionFullScreenPreview({
    required this.publication,
    required this.edition,
    required this.interfacePalette,
    required this.isBookmarked,
    required this.reduceAnimations,
    required this.onDismissed,
    super.key,
  });

  final DailyPublication publication;
  final Edition edition;
  final InterfacePalette interfacePalette;
  final bool isBookmarked;
  final bool reduceAnimations;
  final VoidCallback onDismissed;

  @override
  State<_EditionFullScreenPreview> createState() =>
      _EditionFullScreenPreviewState();
}

class _EditionFullScreenPreviewState extends State<_EditionFullScreenPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
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
    )..forward();
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
    opacity: CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    ),
    child: AbsorbPointer(
      child: ExcludeSemantics(
        child: PublicationView(
          publication: widget.publication,
          edition: widget.edition,
          interfacePaletteOverride: widget.interfacePalette,
          isBookmarked: widget.isBookmarked,
          onBookmarkToggle: null,
        ),
      ),
    ),
  );
}

class _EditionCard extends StatelessWidget {
  const _EditionCard({
    required this.edition,
    required this.palette,
    required this.selected,
    required this.onTap,
    required this.onPreviewStart,
    required this.onPreviewEnd,
    required this.locked,
  });

  final Edition edition;
  final InterfacePalette palette;
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
                TapGestureRecognizer.new,
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
                duration: motionDurationOf(
                  context,
                  const Duration(milliseconds: 150),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? edition.accentColor
                        : palette.divider.withValues(alpha: 0.42),
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
            const SizedBox(height: 7),
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
                          ? palette.primary
                          : palette.primary.withValues(alpha: 0.6),
                      fontFamily: 'NotoSerifJP',
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (locked) ...[
                  const SizedBox(width: 5),
                  Container(
                    key: Key('edition-lock-${edition.id}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: palette.accent.withValues(alpha: 0.7),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'PRO',
                      style: TextStyle(
                        color: palette.accent,
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(width: 32, height: 2, color: edition.accentColor),
        const SizedBox(height: 6),
        Text(
          'Aa',
          style: TextStyle(
            color: edition.primaryTextColor,
            fontFamily: 'NotoSerifJP',
            fontSize: 27,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: edition.accentColor.withValues(alpha: 0.7)),
        const SizedBox(height: 7),
        _PreviewLine(color: edition.secondaryTextColor, widthFactor: 0.92),
        const SizedBox(height: 4),
        _PreviewLine(color: edition.mutedTextColor, widthFactor: 0.72),
      ],
    ),
  );
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.color, required this.widthFactor});

  final Color color;
  final double widthFactor;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: widthFactor,
    alignment: Alignment.centerLeft,
    child: Container(height: 1, color: color.withValues(alpha: 0.55)),
  );
}
