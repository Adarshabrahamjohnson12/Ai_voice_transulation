import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translator/translator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const VoiceTranslatorApp());
}

class VoiceTranslatorApp extends StatelessWidget {
  const VoiceTranslatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const TranslatorHome(),
      debugShowCheckedModeBanner: false,
      title: 'AI Voice Translator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
    );
  }
}

class TranslatorHome extends StatefulWidget {
  const TranslatorHome({super.key});

  @override
  State<TranslatorHome> createState() => _TranslatorHomeState();
}

class _TranslatorHomeState extends State<TranslatorHome> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final GoogleTranslator _translator = GoogleTranslator();

  bool _isListening = false;
  String _spokenText = '';
  String _translatedText = '';
  String _selectedLanguage = 'es'; // Default target language (Spanish)
  String _detectedSourceLanguage = 'en'; // fallback to English

  final Map<String, String> _languages = {
    'Spanish': 'es',
    'French': 'fr',
    'German': 'de',
    'Hindi': 'hi',
    'Chinese': 'zh-cn',
    'Japanese': 'ja',
    'Malayalam': 'ml',
    'Tamil': 'ta',
  };

  @override
  void initState() {
    super.initState();
    _requestMicrophonePermission();
  }

  Future<void> _requestMicrophonePermission() async {
    await Permission.microphone.request();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        print('Speech error: $error');
        setState(() => _isListening = false);
      },
    );

    if (available) {
      final locales = await _speech.locales();
      final systemLocale = await _speech.systemLocale();
      String localeId = systemLocale?.localeId ?? locales.first.localeId;

      print('Using localeId: $localeId');

      setState(() {
        _isListening = true;
        _detectedSourceLanguage = localeId.split('_')[0];
      });

      _speech.listen(
        localeId: localeId,
        onResult: (result) async {
          String spoken = result.recognizedWords;
          setState(() => _spokenText = spoken);

          if (spoken.isNotEmpty) {
            var translation = await _translator.translate(
              spoken,
              from: _detectedSourceLanguage,
              to: _selectedLanguage,
            );
            setState(() => _translatedText = translation.text);
          }
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌍 Auto Detect Voice Language Translator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Select Target Language',
                    border: OutlineInputBorder(),
                  ),
                  items: _languages.entries
                      .map(
                        (entry) => DropdownMenuItem<String>(
                          value: entry.value,
                          child: Text(entry.key),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLanguage = value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Text('Detected input language: $_detectedSourceLanguage'),
                const SizedBox(height: 10),
                TextField(
                  maxLines: 2,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '🎧 Heard:',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: _spokenText),
                ),
                const SizedBox(height: 20),
                TextField(
                  maxLines: 2,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '🌍 Translated:',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: _translatedText),
                ),
                const SizedBox(height: 30),
                AnimatedMicButton(
                  isListening: _isListening,
                  onPressed: _toggleListening,
                ),
              ],
            ),
            Positioned(
              bottom: 5,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Developed by Adarsh Abraham',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedMicButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isListening;

  const AnimatedMicButton({
    required this.onPressed,
    required this.isListening,
    Key? key,
  }) : super(key: key);

  @override
  _AnimatedMicButtonState createState() => _AnimatedMicButtonState();
}

class _AnimatedMicButtonState extends State<AnimatedMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isListening) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        backgroundColor: widget.isListening ? Colors.red : Colors.blue,
        child: Icon(
          widget.isListening ? Icons.mic : Icons.mic_none,
          size: 32,
        ),
      ),
    );
  }
}

