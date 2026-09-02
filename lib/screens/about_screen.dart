import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.menuBackground,
      body: SafeArea(
        child: CustomScrollView(
          key: const Key('about-scroll-view'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
              sliver: SliverList.list(
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
                  const SizedBox(height: 24),
                  const Text(
                    'About Diurnus',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'One remarkable word, every day.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'Diurnus is a quiet place for remarkable words.\n\n'
                    'Each day brings a single word to discover — its meaning, '
                    'its use, and a little more of the language around it.\n\n'
                    'Save the words worth keeping, explore those that came '
                    'before, or use Recall to make them your own.\n\n'
                    'No streaks to maintain. No endless feed. Just words worth '
                    'knowing.',
                    key: Key('about-main-copy'),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Figtree',
                      fontSize: 17,
                      fontWeight: FontWeight.w300,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 44),
                  const Divider(color: AppColors.menuDivider, height: 1),
                  const SizedBox(height: 25),
                  const Text(
                    'Diurnus',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Version unavailable',
                    semanticsLabel: 'Application version unavailable',
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.5),
                      fontFamily: 'Figtree',
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _InactiveInformationRow(label: 'Privacy Policy'),
                  const _InactiveInformationRow(label: 'Terms of Use'),
                  const _InactiveInformationRow(label: 'Acknowledgements'),
                  const SizedBox(height: 48),
                  Text(
                    'Made for the curious.',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.68),
                      fontFamily: 'NotoSerifJP',
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InactiveInformationRow extends StatelessWidget {
  const _InactiveInformationRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, not yet available',
      button: true,
      enabled: false,
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.menuDivider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.72),
                    fontFamily: 'Figtree',
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Text(
                'Not yet available',
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.36),
                  fontFamily: 'Figtree',
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
