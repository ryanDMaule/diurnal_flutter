// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/interface_theme.dart';
import '../widgets/diurnus_brand_lockup.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri url);

class AboutScreen extends StatelessWidget {
  AboutScreen({ExternalUrlLauncher? externalUrlLauncher, super.key})
    : _externalUrlLauncher = externalUrlLauncher ?? _launchExternally;

  static final supportUrl = Uri.parse('https://buymeacoffee.com/ryanMaule');
  final ExternalUrlLauncher _externalUrlLauncher;

  static Future<bool> _launchExternally(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  Future<void> _openSupportPage(BuildContext context) async {
    var opened = false;
    try {
      opened = await _externalUrlLauncher(supportUrl);
    } catch (_) {
      opened = false;
    }
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open the support page right now.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: InterfaceThemeScope.maybePaletteOf(context).background,
      body: InterfaceSafeArea(
        child: CustomScrollView(
          key: Key('about-scroll-view'),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 36),
              sliver: SliverList.list(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back to menu',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        CupertinoIcons.back,
                        color: InterfaceThemeScope.maybePaletteOf(
                          context,
                        ).primary,
                        size: 26,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DiurnusBrandLockup(
                      markColor: InterfaceThemeScope.maybePaletteOf(
                        context,
                      ).accent,
                      wordmarkColor: InterfaceThemeScope.maybePaletteOf(
                        context,
                      ).primary,
                      markSize: 52,
                      wordmarkWidth: 148,
                      spacing: 10,
                      direction: Axis.horizontal,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'About Diurnus',
                    style: TextStyle(
                      color: InterfaceThemeScope.maybePaletteOf(
                        context,
                      ).primary,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'One remarkable word, every day.',
                    style: TextStyle(
                      color: InterfaceThemeScope.maybePaletteOf(context).accent,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 34),
                  Text(
                    'Diurnus is a quiet place for remarkable words.\n\n'
                    'Each day brings a single word to discover — its meaning, '
                    'its use, and a little more of the language around it.\n\n'
                    'Save the words worth keeping, explore those that came '
                    'before, or use Recall to make them your own.\n\n'
                    'No streaks to maintain. No endless feed. Just words worth '
                    'knowing.',
                    key: Key('about-main-copy'),
                    style: TextStyle(
                      color: InterfaceThemeScope.maybePaletteOf(
                        context,
                      ).primary,
                      fontFamily: 'Figtree',
                      fontSize: 17,
                      fontWeight: FontWeight.w300,
                      height: 1.65,
                    ),
                  ),
                  SizedBox(height: 44),
                  Divider(
                    color: InterfaceThemeScope.maybePaletteOf(context).divider,
                    height: 1,
                  ),
                  SizedBox(height: 25),
                  Text(
                    'Diurnus',
                    style: TextStyle(
                      color: InterfaceThemeScope.maybePaletteOf(
                        context,
                      ).primary,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Version unavailable',
                    semanticsLabel: 'Application version unavailable',
                    style: TextStyle(
                      color: InterfaceThemeScope.maybePaletteOf(
                        context,
                      ).primary.withValues(alpha: 0.5),
                      fontFamily: 'Figtree',
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: 28),
                  _InactiveInformationRow(label: 'Privacy Policy'),
                  _InactiveInformationRow(label: 'Terms of Use'),
                  _InactiveInformationRow(label: 'Acknowledgements'),
                  SizedBox(height: 40),
                  Divider(
                    color: InterfaceThemeScope.maybePaletteOf(context).divider,
                    height: 1,
                  ),
                  SizedBox(height: 28),
                  Text(
                    'Support Diurnus',
                    key: Key('about-support-heading'),
                    style: TextStyle(
                      color: InterfaceThemeScope.maybePaletteOf(
                        context,
                      ).primary,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Diurnus is free for everyone. If you enjoy using it and '
                    'would like to support its continued development, you can '
                    'buy me a coffee.',
                    style: TextStyle(
                      color: InterfaceThemeScope.maybePaletteOf(
                        context,
                      ).primary.withValues(alpha: 0.76),
                      fontFamily: 'Figtree',
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      height: 1.55,
                    ),
                  ),
                  SizedBox(height: 20),
                  Semantics(
                    button: true,
                    label: 'Buy me a coffee, opens external browser',
                    child: OutlinedButton(
                      key: Key('buy-me-a-coffee'),
                      onPressed: () => _openSupportPage(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.fromHeight(52),
                        foregroundColor: InterfaceThemeScope.maybePaletteOf(
                          context,
                        ).accent,
                        side: BorderSide(
                          color: InterfaceThemeScope.maybePaletteOf(
                            context,
                          ).accent.withValues(alpha: 0.72),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        textStyle: TextStyle(
                          fontFamily: 'Figtree',
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      child: Text('Buy me a coffee'),
                    ),
                  ),
                  SizedBox(height: 48),
                  Text(
                    'Made for the curious.',
                    style: TextStyle(
                      color: InterfaceThemeScope.maybePaletteOf(
                        context,
                      ).accent.withValues(alpha: 0.68),
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
  _InactiveInformationRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, not yet available',
      button: true,
      enabled: false,
      child: ExcludeSemantics(
        child: Container(
          constraints: BoxConstraints(minHeight: 58),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: InterfaceThemeScope.maybePaletteOf(context).divider,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: InterfaceThemeScope.maybePaletteOf(
                      context,
                    ).primary.withValues(alpha: 0.72),
                    fontFamily: 'Figtree',
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              Text(
                'Not yet available',
                style: TextStyle(
                  color: InterfaceThemeScope.maybePaletteOf(
                    context,
                  ).primary.withValues(alpha: 0.36),
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
