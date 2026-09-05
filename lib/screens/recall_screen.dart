// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../models/edition.dart';
import '../models/match_session.dart';
import '../models/recall_question.dart';
import '../models/recall_settings.dart';
import '../models/recall_settings_policy.dart';
import '../services/bookmark_service.dart';
import '../services/endless_recall_service.dart';
import '../services/match_service.dart';
import '../services/publication_api_service.dart';
import '../services/recall_progress_service.dart';
import '../services/recall_settings_service.dart';
import '../theme/interface_theme.dart';
import '../widgets/edition_background.dart';
import '../widgets/entitlement_scope.dart';
import 'endless_recall_session_screen.dart';
import 'match_session_screen.dart';
import 'match_ready_screen.dart';
import 'pro_screen.dart';
import 'recall_session_screen.dart';
import 'recall_ready_screen.dart';
import 'recall_settings_screen.dart';

const _recallEdition = Edition(
  id: 'recall-background',
  name: 'Recall',
  description: '',
  backgroundAsset: 'assets/images/bust.png',
  tintColor: Color(0xFF000000),
  tintOpacity: 0.32,
  gradientColors: [Color(0x10000000), Color(0xB5000000), Color(0xF2000000)],
  gradientStops: [0, 0.55, 1],
  gradientBegin: Alignment.topCenter,
  gradientEnd: Alignment.bottomCenter,
  primaryTextColor: Color(0xFFE7E0D4),
  secondaryTextColor: Color(0xFFD2C7B5),
  mutedTextColor: Color(0xFF9E988E),
  accentColor: Color(0xFFC49A52),
  systemUiIconBrightness: Brightness.light,
);

class RecallScreen extends StatefulWidget {
  RecallScreen({
    PublicationApiService? apiService,
    BookmarkService? bookmarkService,
    RecallProgressService? progressService,
    RecallSettingsService? settingsService,
    EndlessRecallService? endlessService,
    MatchService? matchService,
    MatchSessionGenerator? matchGenerator,
    RecallSessionGenerator? sessionGenerator,
    super.key,
  }) : apiService = apiService ?? PublicationApiService(),
       bookmarkService = bookmarkService ?? BookmarkService(),
       progressService = progressService ?? RecallProgressService(),
       settingsService = settingsService ?? RecallSettingsService(),
       endlessService = endlessService ?? EndlessRecallService(),
       matchService = matchService ?? MatchService(),
       matchGenerator = matchGenerator ?? MatchSessionGenerator(),
       sessionGenerator = sessionGenerator ?? RecallSessionGenerator();

