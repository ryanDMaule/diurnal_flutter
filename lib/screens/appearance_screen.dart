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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 24, 0),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 20, 28, 0),
              child: Text(
                'Appearance',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'NotoSerifJP',
                  fontSize: 40,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 5, 28, 24),
              child: Text(
                'Choose a Diurnus Edition',
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.56),
                  fontFamily: 'Figtree',
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 30),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.72,
                ),
                itemCount: Editions.all.length,
                itemBuilder: (context, index) {
                  final edition = Editions.all[index];
                  return _EditionPreview(
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

class _EditionPreview extends StatelessWidget {
  const _EditionPreview({
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
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: selected
                        ? edition.accentColor
                        : AppColors.menuDivider,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: EditionBackground(
                  edition: edition,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        width: 22,
                        height: 2,
                        color: edition.accentColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text(
                    edition.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? edition.accentColor
                          : AppColors.textPrimary,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 17,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    size: 16,
                    color: edition.accentColor,
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              edition.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.48),
                fontFamily: 'Figtree',
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
