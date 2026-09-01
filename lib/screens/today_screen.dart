import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../models/daily_publication.dart';
import '../theme/colors.dart';
import '../widgets/morphing_menu_button.dart';
import 'package:flutter/cupertino.dart';

import 'menu_screen.dart';

Future<void> updateWidget(String word, String definition) async {
  await HomeWidget.saveWidgetData<String>('word', word);
  await HomeWidget.saveWidgetData<String>('definition', definition);
  await HomeWidget.updateWidget(
    name: 'HomeWidgetProvider',
    androidName: 'HomeWidgetProvider',
    iOSName: 'HomeWidget',
    qualifiedAndroidName: 'com.example.diurnul.HomeWidgetProvider',
  );
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  String selectedTab = 'definition';
  bool isLoading = true;
  bool isOffline = false;

  late DailyPublication publication;

  String formatDate(DateTime date) {
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

  @override
  void initState() {
    super.initState();
    publication = DailyPublication.localFallback;
    fetchWordOfTheDay();
  }

  Future<void> fetchWordOfTheDay() async {
    const apiUrl = 'https://diurnal-api-7zz8.onrender.com/word';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is! Map<String, dynamic>) {
          throw const FormatException('Invalid publication response.');
        }
        final fetchedPublication = DailyPublication.fromJson(data);
        if (!mounted) return;
        setState(() {
          publication = fetchedPublication;
          isLoading = false;
          isOffline = false;
        });

        // ✅ Update home widget
        await updateWidget(
          fetchedPublication.word,
          fetchedPublication.definition,
        );
      } else {
        debugPrint(
          '⚠️ API returned ${response.statusCode}. Using fallback word.',
        );
        if (!mounted) return;
        setState(() {
          publication = DailyPublication.localFallback;
          isLoading = false;
          isOffline = true;
        });

        // ✅ Push fallback to widget as well
        await updateWidget(publication.word, publication.definition);
      }
    } catch (e) {
      debugPrint('❌ Error fetching word: $e');
      if (!mounted) return;
      setState(() {
        publication = DailyPublication.localFallback;
        isLoading = false;
        isOffline = true;
      });

      // ✅ Ensure widget still shows something
      await updateWidget(publication.word, publication.definition);
    }
  }

  Widget getContent() {
    switch (selectedTab) {
      case 'usage':
        return Text(
          publication.usage,
          key: const ValueKey('usage'),
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppColors.textPrimary,
            fontFamily: 'Figtree',
            fontWeight: FontWeight.w300,
          ),
        );

      case 'synonyms':
        return Column(
          key: const ValueKey('synonyms'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final synonym in publication.synonyms)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "• $synonym",
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: AppColors.textPrimary,
                    fontFamily: 'Figtree',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
          ],
        );

      default:
        return Text(
          publication.definition,
          key: const ValueKey('definition'),
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppColors.textPrimary,
            fontFamily: 'Figtree',
            fontWeight: FontWeight.w300,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    final wordType = publication.type;
    final word = publication.word;
    final phonetic = publication.phonetic;
    final footerDate = publication.publicationDate == null
        ? 'Date unavailable'
        : formatDate(publication.publicationDate!);
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🧭 Push content to start halfway down the screen
                    SizedBox(height: screenHeight * 0.4),

                    // ✅ Offline banner
                    if (isOffline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "⚠️ Offline mode — showing default word",
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontFamily: 'Figtree',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),

                    // Word Type
                    Text(
                      wordType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1,
                      ),
                    ),

                    // Word
                    Text(
                      word,
                      style: const TextStyle(
                        fontSize: 54,
                        color: AppColors.textPrimary,
                        fontFamily: 'NotoSerifJP',
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    // Phonetic
                    Text(
                      phonetic,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        fontFamily: 'Figtree',
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Definition / Usage / Synonyms tabs
                    Row(
                      children: [
                        for (final label in ['definition', 'usage', 'synonyms'])
                          Padding(
                            padding: const EdgeInsets.only(right: 28.0),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  selectedTab = label;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      opacity: selectedTab == label ? 1.0 : 0.5,
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

                    // 📝 Description area — now wraps its content
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            final fadeIn = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOut,
                            );

                            final scaleIn = Tween<double>(begin: 0.98, end: 1.0)
                                .animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutBack,
                                  ),
                                );

                            return FadeTransition(
                              opacity: fadeIn,
                              child: ScaleTransition(
                                scale: scaleIn,
                                child: child,
                              ),
                            );
                          },
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topLeft,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: getContent(),
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
                        child: Text(
                          footerDate,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.8,
                            ),
                            fontFamily: 'Figtree',
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),

                      Icon(
                        CupertinoIcons.bookmark,
                        size: 30,
                        color: AppColors.textPrimary.withValues(alpha: 0.6),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          footerSequence,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.8,
                            ),
                            fontFamily: 'Figtree',
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 20,
                  right: 4,
                  child: MorphingMenuButton(
                    isOpen: false,
                    tooltip: 'Open menu',
                    onPressed: () {
                      final reduceMotion = MediaQuery.of(
                        context,
                      ).disableAnimations;
                      Navigator.of(context).push(
                        PageRouteBuilder<void>(
                          transitionDuration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 250),
                          reverseTransitionDuration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 250),
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const MenuScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOut,
                                    reverseCurve: Curves.easeIn,
                                  ),
                                  child: child,
                                );
                              },
                        ),
                      );
                    },
                  ),
                ),

                // 🌀 Small corner loading indicator (top-right)
                if (isLoading)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: SizedBox(
                      width: 20,
                      height: 20,
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
