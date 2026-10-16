import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../models/daily_publication.dart';
import '../models/edition.dart';
import '../models/edition_access_policy.dart';
import '../services/bookmark_service.dart';
import '../services/edition_service.dart';
import '../services/haptic_service.dart';
import '../services/publication_api_service.dart';
import '../services/sound_effects_service.dart';
import '../services/widget_sync_service.dart';
import '../theme/interface_theme.dart';
import '../theme/motion_preferences.dart';
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
    this.soundEffectsService,
    this.showMenuShimmer = false,
    this.onMenuShimmerConsumed,
    super.key,
  });

  final Future<TodayPublicationLoad>? initialPublication;
  final PublicationApiService? apiService;
  final WidgetSyncService? widgetSyncService;
  final DateTime Function()? now;
  final SoundEffectsService? soundEffectsService;
  final bool showMenuShimmer;
  final Future<void> Function()? onMenuShimmerConsumed;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final BookmarkService _bookmarkService = BookmarkService();
  final EditionService _editionService = EditionService();
  late final WidgetSyncService _widgetSyncService;
  late final PublicationApiService _apiService;
  late final DateTime Function() _now;
  late final SoundEffectsService _soundEffectsService;
  Future<void>? _activeLoad;
  Timer? _dateRolloverTimer;
  Timer? _menuDiscoveryTimer;
  Timer? _errorNotificationTimer;
  late DateTime _observedDate;
  DateTime? _lastAutomaticRefresh;
  bool _initialPublicationConsumed = false;
  DailyPublication publication = DailyPublication.localFallback;
  Edition edition = Editions.library;
  bool isLoading = true;
  bool isOffline = false;
  bool isBookmarked = false;
  bool isBookmarkUpdating = false;
  bool _menuDiscoveryCompleted = false;
  bool _appIsActive = true;
  _TodayErrorStatus? _errorStatus;
  bool _showErrorNotification = false;
  late final AnimationController _menuShimmerController;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? PublicationApiService();
    _widgetSyncService = widget.widgetSyncService ?? WidgetSyncService();
    _now = widget.now ?? DateTime.now;
    _soundEffectsService =
        widget.soundEffectsService ?? SoundEffectsService.instance;
    _menuShimmerController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1800),
        )..addListener(() {
          if (mounted) setState(() {});
        });
    _observedDate = _dateOnly(_now());
    WidgetsBinding.instance.addObserver(this);
    _scheduleDateRollover();
    _restoreEditionState();
    _loadPublication();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scheduleMenuDiscovery(const Duration(seconds: 3)),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dateRolloverTimer?.cancel();
    _menuDiscoveryTimer?.cancel();
    _errorNotificationTimer?.cancel();
    _menuShimmerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appIsActive = true;
      unawaited(_refreshAfterResume());
      _scheduleMenuDiscovery(const Duration(seconds: 3));
    } else {
      _appIsActive = false;
      _menuDiscoveryTimer?.cancel();
      _menuShimmerController.stop();
      _menuShimmerController.reset();
    }
  }

  Future<void> _loadPublication({
    bool showLoading = false,
    bool manual = false,
    bool preferCurrentDateCache = false,
  }) async {
    final activeLoad = _activeLoad;
    if (activeLoad != null) {
      await activeLoad;
      if (manual && mounted && _errorStatus != null) {
        _showCurrentErrorNotification();
      }
      return;
    }
    final load = _performPublicationLoad(
      showLoading: showLoading,
      manual: manual,
      preferCurrentDateCache: preferCurrentDateCache,
    );
    _activeLoad = load;
    await load.whenComplete(() {
      if (identical(_activeLoad, load)) _activeLoad = null;
    });
  }

  Future<void> _performPublicationLoad({
    required bool showLoading,
    required bool manual,
    required bool preferCurrentDateCache,
  }) async {
    if (showLoading && mounted) setState(() => isLoading = true);
    final initialPublication = widget.initialPublication;
    final Future<TodayPublicationLoad> request;
    if (!_initialPublicationConsumed && initialPublication != null) {
      _initialPublicationConsumed = true;
      request = initialPublication;
    } else {
      request = _apiService.loadTodayPublication(
        preferCurrentDateCache: preferCurrentDateCache,
      );
    }
    try {
      final result = await request;
      if (!mounted) return;
      final status = result.isOffline
          ? _TodayErrorStatus.fromLoad(result)
          : null;
      final hadUnresolvedError = _errorStatus != null;
      setState(() {
        publication = result.publication;
        isLoading = false;
        isOffline = result.isOffline;
        isBookmarked = false;
        _errorStatus = status;
        _showErrorNotification =
            status != null && (manual || !hadUnresolvedError);
      });
      if (status == null) {
        _errorNotificationTimer?.cancel();
      } else if (_showErrorNotification) {
        _scheduleErrorNotificationDismissal();
      }
      await _restoreBookmarkState(result.publication);
      await _widgetSyncService.syncPublication(result.publication);
    } catch (error) {
      debugPrint('Error loading Today publication: $error');
      if (mounted) {
        final hadUnresolvedError = _errorStatus != null;
        setState(() {
          isLoading = false;
          isOffline = true;
          _errorStatus = const _TodayErrorStatus(
            category: 'Refresh',
            explanation:
                'Diurnus could not refresh the daily publication. The current word remains available.',
            supportDetails:
                'Publication refresh failed. Category: Refresh. The current word remains visible.',
            bannerMessage: 'Unable to refresh — showing saved word',
          );
          if (publication.id == null) {
            _errorStatus = const _TodayErrorStatus(
              category: 'Refresh',
              explanation:
                  'Diurnus could not refresh the daily publication. The default word remains available.',
              supportDetails:
                  'Publication refresh failed. Category: Refresh. Displaying the default word.',
              bannerMessage: 'Unable to refresh — showing default word',
            );
          }
          _showErrorNotification = manual || !hadUnresolvedError;
        });
        if (_showErrorNotification) _scheduleErrorNotificationDismissal();
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
    await _loadPublication(preferCurrentDateCache: !dateChanged);
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
      onRefresh: () => _loadPublication(manual: true),
      topLeftControl: _errorStatus == null
          ? null
          : _TodayErrorButton(
              color: effectiveEdition.accentColor,
              onPressed: _showErrorDetails,
            ),
      topNotification: _showErrorNotification && _errorStatus != null
          ? _TodayErrorBanner(
              key: const Key('today-error-notification'),
              message: _errorStatus!.bannerMessage,
              edition: effectiveEdition,
            )
          : null,
      topRightControl: MorphingMenuButton(
        isOpen: false,
        color: effectiveEdition.primaryTextColor,
        tooltip: 'Open menu',
        onPressed: _openMenu,
        highlight: _menuShimmerHighlight,
        highlightColor: effectiveEdition.accentColor,
      ),
    );
  }

  void _scheduleErrorNotificationDismissal() {
    _errorNotificationTimer?.cancel();
    _errorNotificationTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showErrorNotification = false);
    });
  }

  void _showCurrentErrorNotification() {
    if (_errorStatus == null) return;
    setState(() => _showErrorNotification = true);
    _scheduleErrorNotificationDismissal();
  }

  Future<void> _showErrorDetails() async {
    final status = _errorStatus;
    if (status == null) return;
    final effectiveEdition = EditionAccessPolicy.effectiveFor(
      edition,
      isPro: EntitlementScope.maybeControllerOf(context)?.isPro ?? false,
    );
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: reduceAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (sheetContext) => _TodayErrorDetailsSheet(
        status: status,
        edition: effectiveEdition,
        onCopy: () async {
          await Clipboard.setData(ClipboardData(text: status.supportDetails));
          if (!sheetContext.mounted) return;
          ScaffoldMessenger.of(
            sheetContext,
          ).showSnackBar(const SnackBar(content: Text('Details copied')));
        },
      ),
    );
  }

  double get _menuShimmerHighlight {
    if (!_menuShimmerController.isAnimating) return 0;
    final wave = math.sin(_menuShimmerController.value * math.pi * 4);
    return math.max(0, wave);
  }

  bool get _reduceMenuDiscoveryMotion => reduceAnimationsOf(context);

  void _scheduleMenuDiscovery(Duration delay) {
    _menuDiscoveryTimer?.cancel();
    if (!widget.showMenuShimmer ||
        _menuDiscoveryCompleted ||
        !_appIsActive ||
        !mounted ||
        _reduceMenuDiscoveryMotion) {
      return;
    }
    _menuDiscoveryTimer = Timer(delay, _playMenuDiscoveryHighlight);
  }

  Future<void> _playMenuDiscoveryHighlight() async {
    if (!mounted ||
        !_appIsActive ||
        _menuDiscoveryCompleted ||
        _reduceMenuDiscoveryMotion) {
      return;
    }
    _scheduleMenuDiscovery(const Duration(seconds: 10));
    await _menuShimmerController.forward(from: 0);
  }

  Future<void> _completeMenuDiscovery() async {
    if (_menuDiscoveryCompleted || !widget.showMenuShimmer) return;
    _menuDiscoveryCompleted = true;
    _menuDiscoveryTimer?.cancel();
    _menuShimmerController.stop();
    _menuShimmerController.reset();
    await widget.onMenuShimmerConsumed?.call();
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
        unawaited(_soundEffectsService.play(SoundEffect.bookmarkRemoved));
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
        unawaited(_soundEffectsService.play(SoundEffect.bookmarkSaved));
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
    await _completeMenuDiscovery();
    if (!mounted) return;
    final reduceMotion = reduceAnimationsOf(context);
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
    PublicationApiService().loadTodayPublication(preferCurrentDateCache: true);

class _TodayErrorStatus {
  const _TodayErrorStatus({
    required this.category,
    required this.explanation,
    required this.supportDetails,
    required this.bannerMessage,
  });

  factory _TodayErrorStatus.fromLoad(TodayPublicationLoad load) {
    final showingSavedWord = load.publication.id != null;
    final contentDescription = showingSavedWord
        ? 'your last saved daily word remains visible'
        : 'the default word remains visible';
    final displayDescription = showingSavedWord
        ? 'Displaying the last saved daily word.'
        : 'Displaying the default word.';
    final bannerMessage = showingSavedWord
        ? 'Unable to refresh — showing saved word'
        : 'Unable to refresh — showing default word';
    final (category, explanation) = switch (load.failure) {
      PublicationLoadFailure.connectivity => (
        'Connection',
        'Diurnus could not connect to refresh the daily publication. $contentDescription.',
      ),
      PublicationLoadFailure.timeout => (
        'Timeout',
        'The publication refresh took too long. $contentDescription.',
      ),
      PublicationLoadFailure.server => (
        'Service response',
        'The Diurnus service could not complete the refresh. $contentDescription.',
      ),
      PublicationLoadFailure.invalidResponse => (
        'Invalid response',
        'Today’s publication could not be read from the service response. $contentDescription.',
      ),
      null => (
        'Refresh',
        'Diurnus could not refresh the daily publication. $contentDescription.',
      ),
    };
    return _TodayErrorStatus(
      category: category,
      explanation: explanation,
      supportDetails:
          'Publication refresh failed. Category: $category. $displayDescription',
      bannerMessage: bannerMessage,
    );
  }

  final String category;
  final String explanation;
  final String supportDetails;
  final String bannerMessage;
}

class _TodayErrorButton extends StatelessWidget {
  const _TodayErrorButton({required this.color, required this.onPressed});

  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Publication refresh details',
    child: SizedBox.square(
      key: const Key('today-error-details-button'),
      dimension: 48,
      child: IconButton(
        tooltip: 'Publication refresh details',
        onPressed: onPressed,
        icon: Icon(
          CupertinoIcons.exclamationmark_circle,
          color: color,
          size: 22,
        ),
      ),
    ),
  );
}

