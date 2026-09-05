// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../services/bookmark_service.dart';
import '../services/edition_service.dart';
import '../theme/interface_theme.dart';
import '../widgets/diurnus_loading_state.dart';
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
  MyLexiconScreen({
    BookmarkService? bookmarkService,
    EditionService? editionService,
    super.key,
  }) : bookmarkService = bookmarkService ?? BookmarkService(),
       editionService = editionService ?? EditionService();

  final BookmarkService bookmarkService;
  final EditionService editionService;

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
          editionService: widget.editionService,
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
        duration: Duration.zero,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InterfaceThemeScope.maybePaletteOf(context).background,
      body: InterfaceSafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 18, 20),
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
              Text(
                'My Lexicon',
                style: TextStyle(
                  color: InterfaceThemeScope.maybePaletteOf(context).primary,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 5),
              Text(
                collectedWordsLabel(_publications.length),
                key: Key('lexicon-count'),
                style: TextStyle(
                  color: InterfaceThemeScope.maybePaletteOf(
                    context,
                  ).primary.withValues(alpha: 0.56),
                  fontFamily: 'Figtree',
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                ),
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
        title: 'Opening your lexicon…',
        message: 'Gathering your saved words.',
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
          style: TextStyle(
            color: InterfaceThemeScope.maybePaletteOf(context).primary,
            fontFamily: 'Figtree',
          ),
          decoration: InputDecoration(
            hintText: 'Search lexicon...',
            hintStyle: TextStyle(
              color: InterfaceThemeScope.maybePaletteOf(
                context,
              ).primary.withValues(alpha: 0.42),
              fontFamily: 'Figtree',
            ),
            prefixIcon: Icon(
              CupertinoIcons.search,
              color: InterfaceThemeScope.maybePaletteOf(
                context,
              ).primary.withValues(alpha: 0.5),
              size: 20,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: InterfaceThemeScope.maybePaletteOf(context).divider,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: InterfaceThemeScope.maybePaletteOf(context).accent,
              ),
            ),
          ),
        ),
        SizedBox(height: 18),
        Expanded(
          child: Stack(
            children: [
              ListView(
                controller: _scrollController,
                padding: EdgeInsets.only(right: 38, bottom: 24),
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
          padding: EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            letter,
            style: TextStyle(
              color: InterfaceThemeScope.maybePaletteOf(context).accent,
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
          Icon(
            CupertinoIcons.bookmark,
            color: InterfaceThemeScope.maybePaletteOf(context).accent,
            size: 72,
          ),
          SizedBox(height: 28),
          Text(
            'No words saved yet',
            style: TextStyle(
              color: InterfaceThemeScope.maybePaletteOf(context).primary,
              fontFamily: 'NotoSerifJP',
              fontSize: 27,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Tap the bookmark on a word\nto add it to your lexicon.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: InterfaceThemeScope.maybePaletteOf(
                context,
              ).primary.withValues(alpha: 0.55),
              fontFamily: 'Figtree',
              fontSize: 15,
              height: 1.5,
            ),
          ),
          SizedBox(height: 30),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            icon: Icon(CupertinoIcons.bookmark, size: 17),
            label: Text("Discover today's word"),
            style: OutlinedButton.styleFrom(
              foregroundColor: InterfaceThemeScope.maybePaletteOf(
                context,
              ).accent,
              side: BorderSide(
                color: InterfaceThemeScope.maybePaletteOf(context).accent,
              ),
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              textStyle: TextStyle(
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
  _LexiconRow({
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
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: InterfaceThemeScope.maybePaletteOf(context).divider,
          ),
        ),
      ),
      child: InkWell(
        key: Key('lexicon-row-${publication.id}'),
        onTap: onOpen,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publication.word,
                      style: TextStyle(
                        color: InterfaceThemeScope.maybePaletteOf(
                          context,
                        ).primary,
                        fontFamily: 'NotoSerifJP',
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      publication.definition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: InterfaceThemeScope.maybePaletteOf(
                          context,
                        ).primary.withValues(alpha: 0.55),
                        fontFamily: 'Figtree',
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 14),
              IconButton(
                key: Key('remove-bookmark-${publication.id}'),
                tooltip: 'Remove ${publication.word}',
                onPressed: onRemove,
                icon: Icon(
                  CupertinoIcons.bookmark_fill,
                  color: InterfaceThemeScope.maybePaletteOf(context).accent,
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

class _AlphabetRail extends StatefulWidget {
  _AlphabetRail({required this.activeLetters, required this.onLetterTap});

  final Set<String> activeLetters;
  final ValueChanged<String> onLetterTap;

  @override
  State<_AlphabetRail> createState() => _AlphabetRailState();
}

class _AlphabetRailState extends State<_AlphabetRail> {
  static const _letterCount = 26;
  String? _selectedLetter;
  String? _indicatorLetter;

  void _selectLetter(Offset localPosition, double railHeight) {
    final index = (localPosition.dy / railHeight * _letterCount)
        .floor()
        .clamp(0, _letterCount - 1);
    final letter = String.fromCharCode(65 + index);
    if (letter == _selectedLetter) return;
    setState(() {
      _selectedLetter = letter;
      _indicatorLetter = letter;
    });
    widget.onLetterTap(letter);
  }

  void _endInteraction() {
    if (_selectedLetter == null) return;
    setState(() => _selectedLetter = null);
  }

  @override
  Widget build(BuildContext context) {
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final railHeight = constraints.maxHeight < 325
            ? constraints.maxHeight
            : 325.0;
        return SizedBox(
          width: 32,
          height: railHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerRight,
            children: [
              Positioned(
                right: 44,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _selectedLetter == null ? 0 : 1,
                    duration: Duration(milliseconds: 100),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.surface.withValues(alpha: 0.94),
                        border: Border.all(color: palette.divider),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _indicatorLetter ?? '',
                        style: TextStyle(
                          color: palette.accent,
                          fontFamily: 'NotoSerifJP',
                          fontSize: 26,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (details) =>
                    _selectLetter(details.localPosition, railHeight),
                onPanUpdate: (details) =>
                    _selectLetter(details.localPosition, railHeight),
                onPanEnd: (_) => _endInteraction(),
                onPanCancel: _endInteraction,
                child: Column(
                  children: [
                    for (var code = 65; code <= 90; code++)
                      Expanded(
                        child: Center(
                          child: Text(
                            String.fromCharCode(code),
                            style: TextStyle(
                              color: palette.accent.withValues(
                                alpha: widget.activeLetters.contains(
                                  String.fromCharCode(code),
                                )
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
