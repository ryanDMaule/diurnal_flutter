import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/daily_publication.dart';
import '../models/app_settings.dart';
import '../models/edition.dart';
import '../models/edition_access_policy.dart';
import '../services/edition_service.dart';
import '../services/onboarding_service.dart';
import '../services/widget_sync_service.dart';
import '../theme/interface_theme.dart';
import '../theme/motion_preferences.dart';
import '../widgets/appearance_selector.dart';
import '../widgets/diurnus_brand_lockup.dart';
import '../widgets/edition_background.dart';
import '../widgets/entitlement_scope.dart';

class OnboardingScreen extends StatefulWidget {
  OnboardingScreen({
    required this.initialStep,
    this.useDefaultAppearance = false,
    required this.onCompleted,
    OnboardingService? onboardingService,
    EditionService? editionService,
    WidgetSyncService? widgetSyncService,
    super.key,
  }) : onboardingService = onboardingService ?? OnboardingService(),
       editionService = editionService ?? EditionService(),
       widgetSyncService = widgetSyncService ?? WidgetSyncService();

  final int initialStep;
  final bool useDefaultAppearance;
  final Future<void> Function() onCompleted;
  final OnboardingService onboardingService;
  final EditionService editionService;
  final WidgetSyncService widgetSyncService;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _samplePublication = DailyPublication(
    id: null,
    sequence: 13,
    publicationDate: null,
    word: 'Laconic',
    type: 'Adjective',
    phonetic: 'la·con·ic',
    definition: 'Using very few words.',
    usage: 'His laconic reply conveyed more than a lengthy explanation.',
    synonyms: ['Brief', 'Concise', 'Terse'],
  );

