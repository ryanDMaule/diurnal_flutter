import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_settings.dart';
import '../models/daily_publication.dart';
import '../models/edition.dart';
import '../theme/interface_theme.dart';
import 'edition_background.dart';

class PublicationView extends StatefulWidget {
  const PublicationView({
    required this.publication,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    this.edition = Editions.library,
    this.isBookmarkUpdating = false,
    this.isLoading = false,
    this.isOffline = false,
    this.topLeftControl,
    this.topRightControl,
    super.key,
  });

  final DailyPublication publication;
  final Edition edition;
  final bool isBookmarked;
  final bool isBookmarkUpdating;
  final bool isLoading;
  final bool isOffline;
  final VoidCallback? onBookmarkToggle;
  final Widget? topLeftControl;
  final Widget? topRightControl;

  @override
  State<PublicationView> createState() => _PublicationViewState();
}

class _PublicationViewState extends State<PublicationView> {
  String selectedTab = 'definition';

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _content({required Color accent}) {
    final style = TextStyle(
      fontSize: 16,
      height: 1.6,
      color: widget.edition.primaryTextColor,
      fontFamily: 'Figtree',
      fontWeight: FontWeight.w300,
    );
    switch (selectedTab) {
      case 'usage':
        return Text(
          widget.publication.usage,
          key: const ValueKey('usage'),
          textAlign: TextAlign.start,
          style: style,
        );
      case 'synonyms':
        return Column(
          key: const ValueKey('synonyms'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final synonym in widget.publication.synonyms)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: CustomPaint(
                        size: const Size(10, 8),
                        painter: _SynonymMarkerPainter(accent),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(child: Text(synonym, style: style)),
                  ],
                ),
              ),
          ],
        );
      default:
        return Text(
          widget.publication.definition,
          key: const ValueKey('definition'),
          textAlign: TextAlign.start,
          style: style,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final publication = widget.publication;
    final interfaceSettings = InterfaceThemeScope.maybeControllerOf(
      context,
    )?.settings;
    final edition = resolveInterfaceColorEdition(
      widget.edition,
      InterfaceThemeScope.maybePaletteOf(context),
    );
    final useTactileType =
        widget.edition.id == Editions.evergreen.id &&
        (interfaceSettings?.textureEnabled ?? true);
    final usesPaperTreatment =
        interfaceSettings?.interfaceColor == InterfaceColor.paper;
    final primary = edition.primaryTextColor;
    final secondary = edition.secondaryTextColor;
    final muted = edition.mutedTextColor;
    final accent = edition.accentColor;
    final iconBrightness = edition.systemUiIconBrightness;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final footerDate = publication.publicationDate == null
        ? 'Date unavailable'
        : _formatDate(publication.publicationDate!);
    final footerSequence = publication.sequence == null
        ? '#—'
        : '#${publication.sequence}';

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: iconBrightness,
          statusBarBrightness: iconBrightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: iconBrightness,
          systemNavigationBarDividerColor: Colors.transparent,
          systemStatusBarContrastEnforced: false,
          systemNavigationBarContrastEnforced: false,
        ),
        child: EditionBackground(
          edition: edition,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      SizedBox(height: screenHeight * 0.4),
                      if (widget.isOffline)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '⚠️ Offline mode — showing default word',
                            style: TextStyle(
                              color: primary,
                              fontSize: 14,
                              fontFamily: 'Figtree',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      Text(
                        publication.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: primary,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1,
                          shadows: _tactileTextShadows(
                            enabled: useTactileType,
                            paper: usesPaperTreatment,
                            supporting: true,
                          ),
                        ),
                      ),
                      Text(
                        publication.word,
                        style: TextStyle(
                          fontSize: 54,
                          color: primary,
                          fontFamily: 'NotoSerifJP',
                          fontWeight: FontWeight.w400,
                          shadows: _tactileTextShadows(
                            enabled: useTactileType,
                            paper: usesPaperTreatment,
                          ),
                        ),
                      ),
                      Text(
                        publication.phonetic,
                        style: TextStyle(
                          fontSize: 16,
                          color: secondary,
                          fontFamily: 'Figtree',
                          fontWeight: FontWeight.w400,
                          shadows: _tactileTextShadows(
                            enabled: useTactileType,
                            paper: usesPaperTreatment,
                            supporting: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          for (final label in [
                            'definition',
                            'usage',
                            'synonyms',
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 28),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    setState(() => selectedTab = label),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        opacity: 1,
                                        child: Text(
                                          '${label[0].toUpperCase()}${label.substring(1)}',
                                          style: TextStyle(
                                            color: selectedTab == label
                                                ? primary
                                                : muted,
                                            fontFamily: 'Figtree',
                                            fontSize: 16,
                                            fontWeight: selectedTab == label
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        width: selectedTab == label ? 22 : 0,
                                        height: 2,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation.drive(
                            CurveTween(
                              curve: const Interval(
                                0.5,
                                1,
                                curve: Curves.easeOut,
                              ),
                            ),
                          ),
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.98, end: 1).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutBack,
                              ),
                            ),
                            child: child,
                          ),
                        ),
                        layoutBuilder: (currentChild, previousChildren) =>
                            Stack(
                              alignment: Alignment.topLeft,
                              children: [
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            ),
                        child: _content(accent: accent),
                      ),
                        const SizedBox(height: 72),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 18,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(footerDate, style: _footerStyle(accent)),
                        ),
                        Semantics(
                          button: true,
                          enabled:
                              widget.onBookmarkToggle != null &&
                              !widget.isBookmarkUpdating,
                          label: widget.isBookmarked
                              ? 'Remove bookmark'
                              : 'Save bookmark',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.isBookmarkUpdating
                                ? null
                                : widget.onBookmarkToggle,
                            child: SizedBox.square(
                              dimension: 30,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 130),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                child: Icon(
                                  widget.isBookmarked
                                      ? CupertinoIcons.bookmark_fill
                                      : CupertinoIcons.bookmark,
                                  key: ValueKey(widget.isBookmarked),
                                  size: 30,
                                  color: widget.isBookmarked
                                      ? accent
                                      : muted.withValues(
                                          alpha: widget.onBookmarkToggle == null
                                              ? 0.45
                                              : 1,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            footerSequence,
                            style: _footerStyle(accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.topLeftControl != null)
                    Positioned(top: 20, left: 4, child: widget.topLeftControl!),
                  if (widget.topRightControl != null)
                    Positioned(
                      top: 20,
                      right: 4,
                      child: widget.topRightControl!,
                    ),
                  if (widget.isLoading)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(primary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _footerStyle(Color accent) => TextStyle(
  color: accent.withValues(alpha: 0.8),
  fontFamily: 'Figtree',
  fontSize: 14,
  fontWeight: FontWeight.w300,
);

List<Shadow>? _tactileTextShadows({
  required bool enabled,
  required bool paper,
  bool supporting = false,
}) {
  if (!enabled) return null;
  if (paper) {
    return supporting
        ? const [
            Shadow(
              color: Color(0x1D000000),
              offset: Offset(0.6, 0.6),
              blurRadius: 0.25,
            ),
            Shadow(
              color: Color(0x1CFFFFFF),
              offset: Offset(-0.5, -0.5),
              blurRadius: 0.2,
            ),
          ]
        : const [
            Shadow(
              color: Color(0x38000000),
              offset: Offset(0.9, 1.0),
              blurRadius: 0.4,
            ),
            Shadow(
              color: Color(0x35FFFFFF),
              offset: Offset(-0.8, -0.8),
              blurRadius: 0.25,
            ),
          ];
  }
  return supporting
      ? const [
          Shadow(
            color: Color(0x26000000),
            offset: Offset(0.7, 0.7),
            blurRadius: 0.3,
          ),
          Shadow(
            color: Color(0x14FFFFFF),
            offset: Offset(-0.6, -0.6),
            blurRadius: 0.2,
          ),
        ]
      : const [
          Shadow(
            color: Color(0x52000000),
            offset: Offset(1.2, 1.3),
            blurRadius: 0.5,
          ),
          Shadow(
            color: Color(0x2BFFFFFF),
            offset: Offset(-1.0, -1.1),
            blurRadius: 0.3,
          ),
        ];
}

class _SynonymMarkerPainter extends CustomPainter {
  const _SynonymMarkerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width * 0.65, 0)
      ..lineTo(size.width, size.height * 0.44)
      ..lineTo(size.width * 0.58, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SynonymMarkerPainter oldDelegate) =>
      oldDelegate.color != color;
}
