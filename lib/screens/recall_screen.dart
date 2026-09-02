import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../models/recall_question.dart';
import '../services/bookmark_service.dart';
import '../services/publication_api_service.dart';
import '../services/recall_progress_service.dart';
import '../theme/colors.dart';
import 'recall_session_screen.dart';

class RecallScreen extends StatefulWidget {
  RecallScreen({
    PublicationApiService? apiService,
    BookmarkService? bookmarkService,
    RecallProgressService? progressService,
    RecallSessionGenerator? sessionGenerator,
    super.key,
  }) : apiService = apiService ?? PublicationApiService(),
       bookmarkService = bookmarkService ?? BookmarkService(),
       progressService = progressService ?? RecallProgressService(),
       sessionGenerator = sessionGenerator ?? RecallSessionGenerator();

  final PublicationApiService apiService;
  final BookmarkService bookmarkService;
  final RecallProgressService progressService;
  final RecallSessionGenerator sessionGenerator;

  @override
  State<RecallScreen> createState() => _RecallScreenState();
}

class _RecallScreenState extends State<RecallScreen> {
  bool _isLoading = false;
  bool _isProgressLoading = true;
  bool _progressUnavailable = false;
  List<DailyPublication>? _archive;
  Future<List<DailyPublication>>? _archiveRequest;
  RecallProgressSummary? _progressSummary;
  RecallMode? _retryMode;
  String? _messageTitle;
  String? _messageBody;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<List<DailyPublication>> _getArchive() {
    final cached = _archive;
    if (cached != null) return Future.value(cached);
    return _archiveRequest ??= widget.apiService
        .fetchPublications()
        .then((data) {
          _archive = data;
          return data;
        })
        .whenComplete(() => _archiveRequest = null);
  }

  Future<void> _loadProgress() async {
    try {
      final archive = await _getArchive();
      final summary = await widget.progressService.summaryFor(archive);
      if (!mounted) return;
      setState(() {
        _progressSummary = summary;
        _isProgressLoading = false;
        _progressUnavailable = false;
      });
    } catch (error) {
      debugPrint('Error loading Recall progress: $error');
      if (!mounted) return;
      setState(() {
        _isProgressLoading = false;
        _progressUnavailable = true;
      });
    }
  }

  Future<void> _refreshProgress() async {
    final archive = _archive;
    if (archive == null) return;
    try {
      final summary = await widget.progressService.summaryFor(archive);
      if (mounted) setState(() => _progressSummary = summary);
    } catch (error) {
      debugPrint('Error refreshing Recall progress: $error');
    }
  }

