import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/bookmark_service.dart';
import '../services/edition_service.dart';
import '../services/publication_api_service.dart';
import '../theme/colors.dart';
import '../widgets/morphing_menu_button.dart';
import 'archive_screen.dart';
import 'appearance_screen.dart';
import 'my_lexicon_screen.dart';
import 'placeholder_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({
    this.archiveApiService,
    this.bookmarkService,
    this.editionService,
    super.key,
  });

  final PublicationApiService? archiveApiService;
  final BookmarkService? bookmarkService;
  final EditionService? editionService;

  void _openDestination(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PlaceholderScreen(title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.menuBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MenuHeader(onClose: () => Navigator.of(context).pop()),
                    const SizedBox(height: 72),
                    _MenuItem(
                      icon: CupertinoIcons.book,
                      title: 'Today',
                      subtitle: 'The word of the day',
                      isSelected: true,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 18),
                    _MenuItem(
                      icon: CupertinoIcons.bookmark,
                      title: 'My Lexicon',
                      subtitle: 'Your saved words',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => MyLexiconScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _MenuItem(
                      icon: CupertinoIcons.archivebox,
                      title: 'Archive',
                      subtitle: 'Every word, every day',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => ArchiveScreen(
                            apiService: archiveApiService,
                            bookmarkService: bookmarkService,
                            editionService: editionService,
                          ),
                        ),
                      ),
                    ),
                    const _MenuDivider(),
                    _MenuItem(
                      icon: CupertinoIcons.circle_grid_hex,
                      title: 'Appearance',
                      subtitle: 'Diurnus editions',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => AppearanceScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _MenuItem(
                      icon: CupertinoIcons.star_circle,
                      title: 'Diurnus Pro',
                      subtitle: 'Unlock the full experience',
                      isPremium: true,
                      trailing: const _ProBadge(),
                      onTap: () => _openDestination(context, 'Diurnus Pro'),
                    ),
                    const _MenuDivider(),
                    _MenuItem(
                      icon: CupertinoIcons.gear,
                      title: 'Settings',
                      onTap: () => _openDestination(context, 'Settings'),
                    ),
                    const _MenuDivider(),
                    _MenuItem(
                      icon: CupertinoIcons.info_circle,
                      title: 'About Diurnus',
                      onTap: () => _openDestination(context, 'About Diurnus'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset(
          'assets/images/branding.png',
          width: 136,
          fit: BoxFit.contain,
        ),
        MorphingMenuButton(
          isOpen: true,
          tooltip: 'Close menu',
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.isSelected = false,
    this.isPremium = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool isSelected;
  final bool isPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected || isPremium
        ? AppColors.textSecondary
        : AppColors.textPrimary;

    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Icon(icon, size: 31, color: iconColor),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'NotoSerifJP',
                        fontSize: 27,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: AppColors.textPrimary.withValues(alpha: 0.58),
                          fontFamily: 'Figtree',
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 22),
      child: Divider(height: 1, thickness: 1, color: AppColors.menuDivider),
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.textSecondary),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
