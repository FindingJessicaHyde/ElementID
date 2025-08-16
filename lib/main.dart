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
  // literal opacity swatch here
  Color textColor = Colors.white.withOpacity(0.93);

  @override
  void initState() {
    super.initState();
    // Load persisted theme values on startup.  This ensures that the
    // primary, background and text colours selected in the settings page
    // are restored when the app is reopened.
    _loadTheme();
  }

  /// Loads the saved theme colours from persistent storage.  If values are
  /// not found the current colours remain unchanged.  After loading, the
  /// widget is rebuilt to apply the colours immediately.
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

  /// Persists the current theme colours to storage.  Called from the
  /// settings page when the user saves changes.
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
          // Persist the selected primary colour immediately so that it is
          // restored the next time the app launches.
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
            // Persist the selected text colour immediately to storage.
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

/// A settings screen where users can configure their default initials,
/// revision letter, file extension and theme colours.  Values are
/// persisted via SharedPreferences and applied when the user saves.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Temporary colour values used during editing.  These are initialised
  // in initState from persistent storage.
  late Color _primary;
  late Color _background;
  late Color _textColour;
  // Controllers for default initials and revision.  Extension has been
  // removed from the user interface per the latest requirements.
  late TextEditingController _initialsController;
  late TextEditingController _revisionController;

  @override
  void initState() {
    super.initState();
    // Load saved settings asynchronously.  Use a Future because
    // SharedPreferences.getInstance() returns a Future.
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _primary = Color(prefs.getInt('primaryColor') ?? const Color.fromARGB(255, 34, 35, 34).value);
        _background = Color(prefs.getInt('backgroundColor') ?? const Color.fromARGB(255, 55, 58, 57).value);
        _textColour = Color(prefs.getInt('textColor') ?? Colors.white.withOpacity(0.93).value);
        _initialsController = TextEditingController(text: prefs.getString('defaultInitials') ?? '');
        _revisionController = TextEditingController(text: prefs.getString('defaultRevision') ?? 'A');
      });
    });
  }

  @override
  void dispose() {
    _initialsController.dispose();
    _revisionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text('Primary Colour'),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white),
                ),
              ),
              onTap: () async {
                final picked = await showDialog<Color>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Select Primary Colour'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: _primary,
                        onColorChanged: (c) => setState(() => _primary = c),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, _primary),
                        child: const Text('DONE'),
                      ),
                    ],
                  ),
                );
                if (picked != null) setState(() => _primary = picked);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Background Colour'),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white),
                ),
              ),
              onTap: () async {
                final picked = await showDialog<Color>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Select Background Colour'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: _background,
                        onColorChanged: (c) => setState(() => _background = c),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, _background),
                        child: const Text('DONE'),
                      ),
                    ],
                  ),
                );
                if (picked != null) setState(() => _background = picked);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Text Colour'),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _textColour,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white),
                ),
              ),
              onTap: () async {
                final picked = await showDialog<Color>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Select Text Colour'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: _textColour,
                        onColorChanged: (c) => setState(() => _textColour = c),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, _textColour),
                        child: const Text('DONE'),
                      ),
                    ],
                  ),
                );
                if (picked != null) setState(() => _textColour = picked);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _initialsController,
              decoration: const InputDecoration(labelText: 'Default Initials'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _revisionController,
              decoration: const InputDecoration(labelText: 'Default Revision'),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('primaryColor', _primary.value);
                    await prefs.setInt('backgroundColor', _background.value);
                    await prefs.setInt('textColor', _textColour.value);
                    await prefs.setString('defaultInitials', _initialsController.text);
                    await prefs.setString('defaultRevision', _revisionController.text);
                    Navigator.pop(context, true);
                  },
                  child: const Text('SAVE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful widget that generates part numbers and descriptions based on user selections.
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

/// Settings page allowing the user to configure default initials, revision
/// and file extension.  Changes made here are persisted via the provided
/// onSave callback and applied immediately to the form.

class _PartNumberGeneratorState extends State<PartNumberGenerator> {
  final String projectCode = 'AK';

  /// High-level assembly categories used as the first drop-down.  Each
  /// category corresponds to a sub-assembly of the watch.  Selecting a
  /// category will populate the part list with only those items relevant
  /// to that assembly.
  final List<Map<String, String>> subsystems = [
    {'code': 'A', 'label': 'Case Assembly'},
    {'code': 'B', 'label': 'Dial & Hand Assembly'},
    {'code': 'C', 'label': 'Integrated Bracelet Assembly'},
    {'code': 'D', 'label': 'Butterfly Clasp Assembly'},
    {'code': 'E', 'label': 'Seals & Water Resistance'},
    {'code': 'F', 'label': 'Decorative / Protective Elements'},
  ];

  /// Maps subsystem codes to a canonical 2–3 letter category code.  These
  /// codes form the second segment of the part number and provide a
  /// human‑readable shorthand for each broad assembly group.  If a
  /// subsystem does not exist in this map the subsystem code itself is
  /// used.
  final Map<String, String> categoryCodes = const {
    'A': 'CAS', // Case Assembly
    'B': 'DIA', // Dial & Hand Assembly
    'C': 'BRA', // Integrated Bracelet Assembly
    'D': 'CLA', // Butterfly Clasp Assembly
    'E': 'SEA', // Seals & Water Resistance
    'F': 'DEC', // Decorative / Protective Elements
  };

  /// Material, finish and colour definitions remain unchanged.
  final Map<String, List<Map<String, String>>> variants = {
    'Material': [
      {'code': 'M1', 'label': 'M1 – Titanium Grade 5'},
      {'code': 'M2', 'label': 'M2 – 904L Stainless'},
      {'code': 'M3', 'label': 'M3 – 316L Stainless'},
      {'code': 'M4', 'label': 'M4 – Sapphire'},
    ],
    'Finish': [
      {'code': 'F1', 'label': 'F1 – Brushed'},
      {'code': 'F2', 'label': 'F2 – Polished'},
      {'code': 'F3', 'label': 'F3 – DLC Black'},
    ],
    'Colour': [
      {'code': 'C1', 'label': 'C1 – Natural / Silver'},
      {'code': 'C2', 'label': 'C2 – Black PVD'},
      {'code': 'C3', 'label': 'C3 – Rose-Gold Tone'},
    ],
  };

  /// Maps category codes to a list of detailed part definitions.  Each part
  /// entry has a unique code and a descriptive label.  These lists drive
  /// the second drop-down when a user selects a category.
  final Map<String, List<Map<String, String>>> partsBySubsystem = {
    'A': [
      {'code': 'A1', 'label': 'Case Middle (Mid-Case Body)'},
      {'code': 'A2', 'label': 'Bezel Body'},
      {'code': 'A3', 'label': 'Bezel Insert (ceramic, aluminium, sapphire)'},
      {'code': 'A4', 'label': 'Crystal (Sapphire) – Flat, domed, or box'},
      {'code': 'A5', 'label': 'Crystal Gasket'},
      {'code': 'A6', 'label': 'Caseback – Solid or Display'},
      {'code': 'A7', 'label': 'Caseback Gasket'},
      {'code': 'A8', 'label': 'Crown'},
      {'code': 'A9', 'label': 'Crown Tube'},
      {'code': 'A10', 'label': 'Crown Gaskets – Upper and lower inside crown'},
      {'code': 'A11', 'label': 'Crown Guard (integrated or separate)'},
      {'code': 'A12', 'label': 'Pusher(s) (if applicable)'},
      {'code': 'A13', 'label': 'Pusher Tube(s)'},
      {'code': 'A14', 'label': 'Pusher Gasket(s)'},
      {'code': 'A15', 'label': 'Helium Escape Valve Assembly (if applicable)'},
      {'code': 'A16', 'label': 'Mid-Case Insert / Movement Holder (if used without movement ring)'},
    ],
    'B': [
      {'code': 'B1', 'label': 'Dial Base Plate'},
      {'code': 'B2', 'label': 'Applied Hour Markers / Indices'},
      {'code': 'B3', 'label': 'Logo Appliqué / Nameplate'},
      {'code': 'B4', 'label': 'Chapter Ring / Rehaut'},
      {'code': 'B5', 'label': 'Date Window Frame (if applicable)'},
      {'code': 'B6', 'label': 'Dial Feet & Fixing Screws (if external to movement fixing)'},
      {'code': 'B7', 'label': 'Hour Hand'},
      {'code': 'B8', 'label': 'Minute Hand'},
      {'code': 'B9', 'label': 'Seconds Hand (central or sub-dial)'},
      {'code': 'B10', 'label': 'Sub-Dial Hand(s) (if applicable)'},
    ],
    'C': [
      {'code': 'C1', 'label': 'Bracelet Body'},
      {'code': 'C2', 'label': 'Outer Link – Primary'},
      {'code': 'C3', 'label': 'Outer Link – Intermediate (if tapered)'},
      {'code': 'C4', 'label': 'Center Link – Primary'},
      {'code': 'C5', 'label': 'Center Link – Intermediate'},
      {'code': 'C6', 'label': 'Transition Link (End Link) – Integrated solid type'},
      {'code': 'C7', 'label': 'Mid-Link Connector (if multi-link articulation)'},
      {'code': 'C8', 'label': 'Link-to-Link Connector Pin'},
      {'code': 'C9', 'label': 'Tube Sleeve'},
      {'code': 'C10', 'label': 'Screw Bar (if applicable)'},
      {'code': 'C11', 'label': 'Link Hardware'},
    ],
    'D': [
      {'code': 'D1', 'label': 'Clasp Body'},
      {'code': 'D2', 'label': 'Clasp Center Bridge'},
      {'code': 'D3', 'label': 'Folding Blade – Left'},
      {'code': 'D4', 'label': 'Folding Blade – Right'},
      {'code': 'D5', 'label': 'End Link Interface Plate – Left'},
      {'code': 'D6', 'label': 'End Link Interface Plate – Right'},
      {'code': 'D7', 'label': 'Release Push Button – Left'},
      {'code': 'D8', 'label': 'Release Push Button – Right'},
      {'code': 'D9', 'label': 'Button Return Spring – Left'},
      {'code': 'D10', 'label': 'Button Return Spring – Right'},
      {'code': 'D11', 'label': 'Latch Hook – Left'},
      {'code': 'D12', 'label': 'Latch Hook – Right'},
      {'code': 'D13', 'label': 'Hinge Pin – Main'},
      {'code': 'D14', 'label': 'Hinge Pin – End Link Interface'},
      {'code': 'D15', 'label': 'Detent Spring / Click Spring'},
      {'code': 'D16', 'label': 'Decorative Cap Plate – Left'},
      {'code': 'D17', 'label': 'Decorative Cap Plate – Right'},
      {'code': 'D18', 'label': 'Clasp Finish Components'},
      {'code': 'D19', 'label': 'Surface Finish Treatments (brushed, polished, DLC, etc.)'},
      {'code': 'D20', 'label': 'Clasp Mechanism'},
    ],
    'E': [
      {'code': 'E1', 'label': 'Crystal Gasket (listed in A5, repeated here for sealing overview)'},
      {'code': 'E2', 'label': 'Caseback Gasket (listed in A7, repeated here)'},
      {'code': 'E3', 'label': 'Crown Gaskets (listed in A10, repeated here)'},
      {'code': 'E4', 'label': 'Crown Tube Gasket (if separate)'},
      {'code': 'E5', 'label': 'Pusher Gasket(s) (listed in A14, repeated here)'},
      {'code': 'E6', 'label': 'Helium Valve Seals (if applicable)'},
    ],
    'F': [
      {'code': 'F1', 'label': 'Bezel Lume Pip Assembly (if dive bezel)'},
      {'code': 'F2', 'label': 'Protective Coatings – AR on crystal, DLC/PVD/CVD on case or bracelet'},
      {'code': 'F3', 'label': 'Engraved / Laser-Etched Decorative Plates (caseback medallions, branding plates)'},
      {'code': 'F4', 'label': 'Serial Number Plate / Laser Marking'},
      {'code': 'F5', 'label': 'Applied Gem Settings (bezel, dial, lugs)'},
    ],
  };

  /// Alphabetical revision list.
  final List<String> revisions =
      List.generate(26, (i) => String.fromCharCode(65 + i));

  String? subsystem, material, finish, colour;
  String? part;
  String revision = 'A';
  int sequence = 1;
  String initials = '';
  String ext = '';
  DateTime date = DateTime.now();
  final TextEditingController dateController = TextEditingController();
  Set<String> generatedPartNumbers = {};

  // Default settings loaded from persistent storage.  These values are
  // used to prefill fields when clearing the form.  Users can edit
  // these defaults in the settings screen accessible from the app bar.
  String defaultInitials = '';
  String defaultRevision = 'A';
  // Default extension is retained for future use but not exposed in the UI.
  String defaultExt = 'SLDPRT';

  /// Search controllers for the subsystem and part autocomplete fields.
  ///
  /// These controllers are lazily assigned from the autocomplete widgets'
  /// internal controllers via the fieldViewBuilder callback.  We do not
  /// instantiate them in initState because doing so would decouple them
  /// from the Autocomplete's internal state and prevent the suggestions
  /// list from updating correctly.  Instead, when the Autocomplete
  /// constructs its TextField, we assign our variables if they are null.
  TextEditingController? subsystemSearchController;
  TextEditingController? partSearchController;

  /// Some materials require a colour specification.  When the selected
  /// material is not in this set the colour field will be hidden.
  final Set<String> materialsRequiringColour = {'M1', 'M2', 'M3'};


  /// Phase of the part lifecycle.  The user can choose from four stages:
  /// Design (DES), R&D (RND), Proto (PRO) or Production (PRD).  This
  /// value is encoded into the part number immediately after the brand
  /// prefix.  Design is the default.
  String phase = 'DES';

  /// A map storing the next sequence number for each subsystem/part pair.  The
  /// key is formatted as "<subsystem>-<part>".  When the subsystem or part
  /// selection changes, the sequence field is automatically populated from
  /// this map.  This helps prevent accidental reuse of numbers.
  Map<String, int> nextSequenceMap = {};

  /// A rolling list of the last five generated part numbers.  Displayed
  /// below the generator to help users identify recent creations and detect
  /// collisions early.
  List<String> recentPartNumbers = [];

  /// Full history of generated part numbers.  Each entry is a map
  /// containing: timestamp, partNumber, description, initials, revision,
  /// note, and catalogVersion.  Persisted locally and exportable.
  List<Map<String, dynamic>> history = [];

  /// Note associated with the current part.  Only used when the part is in
  /// the R&D or Proto phase.  When a user adds a note it will be stored
  /// in the history export but does not appear in the part number.
  String note = '';
  // Controller for the note field.  Only created when needed.
  TextEditingController? noteController;

  // The notes field has been removed at user request.  To maintain
  // compatibility with the history structure, we no longer store a notes
  // controller.  When generating history entries, the note field will
  // remain blank.

  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat('yyyy-MM-dd').format(date);
    // Do not initialise autocomplete controllers here.  The controllers for
    // the subsystem and part search fields are provided by the Autocomplete
    // widgets via the fieldViewBuilder.  Assigning new controllers here
    // would decouple our variables from the Autocomplete's internal
    // controllers and prevent suggestion lists from updating properly.
    _loadGeneratedPartNumbers();
    // Load auxiliary data structures from shared preferences.  These
    // asynchronous calls initialise the next sequence counters, recent list
    // and history store.
    _loadNextSequenceMap();
    _loadRecentPartNumbers();
    _loadHistory();
    // Load persisted default values.  This call sets default initials,
    // revision and extension.  If no values are stored, the defaults set
    // in the constructors will remain.
    _loadDefaults();
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the tree.
    subsystemSearchController?.dispose();
    partSearchController?.dispose();
    dateController.dispose();
    noteController?.dispose();
    super.dispose();
  }

  Future<void> _loadGeneratedPartNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      generatedPartNumbers =
          (prefs.getStringList('generatedPartNumbers') ?? []).toSet();
    });
  }

  Future<void> _saveGeneratedPartNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'generatedPartNumbers', generatedPartNumbers.toList());
  }

  void _clearAll() {
    setState(() {
      subsystem = null;
      part = null;
      material = null;
      finish = null;
      colour = null;
      // Reset revision, initials and extension to the configured defaults.
      revision = defaultRevision;
      sequence = 1;
      initials = defaultInitials;
      ext = defaultExt;
      date = DateTime.now();
      dateController.text = DateFormat('yyyy-MM-dd').format(date);
      note = '';
    });
    // Reset the displayed values in the autocomplete fields.  These are not
    // managed by the form's state so they need to be cleared explicitly.
    subsystemSearchController?.clear();
    partSearchController?.clear();
    noteController?.clear();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        date = picked;
        dateController.text = DateFormat('yyyy-MM-dd').format(date);
      });
    }
  }

  String pad(int num, [int size = 3]) => num.toString().padLeft(size, '0');

  /// Generates the part number based on current selections.  Includes the part code when selected.
  String get partNumber {
    // If no part code has been selected, no meaningful part number can be generated.
    if (subsystem == null || part == null || part!.isEmpty) return '';
    // Derive the category code from the subsystem using the lookup table.  If
    // none is found, fall back to the raw subsystem code.  This ensures the
    // part number remains predictable even if new subsystems are added.
    final String catCode = categoryCodes[subsystem!] ?? subsystem!;
    // Extract the numeric portion of the part code (e.g. A12 -> 12) and
    // convert it into a 2–3 digit subcategory code.  Pad to two digits for
    // values below 100 and three digits above 99.  This satisfies the
    // requirement for a 2–3 digit functional subassembly code.
    final int numeric = int.tryParse(part!.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final String subCode = numeric >= 100
        ? numeric.toString().padLeft(3, '0')
        : numeric.toString().padLeft(2, '0');
    // Determine the sequence segment.  Pad to three digits for values up to
    // 999, or four digits when the value reaches four figures.  This gives
    // flexibility for large quantities without changing the overall format.
    final String seqStr = sequence >= 1000
        ? sequence.toString().padLeft(4, '0')
        : sequence.toString().padLeft(3, '0');
    // Build the base number: brand prefix, category code, subcategory code and
    // sequence.  Then append the material, finish and colour codes if
    // available.  Finally include the date in a compact YYYYMMDD format,
    // followed by revision and initials.  This retains valuable metadata in
    // the part number while keeping the order logical and readable.
    // Include the selected phase code between the project code and category code
    List<String> segments = [projectCode, phase, catCode, subCode, seqStr];
    if (material != null && material!.isNotEmpty) segments.add(material!);
    if (finish != null && finish!.isNotEmpty) segments.add(finish!);
    if (colour != null && colour!.isNotEmpty) segments.add(colour!);
    // Append date; using a hyphenated format (YYYY-MM-DD) improves
    // readability while remaining sortable.  Adjust the pattern to your
    // preference if you require a shorter or different style.
    segments.add(DateFormat('yyyy-MM-dd').format(date));
    if (revision.isNotEmpty) segments.add(revision);
    if (initials.isNotEmpty) segments.add(initials.toUpperCase());
    return segments.join('-');
  }

  /// Generates a human-readable description string based on selected labels.
  String get generatedDescription {
    final List<String> descParts = [];
    if (subsystem != null) {
      final sub = subsystems.firstWhere(
        (s) => s['code'] == subsystem,
        orElse: () => {},
      );
      if (sub.isNotEmpty) descParts.add(sub['label']!);
    }
    if (part != null && subsystem != null) {
      final partList = partsBySubsystem[subsystem] ?? [];
      final p = partList.firstWhere(
        (e) => e['code'] == part,
        orElse: () => {},
      );
      if (p.isNotEmpty) descParts.add(p['label']!);
    }
    if (material != null) {
      final mat = variants['Material']!.firstWhere(
        (m) => m['code'] == material,
        orElse: () => {},
      );
      if (mat.isNotEmpty) descParts.add(mat['label']!);
    }
    if (finish != null) {
      final fin = variants['Finish']!.firstWhere(
        (f) => f['code'] == finish,
        orElse: () => {},
      );
      if (fin.isNotEmpty) descParts.add(fin['label']!);
    }
    if (colour != null) {
      final col = variants['Colour']!.firstWhere(
        (c) => c['code'] == colour,
        orElse: () => {},
      );
      if (col.isNotEmpty) descParts.add(col['label']!);
    }
    return descParts.join(' – ');
  }

  Future<void> _handleCopyPartNumber() async {
    if (partNumber.isEmpty) return;
    if (generatedPartNumbers.contains(partNumber)) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Duplicate Part Number'),
          content:
              const Text('This part number has already been generated.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    generatedPartNumbers.add(partNumber);
    await _saveGeneratedPartNumbers();
    // Record this part number in recent list and history.
    _addToRecent(partNumber);
    _addToHistory();
    await _saveRecentPartNumbers();
    await _saveHistory();
    // Increment the next sequence counter for future numbers.
    _incrementNextSequence();
    await Clipboard.setData(ClipboardData(text: partNumber));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Part number copied!')));
  }

  Future<void> _handleCopyDescription() async {
    if (generatedDescription.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: generatedDescription));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Description copied!')));
  }

  /// Loads the next sequence map from persistent storage.  If no data is
  /// found, the map remains empty.
  Future<void> _loadNextSequenceMap() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('nextSequenceMap');
    if (jsonString != null) {
      final Map<String, dynamic> decoded = json.decode(jsonString);
      nextSequenceMap = decoded.map((key, value) => MapEntry(key, value as int));
    }
  }

  /// Saves the next sequence map back to persistent storage.
  Future<void> _saveNextSequenceMap() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nextSequenceMap', json.encode(nextSequenceMap));
  }

  /// Loads the list of recent part numbers from persistent storage.
  Future<void> _loadRecentPartNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recentPartNumbers');
    if (list != null) {
      recentPartNumbers = List<String>.from(list);
    }
  }

  /// Saves the recent part numbers list to persistent storage.
  Future<void> _saveRecentPartNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentPartNumbers', recentPartNumbers);
  }

  /// Loads the history of generated parts from persistent storage.
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('partHistory');
    if (jsonString != null) {
      final List<dynamic> decoded = json.decode(jsonString);
      history = decoded.cast<Map<String, dynamic>>();
    }
  }

  /// Saves the history list back to persistent storage.
  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('partHistory', json.encode(history));
  }

  /// Loads the default initials, revision and file extension from
  /// persistent storage.  If values are not found the defaults
  /// remain unchanged.  After loading, the current form fields are
  /// updated to reflect these defaults.
  Future<void> _loadDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      defaultInitials = prefs.getString('defaultInitials') ?? defaultInitials;
      defaultRevision = prefs.getString('defaultRevision') ?? defaultRevision;
      defaultExt = prefs.getString('defaultExt') ?? defaultExt;
      // Apply defaults to form fields only if they are currently empty
      if (initials.isEmpty) initials = defaultInitials;
      if (revision.isEmpty || revision == 'A') revision = defaultRevision;
      if (ext.isEmpty) ext = defaultExt;
    });
  }

  /// Persists the default initials, revision and file extension to
  /// storage.  Called when the user saves changes in the settings page.
  Future<void> _saveDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultInitials', defaultInitials);
    await prefs.setString('defaultRevision', defaultRevision);
    await prefs.setString('defaultExt', defaultExt);
  }

  /// Adds a part number to the recent list, ensuring the list does not
  /// exceed five entries.  The newest entry appears first.
  void _addToRecent(String pn) {
    recentPartNumbers.remove(pn);
    recentPartNumbers.insert(0, pn);
    if (recentPartNumbers.length > 5) {
      recentPartNumbers = recentPartNumbers.sublist(0, 5);
    }
  }

  /// Appends the current part number and metadata to the history list.
  void _addToHistory() {
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'partNumber': partNumber,
      'description': generatedDescription,
      'initials': initials,
      'revision': revision,
      // Include note only for R&D or Proto phases.  Otherwise keep blank.
      'note': (phase == 'RND' || phase == 'PRO') ? note : '',
      'catalogVersion': 'v1',
    };
    history.insert(0, entry);
    // Limit history length to avoid unbounded growth; keep last 100 entries.
    if (history.length > 100) {
      history = history.sublist(0, 100);
    }
  }

  /// Pre-fills the sequence number based on the selected subsystem/part.
  void _prefillSequence() {
    if (subsystem != null) {
      final key = part != null && part!.isNotEmpty
          ? '${subsystem!}-${part!}'
          : subsystem!;
      setState(() {
        sequence = nextSequenceMap[key] ?? 1;
      });
    }
  }

  /// Increments the next sequence counter for the currently selected
  /// subsystem/part combination after a part number has been generated.
  void _incrementNextSequence() {
    if (subsystem != null) {
      final key = part != null && part!.isNotEmpty
          ? '${subsystem!}-${part!}'
          : subsystem!;
      final current = nextSequenceMap[key] ?? 1;
      nextSequenceMap[key] = current + 1;
      _saveNextSequenceMap();
    }
  }

  /// Converts the history list into a CSV string with a header row.
  String _historyToCsv() {
    final buffer = StringBuffer();
    buffer.writeln(
        'timestamp,partNumber,description,initials,revision,note,catalogVersion');
    for (final entry in history) {
      buffer.writeln(
          '${entry['timestamp']},${entry['partNumber']},${entry['description']},${entry['initials']},${entry['revision']},${entry['note']},${entry['catalogVersion']}');
    }
    return buffer.toString();
  }

  /// Converts the history list into a JSON string.
  String _historyToJson() {
    return json.encode(history);
  }

  /// Copies the history as CSV to the clipboard for export.
  Future<void> _copyCsvToClipboard() async {
    final csvStr = _historyToCsv();
    await Clipboard.setData(ClipboardData(text: csvStr));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('CSV copied to clipboard')));
  }

  /// Copies the history as JSON to the clipboard for export.
  Future<void> _copyJsonToClipboard() async {
    final jsonStr = _historyToJson();
    await Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('JSON copied to clipboard')));
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
          // Settings button to configure defaults and theme.  When the
          // settings page returns a true value we reload theme and
          // default values from storage.  This allows changes to be
          // immediately applied throughout the app.
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
                // Reload theme via ancestor state if available.
                final rootState = context.findAncestorStateOfType<_ThemeEditingAppState>();
                await rootState?._loadTheme();
                // Reload default values for initials, revision and extension.
                await _loadDefaults();
              }
            },
          ),
        ],
        systemOverlayStyle: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      body: Center(
        child: GlassmorphicContainer(
          width: 700,
          // Reduce overall height of the glass container so the entire
          // form fits on typical screens without scrolling.  Adjust as
          // necessary for your target device.
          height: 950,
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
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // Phase selection: Design, R&D, Proto or Production
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Phase'),
                        value: phase,
                        items: [
                          DropdownMenuItem(value: 'DES', child: Text('Design')),
                          DropdownMenuItem(value: 'RND', child: Text('R&D')),
                          DropdownMenuItem(value: 'PRO', child: Text('Proto')),
                          DropdownMenuItem(value: 'PRD', child: Text('Production')),
                        ],
                        onChanged: (v) => setState(() => phase = v!),
                        dropdownColor: bgColor,
                      ),
                      const SizedBox(height: 12),
                      // Replace the subsystem dropdown with an autocomplete search.
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final query = textEditingValue.text.toLowerCase();
                          return subsystems
                              .map((s) => '${s['code']!} - ${s['label']!}')
                              .where((option) => option.toLowerCase().contains(query))
                              .toList();
                        },
                        displayStringForOption: (option) => option,
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          // Use the controller supplied by the Autocomplete.  If we
                          // have not yet stored a reference to it, save it so we
                          // can clear the field when resetting the form.  Using
                          // the same controller as the Autocomplete ensures
                          // suggestions update correctly when the user types.
                          subsystemSearchController ??= controller;
                          return TextFormField(
                            controller: subsystemSearchController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(labelText: 'Subsystem'),
                          );
                        },
                          onSelected: (String selection) {
                            final code = selection.split(' - ').first;
                            setState(() {
                              subsystem = code;
                              part = null;
                              // update displayed selection text; store full label in controller.
                              subsystemSearchController?.text = selection;
                              partSearchController?.clear();
                            });
                            _prefillSequence();
                          },
                        optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                          // Custom drop-down for subsystem suggestions.  Use a dark
                          // background and theme-consistent text colour.  The
                          // overlay is aligned beneath the input field and
                          // shrinks to fit its contents.
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              color: bgColor,
                              elevation: 4,
                              borderRadius: BorderRadius.circular(4),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                children: options.map((String option) {
                                  return ListTile(
                                    dense: true,
                                    title: Text(option, style: TextStyle(color: txtColor)),
                                    onTap: () => onSelected(option),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Autocomplete for parts, filtered by the selected subsystem.
                      if (subsystem != null && (partsBySubsystem[subsystem] ?? []).isNotEmpty)
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            final query = textEditingValue.text.toLowerCase();
                            final List<String> partOptions = (partsBySubsystem[subsystem] ?? [])
                                .map((p) => '${p['code']!} - ${p['label']!}')
                                .toList();
                            return partOptions
                                .where((option) => option.toLowerCase().contains(query))
                                .toList();
                          },
                          displayStringForOption: (option) => option,
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            // Use the controller provided by Autocomplete.  Assign
                            // it to our variable the first time this builder is
                            // invoked so we can clear its text when resetting.
                            partSearchController ??= controller;
                            return TextFormField(
                              controller: partSearchController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(labelText: 'Part'),
                            );
                          },
                          onSelected: (String selection) {
                            final code = selection.split(' - ').first;
                            setState(() {
                              part = code;
                              partSearchController?.text = selection;
                            });
                            _prefillSequence();
                          },
                          optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                            // Custom drop-down for part suggestions.  Use the same
                            // dark theme as the subsystem list to maintain
                            // consistency.  Each option displays the code and
                            // label.
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                color: bgColor,
                                elevation: 4,
                                borderRadius: BorderRadius.circular(4),
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  children: options.map((String option) {
                                    return ListTile(
                                      dense: true,
                                      title: Text(option, style: TextStyle(color: txtColor)),
                                      onTap: () => onSelected(option),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      if (subsystem != null && (partsBySubsystem[subsystem] ?? []).isNotEmpty)
                        const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration:
                            const InputDecoration(labelText: 'Material'),
                        value: material,
                        items: variants['Material']!
                            .map((v) => DropdownMenuItem(
                                value: v['code'], child: Text(v['label']!)))
                            .toList(),
                        onChanged: (v) => setState(() => material = v),
                        dropdownColor: bgColor,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration:
                            const InputDecoration(labelText: 'Finish'),
                        value: finish,
                        items: variants['Finish']!
                            .map((v) => DropdownMenuItem(
                                value: v['code'], child: Text(v['label']!)))
                            .toList(),
                        onChanged: (v) => setState(() => finish = v),
                        dropdownColor: bgColor,
                      ),
                      const SizedBox(height: 12),
                      if (material != null && materialsRequiringColour.contains(material)) ...[
                        DropdownButtonFormField<String>(
                          decoration:
                              const InputDecoration(labelText: 'Colour'),
                          value: colour,
                          items: variants['Colour']!
                              .map((v) => DropdownMenuItem(
                                  value: v['code'], child: Text(v['label']!)))
                              .toList(),
                          onChanged: (v) => setState(() => colour = v),
                          dropdownColor: bgColor,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        initialValue: sequence >= 1000
                            ? sequence.toString().padLeft(4, '0')
                            : sequence.toString().padLeft(3, '0'),
                        decoration: const InputDecoration(
                            labelText: 'Sequence Number'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) =>
                            setState(() => sequence = int.tryParse(v) ?? 1),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration:
                            const InputDecoration(labelText: 'Revision'),
                        value: revision,
                        items: revisions
                            .map((r) =>
                                DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setState(() => revision = v!),
                        dropdownColor: bgColor,
                      ),
                        const SizedBox(height: 12),
                      TextFormField(
                        initialValue: initials,
                        decoration:
                            const InputDecoration(labelText: 'Initials'),
                        onChanged: (v) => setState(() => initials = v),
                      ),
                      // Show note field only for R&D and Proto phases.  This
                      // field allows the user to attach a short comment to
                      // prototype or research parts.  The controller is
                      // lazily initialised to avoid unnecessary overhead.
                      if (phase == 'RND' || phase == 'PRO') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: noteController ??= TextEditingController(text: note),
                          decoration: const InputDecoration(labelText: 'Notes'),
                          // Limit to a single line so that the height matches other
                          // form fields.  Additional text will scroll horizontally.
                          maxLines: 1,
                          onChanged: (v) => setState(() => note = v),
                        ),
                      ],
                      // Add spacing before the date picker so that it does
                      // not butt up against the previous field (either
                      // initials or notes).  This ensures consistent
                      // vertical rhythm throughout the form.
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Date',
                          suffixIcon:
                              Icon(Icons.calendar_today, color: txtColor),
                        ),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: _clearAll,
                            child: const Text('Clear All')),
                      ),
                    ],
                  ),
                ),
                        const SizedBox(height: 12),
                Text('Generated Part Number:',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                SelectableText(partNumber,
                    style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 12),
                Builder(builder: (context) {
                  // Determine whether the form is complete and the part
                  // number is unique.  Only when these conditions are
                  // satisfied should the copy button be enabled.  This
                  // prevents accidental generation of duplicate or
                  // incomplete part numbers.  A duplicate is detected
                  // by checking the current part number against the set
                  // of generated part numbers.
                  final bool formComplete = subsystem != null && part != null && part!.isNotEmpty;
                  final bool isDuplicate = generatedPartNumbers.contains(partNumber);
                  final bool canGenerate = formComplete && !isDuplicate && partNumber.isNotEmpty;
                  return ElevatedButton(
                    onPressed: canGenerate ? _handleCopyPartNumber : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12)),
                    child: const Text('Copy Part Number'),
                  );
                }),
                const SizedBox(height: 12),
                Text('Generated Description:',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                SelectableText(generatedDescription,
                    style: theme.textTheme.bodyLarge),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _handleCopyDescription,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12)),
                  child: const Text('Copy Description'),
                ),
                const SizedBox(height: 12),
                // Export buttons for history.  These allow users to
                // download the full history in CSV or JSON format for
                // auditing or backup.  They are always enabled.
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _copyCsvToClipboard,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10)),
                      child: const Text('Export CSV'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _copyJsonToClipboard,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10)),
                      child: const Text('Export JSON'),
                    ),
                  ],
                ),
                    const SizedBox(height: 12),
                // Recent part numbers display: show the last five entries so
                // users can quickly see recently generated part numbers and
                // avoid duplicates.
                if (recentPartNumbers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Recent Part Numbers:',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  for (final pn in recentPartNumbers)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(pn, style: theme.textTheme.bodyMedium),
                    ),
                  const SizedBox(height: 12),
                ],
                Align(
                    alignment: Alignment.bottomRight,
                    child: Text('Powered by Elemental Studios',
                        style: theme.textTheme.bodySmall)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}