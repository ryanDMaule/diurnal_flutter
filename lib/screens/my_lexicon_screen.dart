import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../services/bookmark_service.dart';
import '../theme/colors.dart';
import 'saved_publication_screen.dart';

List<DailyPublication> sortLexiconPublications(
  Iterable<DailyPublication> publications,
) {
  final sorted = publications.toList();
  sorted.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
  return sorted;
}

List<DailyPublication> filterLexiconPublications(
  Iterable<DailyPublication> publications,
  String query,
) {
  final normalized = query.trim().toLowerCase();
  return sortLexiconPublications(
    normalized.isEmpty
        ? publications
        : publications.where(
            (publication) =>
                publication.word.toLowerCase().contains(normalized),
          ),
  );
}

String collectedWordsLabel(int count) =>
    '$count ${count == 1 ? 'word' : 'words'} collected';

class MyLexiconScreen extends StatefulWidget {
  MyLexiconScreen({BookmarkService? bookmarkService, super.key})
    : bookmarkService = bookmarkService ?? BookmarkService();

  final BookmarkService bookmarkService;

  @override
  State<MyLexiconScreen> createState() => _MyLexiconScreenState();
}

class _MyLexiconScreenState extends State<MyLexiconScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  List<DailyPublication> _publications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPublications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPublications() async {
    try {
      final saved = await widget.bookmarkService.getSavedPublications();
      if (!mounted) return;
      setState(() {
        _publications = sortLexiconPublications(saved);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading My Lexicon: $error');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _remove(DailyPublication publication) async {
    final previous = _publications;
    setState(() {
      _publications = _publications
          .where((item) => item.id != publication.id)
          .toList();
    });
    try {
      await widget.bookmarkService.remove(publication.id!);
    } catch (error) {
      debugPrint('Error removing publication: $error');
      if (mounted) setState(() => _publications = previous);
    }
  }

  Future<void> _open(DailyPublication publication) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SavedPublicationScreen(
          publication: publication,
          bookmarkService: widget.bookmarkService,
        ),
      ),
    );
    await _loadPublications();
  }

  void _jumpTo(String letter) {
    final sectionContext = _sectionKeys[letter]?.currentContext;
    if (sectionContext != null) {
      Scrollable.ensureVisible(
        sectionContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.menuBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: 'Back to menu',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  CupertinoIcons.back,
                  color: AppColors.textPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'My Lexicon',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                collectedWordsLabel(_publications.length),
                key: const Key('lexicon-count'),
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.56),
                  fontFamily: 'Figtree',
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.textSecondary,
        ),
      );
    }
    if (_publications.isEmpty) return _emptyState();

    final filtered = filterLexiconPublications(
      _publications,
      _searchController.text,
    );
    final grouped = <String, List<DailyPublication>>{};
    for (final publication in filtered) {
      final letter = publication.word[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(publication);
      _sectionKeys.putIfAbsent(letter, GlobalKey.new);
    }

    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Figtree',
          ),
          decoration: InputDecoration(
            hintText: 'Search lexicon...',
            hintStyle: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.42),
              fontFamily: 'Figtree',
            ),
            prefixIcon: Icon(
              CupertinoIcons.search,
              color: AppColors.textPrimary.withValues(alpha: 0.5),
              size: 20,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.menuDivider),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Stack(
            children: [
              ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(right: 38, bottom: 24),
                children: [
                  for (final entry in grouped.entries)
                    _section(entry.key, entry.value),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _AlphabetRail(
                  activeLetters: grouped.keys.toSet(),
                  onLetterTap: _jumpTo,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String letter, List<DailyPublication> publications) {
    return Column(
      key: _sectionKeys[letter],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            letter,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Figtree',
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        for (final publication in publications)
          _LexiconRow(
            publication: publication,
            onOpen: () => _open(publication),
            onRemove: () => _remove(publication),
          ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.bookmark,
            color: AppColors.textSecondary,
            size: 72,
          ),
          const SizedBox(height: 28),
          const Text(
            'No words saved yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'NotoSerifJP',
              fontSize: 27,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the bookmark on a word\nto add it to your lexicon.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.55),
              fontFamily: 'Figtree',
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(CupertinoIcons.bookmark, size: 17),
            label: const Text("Discover today's word"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.textSecondary),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              textStyle: const TextStyle(
                fontFamily: 'Figtree',
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LexiconRow extends StatelessWidget {
  const _LexiconRow({
    required this.publication,
    required this.onOpen,
    required this.onRemove,
  });

  final DailyPublication publication;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.menuDivider)),
      ),
      child: InkWell(
        key: Key('lexicon-row-${publication.id}'),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publication.word,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'NotoSerifJP',
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      publication.definition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.55),
                        fontFamily: 'Figtree',
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              IconButton(
                key: Key('remove-bookmark-${publication.id}'),
                tooltip: 'Remove ${publication.word}',
                onPressed: onRemove,
                icon: const Icon(
                  CupertinoIcons.bookmark_fill,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlphabetRail extends StatelessWidget {
  const _AlphabetRail({required this.activeLetters, required this.onLetterTap});

  final Set<String> activeLetters;
  final ValueChanged<String> onLetterTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var code = 65; code <= 90; code++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: activeLetters.contains(String.fromCharCode(code))
                ? () => onLetterTap(String.fromCharCode(code))
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              child: Text(
                String.fromCharCode(code),
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(
                    alpha: activeLetters.contains(String.fromCharCode(code))
                        ? 0.9
                        : 0.25,
                  ),
                  fontFamily: 'Figtree',
                  fontSize: 10,
                  height: 1.05,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
