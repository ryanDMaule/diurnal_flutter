import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:home_widget/home_widget.dart';

Future<void> updateWidget(String word, String definition) async {
  await HomeWidget.saveWidgetData<String>('word', word);
  await HomeWidget.saveWidgetData<String>('definition', definition);
  await HomeWidget.updateWidget(
    name: 'HomeWidgetProvider',
    androidName: 'HomeWidgetProvider',
    iOSName: 'HomeWidget',
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
  String selectedTab = 'Definition';
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
    "synonyms": ["Daily", "Daytime", "Circadian"]
  };

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
      debugPrint('⚠️ API returned ${response.statusCode}. Using fallback word.');
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

  String getContent() {
    switch (selectedTab) {
      case 'Usage':
        return wordData['usage'];
      case 'Synonyms':
        return (wordData['synonyms'] as List<dynamic>).join(', ');
      default:
        return wordData['definition'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final double descriptionHeight = MediaQuery.of(context).size.height * 0.25;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final wordType = wordData['type'];
    final word = wordData['word'];
    final phonetic = wordData['phonetic'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              // ✅ Offline banner
              if (isOffline)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    "⚠️ Offline mode — showing default word",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ),

              // Word Type
              Text(
                wordType.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.indigo[400],
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              // Word
              Text(
                word,
                style: const TextStyle(
                  fontSize: 54,
                  color: Colors.black87,
                  fontFamily: 'NotoSerifJP',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),

              // // Phonetic + Speaker Icon Row
              // Row(
              //   crossAxisAlignment: CrossAxisAlignment.center,
              //   children: [
              //     Text(
              //       phonetic,
              //       style: TextStyle(
              //         fontFamily: 'NotoSerifJP',
              //         fontSize: 18,
              //         fontStyle: FontStyle.italic,
              //         color: Colors.grey[700],
              //       ),
              //     ),
              //     const SizedBox(width: 8),
              //     IconButton(
              //       icon: const Icon(Icons.volume_up_rounded),
              //       color: Colors.indigo[400],
              //       iconSize: 24,
              //       onPressed: playPronunciation,
              //       tooltip: 'Hear pronunciation',
              //     ),
              //   ],
              // ),

              // Phonetic only
              Text(
                phonetic,
                style: TextStyle(
                  fontFamily: 'NotoSerifJP',
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),


              // Pills row
              Row(
                children: [
                  for (final label in ['Definition', 'Usage', 'Synonyms'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(label),
                        labelStyle: TextStyle(
                          color: selectedTab == label
                              ? Colors.white
                              : Colors.indigo[400],
                          fontWeight: FontWeight.w600,
                        ),
                        selected: selectedTab == label,
                        selectedColor: Colors.indigo[400],
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.indigo[200]!,
                            width: 1,
                          ),
                        ),
                        onSelected: (_) {
                          setState(() => selectedTab = label);
                        },
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Fixed-height area for description
              SizedBox(
                height: descriptionHeight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    getContent(),
                    key: ValueKey(selectedTab),
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
