// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/edition.dart';
import '../models/subscription_tier.dart';
import '../services/entitlement_service.dart';
import '../widgets/edition_background.dart';
import '../widgets/entitlement_scope.dart';

class ProScreen extends StatelessWidget {
  ProScreen({
    this.entitlementController,
    this.backTooltip = 'Back to menu',
    super.key,
  });

  final EntitlementController? entitlementController;
  final String backTooltip;

  @override
  Widget build(BuildContext context) {
    final controller =
        entitlementController ?? EntitlementScope.controllerOf(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) =>
          _ProContent(controller: controller, backTooltip: backTooltip),
    );
  }
}

class _ProContent extends StatelessWidget {
  const _ProContent({required this.controller, required this.backTooltip});

  static const _proEdition = Edition(
    id: 'pro-background',
    name: 'Pro',
    description: '',
    backgroundAsset: 'assets/images/pro.png',
    tintColor: Color(0xFF000000),
    tintOpacity: 0.30,
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

  final EntitlementController controller;
  final String backTooltip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: EditionBackground(
        edition: _proEdition,
        child: SafeArea(
          child: CustomScrollView(
            key: Key('pro-scroll-view'),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 34),
                sliver: SliverList.list(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: backTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          CupertinoIcons.back,
                          color: _proEdition.primaryTextColor,
                          size: 27,
                        ),
                      ),
                    ),
                    SizedBox(height: 60),
                    _TitleLockup(),
                    SizedBox(height: 24),
                    Text(
                      'Go deeper into the language.',
                      style: TextStyle(
                        color: _proEdition.primaryTextColor,
                        fontFamily: 'NotoSerifJP',
                        fontSize: 25,
                        fontWeight: FontWeight.w300,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 34),
                    _FeatureRow(
                      icon: Icons.play_circle_outline_rounded,
                      title: 'Recall Games',
                      description:
                          'Match, Endless and advanced ways to explore your words.',
                    ),
                    _FeatureRow(
                      icon: Icons.menu_book_outlined,
                      title: 'Full Archive',
                      description:
                          'Return to every word Diurnus has published.',
                    ),
                    _FeatureRow(
                      icon: Icons.collections_outlined,
                      title: 'Premium Editions',
                      description:
                          'Unlock the complete collection of photographic Editions.',
                    ),
                    _FeatureRow(
                      icon: Icons.school_outlined,
                      title: 'Advanced Recall',
                      description:
                          'More session lengths, directions and ways to practise.',
                    ),
                    SizedBox(height: 10),
                    _PricingSelector(),
                    SizedBox(height: 26),
                    _ProCta(controller: controller),
                    SizedBox(height: 24),
                    Text(
                      'Cancel anytime.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _proEdition.mutedTextColor,
                        fontFamily: 'Figtree',
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.4,
                      ),
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

class _TitleLockup extends StatelessWidget {
  const _TitleLockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Diurnus',
              style: TextStyle(
                color: _ProContent._proEdition.primaryTextColor,
                fontFamily: 'NotoSerifJP',
                fontSize: 43,
                fontWeight: FontWeight.w400,
                height: 1,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'PRO',
              style: TextStyle(
                color: _ProContent._proEdition.accentColor,
                fontFamily: 'Figtree',
                fontSize: 21,
                fontWeight: FontWeight.w500,
                letterSpacing: 5,
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Container(
          width: 36,
          height: 1.5,
          color: _ProContent._proEdition.accentColor,
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 27),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.34),
              border: Border.all(
                color: _ProContent._proEdition.accentColor.withValues(
                  alpha: 0.16,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 25,
              color: _ProContent._proEdition.accentColor,
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
                    color: _ProContent._proEdition.primaryTextColor,
                    fontFamily: 'NotoSerifJP',
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    color: _ProContent._proEdition.secondaryTextColor
                        .withValues(alpha: 0.74),
                    fontFamily: 'Figtree',
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ProPlan { monthly, yearly }

class _PricingSelector extends StatefulWidget {
  const _PricingSelector();

  @override
  State<_PricingSelector> createState() => _PricingSelectorState();
}

class _PricingSelectorState extends State<_PricingSelector> {
  _ProPlan _selectedPlan = _ProPlan.yearly;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final monthly = _PlanOption(
              label: '£2.99 / month',
              selected: _selectedPlan == _ProPlan.monthly,
              onTap: () => setState(() => _selectedPlan = _ProPlan.monthly),
            );
            final yearly = _PlanOption(
              label: '£15 / year',
              badge: 'Best value',
              selected: _selectedPlan == _ProPlan.yearly,
              onTap: () => setState(() => _selectedPlan = _ProPlan.yearly),
            );
            if (constraints.maxWidth < 340) {
              return Column(
                children: [monthly, SizedBox(height: 12), yearly],
              );
            }
            return Row(
              children: [
                Expanded(child: monthly),
                SizedBox(width: 12),
                Expanded(child: yearly),
              ],
            );
          },
        ),
        SizedBox(height: 16),
        Text(
          'Save £20.88 with yearly.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ProContent._proEdition.secondaryTextColor.withValues(
              alpha: 0.72,
            ),
            fontFamily: 'Figtree',
            fontSize: 13,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _ProContent._proEdition.accentColor;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 56),
                child: Ink(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: selected
                          ? accent
                          : _ProContent._proEdition.mutedTextColor.withValues(
                              alpha: 0.46,
                            ),
                      width: selected ? 1.25 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? accent : Colors.transparent,
                          border: Border.all(
                            color: selected
                                ? accent
                                : _ProContent._proEdition.secondaryTextColor
                                      .withValues(alpha: 0.72),
                            width: 1.4,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: selected
                            ? Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF17140E),
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                            color: selected
                                ? accent
                                : _ProContent._proEdition.primaryTextColor,
                            fontFamily: 'Figtree',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -8,
              right: 12,
              child: IgnorePointer(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    maxLines: 1,
                    style: TextStyle(
                      color: Color(0xFF17140E),
                      fontFamily: 'Figtree',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProCta extends StatelessWidget {
  const _ProCta({required this.controller});

  final EntitlementController controller;

  @override
  Widget build(BuildContext context) {
    final target = controller.isPro
        ? SubscriptionTier.free
        : SubscriptionTier.pro;
    return Semantics(
      button: true,
      label: controller.isPro ? 'Return to Free' : 'Enter Pro',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('pro-entitlement-toggle'),
          onTap: () => controller.update(target),
          borderRadius: BorderRadius.circular(34),
          child: Ink(
            height: 66,
            decoration: BoxDecoration(
              color: _ProContent._proEdition.accentColor,
              borderRadius: BorderRadius.circular(34),
            ),
            padding: EdgeInsets.symmetric(horizontal: 27),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.isPro ? 'Return to Free' : 'Enter Pro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF17140E),
                      fontFamily: 'NotoSerifJP',
                      fontSize: 21,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF17140E),
                  size: 25,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
