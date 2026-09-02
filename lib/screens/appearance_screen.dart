import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/edition.dart';
import '../services/edition_service.dart';
import '../theme/colors.dart';
import '../widgets/edition_background.dart';

class AppearanceScreen extends StatefulWidget {
  AppearanceScreen({EditionService? editionService, super.key})
    : editionService = editionService ?? EditionService();

  final EditionService editionService;

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  Edition selectedEdition = Editions.library;

  @override
  void initState() {
    super.initState();
    _restoreSelection();
  }

  Future<void> _restoreSelection() async {
    final edition = await widget.editionService.loadSelectedEdition();
    if (mounted) setState(() => selectedEdition = edition);
  }

  Future<void> _select(Edition edition) async {
    setState(() => selectedEdition = edition);
    try {
      await widget.editionService.selectEdition(edition);
    } catch (error) {
      debugPrint('Error saving Edition: $error');
      await _restoreSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.menuBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
              child: SizedBox(
                height: 74,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: 'Back to menu',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          CupertinoIcons.back,
                          color: AppColors.textPrimary,
                          size: 26,
                        ),
                      ),
                    ),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Appearance',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'NotoSerifJP',
                            fontSize: 31,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Choose your Diurnus Edition',
                          style: TextStyle(
                            color: Color(0x8FD4D4D4),
                            fontFamily: 'Figtree',
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                key: const Key('appearance-edition-list'),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                itemCount: Editions.all.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final edition = Editions.all[index];
                  return _EditionCard(
                    edition: edition,
                    selected: selectedEdition.id == edition.id,
                    onTap: () => _select(edition),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditionCard extends StatelessWidget {
  const _EditionCard({
    required this.edition,
    required this.selected,
    required this.onTap,
  });

  final Edition edition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${edition.name} Edition',
      child: GestureDetector(
        key: Key('edition-${edition.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 122,
          decoration: BoxDecoration(
            color: const Color(0xFF0B332A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? edition.accentColor.withValues(alpha: 0.68)
                  : AppColors.menuDivider.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(13),
                ),
                child: SizedBox(
                  width: 122,
                  height: 122,
                  child: EditionBackground(
                    edition: edition,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edition.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'NotoSerifJP',
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      edition.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.48),
                        fontFamily: 'Figtree',
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _SelectionIndicator(
                key: Key('edition-selection-${edition.id}'),
                selected: selected,
                accentColor: edition.accentColor,
              ),
              const SizedBox(width: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({
    required this.selected,
    required this.accentColor,
    super.key,
  });

  final bool selected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? accentColor : Colors.transparent,
        border: Border.all(
          color: selected
              ? accentColor
              : AppColors.textPrimary.withValues(alpha: 0.42),
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(
              CupertinoIcons.check_mark,
              color: AppColors.menuBackground,
              size: 18,
            )
          : null,
    );
  }
}
