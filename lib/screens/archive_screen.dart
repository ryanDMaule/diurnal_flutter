import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../services/bookmark_service.dart';
import '../services/edition_service.dart';
import '../services/publication_api_service.dart';
import '../theme/colors.dart';
import 'saved_publication_screen.dart';

List<DailyPublication> sortArchivePublications(
  Iterable<DailyPublication> publications,
) {
  final sorted = publications.toList();
  sorted.sort((a, b) => b.publicationDate!.compareTo(a.publicationDate!));
  return sorted;
}

String archiveMonthHeading(DateTime date) {
  const months = [
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
    super.key,
  }) : apiService = apiService ?? PublicationApiService(),
       bookmarkService = bookmarkService ?? BookmarkService(),
       editionService = editionService ?? EditionService();

  final PublicationApiService apiService;
  final BookmarkService bookmarkService;
  final EditionService editionService;

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<DailyPublication> _publications = const [];
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadPublications();
  }

  Future<void> _loadPublications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final publications = await widget.apiService.fetchPublications();
      if (!mounted) return;
      setState(() {
        _publications = sortArchivePublications(publications);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error loading Archive: $error');
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _openPublication(DailyPublication publication) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.menuBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
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
                'Archive',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Every word, every day',
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
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }
    if (_error != null) {
      return _ArchiveMessage(
        title: 'Archive unavailable',
        message: 'Please check your connection and try again.',
        action: TextButton(
          onPressed: _loadPublications,
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Retry'),
        ),
      );
    }
    if (_publications.isEmpty) {
      return const _ArchiveMessage(
        title: 'Nothing here yet',
        message: 'Published words will appear here as they become available.',
      );
    }

    final sections = <String, List<DailyPublication>>{};
    for (final publication in _publications) {
      final heading = archiveMonthHeading(publication.publicationDate!);
      sections.putIfAbsent(heading, () => []).add(publication);
    }

    return ListView(
      key: const Key('archive-list'),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final section in sections.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              section.key,
              key: Key('archive-month-${section.key}'),
              style: const TextStyle(
                color: AppColors.textSecondary,
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
              onTap: () => _openPublication(publication),
            ),
          const SizedBox(height: 22),
        ],
      ],
    );
  }
}

class _ArchiveRow extends StatelessWidget {
  const _ArchiveRow({required this.publication, required this.onTap});

  static const double height = 118;

  final DailyPublication publication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = publication.publicationDate!;
    const months = [
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
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.menuDivider)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 66,
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'NotoSerifJP',
                        fontSize: 23,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      publication.type.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.5),
                        fontFamily: 'Figtree',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      publication.definition,
                      key: Key('archive-definition-${publication.id}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.58),
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
  const _ArchiveMessage({
    required this.title,
    required this.message,
    this.action,
  });

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
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontFamily: 'NotoSerifJP',
              fontSize: 25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.55),
              fontFamily: 'Figtree',
              fontSize: 14,
              fontWeight: FontWeight.w300,
              height: 1.45,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}