  final PublicationApiService apiService;
  final BookmarkService bookmarkService;
  final RecallProgressService progressService;
  final RecallSettingsService settingsService;
  final EndlessRecallService endlessService;
  final MatchService matchService;
  final MatchSessionGenerator matchGenerator;
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
  bool _canRetry = false;
  String? _messageTitle;
  String? _messageBody;
  int? _endlessBest;
  int? _matchBestMilliseconds;
  bool _retryStartsEndless = false;
  bool _retryStartsMatch = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadEndlessBest();
    _loadMatchBest();
  }

  Future<void> _loadMatchBest() async {
    try {
      final best = await widget.matchService.personalBestMilliseconds();
      if (mounted) setState(() => _matchBestMilliseconds = best);
    } catch (error) {
      debugPrint('Error loading Match best: $error');
    }
  }

  Future<void> _loadEndlessBest() async {
    try {
      final best = await widget.endlessService.personalBest();
      if (mounted) setState(() => _endlessBest = best);
    } catch (error) {
      debugPrint('Error loading Endless Recall best: $error');
    }
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

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            RecallSettingsScreen(settingsService: widget.settingsService),
      ),
    );
  }

  Future<void> _openPro() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProScreen(backTooltip: 'Back to Recall'),
      ),
    );
  }

  Future<void> _start() async {
    if (_isLoading) return;
    final isPro = EntitlementScope.maybeControllerOf(context)?.isPro ?? false;
    setState(() {
      _isLoading = true;
      _canRetry = false;
      _messageTitle = null;
      _messageBody = null;
      _retryStartsEndless = false;
      _retryStartsMatch = false;
    });

    try {
      final storedSettings = await widget.settingsService.load();
      final settings = RecallSettingsPolicy.effectiveFor(
        storedSettings,
        isPro: isPro,
      );
      List<DailyPublication>? savedSubjects;
      if (settings.wordPool == RecallWordPool.myLexicon) {
        savedSubjects = await widget.bookmarkService.getSavedPublications();
        if (savedSubjects.isEmpty) {
          if (!mounted) return;
          final message = _emptyPoolMessage(settings.wordPool);
          setState(() {
            _isLoading = false;
            _messageTitle = message.$1;
            _messageBody = message.$2;
          });
          return;
        }
      }
      final archive = await _getArchive();
      final subjects = switch (settings.wordPool) {
        RecallWordPool.archive => archive,
        RecallWordPool.myLexicon => savedSubjects!,
        RecallWordPool.unrecalled =>
          await widget.progressService.publicationsInStates(archive, {
            RecallProgressState.unseen,
            RecallProgressState.revisit,
          }),
        RecallWordPool.revisit =>
          await widget.progressService.publicationsInStates(archive, {
            RecallProgressState.revisit,
          }),
      };
      if (subjects.isEmpty) {
        if (!mounted) return;
        final message = _emptyPoolMessage(settings.wordPool);
        setState(() {
          _isLoading = false;
          _messageTitle = message.$1;
          _messageBody = message.$2;
        });
        return;
      }
      List<RecallQuestion> generate(Set<String> avoidSubjectIds) =>
          widget.sessionGenerator.generate(
            subjects: subjects,
            distractorPool: archive,
            questionCount: settings.questionCount,
            enabledTypes: settings.enabledQuestionTypes,
            avoidSubjectIds: avoidSubjectIds,
          );
      final questions = generate({});
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (questions.isEmpty) {
        setState(() {
          _messageTitle = 'Recall unavailable';
          _messageBody = 'There are not enough published words yet.';
        });
        return;
      }

      void openSession(BuildContext readyContext) {
        Navigator.of(readyContext).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => RecallSessionScreen(
              questions: questions,
              progressService: widget.progressService,
              onRecallAgain: (previousSubjectIds) async =>
                  generate(previousSubjectIds),
            ),
          ),
        );
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => RecallReadyScreen(
            heading: 'Ready to recall?',
            body:
                'You\'ll be shown ${settings.questionCount} questions from your '
                'selected word pool. Take your time and choose the answer you remember.',
            onStart: openSession,
          ),
        ),
      );
      await _refreshProgress();
    } catch (error) {
      debugPrint('Error preparing Recall: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _canRetry = true;
        _messageTitle = 'Recall unavailable';
        _messageBody = 'Please check your connection and try again.';
      });
    }
  }

  Future<void> _startEndless() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _canRetry = false;
      _messageTitle = null;
      _messageBody = null;
      _retryStartsEndless = true;
      _retryStartsMatch = false;
    });
    try {
      final archive = await _getArchive();
      final eligible = archive
          .where((publication) => publication.id != null)
          .toList();
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (eligible.isEmpty) {
        setState(() {
          _messageTitle = 'Endless Recall unavailable';
          _messageBody = 'There are no published words to recall yet.';
        });
        return;
      }
      final probe = widget.sessionGenerator.generateQuestion(
        subject: eligible.first,
        distractorPool: archive,
      );
      if (probe == null) {
        setState(() {
          _messageTitle = 'Endless Recall unavailable';
          _messageBody = 'There are no valid published questions yet.';
        });
        return;
      }
      void openSession(BuildContext readyContext) {
        Navigator.of(readyContext).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => EndlessRecallSessionScreen(
              archive: List.unmodifiable(eligible),
              generator: widget.sessionGenerator,
              progressService: widget.progressService,
              endlessService: widget.endlessService,
              onFinished: _loadEndlessBest,
            ),
          ),
        );
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => RecallReadyScreen(
            heading: 'Ready to go endless?',
            body:
                'Keep recalling words for as long as you can. One incorrect answer ends the session.',
            onStart: openSession,
          ),
        ),
      );
      await Future.wait([_refreshProgress(), _loadEndlessBest()]);
    } catch (error) {
      debugPrint('Error preparing Endless Recall: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _canRetry = true;
        _messageTitle = 'Endless Recall unavailable';
        _messageBody = 'Please check your connection and try again.';
      });
    }
  }

  Future<void> _startMatch() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _canRetry = false;
      _messageTitle = null;
      _messageBody = null;
      _retryStartsEndless = false;
      _retryStartsMatch = true;
    });
    try {
      final archive = await _getArchive();
      MatchSession generate(Set<String> avoidSubjectIds) => widget
          .matchGenerator
          .generate(publications: archive, avoidSubjectIds: avoidSubjectIds);
      final session = generate({});
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!session.isAvailable) {
        setState(() {
          _messageTitle = 'Match unavailable';
          _messageBody = 'At least two published word pairs are needed.';
        });
        return;
      }
      void openSession(BuildContext readyContext) {
        Navigator.of(readyContext).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => MatchSessionScreen(
              session: session,
              matchService: widget.matchService,
              progressService: widget.progressService,
              onPlayAgain: (previousSubjectIds) async =>
                  generate(previousSubjectIds),
              onFinished: _loadMatchBest,
            ),
          ),
        );
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => MatchReadyScreen(onStart: openSession),
        ),
      );
      await Future.wait([_refreshProgress(), _loadMatchBest()]);
    } catch (error) {
      debugPrint('Error preparing Match: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _canRetry = true;
        _messageTitle = 'Match unavailable';
        _messageBody = 'Please check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = EntitlementScope.maybeControllerOf(context)?.isPro ?? false;
    return Scaffold(
      backgroundColor: Colors.black,
      body: EditionBackground(
        edition: _recallEdition,
        child: InterfaceSafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SingleChildScrollView(
              key: Key('recall-landing-scroll'),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back to menu',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        CupertinoIcons.back,
                        color: _recallEdition.primaryTextColor,
                        size: 26,
                      ),
                    ),
                    Spacer(),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.32),
                        border: Border.all(
                          color: _recallEdition.accentColor.withValues(
                            alpha: 0.34,
                          ),
                        ),
                      ),
                      child: IconButton(
                        key: Key('recall-settings'),
                        tooltip: 'Recall Settings',
                        onPressed: _openSettings,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        icon: Icon(
                          CupertinoIcons.slider_horizontal_3,
                          color: _recallEdition.accentColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 70),
                Text(
                  'Recall',
                  style: TextStyle(
                    color: _recallEdition.primaryTextColor,
                    fontFamily: 'NotoSerifJP',
                    fontSize: 48,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: 36,
                  height: 1.5,
                  color: _recallEdition.accentColor,
                ),
                SizedBox(height: 24),
                Text(
                  'Words worth remembering.',
                  style: TextStyle(
                    color: _recallEdition.secondaryTextColor,
                    fontFamily: 'NotoSerifJP',
                    fontSize: 21,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(height: 42),
                _RecallCard(
                  key: Key('normal-recall'),
                  icon: CupertinoIcons.book,
                  title: 'Recall',
                  description: 'A short session from your selected word pool.',
                  onTap: _start,
                ),
                SizedBox(height: 8),
                _RecallCard(
                  key: Key('match-recall'),
                  icon: CupertinoIcons.square_grid_2x2,
                  title: 'Match',
                  description: 'Pair words with their meanings.',
                  footer:
                      'Best · ${_matchBestMilliseconds == null ? '—' : formatMatchTime(_matchBestMilliseconds!)}',
                  isLocked: !isPro,
                  onTap: isPro ? _startMatch : _openPro,
                ),
                SizedBox(height: 8),
                _RecallCard(
                  key: Key('endless-recall'),
                  icon: CupertinoIcons.infinite,
                  title: 'Endless Recall',
                  description: 'Keep going until you miss one.',
                  footer: 'Best · ${_endlessBest ?? '—'}',
                  isLocked: !isPro,
                  onTap: isPro ? _startEndless : _openPro,
                ),
                SizedBox(height: 30),
                _WordProgressSection(
                  summary: _progressSummary,
                  isLoading: _isProgressLoading,
                  isUnavailable: _progressUnavailable,
                ),
                SizedBox(height: 30),
                if (_isLoading)
                  Center(
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _recallEdition.accentColor,
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
                          style: TextStyle(
                            color: _recallEdition.primaryTextColor,
                            fontFamily: 'NotoSerifJP',
                            fontSize: 22,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _messageBody!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _recallEdition.secondaryTextColor.withValues(
                              alpha: 0.72,
                            ),
                            fontFamily: 'Figtree',
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        if (_canRetry) ...[
                          SizedBox(height: 10),
                          TextButton(
                            key: Key('retry-recall'),
                            onPressed: _retryStartsMatch
                                ? _startMatch
                                : _retryStartsEndless
                                ? _startEndless
                                : _start,
                            style: TextButton.styleFrom(
                              foregroundColor: _recallEdition.accentColor,
                            ),
                            child: Text('Retry'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecallCard extends StatelessWidget {
  _RecallCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.footer,
    this.isLocked = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final String? footer;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: isLocked ? '$title, Diurnus Pro' : title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.28),
                  border: Border.all(color: _recallEdition.accentColor),
                ),
                child: Icon(
                  icon,
                  color: _recallEdition.accentColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _recallEdition.primaryTextColor,
                        fontFamily: 'NotoSerifJP',
                        fontSize: 23,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: _recallEdition.secondaryTextColor.withValues(
                          alpha: isLocked ? 0.58 : 0.76,
                        ),
                        fontFamily: 'Figtree',
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        height: 1.45,
                      ),
                    ),
                    if (footer != null) ...[
                      SizedBox(height: 8),
                      Text(
                        footer!,
                        style: TextStyle(
                          color: _recallEdition.accentColor.withValues(
                            alpha: 0.86,
                          ),
                          fontFamily: 'Figtree',
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isLocked) ...[
                SizedBox(width: 12),
                Row(
                  key: Key(
                    '${title == 'Match' ? 'match' : 'endless'}-pro-lock',
                  ),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.lock,
                      color: _recallEdition.accentColor.withValues(alpha: 0.8),
                      size: 13,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Pro',
                      style: TextStyle(
                        color: _recallEdition.accentColor.withValues(
                          alpha: 0.88,
                        ),
                        fontFamily: 'Figtree',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              if (onTap != null) ...[
                SizedBox(width: isLocked ? 8 : 12),
                Icon(
                  CupertinoIcons.chevron_right,
                  color: _recallEdition.secondaryTextColor.withValues(
                    alpha: 0.72,
                  ),
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WordProgressSection extends StatelessWidget {
  _WordProgressSection({
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
      key: Key('recall-word-progress'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Word progress',
          style: TextStyle(
            color: _recallEdition.primaryTextColor,
            fontFamily: 'NotoSerifJP',
            fontSize: 24,
          ),
        ),
        SizedBox(height: 8),
        if (isLoading)
          Text('Loading…', style: _progressDetailStyle(context))
        else if (isUnavailable || summary == null)
          Text('Progress unavailable', style: _progressDetailStyle(context))
        else ...[
          Text(
            recallProgressHeadline(summary!),
            key: Key('recall-progress-headline'),
            style: _progressDetailStyle(context),
          ),
          SizedBox(height: 14),
          _SegmentedProgressBar(summary: summary!),
          SizedBox(height: 12),
          Text(
            'Unseen ${summary!.unseen} · Revisit ${summary!.revisit} · '
            'Recalled ${summary!.recalled}',
            key: Key('recall-progress-legend'),
            style: _progressDetailStyle(context, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  _SegmentedProgressBar({required this.summary});

  final RecallProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('recall-segmented-progress'),
      width: double.infinity,
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: summary.total == 0
            ? ColoredBox(
                color: _recallEdition.mutedTextColor.withValues(alpha: 0.45),
              )
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
                            key: Key('recall-progress-unseen'),
                            color: _recallEdition.mutedTextColor.withValues(
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
                          child: ColoredBox(
                            key: Key('recall-progress-revisit'),
                            color: _recallEdition.accentColor,
                          ),
                        ),
                      if (summary.recalled > 0)
                        Positioned(
                          left: unseenWidth + revisitWidth,
                          width: recalledWidth,
                          top: 0,
                          bottom: 0,
                          child: ColoredBox(
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

TextStyle _progressDetailStyle(BuildContext context, {double fontSize = 14}) =>
    TextStyle(
      color: _recallEdition.secondaryTextColor.withValues(alpha: 0.72),
      fontFamily: 'Figtree',
      fontSize: fontSize,
      fontWeight: FontWeight.w300,
    );

(String, String) _emptyPoolMessage(RecallWordPool pool) => switch (pool) {
  RecallWordPool.archive => (
    'Recall unavailable',
    'There are not enough published words yet.',
  ),
  RecallWordPool.myLexicon => (
    'Your Lexicon is empty',
    'Save words to practise them here.',
  ),
  RecallWordPool.unrecalled => (
    'All caught up',
    'You\'ve recalled every published word.',
  ),
  RecallWordPool.revisit => (
    'Nothing to revisit',
    'Words you miss will appear here.',
  ),
};
