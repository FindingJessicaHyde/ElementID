import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert';

/// Entry point of the application.  Runs the theme editing app.
void main() {
  runApp(const ThemeEditingApp());
}

/// Root widget that manages theme editing and wraps the part number generator.
class ThemeEditingApp extends StatefulWidget {
  const ThemeEditingApp({super.key});
  @override
  State<ThemeEditingApp> createState() => _ThemeEditingAppState();
}

class _ThemeEditingAppState extends State<ThemeEditingApp> {
  Color primary = const Color.fromARGB(255, 34, 35, 34);
  Color background = const Color.fromARGB(255, 55, 58, 57);
  Color textColor = Colors.white.withOpacity(0.93);

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final int? primaryValue = prefs.getInt('primaryColor');
      final int? backgroundValue = prefs.getInt('backgroundColor');
      final int? textValue = prefs.getInt('textColor');
      if (primaryValue != null) primary = Color(primaryValue);
      if (backgroundValue != null) background = Color(backgroundValue);
      if (textValue != null) textColor = Color(textValue);
    });
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', primary.value);
    await prefs.setInt('backgroundColor', background.value);
    await prefs.setInt('textColor', textColor.value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aurévant Koenig | ElementID',
      theme: ThemeData(
        primaryColor: primary,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        textTheme: GoogleFonts.assistantTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: Colors.white.withOpacity(0.93),
          displayColor: Colors.white.withOpacity(0.93),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          isDense: true,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.93)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.93)),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
      home: PartNumberGenerator(
        onEditTheme: () => _showColorPicker(context),
        onEditTextColor: () => _showTextColorPicker(context),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
    );
  }

  void _showColorPicker(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Pick Primary Color'),
        content: ColorPicker(
          pickerColor: primary,
          onColorChanged: (c) {
            setState(() => primary = c);
            _saveTheme();
          },
          showLabel: true,
          pickerAreaHeightPercent: 0.7,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }

  void _showTextColorPicker(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Pick Text Color'),
        content: ColorPicker(
          pickerColor: textColor,
          onColorChanged: (c) {
            setState(() => textColor = c);
            _saveTheme();
          },
          showLabel: true,
          pickerAreaHeightPercent: 0.7,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }
}

// Stub SettingsPage to avoid missing constructor errors
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text('Settings page not implemented'),
      ),
    );
  }
}

class PartNumberGenerator extends StatefulWidget {
  final VoidCallback onEditTheme;
  final VoidCallback onEditTextColor;
  const PartNumberGenerator({
    required this.onEditTheme,
    required this.onEditTextColor,
    super.key,
  });
  @override
  State<PartNumberGenerator> createState() => _PartNumberGeneratorState();
}

class _PartNumberGeneratorState extends State<PartNumberGenerator> {
  String phase = 'DES';

  // Load default values when returning from the Settings page
  Future<void> _loadDefaults() async {
    setState(() {
      phase = 'DES';
      // reset other fields to defaults if necessary
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color bgColor = theme.scaffoldBackgroundColor;
    final Color txtColor = Colors.white.withOpacity(0.93);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Aurévant Koenig | ElementID',
            style: theme.textTheme.titleLarge),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: widget.onEditTheme,
          ),
          IconButton(
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: txtColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white),
              ),
            ),
            onPressed: widget.onEditTextColor,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsPage(),
                ),
              );
              if (result == true) {
                final rootState =
                    context.findAncestorStateOfType<_ThemeEditingAppState>();
                await rootState?._loadTheme();
                await _loadDefaults();
              }
            },
          ),
        ],
      ),
      body: Center(
        child: GlassmorphicContainer(
          width: 700,
          height: 1200, // increased height to avoid scrolling
          borderRadius: 24,
          blur: 20,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.05),
            ],
            stops: const [0.1, 1],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.5),
              Colors.white.withOpacity(0.1),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 32), // increased top padding
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration:
                            const InputDecoration(hintText: 'Phase'),
                        value: phase,
                        items: const [
                          DropdownMenuItem(
                              value: 'DES', child: Text('Design')),
                          DropdownMenuItem(
                              value: 'RND', child: Text('R&D')),
                          DropdownMenuItem(
                              value: 'PRO', child: Text('Proto')),
                        "),
                        DropdownMenuItem(
                              value: 'PRD', child: Text('Production')),
                        ],
                        onChanged: (v) => setState(() => phase = v!),
                        dropdownColor: bgColor,
                      ),
                      // Rest of the form fields remain unchanged...
                    ],
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
