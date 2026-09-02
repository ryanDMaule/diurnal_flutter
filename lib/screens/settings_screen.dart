import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/app_settings_service.dart';
import '../services/bookmark_service.dart';
import '../services/endless_recall_service.dart';
import '../services/recall_progress_service.dart';
import '../theme/interface_theme.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({
    AppSettingsService? settingsService,
    BookmarkService? bookmarkService,
    RecallProgressService? recallProgressService,
    EndlessRecallService? endlessRecallService,
    super.key,
  }) : settingsService = settingsService ?? AppSettingsService(),
       bookmarkService = bookmarkService ?? BookmarkService(),
       recallProgressService = recallProgressService ?? RecallProgressService(),
       endlessRecallService = endlessRecallService ?? EndlessRecallService();

  final AppSettingsService settingsService;
  final BookmarkService bookmarkService;
  final RecallProgressService recallProgressService;
  final EndlessRecallService endlessRecallService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings _settings = AppSettings.defaults;
  bool _loading = true;

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
      _loading = false;
    });
  }

  Future<void> _save(AppSettings settings) async {
    final previous = _settings;
    setState(() => _settings = settings);
    try {
      final controller = InterfaceThemeScope.maybeControllerOf(context);
      if (controller == null) {
        await widget.settingsService.save(settings);
      } else {
        await controller.update(settings);
      }
    } catch (error) {
      debugPrint('Error saving app settings: $error');
      if (mounted) setState(() => _settings = previous);
    }
  }

  Future<void> _resetRecall(InterfacePalette palette) async {
    final confirmed = await _confirm(
      palette: palette,
      title: 'Reset Recall progress?',
      body:
          'This will clear your recalled and revisit progress, including your Endless Recall personal best. Recall Settings will be preserved.',
      action: 'Reset progress',
    );
    if (confirmed != true) return;
    await widget.recallProgressService.clear();
    await widget.endlessRecallService.clearPersonalBest();
    if (mounted) _showConfirmation('Recall progress reset.');
  }

  Future<void> _clearLexicon(InterfacePalette palette) async {
    final confirmed = await _confirm(
      palette: palette,
      title: 'Clear My Lexicon?',
      body: 'This will remove every word saved locally to My Lexicon.',
      action: 'Clear Lexicon',
    );
    if (confirmed != true) return;
    await widget.bookmarkService.clearAll();
    if (mounted) _showConfirmation('My Lexicon cleared.');
  }

  Future<bool?> _confirm({
    required InterfacePalette palette,
    required String title,
    required String body,
    required String action,
  }) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: palette.surface,
      title: Text(title, style: TextStyle(color: palette.primary)),
      content: Text(body, style: TextStyle(color: palette.secondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: TextStyle(color: palette.secondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action, style: TextStyle(color: palette.accent)),
        ),
      ],
    ),
  );

  void _showConfirmation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.accent,
                ),
              )
            : ListView(
                key: const Key('settings-list'),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back to menu',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        CupertinoIcons.back,
                        color: palette.primary,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: palette.primary,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _SectionLabel('EXPERIENCE', color: palette.accent),
                  const SizedBox(height: 12),
                  _ToggleRow(
                    key: const Key('sound-effects-setting'),
                    title: 'Sound effects',
                    description:
                        'Use subtle sound cues when they become available.',
                    value: _settings.soundEffectsEnabled,
                    palette: palette,
                    onChanged: (value) =>
                        _save(_settings.copyWith(soundEffectsEnabled: value)),
                  ),
                  _ToggleRow(
                    key: const Key('reduce-animations-setting'),
                    title: 'Reduce animations',
                    description:
                        'Limit decorative movement throughout Diurnus.',
                    value: _settings.reduceAnimations,
                    palette: palette,
                    onChanged: (value) =>
                        _save(_settings.copyWith(reduceAnimations: value)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Interface appearance',
                    style: TextStyle(
                      color: palette.primary,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AppearanceSelector(
                    selected: _settings.interfaceAppearance,
                    palette: palette,
                    onSelected: (value) =>
                        _save(_settings.copyWith(interfaceAppearance: value)),
                  ),
                  const SizedBox(height: 44),
                  _SectionLabel('YOUR DATA', color: palette.accent),
                  const SizedBox(height: 12),
                  _ActionRow(
                    key: const Key('reset-recall-progress'),
                    title: 'Reset Recall progress',
                    description:
                        'Start your Recall progress again from the beginning.',
                    palette: palette,
                    onTap: () => _resetRecall(palette),
                  ),
                  _ActionRow(
                    key: const Key('clear-my-lexicon'),
                    title: 'Clear My Lexicon',
                    description: 'Remove every word saved to My Lexicon.',
                    palette: palette,
                    onTap: () => _clearLexicon(palette),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: color,
      fontFamily: 'Figtree',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.6,
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.description,
    required this.value,
    required this.palette,
    required this.onChanged,
    super.key,
  });
  final String title;
  final String description;
  final bool value;
  final InterfacePalette palette;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Semantics(
    label: title,
    toggled: value,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: palette.primary,
                    fontFamily: 'NotoSerifJP',
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    color: palette.secondary,
                    fontFamily: 'Figtree',
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch.adaptive(
            value: value,
            activeThumbColor: palette.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    ),
  );
}

class _AppearanceSelector extends StatelessWidget {
  const _AppearanceSelector({
    required this.selected,
    required this.palette,
    required this.onSelected,
  });
  final InterfaceAppearance selected;
  final InterfacePalette palette;
  final ValueChanged<InterfaceAppearance> onSelected;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final value in InterfaceAppearance.values)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: value == InterfaceAppearance.dark ? 0 : 8,
            ),
            child: Semantics(
              button: true,
              selected: selected == value,
              label: '${_appearanceLabel(value)} interface appearance',
              child: OutlinedButton(
                key: Key('appearance-${value.name}'),
                onPressed: () => onSelected(value),
                style: OutlinedButton.styleFrom(
                  foregroundColor: selected == value
                      ? palette.background
                      : palette.primary,
                  backgroundColor: selected == value
                      ? palette.accent
                      : Colors.transparent,
                  side: BorderSide(
                    color: selected == value ? palette.accent : palette.divider,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(_appearanceLabel(value)),
              ),
            ),
          ),
        ),
    ],
  );
}

String _appearanceLabel(InterfaceAppearance appearance) => switch (appearance) {
  InterfaceAppearance.system => 'System',
  InterfaceAppearance.light => 'Light',
  InterfaceAppearance.dark => 'Dark',
};

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.title,
    required this.description,
    required this.palette,
    required this.onTap,
    super.key,
  });
  final String title;
  final String description;
  final InterfacePalette palette;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: title,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: palette.primary,
                fontFamily: 'NotoSerifJP',
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: palette.secondary,
                fontFamily: 'Figtree',
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
