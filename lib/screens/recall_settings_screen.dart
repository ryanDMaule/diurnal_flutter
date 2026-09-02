import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/recall_question.dart';
import '../models/recall_settings.dart';
import '../services/recall_settings_service.dart';
import '../theme/colors.dart';

class RecallSettingsScreen extends StatefulWidget {
  const RecallSettingsScreen({required this.settingsService, super.key});

  final RecallSettingsService settingsService;

  @override
  State<RecallSettingsScreen> createState() => _RecallSettingsScreenState();
}

class _RecallSettingsScreenState extends State<RecallSettingsScreen> {
  RecallSettings _settings = RecallSettings.defaults;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await widget.settingsService.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _save(RecallSettings settings) async {
    final previous = _settings;
    setState(() => _settings = settings);
    try {
      await widget.settingsService.save(settings);
    } catch (error) {
      debugPrint('Error saving Recall settings: $error');
      if (mounted) setState(() => _settings = previous);
    }
  }

  void _toggleType(RecallQuestionType type) {
    final enabled = _settings.enabledQuestionTypes.toSet();
    if (enabled.contains(type)) {
      if (enabled.length == 1) return;
      enabled.remove(type);
    } else {
      enabled.add(type);
    }
    _save(_settings.copyWith(enabledQuestionTypes: enabled));
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
                tooltip: 'Back to Recall',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  CupertinoIcons.back,
                  color: AppColors.textPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Recall Settings',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 36,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Shape your regular Recall sessions.',
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.56),
                  fontFamily: 'Figtree',
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : ListView(
                        key: const Key('recall-settings-list'),
                        children: [
                          const _SectionHeading('Word pool'),
                          _SingleOption(
                            key: const Key('pool-archive'),
                            title: 'Archive',
                            subtitle: 'All published Diurnus words.',
                            selected:
                                _settings.wordPool == RecallWordPool.archive,
                            onTap: () => _save(
                              _settings.copyWith(
                                wordPool: RecallWordPool.archive,
                              ),
                            ),
                          ),
                          _SingleOption(
                            key: const Key('pool-myLexicon'),
                            title: 'My Lexicon',
                            subtitle: 'Only words you\'ve chosen to keep.',
                            selected:
                                _settings.wordPool == RecallWordPool.myLexicon,
                            onTap: () => _save(
                              _settings.copyWith(
                                wordPool: RecallWordPool.myLexicon,
                              ),
                            ),
                          ),
                          _SingleOption(
                            key: const Key('pool-unrecalled'),
                            title: 'Unrecalled',
                            subtitle: 'Words you\'ve yet to recall correctly.',
                            selected:
                                _settings.wordPool == RecallWordPool.unrecalled,
                            onTap: () => _save(
                              _settings.copyWith(
                                wordPool: RecallWordPool.unrecalled,
                              ),
                            ),
                          ),
                          _SingleOption(
                            key: const Key('pool-revisit'),
                            title: 'To Revisit',
                            subtitle: 'Words you\'ve previously missed.',
                            selected:
                                _settings.wordPool == RecallWordPool.revisit,
                            onTap: () => _save(
                              _settings.copyWith(
                                wordPool: RecallWordPool.revisit,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const _SectionHeading('Questions per session'),
                          Row(
                            children: [
                              for (final count in [5, 10, 20]) ...[
                                Expanded(
                                  child: _CountOption(
                                    key: Key('question-count-$count'),
                                    count: count,
                                    selected: _settings.questionCount == count,
                                    onTap: () => _save(
                                      _settings.copyWith(questionCount: count),
                                    ),
                                  ),
                                ),
                                if (count != 20) const SizedBox(width: 10),
                              ],
                            ],
                          ),
                          const SizedBox(height: 28),
                          const _SectionHeading('Question types'),
                          _ToggleOption(
                            key: const Key('type-wordToDefinition'),
                            title: 'Word → Definition',
                            selected: _settings.enabledQuestionTypes.contains(
                              RecallQuestionType.wordToDefinition,
                            ),
                            onTap: () => _toggleType(
                              RecallQuestionType.wordToDefinition,
                            ),
                          ),
                          _ToggleOption(
                            key: const Key('type-definitionToWord'),
                            title: 'Definition → Word',
                            selected: _settings.enabledQuestionTypes.contains(
                              RecallQuestionType.definitionToWord,
                            ),
                            onTap: () => _toggleType(
                              RecallQuestionType.definitionToWord,
                            ),
                          ),
                          _ToggleOption(
                            key: const Key('type-wordToSynonym'),
                            title: 'Word → Synonym',
                            selected: _settings.enabledQuestionTypes.contains(
                              RecallQuestionType.wordToSynonym,
                            ),
                            onTap: () =>
                                _toggleType(RecallQuestionType.wordToSynonym),
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontFamily: 'Figtree',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _SingleOption extends StatelessWidget {
  const _SingleOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          _SelectionMark(selected: selected),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _optionTitleStyle),
                const SizedBox(height: 3),
                Text(subtitle, style: _optionSubtitleStyle),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CountOption extends StatelessWidget {
  const _CountOption({
    required this.count,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? AppColors.textSecondary : AppColors.menuDivider,
        ),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? AppColors.textSecondary : AppColors.textPrimary,
          fontFamily: 'Figtree',
          fontSize: 15,
        ),
      ),
    ),
  );
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.title,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: _optionTitleStyle)),
          _SelectionMark(selected: selected, multiple: true),
        ],
      ),
    ),
  );
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected, this.multiple = false});
  final bool selected;
  final bool multiple;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 140),
    width: 22,
    height: 22,
    decoration: BoxDecoration(
      shape: multiple ? BoxShape.rectangle : BoxShape.circle,
      borderRadius: multiple ? BorderRadius.circular(5) : null,
      color: selected ? AppColors.textSecondary : Colors.transparent,
      border: Border.all(
        color: selected
            ? AppColors.textSecondary
            : AppColors.textPrimary.withValues(alpha: 0.42),
      ),
    ),
    child: selected
        ? const Icon(
            CupertinoIcons.check_mark,
            size: 15,
            color: AppColors.menuBackground,
          )
        : null,
  );
}

const _optionTitleStyle = TextStyle(
  color: AppColors.textPrimary,
  fontFamily: 'Figtree',
  fontSize: 15,
  fontWeight: FontWeight.w400,
);

final _optionSubtitleStyle = TextStyle(
  color: AppColors.textPrimary.withValues(alpha: 0.5),
  fontFamily: 'Figtree',
  fontSize: 13,
  fontWeight: FontWeight.w300,
);
