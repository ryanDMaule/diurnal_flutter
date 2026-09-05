// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../services/archive_access.dart';
import '../services/bookmark_service.dart';
import '../services/edition_service.dart';
import '../services/entitlement_service.dart';
import '../services/publication_api_service.dart';
import '../theme/interface_theme.dart';
import '../widgets/diurnus_loading_state.dart';
import '../widgets/entitlement_scope.dart';
import 'archive_calendar_screen.dart';
import 'pro_screen.dart';
import 'saved_publication_screen.dart';

List<DailyPublication> sortArchivePublications(
  Iterable<DailyPublication> publications,
) {
  final sorted = publications.toList();
  sorted.sort((a, b) => b.publicationDate!.compareTo(a.publicationDate!));
  return sorted;
}

String archiveMonthHeading(DateTime date) {
  final months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

class ArchiveScreen extends StatefulWidget {
  ArchiveScreen({
    PublicationApiService? apiService,
    BookmarkService? bookmarkService,
    EditionService? editionService,
    this.entitlementController,
    super.key,
  }) : apiService = apiService ?? PublicationApiService(),
       bookmarkService = bookmarkService ?? BookmarkService(),
       editionService = editionService ?? EditionService();

  final PublicationApiService apiService;
  final BookmarkService bookmarkService;
  final EditionService editionService;
  final EntitlementController? entitlementController;

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<DailyPublication> _publications = [];
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadPublications();
  }

  Future<void> _loadPublications() async {
    final loadingTimer = Stopwatch()..start();
    Future<void> waitForMinimumDuration() async {
      final remainingMilliseconds = 850 - loadingTimer.elapsedMilliseconds;
      if (remainingMilliseconds > 0) {
        await Future<void>.delayed(
          Duration(milliseconds: remainingMilliseconds),
        );
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final publications = await widget.apiService.fetchPublications();
      await waitForMinimumDuration();
      if (!mounted) return;
      setState(() {
        _publications = sortArchivePublications(publications);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading Archive: $error');
      await waitForMinimumDuration();
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  EntitlementController? _entitlementController() =>
      widget.entitlementController ??
      EntitlementScope.maybeControllerOf(context);

  bool _isAccessible(DailyPublication publication) =>
      ArchiveAccess.isAccessible(
        publication,
        _publications,
        isPro: _entitlementController()?.isPro ?? false,
      );

  Future<void> _openPublication(DailyPublication publication) async {
    if (!_isAccessible(publication)) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ProScreen(
            entitlementController: _entitlementController(),
            backTooltip: 'Back to Archive',
          ),
        ),
      );
      return;
    }
    final isBookmarked = await widget.bookmarkService.isSaved(publication.id);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SavedPublicationScreen(
          publication: publication,
          bookmarkService: widget.bookmarkService,
          editionService: widget.editionService,
          backTooltip: 'Back to Archive',
          initiallyBookmarked: isBookmarked,
        ),
      ),
    );
  }

  Future<void> _openCalendar() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ArchiveCalendarScreen(
          publications: _publications,
          bookmarkService: widget.bookmarkService,
          editionService: widget.editionService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InterfaceThemeScope.maybePaletteOf(context).background,
      body: InterfaceSafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: 'Back to menu',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  CupertinoIcons.back,
                  color: InterfaceThemeScope.maybePaletteOf(context).primary,
                  size: 26,
                ),
              ),
              SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Archive',
                          style: TextStyle(
                            color: InterfaceThemeScope.maybePaletteOf(
                              context,
                            ).primary,
                            fontFamily: 'NotoSerifJP',
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Every word, every day',
                          style: TextStyle(
                            color: InterfaceThemeScope.maybePaletteOf(
                              context,
                            ).primary.withValues(alpha: 0.56),
                            fontFamily: 'Figtree',
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isLoading && _error == null && _publications.isNotEmpty)
                    IconButton(
                      key: Key('open-archive-calendar'),
                      tooltip: 'Open Archive calendar',
                      onPressed: _openCalendar,
                      constraints: BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: Icon(
                        CupertinoIcons.calendar,
                        color: InterfaceThemeScope.maybePaletteOf(
                          context,
                        ).accent,
                        size: 24,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 30),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_isLoading) {
      return DiurnusLoadingState(
        title: 'Assembling the library…',
        message: 'Gathering your published words.',
      );
    }
    if (_error != null) {
      return _ArchiveMessage(
        title: 'Archive unavailable',
        message: 'Please check your connection and try again.',
        action: TextButton(
          onPressed: _loadPublications,
          style: TextButton.styleFrom(
            foregroundColor: InterfaceThemeScope.maybePaletteOf(context).accent,
          ),
          child: Text('Retry'),
        ),
      );
    }
    if (_publications.isEmpty) {
      return _ArchiveMessage(
        title: 'Nothing here yet',
        message: 'Published words will appear here as they become available.',
      );
    }

    final accessibleIds = ArchiveAccess.accessiblePublicationIds(
      _publications,
      isPro: _entitlementController()?.isPro ?? false,
    );

    final sections = <String, List<DailyPublication>>{};
    for (final publication in _publications) {
      final heading = archiveMonthHeading(publication.publicationDate!);
      sections.putIfAbsent(heading, () => []).add(publication);
    }

    return ListView(
      key: Key('archive-list'),
      padding: EdgeInsets.only(bottom: 24),
      children: [
        for (final section in sections.entries) ...[
          Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              section.key,
              key: Key('archive-month-${section.key}'),
              style: TextStyle(
                color: InterfaceThemeScope.maybePaletteOf(context).accent,
                fontFamily: 'Figtree',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.4,
              ),
            ),
          ),
          for (final publication in section.value)
            _ArchiveRow(
              publication: publication,
              isLocked: !accessibleIds.contains(publication.id),
              onTap: () => _openPublication(publication),
            ),
          SizedBox(height: 22),
        ],
      ],
    );
  }
}

