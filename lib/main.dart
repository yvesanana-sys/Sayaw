import 'package:flutter/material.dart';

/// Placeholder entry point.
///
/// The real shell — playlist view, deck transport, announcement controls — is
/// not built yet, and the audio engine is deliberately not wired up here. The
/// engine is pure Dart under test; keeping `main()` empty until there is a UI
/// worth booting means nothing in this file can quietly become load-bearing.
void main() {
  runApp(const SayawApp());
}

class SayawApp extends StatelessWidget {
  const SayawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sayaw',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8E4EC6)),
      ),
      home: const Scaffold(
        body: Center(child: Text('Sayaw')),
      ),
    );
  }
}
