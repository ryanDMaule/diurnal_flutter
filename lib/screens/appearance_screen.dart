// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/edition.dart';
import '../models/edition_access_policy.dart';
import '../services/edition_service.dart';
import '../services/widget_sync_service.dart';
import '../theme/interface_theme.dart';
import '../widgets/edition_background.dart';
import '../widgets/entitlement_scope.dart';
import 'pro_screen.dart';

class AppearanceScreen extends StatefulWidget {
  AppearanceScreen({
    EditionService? editionService,
    WidgetSyncService? widgetSyncService,
    super.key,
  }) : editionService = editionService ?? EditionService(),
       widgetSyncService = widgetSyncService ?? WidgetSyncService();

  final EditionService editionService;
  final WidgetSyncService widgetSyncService;

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  Edition selectedEdition = Editions.library;

  @override
  void initState() {
    super.initState();
    _restoreSelection();
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

class _EditionCard extends StatelessWidget {
  _EditionCard({
    required this.edition,
    required this.selected,
    required this.onTap,
    required this.locked,
  });

  final Edition edition;
  final bool selected;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${edition.name} Edition',
      child: GestureDetector(
        key: Key('edition-${edition.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
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
            if (color != InterfaceColor.values.first) SizedBox(width: 8),
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
  InterfaceColor.paper => 'Paper',
};
