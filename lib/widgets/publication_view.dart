import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/daily_publication.dart';
import '../theme/colors.dart';

class PublicationView extends StatefulWidget {
  const PublicationView({
    required this.publication,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    this.isBookmarkUpdating = false,
    this.isLoading = false,
    this.isOffline = false,
    this.topLeftControl,
    this.topRightControl,
    super.key,
  });

  final DailyPublication publication;
  final bool isBookmarked;
  final bool isBookmarkUpdating;
  final bool isLoading;
  final bool isOffline;
  final VoidCallback? onBookmarkToggle;
  final Widget? topLeftControl;
  final Widget? topRightControl;

  @override
  State<PublicationView> createState() => _PublicationViewState();
}

class _PublicationViewState extends State<PublicationView> {
  String selectedTab = 'definition';

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _content() {
    const style = TextStyle(
      fontSize: 16,
      height: 1.6,
      color: AppColors.textPrimary,
      fontFamily: 'Figtree',
      fontWeight: FontWeight.w300,
    );
    switch (selectedTab) {
      case 'usage':
        return Text(
          widget.publication.usage,
          key: const ValueKey('usage'),
          textAlign: TextAlign.start,
          style: style,
        );
      case 'synonyms':
        return Column(
          key: const ValueKey('synonyms'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final synonym in widget.publication.synonyms)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $synonym', style: style),
              ),
          ],
        );
      default:
        return Text(
          widget.publication.definition,
          key: const ValueKey('definition'),
          textAlign: TextAlign.start,
          style: style,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final publication = widget.publication;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final footerDate = publication.publicationDate == null
        ? 'Date unavailable'
        : _formatDate(publication.publicationDate!);
    final footerSequence = publication.sequence == null
        ? '#—'
        : '#${publication.sequence}';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.4),
                    if (widget.isOffline)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          '⚠️ Offline mode — showing default word',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontFamily: 'Figtree',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    Text(
                      publication.type.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      publication.word,
                      style: const TextStyle(
                        fontSize: 54,
                        color: AppColors.textPrimary,
                        fontFamily: 'NotoSerifJP',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      publication.phonetic,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontFamily: 'Figtree',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        for (final label in ['definition', 'usage', 'synonyms'])
                          Padding(
                            padding: const EdgeInsets.only(right: 28),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => selectedTab = label),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      opacity: selectedTab == label ? 1 : 0.5,
                                      child: Text(
                                        '${label[0].toUpperCase()}${label.substring(1)}',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Figtree',
                                          fontSize: 16,
                                          fontWeight: selectedTab == label
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      width: selectedTab == label ? 22 : 0,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFC59A5B),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.98, end: 1).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      ),
                      child: _content(),
                    ),
                    const Spacer(),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(footerDate, style: _footerStyle),
                      ),
                      Semantics(
                        button: true,
                        enabled:
                            widget.onBookmarkToggle != null &&
                            !widget.isBookmarkUpdating,
                        label: widget.isBookmarked
                            ? 'Remove bookmark'
                            : 'Save bookmark',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.isBookmarkUpdating
                              ? null
                              : widget.onBookmarkToggle,
                          child: SizedBox.square(
                            dimension: 30,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 130),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                              child: Icon(
                                widget.isBookmarked
                                    ? CupertinoIcons.bookmark_fill
                                    : CupertinoIcons.bookmark,
                                key: ValueKey(widget.isBookmarked),
                                size: 30,
                                color: widget.isBookmarked
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary.withValues(
                                        alpha: widget.onBookmarkToggle == null
                                            ? 0.25
                                            : 0.6,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(footerSequence, style: _footerStyle),
                      ),
                    ],
                  ),
                ),
                if (widget.topLeftControl != null)
                  Positioned(top: 20, left: 4, child: widget.topLeftControl!),
                if (widget.topRightControl != null)
                  Positioned(top: 20, right: 4, child: widget.topRightControl!),
                if (widget.isLoading)
                  const Positioned(
                    top: 12,
                    left: 12,
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final _footerStyle = TextStyle(
  color: AppColors.textSecondary.withValues(alpha: 0.8),
  fontFamily: 'Figtree',
  fontSize: 14,
  fontWeight: FontWeight.w300,
);
