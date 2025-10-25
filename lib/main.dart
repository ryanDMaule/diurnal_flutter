import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'theme/colors.dart';

Future<void> updateWidget(String word, String definition) async {
  await HomeWidget.saveWidgetData<String>('word', word);
  await HomeWidget.saveWidgetData<String>('definition', definition);
  await HomeWidget.updateWidget(
    name: 'HomeWidgetProvider',
    androidName: 'HomeWidgetProvider',
    iOSName: 'HomeWidget',
    qualifiedAndroidName: 'com.example.HomeWidgetProvider',
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DiurnalApp());
}

class DiurnalApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diurnal',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.indigo,
        fontFamily: 'Inter',
      ),
      home: const WordScreen(),
    );
  }
}

class WordScreen extends StatefulWidget {
  const WordScreen({super.key});

  @override
  State<WordScreen> createState() => _WordScreenState();
}

class _WordScreenState extends State<WordScreen> {
  final player = AudioPlayer();
  String selectedTab = 'definition';
  bool isLoading = true;
  bool isOffline = false;

  // ✅ Word data (can be overridden by API)
  late Map<String, dynamic> wordData;

  // ✅ Default fallback word
  final Map<String, dynamic> fallbackWord = {
    "date": "2025-10-05",
    "word": "Diurnal",
    "type": "Adjective",
    "phonetic": "di·​ur·​nal",
    "definition":
        "Occurring or active during the daytime; relating to or happening once every day.",
    "usage":
        "Unlike nocturnal creatures, diurnal animals such as squirrels and hawks are active during the day.",
    "synonyms": ["Daily", "Daytime", "Circadian"],
  };

  // Local variable to track pressed pill
  String? _isPressed;

  @override
  void initState() {
    super.initState();
    wordData = fallbackWord; // Initialize with default
    fetchWordOfTheDay();
  }

  Future<void> fetchWordOfTheDay() async {
    const apiUrl = 'https://diurnal-api-7zz8.onrender.com/word';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          wordData = data;
          isLoading = false;
          isOffline = false;
        });

        // ✅ Update home widget
        await updateWidget(wordData['word'], wordData['definition']);
      } else {
        debugPrint(
          '⚠️ API returned ${response.statusCode}. Using fallback word.',
        );
        setState(() {
          wordData = fallbackWord;
          isLoading = false;
          isOffline = true;
        });

        // ✅ Push fallback to widget as well
        await updateWidget(wordData['word'], wordData['definition']);
      }
    } catch (e) {
      debugPrint('❌ Error fetching word: $e');
      setState(() {
        wordData = fallbackWord;
        isLoading = false;
        isOffline = true;
      });

      // ✅ Ensure widget still shows something
      await updateWidget(wordData['word'], wordData['definition']);
    }
  }

  // Future<void> playPronunciation() async {
  //   try {
  //     await player.play(AssetSource('audio/diurnul.mp3'));
  //   } catch (e) {
  //     debugPrint('EEEEEK : Error playing audio: $e');
  //   }
  // }

  Widget getContent() {
    switch (selectedTab) {
      case 'usage':
        return Text(
          wordData['usage'],
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
        final synonyms = (wordData['synonyms'] as List<dynamic>).cast<String>();
        return Column(
          key: const ValueKey('synonyms'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final synonym in synonyms)
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
          wordData['definition'],
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

  final wordType = wordData['type'];
  final word = wordData['word'];
  final phonetic = wordData['phonetic'];

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
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontFamily: 'Figtree',
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
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
                      fontSize: 18,
                      color: AppColors.textPrimary,
                      fontFamily: 'Figtree',
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Pills row
                  Row(
                    children: [
                      for (final label in ['definition', 'usage', 'synonyms'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTapDown: (_) => setState(() => _isPressed = label),
                            onTapUp: (_) {
                              setState(() {
                                _isPressed = null;
                                selectedTab = label;
                              });
                            },
                            onTapCancel: () => setState(() => _isPressed = null),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: _isPressed == label ? 0.6 : 1.0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selectedTab == label
                                        ? AppColors.textPrimary.withOpacity(1.0)
                                        : AppColors.textPrimary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: selectedTab == label
                                        ? AppColors.textPrimary.withOpacity(1.0)
                                        : AppColors.textPrimary.withOpacity(0.4),
                                    fontFamily: 'Figtree',
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
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

                      final scaleIn = Tween<double>(begin: 0.98, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      );

                      return FadeTransition(
                        opacity: fadeIn,
                        child: ScaleTransition(scale: scaleIn, child: child),
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

              // 🌀 Small corner loading indicator (top-right)
              if (isLoading)
                Positioned(
                  top: 12,
                  right: 12,
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation(AppColors.textPrimary),
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