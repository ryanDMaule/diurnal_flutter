// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/interface_theme.dart';
import '../widgets/diurnus_brand_lockup.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri url);
typedef AppVersionLoader = Future<String> Function();

class AboutScreen extends StatefulWidget {
  AboutScreen({
    ExternalUrlLauncher? externalUrlLauncher,
    AppVersionLoader? appVersionLoader,
    super.key,
  }) : _externalUrlLauncher = externalUrlLauncher ?? _launchExternally,
       _appVersionLoader = appVersionLoader ?? _loadAppVersion;

  static final supportUrl = Uri.parse('https://buymeacoffee.com/ryanMaule');
  static final privacyPolicyUrl = Uri.parse(
    'https://sites.google.com/view/mauleapplications',
  );
  final ExternalUrlLauncher _externalUrlLauncher;
  final AppVersionLoader _appVersionLoader;

  static Future<bool> _launchExternally(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  static Future<String> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version} (${packageInfo.buildNumber})';
  }

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = 'Loading…';

  @override
  void initState() {
    super.initState();
    _resolveAppVersion();
  }

  Future<void> _resolveAppVersion() async {
    try {
      final version = await widget._appVersionLoader();
      if (mounted) setState(() => _appVersion = version);
    } catch (_) {
      if (mounted) setState(() => _appVersion = 'Information unavailable');
    }
  }

  Future<void> _openExternalPage(Uri url, String failureMessage) async {
    var opened = false;
    try {
      opened = await widget._externalUrlLauncher(url);
    } catch (_) {
      opened = false;
    }
    if (opened || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failureMessage)));
  }

  void _openAcknowledgements() {
    showLicensePage(
      context: context,
      applicationName: 'Diurnus',
      applicationVersion: _appVersion == 'Loading…' ? null : _appVersion,
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
                    'Version $_appVersion',
                    key: Key('about-app-version'),
                    semanticsLabel: 'Application version $_appVersion',
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
                  _InformationRow(
                    key: Key('privacy-policy'),
                    label: 'Privacy Policy',
                    semanticsLabel: 'Privacy Policy, opens external browser',
                    onTap: () => _openExternalPage(
                      AboutScreen.privacyPolicyUrl,
                      'Unable to open the privacy policy right now.',
                    ),
                  ),
                  _InformationRow(
                    key: Key('acknowledgements'),
                    label: 'Acknowledgements',
                    semanticsLabel: 'Acknowledgements and software licences',
                    onTap: _openAcknowledgements,
                  ),
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
                      onPressed: () => _openExternalPage(
                        AboutScreen.supportUrl,
                        'Unable to open the support page right now.',
                      ),
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

class _InformationRow extends StatelessWidget {
  const _InformationRow({
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
    super.key,
  });

  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
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
                Icon(
                  CupertinoIcons.chevron_right,
                  color: InterfaceThemeScope.maybePaletteOf(
                    context,
                  ).primary.withValues(alpha: 0.36),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