  late int _step;
  late InterfaceColor _draftColor;
  Edition _draftEdition = Editions.library;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, OnboardingService.lastPageIndex);
    _draftColor = AppSettings.defaults.interfaceColor;
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
  }

  Future<void> _restoreDraft() async {
    if (widget.useDefaultAppearance) {
      if (!mounted) return;
      setState(() {
        _draftColor = AppSettings.defaults.interfaceColor;
        _draftEdition = Editions.library;
      });
      return;
    }
    final controller = InterfaceThemeScope.controllerOf(context);
    final edition = await widget.editionService.loadSelectedEdition();
    if (!mounted) return;
    setState(() {
      _draftColor = controller.settings.interfaceColor;
      _draftEdition = edition;
    });
  }

  Future<void> _goTo(int step) async {
    final next = step.clamp(0, OnboardingService.lastPageIndex);
    setState(() => _step = next);
    await widget.onboardingService.saveStep(next);
  }

  Future<void> _saveAppearanceAndContinue() async {
    if (_saving) return;
    setState(() => _saving = true);
    final controller = InterfaceThemeScope.controllerOf(context);
    final isPro = EntitlementScope.maybeControllerOf(context)?.isPro ?? false;
    try {
      await controller.update(
        controller.settings.copyWith(interfaceColor: _draftColor),
      );
      await widget.editionService.selectEdition(_draftEdition);
      await widget.widgetSyncService.syncEdition(
        EditionAccessPolicy.effectiveFor(_draftEdition, isPro: isPro),
      );
      if (mounted) await _goTo(2);
    } catch (error) {
      debugPrint('Error saving onboarding appearance: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your appearance.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onboardingService.complete();
      await widget.onCompleted();
    } catch (error) {
      debugPrint('Error completing onboarding: $error');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not finish setup. Try again.')),
        );
      }
    }
  }

  Future<bool> _handleBack() async {
    if (_step == 0) return true;
    await _goTo(_step - 1);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = InterfacePalette.forColor(_draftColor);
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) _handleBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: _step == 0
              ? Brightness.light
              : palette.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
          systemNavigationBarColor: _step == 0
              ? Colors.black
              : palette.background,
          systemNavigationBarIconBrightness:
              palette.brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        child: switch (_step) {
          0 => _WelcomePage(onBegin: () => _goTo(1)),
          1 => _AppearancePage(
            palette: palette,
            selectedColor: _draftColor,
            selectedEdition: _draftEdition,
            isPro: EntitlementScope.maybeControllerOf(context)?.isPro ?? false,
            samplePublication: _samplePublication,
            saving: _saving,
            onBack: () => _goTo(0),
            onColorSelected: (color) => setState(() => _draftColor = color),
            onEditionSelected: (edition) =>
                setState(() => _draftEdition = edition),
            onLockedEditionSelected: (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This Edition is available with Diurnus Pro.'),
                ),
              );
            },
            onContinue: _saveAppearanceAndContinue,
          ),
          _ => _WidgetsPage(
            palette: palette,
            edition: resolveInterfaceColorEdition(_draftEdition, palette),
            publication: _samplePublication,
            saving: _saving,
            onBack: () => _goTo(1),
            onExplore: _finish,
          ),
        },
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onBegin});

  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: EditionBackground(
      edition: Editions.library,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 22, 30, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: _StepLabel(
                  '1 / ${OnboardingService.pageCount}',
                  color: Color(0xFFD9BF8B),
                ),
              ),
              const Spacer(flex: 3),
              const Center(
                child: DiurnusBrandLockup(
                  markColor: Color(0xFFC49A52),
                  wordmarkColor: Color(0xFFE7E0D4),
                  markSize: 132,
                  wordmarkWidth: 230,
                  spacing: 24,
                ),
              ),
              const Spacer(flex: 2),
              const Text(
                'One remarkable\nword, every day.',
                style: TextStyle(
                  color: Color(0xFFE7E0D4),
                  fontFamily: 'NotoSerifJP',
                  fontSize: 37,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Discover extraordinary words, build your collection, and make language part of your everyday.',
                style: TextStyle(
                  color: Color(0xFFD2C7B5),
                  fontFamily: 'Figtree',
                  fontSize: 17,
                  height: 1.5,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Spacer(flex: 2),
              _GoldButton(label: 'Begin', onPressed: onBegin),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AppearancePage extends StatelessWidget {
  const _AppearancePage({
    required this.palette,
    required this.selectedColor,
    required this.selectedEdition,
    required this.isPro,
    required this.samplePublication,
    required this.saving,
    required this.onBack,
    required this.onColorSelected,
    required this.onEditionSelected,
    required this.onLockedEditionSelected,
    required this.onContinue,
  });

  final InterfacePalette palette;
  final InterfaceColor selectedColor;
  final Edition selectedEdition;
  final bool isPro;
  final DailyPublication samplePublication;
  final bool saving;
  final VoidCallback onBack;
  final ValueChanged<InterfaceColor> onColorSelected;
  final ValueChanged<Edition> onEditionSelected;
  final ValueChanged<Edition> onLockedEditionSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: palette.background,
    body: Stack(
      fit: StackFit.expand,
      children: [
        InterfaceTextureOverlay(
          asset: 'assets/images/paper.png',
          baseColor: palette.background,
          strength: 0.10,
        ),
        SafeArea(
          child: Column(
            children: [
              _OnboardingHeader(
                step: '2 / ${OnboardingService.pageCount}',
                title: 'Make Diurnus yours.',
                subtitle: 'Choose the look and feel of your app and widgets.',
                palette: palette,
                onBack: onBack,
              ),
              Expanded(
                child: ListView(
                  key: const Key('onboarding-appearance-list'),
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                  children: [
                    AppearanceSelector(
                      selectedColor: selectedColor,
                      selectedEdition: selectedEdition,
                      isPro: isPro,
                      previewPublication: samplePublication,
                      onColorSelected: onColorSelected,
                      onEditionSelected: onEditionSelected,
                      onLockedEditionSelected: onLockedEditionSelected,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
                child: _GoldButton(
                  label: 'Continue',
                  onPressed: saving ? null : onContinue,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _WidgetsPage extends StatefulWidget {
  const _WidgetsPage({
    required this.palette,
    required this.edition,
    required this.publication,
    required this.saving,
    required this.onBack,
    required this.onExplore,
  });

  final InterfacePalette palette;
  final Edition edition;
  final DailyPublication publication;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onExplore;

  @override
  State<_WidgetsPage> createState() => _WidgetsPageState();
}

class _WidgetsPageState extends State<_WidgetsPage> {
  static const _showcases = [
    _WidgetShowcase(
      composition: WidgetPreviewComposition.small,
      title: 'Small widget',
      detail: 'Part of speech and word.',
    ),
    _WidgetShowcase(
      composition: WidgetPreviewComposition.medium,
      title: 'Medium widget',
      detail: 'Word and definition.',
    ),
    _WidgetShowcase(
      composition: WidgetPreviewComposition.large,
      title: 'Large widget',
      detail: 'Word, pronunciation and definition.',
    ),
  ];

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showInstructions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: widget.palette.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to add a widget',
                  style: TextStyle(
                    color: widget.palette.primary,
                    fontFamily: 'NotoSerifJP',
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 18),
                for (final instruction in const [
                  'Long-press an empty area of your home screen.',
                  'Tap Widgets and find Diurnus.',
                  'Choose your preferred widget and drag it into position.',
                ].indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 13),
                    child: Text(
                      '${instruction.$1 + 1}.  ${instruction.$2}',
                      style: TextStyle(
                        color: widget.palette.secondary,
                        fontFamily: 'Figtree',
                        fontSize: 16,
                        height: 1.35,
                      ),
                    ),
                  ),
                Text(
                  'Steps may vary slightly depending on your device.',
                  style: TextStyle(
                    color: widget.palette.secondary.withValues(alpha: 0.72),
                    fontFamily: 'Figtree',
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: widget.palette.background,
    body: SafeArea(
      child: Column(
        children: [
          _OnboardingHeader(
            step: '3 / ${OnboardingService.pageCount}',
            title: 'Words beyond the app.',
            subtitle: 'Your words. Your style.',
            palette: widget.palette,
            onBack: widget.onBack,
          ),
          Expanded(
            child: ListView(
              key: const Key('onboarding-widget-list'),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              children: [
                Text(
                  'Bring Diurnus to your home screen with beautifully designed widgets that match your chosen Edition.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.palette.secondary,
                    fontFamily: 'Figtree',
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final unit = math.min(164.0, constraints.maxWidth / 2);
                    return SizedBox(
                      key: const Key('onboarding-widget-carousel'),
                      height: (unit * 2) + 58,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _showcases.length,
                        onPageChanged: (page) =>
                            setState(() => _currentPage = page),
                        itemBuilder: (context, index) {
                          final showcase = _showcases[index];
                          return Column(
                            children: [
                              SizedBox(
                                height: unit * 2,
                                child: Center(
                                  child: WidgetEditionPreview(
                                    key: Key(
                                      'widget-preview-${showcase.composition.name}',
                                    ),
                                    composition: showcase.composition,
                                    edition: widget.edition,
                                    publication: widget.publication,
                                    width:
                                        unit * showcase.composition.widthUnits,
                                    height:
                                        unit * showcase.composition.heightUnits,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _WidgetCaption(
                                title: showcase.title,
                                detail: showcase.detail,
                                palette: widget.palette,
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _showcases.length,
                    (index) => AnimatedContainer(
                      key: Key('widget-carousel-dot-$index'),
                      duration: motionDurationOf(
                        context,
                        const Duration(milliseconds: 180),
                      ),
                      width: index == _currentPage ? 8 : 6,
                      height: index == _currentPage ? 8 : 6,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentPage
                            ? widget.palette.accent
                            : widget.palette.secondary.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your widgets match your Edition. Change your Edition anytime in Appearance, and your widgets will follow.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.palette.secondary,
                    fontFamily: 'Figtree',
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
            child: Column(
              children: [
                _GoldButton(
                  label: 'Explore Diurnus',
                  onPressed: widget.saving ? null : widget.onExplore,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => _showInstructions(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: widget.palette.primary,
                      side: BorderSide(
                        color: widget.palette.divider.withValues(alpha: 0.75),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'NotoSerifJP',
                        fontSize: 16,
                      ),
                    ),
                    child: const Text('How to add a widget'),
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

class _WidgetShowcase {
  const _WidgetShowcase({
    required this.composition,
    required this.title,
    required this.detail,
  });

  final WidgetPreviewComposition composition;
  final String title;
  final String detail;
}

enum WidgetPreviewComposition { small, medium, large }

extension on WidgetPreviewComposition {
  double get widthUnits => switch (this) {
    WidgetPreviewComposition.small => 1,
    WidgetPreviewComposition.medium || WidgetPreviewComposition.large => 2,
  };

  double get heightUnits => switch (this) {
    WidgetPreviewComposition.small || WidgetPreviewComposition.medium => 1,
    WidgetPreviewComposition.large => 2,
  };
}

class WidgetEditionPreview extends StatelessWidget {
  const WidgetEditionPreview({
    required this.composition,
    required this.edition,
    required this.publication,
    required this.width,
    required this.height,
    super.key,
  });

  final WidgetPreviewComposition composition;
  final Edition edition;
  final DailyPublication publication;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: edition.mutedTextColor.withValues(alpha: 0.55),
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: EditionBackground(
            edition: edition,
            child: Padding(
              padding: switch (composition) {
                WidgetPreviewComposition.small => const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                WidgetPreviewComposition.medium => const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                WidgetPreviewComposition.large => const EdgeInsets.fromLTRB(
                  20,
                  28,
                  20,
                  22,
                ),
              },
              child: _widgetContent(),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _widgetContent() => switch (composition) {
    WidgetPreviewComposition.small => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_type(), const SizedBox(height: 2), _word(30)],
    ),
    WidgetPreviewComposition.medium => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_word(28), const SizedBox(height: 2), _definition()],
    ),
    WidgetPreviewComposition.large => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _type(),
        const SizedBox(height: 4),
        _word(32),
        Text(
          publication.phonetic,
          style: TextStyle(
            color: edition.secondaryTextColor,
            fontFamily: 'Figtree',
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: _definition()),
            Text(
              '#${publication.sequence}',
              style: TextStyle(
                color: edition.secondaryTextColor,
                fontFamily: 'Figtree',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    ),
  };

  Widget _type() => Text(
    publication.type.toUpperCase(),
    style: TextStyle(
      color: edition.secondaryTextColor,
      fontFamily: 'Figtree',
      fontSize: 10,
      letterSpacing: 0.8,
    ),
  );

  Widget _word(double size) => Text(
    publication.word,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: edition.primaryTextColor,
      fontFamily: 'NotoSerifJP',
      fontSize: size,
      height: 1.05,
    ),
  );

  Widget _definition() => Text(
    publication.definition,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: edition.secondaryTextColor,
      fontFamily: 'Figtree',
      fontSize: 13,
      height: 1.25,
    ),
  );
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.onBack,
  });

  final String step;
  final String title;
  final String subtitle;
  final InterfacePalette palette;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 22, 14),
    child: Column(
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('onboarding-back'),
              tooltip: 'Back',
              onPressed: onBack,
              icon: Icon(CupertinoIcons.back, color: palette.primary, size: 26),
            ),
            const Spacer(),
            _StepLabel(step, color: palette.accent),
          ],
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.primary,
            fontFamily: 'NotoSerifJP',
            fontSize: 30,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.secondary,
            fontFamily: 'Figtree',
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    ),
  );
}

class _StepLabel extends StatelessWidget {
  const _StepLabel(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: color,
      fontFamily: 'Figtree',
      fontSize: 13,
      letterSpacing: 0.6,
    ),
  );
}

class _WidgetCaption extends StatelessWidget {
  const _WidgetCaption({
    required this.title,
    required this.detail,
    required this.palette,
  });

  final String title;
  final String detail;
  final InterfacePalette palette;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: palette.primary,
          fontFamily: 'NotoSerifJP',
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        detail,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: palette.secondary,
          fontFamily: 'Figtree',
          fontSize: 10,
        ),
      ),
    ],
  );
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 58,
    child: FilledButton(
      key: Key('onboarding-${label.toLowerCase().replaceAll(' ', '-')}'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFD8AA61),
        foregroundColor: const Color(0xFF18130D),
        disabledBackgroundColor: const Color(0xFFD8AA61).withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        textStyle: const TextStyle(
          fontFamily: 'NotoSerifJP',
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 14),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    ),
  );
}