  Future<void> _start(RecallMode mode) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _retryMode = null;
      _messageTitle = null;
      _messageBody = null;
    });

    try {
      var subjects = <DailyPublication>[];
      if (mode == RecallMode.lexicon) {
        subjects = await widget.bookmarkService.getSavedPublications();
        if (subjects.isEmpty) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _messageTitle = 'Your Lexicon is empty';
            _messageBody = 'Save words to practise them here.';
          });
          return;
        }
      }

      final archive = await _getArchive();
      if (mode == RecallMode.daily) subjects = archive;
      List<RecallQuestion> generate(Set<String> avoidSubjectIds) =>
          widget.sessionGenerator.generate(
            subjects: subjects,
            distractorPool: archive,
            avoidSubjectIds: avoidSubjectIds,
          );
      final questions = generate(const {});
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (questions.isEmpty) {
        setState(() {
          _messageTitle = 'Recall unavailable';
          _messageBody = 'There are not enough published words yet.';
        });
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => RecallSessionScreen(
            questions: questions,
            progressService: widget.progressService,
            onRecallAgain: (previousSubjectIds) async =>
                generate(previousSubjectIds),
          ),
        ),
      );
      await _refreshProgress();
    } catch (error) {
      debugPrint('Error preparing Recall: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _retryMode = mode;
        _messageTitle = 'Recall unavailable';
        _messageBody = 'Please check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.menuBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
              const SizedBox(height: 28),
              const Text(
                'Recall',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Words worth remembering.',
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.58),
                  fontFamily: 'Figtree',
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 38),
              _RecallCard(
                key: const Key('daily-recall'),
                icon: CupertinoIcons.book,
                title: 'Daily Recall',
                description:
                    'A short session from words in the Diurnus Archive.',
                onTap: () => _start(RecallMode.daily),
              ),
              const SizedBox(height: 18),
              _RecallCard(
                key: const Key('lexicon-recall'),
                icon: CupertinoIcons.bookmark,
                title: 'My Lexicon Recall',
                description: 'Practice the words you\'ve chosen to keep.',
                onTap: () => _start(RecallMode.lexicon),
              ),
              const SizedBox(height: 30),
              _WordProgressSection(
                summary: _progressSummary,
                isLoading: _isProgressLoading,
                isUnavailable: _progressUnavailable,
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else if (_messageTitle != null)
                Center(
                  child: Column(
                    children: [
                      Text(
                        _messageTitle!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'NotoSerifJP',
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _messageBody!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.55),
                          fontFamily: 'Figtree',
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      if (_retryMode != null) ...[
                        const SizedBox(height: 10),
                        TextButton(
                          key: const Key('retry-recall'),
                          onPressed: () => _start(_retryMode!),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
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

class _RecallCard extends StatelessWidget {
  const _RecallCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF0B332A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.menuDivider),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textSecondary),
              ),
              child: Icon(icon, color: AppColors.textSecondary, size: 23),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.56),
                      fontFamily: 'Figtree',
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.textPrimary.withValues(alpha: 0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _WordProgressSection extends StatelessWidget {
  const _WordProgressSection({
    required this.summary,
    required this.isLoading,
    required this.isUnavailable,
  });

  final RecallProgressSummary? summary;
  final bool isLoading;
  final bool isUnavailable;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('recall-word-progress'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Word progress',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'NotoSerifJP',
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          Text('Loading…', style: _progressDetailStyle())
        else if (isUnavailable || summary == null)
          Text('Progress unavailable', style: _progressDetailStyle())
        else ...[
          Text(
            recallProgressHeadline(summary!),
            key: const Key('recall-progress-headline'),
            style: _progressDetailStyle(),
          ),
          const SizedBox(height: 14),
          _SegmentedProgressBar(summary: summary!),
          const SizedBox(height: 12),
          Text(
            'Unseen ${summary!.unseen} · Revisit ${summary!.revisit} · '
            'Recalled ${summary!.recalled}',
            key: const Key('recall-progress-legend'),
            style: _progressDetailStyle(fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  const _SegmentedProgressBar({required this.summary});

  final RecallProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('recall-segmented-progress'),
      width: double.infinity,
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: summary.total == 0
            ? ColoredBox(color: AppColors.menuDivider.withValues(alpha: 0.45))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth = constraints.maxWidth;
                  final unseenWidth =
                      trackWidth * summary.unseen / summary.total;
                  final revisitWidth =
                      trackWidth * summary.revisit / summary.total;
                  final recalledWidth = trackWidth - unseenWidth - revisitWidth;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (summary.unseen > 0)
                        Positioned(
                          left: 0,
                          width: unseenWidth,
                          top: 0,
                          bottom: 0,
                          child: ColoredBox(
                            key: const Key('recall-progress-unseen'),
                            color: AppColors.menuDivider.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                      if (summary.revisit > 0)
                        Positioned(
                          left: unseenWidth,
                          width: revisitWidth,
                          top: 0,
                          bottom: 0,
                          child: const ColoredBox(
                            key: Key('recall-progress-revisit'),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (summary.recalled > 0)
                        Positioned(
                          left: unseenWidth + revisitWidth,
                          width: recalledWidth,
                          top: 0,
                          bottom: 0,
                          child: const ColoredBox(
                            key: Key('recall-progress-recalled'),
                            color: Color(0xFF4C8B62),
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

String recallProgressHeadline(RecallProgressSummary summary) =>
    '${summary.recalled} of ${summary.total} recalled';

TextStyle _progressDetailStyle({double fontSize = 14}) => TextStyle(
  color: AppColors.textPrimary.withValues(alpha: 0.56),
  fontFamily: 'Figtree',
  fontSize: fontSize,
  fontWeight: FontWeight.w300,
);
