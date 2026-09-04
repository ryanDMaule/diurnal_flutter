// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/subscription_tier.dart';
import '../services/entitlement_service.dart';
import '../theme/interface_theme.dart';
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

  final EntitlementController controller;
  final String backTooltip;

  @override
  Widget build(BuildContext context) {
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: InterfaceSafeArea(
        child: CustomScrollView(
          key: Key('pro-scroll-view'),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 36),
              sliver: SliverList.list(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: backTooltip,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        CupertinoIcons.back,
                        color: palette.primary,
                        size: 26,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Diurnus Pro',
                    style: TextStyle(
                      color: palette.primary,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Go beyond the word of the day.',
                    style: TextStyle(
                      color: palette.accent,
                      fontFamily: 'NotoSerifJP',
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Remember more. Explore further. Make Diurnus yours.',
                    style: TextStyle(
                      color: palette.primary.withValues(alpha: 0.64),
                      fontFamily: 'Figtree',
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 34),
                  _StatusArea(isPro: controller.isPro),
                  SizedBox(height: 42),
                  _ValueArea(
                    title: 'Full Archive',
                    body:
                        'Explore every published word, not just the last five days.',
                  ),
                  _ValueArea(
                    title: 'Advanced Recall',
                    body:
                        'Choose larger sessions, focused word pools, and additional question types.',
                  ),
                  _ValueArea(
                    title: 'Match & Endless',
                    body:
                        'Practise through rapid association or keep going until your first miss.',
                  ),
                  _ValueArea(
                    title: 'All Editions',
                    body:
                        'Unlock Atrium, Archive, and Gallery alongside Library and Midnight.',
                  ),
                  if (kDebugMode) ...[
                    SizedBox(height: 18),
                    Divider(height: 1, color: palette.divider),
                    SizedBox(height: 30),
                    Text(
                      'Developer entitlement',
                      style: TextStyle(
                        color: palette.primary.withValues(alpha: 0.62),
                        fontFamily: 'Figtree',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CupertinoSlidingSegmentedControl<SubscriptionTier>(
                        key: Key('developer-entitlement-control'),
                        groupValue: controller.tier,
                        backgroundColor: palette.surface,
                        thumbColor: palette.accent.withValues(alpha: 0.82),
                        children: {
                          SubscriptionTier.free: _TierLabel(
                            key: Key('developer-tier-free'),
                            label: 'Free',
                            selected: !controller.isPro,
                          ),
                          SubscriptionTier.pro: _TierLabel(
                            key: Key('developer-tier-pro'),
                            label: 'Pro',
                            selected: controller.isPro,
                          ),
                        },
                        onValueChanged: (tier) {
                          if (tier != null) controller.update(tier);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusArea extends StatelessWidget {
  const _StatusArea({required this.isPro});

  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    return Container(
      key: Key('pro-current-status'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: palette.divider),
      ),
      child: Text(
        isPro ? 'Diurnus Pro active' : 'Diurnus Free',
        style: TextStyle(
          color: isPro ? palette.accent : palette.primary,
          fontFamily: 'Figtree',
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _ValueArea extends StatelessWidget {
  const _ValueArea({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.primary,
              fontFamily: 'NotoSerifJP',
              fontSize: 21,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: palette.primary.withValues(alpha: 0.6),
              fontFamily: 'Figtree',
              fontSize: 15,
              fontWeight: FontWeight.w300,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TierLabel extends StatelessWidget {
  const _TierLabel({required this.label, required this.selected, super.key});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final palette = InterfaceThemeScope.maybePaletteOf(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? palette.background : palette.primary,
          fontFamily: 'Figtree',
          fontSize: 13,
        ),
      ),
    );
  }
}