class _ArchiveRow extends StatelessWidget {
  _ArchiveRow({
    required this.publication,
    required this.isLocked,
    required this.onTap,
  });

  static double height = 118;

  final DailyPublication publication;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = publication.publicationDate!;
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]}';

    return SizedBox(
      key: Key('archive-row-${publication.id}'),
      height: height,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: InterfaceThemeScope.maybePaletteOf(context).divider,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 66,
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    color: InterfaceThemeScope.maybePaletteOf(context).accent,
                    fontFamily: 'Figtree',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publication.word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: InterfaceThemeScope.maybePaletteOf(
                          context,
                        ).primary.withValues(alpha: isLocked ? 0.64 : 1),
                        fontFamily: 'NotoSerifJP',
                        fontSize: 23,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      publication.type.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: InterfaceThemeScope.maybePaletteOf(
                          context,
                        ).primary.withValues(alpha: 0.5),
                        fontFamily: 'Figtree',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 5),
                    if (isLocked)
                      Row(
                        key: Key('archive-lock-${publication.id}'),
                        children: [
                          Icon(
                            CupertinoIcons.lock,
                            size: 12,
                            color: InterfaceThemeScope.maybePaletteOf(
                              context,
                            ).accent.withValues(alpha: 0.72),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Diurnus Pro',
                            style: TextStyle(
                              color: InterfaceThemeScope.maybePaletteOf(
                                context,
                              ).accent.withValues(alpha: 0.72),
                              fontFamily: 'Figtree',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        publication.definition,
                        key: Key('archive-definition-${publication.id}'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: InterfaceThemeScope.maybePaletteOf(
                            context,
                          ).primary.withValues(alpha: 0.58),
                          fontFamily: 'Figtree',
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          height: 1.25,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveMessage extends StatelessWidget {
  _ArchiveMessage({required this.title, required this.message, this.action});

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: InterfaceThemeScope.maybePaletteOf(context).primary,
              fontFamily: 'NotoSerifJP',
              fontSize: 25,
            ),
          ),
          SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: InterfaceThemeScope.maybePaletteOf(
                context,
              ).primary.withValues(alpha: 0.55),
              fontFamily: 'Figtree',
              fontSize: 14,
              fontWeight: FontWeight.w300,
              height: 1.45,
            ),
          ),
          if (action != null) ...[SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}
