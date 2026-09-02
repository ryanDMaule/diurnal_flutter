import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../services/bookmark_service.dart';
import '../theme/colors.dart';
import '../widgets/publication_view.dart';

class SavedPublicationScreen extends StatefulWidget {
  const SavedPublicationScreen({
    required this.publication,
    required this.bookmarkService,
    super.key,
  });

  final DailyPublication publication;
  final BookmarkService bookmarkService;

  @override
  State<SavedPublicationScreen> createState() => _SavedPublicationScreenState();
}

class _SavedPublicationScreenState extends State<SavedPublicationScreen> {
  bool isBookmarked = true;
  bool isBookmarkUpdating = false;

  @override
  void initState() {
    super.initState();
    _restoreBookmarkState();
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
      isBookmarked: isBookmarked,
      isBookmarkUpdating: isBookmarkUpdating,
      onBookmarkToggle: _toggleBookmark,
      topLeftControl: IconButton(
        tooltip: 'Back to My Lexicon',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          CupertinoIcons.back,
          size: 26,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