class _TodayErrorBanner extends StatelessWidget {
  const _TodayErrorBanner({
    required this.message,
    required this.edition,
    super.key,
  });

  final String message;
  final Edition edition;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: message,
    child: ExcludeSemantics(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: edition.accentColor.withValues(alpha: 0.48),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_circle,
              color: edition.accentColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  color: edition.primaryTextColor,
                  fontFamily: 'Figtree',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TodayErrorDetailsSheet extends StatelessWidget {
  const _TodayErrorDetailsSheet({
    required this.status,
    required this.edition,
    required this.onCopy,
  });

  final _TodayErrorStatus status;
  final Edition edition;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF102923),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: edition.accentColor.withValues(alpha: 0.45)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Close publication status',
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(CupertinoIcons.xmark, color: edition.primaryTextColor),
            ),
          ),
          Text(
            'Publication status',
            style: TextStyle(
              color: edition.primaryTextColor,
              fontFamily: 'NotoSerifJP',
              fontSize: 27,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            status.explanation,
            style: TextStyle(
              color: edition.secondaryTextColor,
              fontFamily: 'Figtree',
              fontSize: 15,
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'CATEGORY · ${status.category.toUpperCase()}',
            key: const Key('today-error-category'),
            style: TextStyle(
              color: edition.accentColor,
              fontFamily: 'Figtree',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('copy-publication-error-details'),
              onPressed: onCopy,
              icon: const Icon(CupertinoIcons.doc_on_doc, size: 17),
              label: const Text('Copy details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: edition.accentColor,
                minimumSize: const Size.fromHeight(50),
                side: BorderSide(
                  color: edition.accentColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
