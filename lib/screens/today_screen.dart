import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;

import '../models/daily_publication.dart';
import '../models/edition.dart';
import '../services/bookmark_service.dart';
import '../services/edition_service.dart';
import '../widgets/morphing_menu_button.dart';
import '../widgets/publication_view.dart';
import 'menu_screen.dart';

Future<void> updateWidget(String word, String definition) async {
  await HomeWidget.saveWidgetData<String>('word', word);
  await HomeWidget.saveWidgetData<String>('definition', definition);
  await HomeWidget.updateWidget(
    name: 'HomeWidgetProvider',
    androidName: 'HomeWidgetProvider',
    iOSName: 'HomeWidget',
    qualifiedAndroidName: 'com.example.diurnul.HomeWidgetProvider',
  );
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  final EditionService _editionService = EditionService();
  DailyPublication publication = DailyPublication.localFallback;
  Edition edition = Editions.originalLibrary;
  bool isLoading = true;
  bool isOffline = false;
  bool isBookmarked = false;
  bool isBookmarkUpdating = false;

  @override
  void initState() {
    super.initState();
    _restoreEditionState();
    fetchWordOfTheDay();
  }

  Future<void> fetchWordOfTheDay() async {
    const apiUrl = 'https://diurnal-api-7zz8.onrender.com/word';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is! Map<String, dynamic>) {
          throw const FormatException('Invalid publication response.');
        }
        final fetched = DailyPublication.fromJson(data);
        if (!mounted) return;
        setState(() {
          publication = fetched;
          isLoading = false;
          isOffline = false;
          isBookmarked = false;
        });
        await _restoreBookmarkState(fetched);
        await updateWidget(fetched.word, fetched.definition);
      } else {
        debugPrint(
          '⚠️ API returned ${response.statusCode}. Using fallback word.',
        );
        await _showFallback();
      }
    } catch (error) {
      debugPrint('❌ Error fetching word: $error');
      await _showFallback();
    }
  }

  Future<void> _showFallback() async {
    if (!mounted) return;
    setState(() {
      publication = DailyPublication.localFallback;
      isLoading = false;
      isOffline = true;
      isBookmarked = false;
    });
    await updateWidget(publication.word, publication.definition);
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
      } else {
        await _bookmarkService.save(current);
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
            : const Duration(milliseconds: 250),
        reverseTransitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 250),
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

  @override
  Widget build(BuildContext context) {
    return PublicationView(
      publication: publication,
      edition: edition,
      isLoading: isLoading,
      isOffline: isOffline,
      isBookmarked: isBookmarked,
      isBookmarkUpdating: isBookmarkUpdating,
      onBookmarkToggle: publication.id == null ? null : _toggleBookmark,
      topRightControl: MorphingMenuButton(
        isOpen: false,
        color: edition.primaryTextColor,
        tooltip: 'Open menu',
        onPressed: _openMenu,
      ),
    );
  }
}
