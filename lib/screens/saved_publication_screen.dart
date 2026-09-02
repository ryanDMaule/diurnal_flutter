import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../models/edition.dart';
import '../services/bookmark_service.dart';
import '../services/edition_service.dart';
import '../widgets/publication_view.dart';

class SavedPublicationScreen extends StatefulWidget {
  const SavedPublicationScreen({
    required this.publication,
    required this.bookmarkService,
    this.editionService,
    this.backTooltip = 'Back to My Lexicon',
    this.initiallyBookmarked = true,
    super.key,
  });

  final DailyPublication publication;
  final BookmarkService bookmarkService;
  final EditionService? editionService;
  final String backTooltip;
  final bool initiallyBookmarked;

  @override
  State<SavedPublicationScreen> createState() => _SavedPublicationScreenState();
}

class _SavedPublicationScreenState extends State<SavedPublicationScreen> {
  late bool isBookmarked;
  bool isBookmarkUpdating = false;
  Edition edition = Editions.library;
  late final EditionService _editionService;

  @override
  void initState() {
    super.initState();
    isBookmarked = widget.initiallyBookmarked;
    _editionService = widget.editionService ?? EditionService();
    _restoreBookmarkState();
    _restoreEditionState();
  }

  Future<void> _restoreBookmarkState() async {
    try {
      final saved = await widget.bookmarkService.isSaved(widget.publication.id);
      if (!mounted || isBookmarkUpdating) return;
      setState(() => isBookmarked = saved);
    } catch (error) {
      debugPrint('Error loading saved publication state: $error');
    }
  }

  Future<void> _restoreEditionState() async {
    try {
      final selectedEdition = await _editionService.loadSelectedEdition();
      if (mounted) setState(() => edition = selectedEdition);
    } catch (error) {
      debugPrint('Error loading saved publication Edition: $error');
    }
  }

  Future<void> _toggleBookmark() async {
    if (isBookmarkUpdating) return;
    final wasBookmarked = isBookmarked;
    setState(() {
      isBookmarked = !wasBookmarked;
      isBookmarkUpdating = true;
    });
    try {
      if (wasBookmarked) {
        await widget.bookmarkService.remove(widget.publication.id!);
      } else {
        await widget.bookmarkService.save(widget.publication);
      }
    } catch (error) {
      debugPrint('Error updating saved publication: $error');
      if (mounted) setState(() => isBookmarked = wasBookmarked);
    } finally {
      if (mounted) setState(() => isBookmarkUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicationView(
      publication: widget.publication,
      edition: edition,
      isBookmarked: isBookmarked,
      isBookmarkUpdating: isBookmarkUpdating,
      onBookmarkToggle: _toggleBookmark,
      topLeftControl: IconButton(
        tooltip: widget.backTooltip,
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(CupertinoIcons.back, size: 26),
        color: edition.primaryTextColor,
      ),
    );
  }
}
