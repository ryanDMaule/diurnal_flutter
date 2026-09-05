// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../services/bookmark_service.dart';
import '../services/archive_access.dart';
import '../services/edition_service.dart';
import '../services/haptic_service.dart';
import '../services/entitlement_service.dart';
import '../theme/interface_theme.dart';
import '../widgets/entitlement_scope.dart';
import 'pro_screen.dart';
import 'saved_publication_screen.dart';

class ArchiveCalendarScreen extends StatefulWidget {
  ArchiveCalendarScreen({
    required this.publications,
    required this.bookmarkService,
    required this.editionService,
    this.entitlementController,
    super.key,
  });

  final List<DailyPublication> publications;
  final BookmarkService bookmarkService;
  final EditionService editionService;
  final EntitlementController? entitlementController;

  @override
  State<ArchiveCalendarScreen> createState() => _ArchiveCalendarScreenState();
}

class _ArchiveCalendarScreenState extends State<ArchiveCalendarScreen> {
  late final Map<int, DailyPublication> _publicationsByDate;
  late final DateTime _earliestMonth;
  late final DateTime _newestMonth;
  late DateTime _visibleMonth;
  int? _selectedDateKey;

  @override
  void initState() {
    super.initState();
    _publicationsByDate = {
      for (final publication in widget.publications)
        _dateKey(publication.publicationDate!): publication,
    };
    final dates =
        widget.publications
            .map((publication) => publication.publicationDate!)
            .toList()
          ..sort();
    _earliestMonth = _monthOnly(dates.first);
    _newestMonth = _monthOnly(dates.last);
    _visibleMonth = _newestMonth;
  }

  bool get _canGoPrevious => _visibleMonth.isAfter(_earliestMonth);
  bool get _canGoNext => _visibleMonth.isBefore(_newestMonth);

  EntitlementController? _entitlementController() =>
      widget.entitlementController ??
      EntitlementScope.maybeControllerOf(context);

  bool _isAccessible(DailyPublication publication) =>
      ArchiveAccess.isAccessible(
        publication,
        widget.publications,
        isPro: _entitlementController()?.isPro ?? false,
      );

  void _showPreviousMonth() {
    if (!_canGoPrevious) return;
    setState(() {
      _visibleMonth = DateTime.utc(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _showNextMonth() {
    if (!_canGoNext) return;
    setState(() {
      _visibleMonth = DateTime.utc(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  Future<void> _openPublication(DailyPublication publication) async {
    final dateKey = _dateKey(publication.publicationDate!);
    if (_selectedDateKey != dateKey) {
      _selectedDateKey = dateKey;
      HapticService.selection(
        enabled:
            InterfaceThemeScope.maybeControllerOf(
              context,
            )?.settings.hapticFeedbackEnabled ??
            true,
      );
    }
    if (!_isAccessible(publication)) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ProScreen(
            entitlementController: _entitlementController(),
            backTooltip: 'Back to Calendar',
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
          backTooltip: 'Back to Calendar',
          initiallyBookmarked: isBookmarked,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime.utc(_visibleMonth.year, _visibleMonth.month);
    final leadingBlankDays = firstDay.weekday - DateTime.monday;
    final daysInMonth = DateTime.utc(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    return Scaffold(
      backgroundColor: InterfaceThemeScope.maybePaletteOf(context).background,
      body: InterfaceSafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back to Archive',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    CupertinoIcons.back,
                    color: InterfaceThemeScope.maybePaletteOf(context).primary,
                    size: 26,
                  ),
                ),
              ),
              SizedBox(height: 42),
              Row(
                children: [
                  _MonthButton(
                    buttonKey: Key('previous-month'),
                    tooltip: 'Previous month',
                    icon: CupertinoIcons.chevron_left,
                    onPressed: _canGoPrevious ? _showPreviousMonth : null,
                  ),
                  Expanded(
                    child: Text(
                      _monthHeading(_visibleMonth),
                      key: Key('calendar-month-heading'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: InterfaceThemeScope.maybePaletteOf(
                          context,
                        ).primary,
                        fontFamily: 'NotoSerifJP',
                        fontSize: 25,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  _MonthButton(
                    buttonKey: Key('next-month'),
                    tooltip: 'Next month',
                    icon: CupertinoIcons.chevron_right,
                    onPressed: _canGoNext ? _showNextMonth : null,
                  ),
                ],
              ),
              SizedBox(height: 36),
              Row(
                children: [
                  for (final weekday in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                    Expanded(
                      child: Text(
                        weekday,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: InterfaceThemeScope.maybePaletteOf(
                            context,
                          ).secondary,
                          fontFamily: 'Figtree',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              GridView.builder(
                key: Key('archive-calendar-grid'),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: leadingBlankDays + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingBlankDays) return SizedBox.shrink();
                  final day = index - leadingBlankDays + 1;
                  final date = DateTime.utc(
                    _visibleMonth.year,
                    _visibleMonth.month,
                    day,
                  );
                  final publication = _publicationsByDate[_dateKey(date)];
                  final isLocked =
                      publication != null && !_isAccessible(publication);
                  return _CalendarDay(
                    date: date,
                    publication: publication,
                    isLocked: isLocked,
                    onTap: publication == null
                        ? null
                        : () => _openPublication(publication),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  _MonthButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final Key buttonKey;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      color: InterfaceThemeScope.maybePaletteOf(context).accent,
      disabledColor: InterfaceThemeScope.maybePaletteOf(
        context,
      ).primary.withValues(alpha: 0.2),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  _CalendarDay({
    required this.date,
    required this.publication,
    required this.isLocked,
    required this.onTap,
  });

  final DateTime date;
  final DailyPublication? publication;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dateId = _dateId(date);
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${date.day}',
            style: TextStyle(
              color: InterfaceThemeScope.maybePaletteOf(
                context,
              ).primary.withValues(alpha: publication == null ? 0.32 : 0.9),
              fontFamily: 'Figtree',
              fontSize: 15,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 5),
          SizedBox(
            height: 4,
            child: publication == null
                ? null
                : Container(
                    key: Key('publication-indicator-$dateId'),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: InterfaceThemeScope.maybePaletteOf(
                        context,
                      ).accent.withValues(alpha: isLocked ? 0.38 : 1),
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ],
      ),
    );

    if (publication == null) {
      return ExcludeSemantics(
        child: SizedBox(key: Key('calendar-day-$dateId'), child: content),
      );
    }

    return Semantics(
      button: true,
      label:
          '${date.day} ${_spokenMonth(date.month)} ${date.year}, '
          '${publication!.word}'
          '${isLocked ? ', locked, Diurnus Pro' : ''}',
      child: InkWell(
        key: Key('calendar-day-$dateId'),
        onTap: onTap,
        customBorder: CircleBorder(),
        child: content,
      ),
    );
  }
}

DateTime _monthOnly(DateTime date) => DateTime.utc(date.year, date.month);

int _dateKey(DateTime date) => date.year * 10000 + date.month * 100 + date.day;

String _dateId(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _monthHeading(DateTime date) =>
    '${_spokenMonth(date.month).toUpperCase()} ${date.year}';

String _spokenMonth(int month) => [
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
][month - 1];
