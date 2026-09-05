import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  const TodayScreen({this.initialPublication, super.key});

  final Future<TodayPublicationLoad>? initialPublication;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  final EditionService _editionService = EditionService();
  final WidgetSyncService _widgetSyncService = WidgetSyncService();
  DailyPublication publication = DailyPublication.localFallback;
  Edition edition = Editions.library;
  bool isLoading = true;
  bool isOffline = false;
  bool isBookmarked = false;
  bool isBookmarkUpdating = false;

  @override
  void initState() {
    super.initState();
    _restoreEditionState();
    _loadPublication();
  }

  Future<void> _loadPublication() async {
    final result = await (widget.initialPublication ?? loadTodayPublication());
    if (!mounted) return;
    setState(() {
      publication = result.publication;
      isLoading = false;
      isOffline = result.isOffline;
      isBookmarked = false;
    });
    await _restoreBookmarkState(result.publication);
    await _widgetSyncService.syncPublication(result.publication);
  }

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
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MenuScreen(),
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

class TodayPublicationLoad {
  const TodayPublicationLoad({
    required this.publication,
    required this.isOffline,
  });

  final DailyPublication publication;
  final bool isOffline;
}

Future<TodayPublicationLoad> loadTodayPublication() async {
  try {
    final response = await http.get(PublicationApiService.wordOfTheDayUri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid publication response.');
      }
      final fetched = DailyPublication.fromJson(data);
      return TodayPublicationLoad(publication: fetched, isOffline: false);
    } else {
      debugPrint(
        '⚠️ API returned ${response.statusCode}. Using fallback word.',
      );
    }
  } catch (error) {
    debugPrint('❌ Error fetching word: $error');
  }
  return TodayPublicationLoad(
    publication: DailyPublication.localFallback,
    isOffline: true,
  );
}
