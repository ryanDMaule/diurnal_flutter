import 'dart:async';

import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../models/edition.dart';
import '../models/edition_access_policy.dart';
import '../services/bookmark_service.dart';
import '../services/edition_service.dart';
import '../services/haptic_service.dart';
import '../services/publication_api_service.dart';
import '../services/widget_sync_service.dart';
import '../theme/interface_theme.dart';
import '../widgets/morphing_menu_button.dart';
import '../widgets/publication_view.dart';
import '../widgets/entitlement_scope.dart';
import 'menu_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    this.initialPublication,
    this.apiService,
    this.widgetSyncService,
    this.now,
    super.key,
  });

  final Future<TodayPublicationLoad>? initialPublication;
  final PublicationApiService? apiService;
  final WidgetSyncService? widgetSyncService;
  final DateTime Function()? now;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  final BookmarkService _bookmarkService = BookmarkService();
  final EditionService _editionService = EditionService();
  late final WidgetSyncService _widgetSyncService;
  late final PublicationApiService _apiService;
  late final DateTime Function() _now;
  Future<void>? _activeLoad;
  Timer? _dateRolloverTimer;
  late DateTime _observedDate;
  DateTime? _lastAutomaticRefresh;
  bool _initialPublicationConsumed = false;
  DailyPublication publication = DailyPublication.localFallback;
  Edition edition = Editions.library;
  bool isLoading = true;
  bool isOffline = false;
  bool isBookmarked = false;
  bool isBookmarkUpdating = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? PublicationApiService();
    _widgetSyncService = widget.widgetSyncService ?? WidgetSyncService();
    _now = widget.now ?? DateTime.now;
    _observedDate = _dateOnly(_now());
    WidgetsBinding.instance.addObserver(this);
    _scheduleDateRollover();
    _restoreEditionState();
    _loadPublication();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateRolloverTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshAfterResume());
    }
  }

  Future<void> _loadPublication({bool showLoading = false}) {
    final activeLoad = _activeLoad;
    if (activeLoad != null) return activeLoad;
    final load = _performPublicationLoad(showLoading: showLoading);
    _activeLoad = load;
    return load.whenComplete(() {
      if (identical(_activeLoad, load)) _activeLoad = null;
    });
  }

  Future<void> _performPublicationLoad({required bool showLoading}) async {
    if (showLoading && mounted) setState(() => isLoading = true);
    final initialPublication = widget.initialPublication;
    final Future<TodayPublicationLoad> request;
    if (!_initialPublicationConsumed && initialPublication != null) {
      _initialPublicationConsumed = true;
      request = initialPublication;
    } else {
      request = _apiService.loadTodayPublication();
    }
    try {
      final result = await request;
      if (!mounted) return;
      setState(() {
        publication = result.publication;
        isLoading = false;
        isOffline = result.isOffline;
        isBookmarked = false;
      });
      await _restoreBookmarkState(result.publication);
      await _widgetSyncService.syncPublication(result.publication);
    } catch (error) {
      debugPrint('Error loading Today publication: $error');
      if (mounted) {
        setState(() {
          isLoading = false;
          isOffline = true;
        });
      }
    }
  }

  Future<void> _refreshAfterResume() async {
    final now = _now();
    final date = _dateOnly(now);
    final dateChanged = date != _observedDate;
    final recentlyRefreshed =
        _lastAutomaticRefresh != null &&
        now.difference(_lastAutomaticRefresh!) < const Duration(seconds: 30);
    if (!dateChanged && !isOffline && recentlyRefreshed) return;
    _observedDate = date;
    _lastAutomaticRefresh = now;
    await _loadPublication();
    _scheduleDateRollover();
  }

  void _scheduleDateRollover() {
    _dateRolloverTimer?.cancel();
    final now = _now();
    final nextDate = DateTime(now.year, now.month, now.day + 1);
    _dateRolloverTimer = Timer(nextDate.difference(now), () {
      _observedDate = _dateOnly(_now());
      _lastAutomaticRefresh = _now();
      unawaited(_loadPublication().whenComplete(_scheduleDateRollover));
    });
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  Widget build(BuildContext context) {
    final effectiveEdition = EditionAccessPolicy.effectiveFor(
      edition,
      isPro: EntitlementScope.maybeControllerOf(context)?.isPro ?? false,
    );
    return PublicationView(
      publication: publication,
      edition: effectiveEdition,
      isLoading: isLoading,
      isOffline: isOffline,
      isBookmarked: isBookmarked,
      isBookmarkUpdating: isBookmarkUpdating,
      onBookmarkToggle: publication.id == null ? null : _toggleBookmark,
      onRefresh: _loadPublication,
      topRightControl: MorphingMenuButton(
        isOpen: false,
        color: effectiveEdition.primaryTextColor,
        tooltip: 'Open menu',
        onPressed: _openMenu,
      ),
    );
  }

  Future<void> _restoreBookmarkState(DailyPublication current) async {
    try {
      final saved = await _bookmarkService.isSaved(current.id);
      if (!mounted || publication.id != current.id) return;
      setState(() => isBookmarked = saved);
    } catch (error) {
      debugPrint('Error loading bookmark state: $error');
    }
  }

  Future<void> _restoreEditionState() async {
    try {
      final selectedEdition = await _editionService.loadSelectedEdition();
      if (mounted) setState(() => edition = selectedEdition);
    } catch (error) {
      debugPrint('Error loading Edition: $error');
    }
  }

  Future<void> _toggleBookmark() async {
    final current = publication;
    final id = current.id;
    if (id == null || isBookmarkUpdating) return;
    final wasBookmarked = isBookmarked;
    setState(() {
      isBookmarked = !wasBookmarked;
      isBookmarkUpdating = true;
    });
    try {
      if (wasBookmarked) {
        await _bookmarkService.remove(id);
        if (mounted) {
          HapticService.selection(
            enabled:
                InterfaceThemeScope.maybeControllerOf(
                  context,
                )?.settings.hapticFeedbackEnabled ??
                true,
          );
        }
      } else {
        await _bookmarkService.save(current);
        if (mounted) {
          HapticService.confirmation(
            enabled:
                InterfaceThemeScope.maybeControllerOf(
                  context,
                )?.settings.hapticFeedbackEnabled ??
                true,
          );
        }
      }
    } catch (error) {
      debugPrint('Error updating bookmark: $error');
      if (mounted && publication.id == id) {
        setState(() => isBookmarked = wasBookmarked);
      }
    } finally {
      if (mounted && publication.id == id) {
        setState(() => isBookmarkUpdating = false);
      }
    }
  }

  Future<void> _openMenu() async {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 450),
        reverseTransitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) => MenuScreen(
          currentPublication: publication,
          bookmarkService: _bookmarkService,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
                reverseCurve: Curves.easeIn,
              ),
              child: child,
            ),
      ),
    );
    if (!mounted) return;
    await _restoreBookmarkState(publication);
    await _restoreEditionState();
  }
}

Future<TodayPublicationLoad> loadTodayPublication() =>
    PublicationApiService().loadTodayPublication();
