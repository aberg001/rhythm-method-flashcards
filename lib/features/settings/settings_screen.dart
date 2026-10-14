import 'package:flutter/material.dart';

import '../../data/library_backup.dart';
import '../../domain/scheduler.dart';
import '../backup/pick_backup.dart';
import '../backup/share_backup.dart';
import '../library/library_scope.dart';
import '../library/name_dialog.dart';

/// The five scheduler parameters. Other bounds stay in code.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.shareBackup, this.pickBackup});

  /// Sends the backup JSON and the export button's rectangle.
  ///
  /// Null opens the platform share sheet. Tests pass their own function.
  final Future<void> Function(String json, Rect origin)? shareBackup;

  /// Reads a backup file. Null opens the platform file picker.
  ///
  /// Returns null when the user cancels. Tests pass their own function.
  final Future<String?> Function()? pickBackup;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _correct = TextEditingController();
  final _wrong = TextEditingController();
  final _difficulty = TextEditingController();
  final _window = TextEditingController();
  final _threshold = TextEditingController();

  String? _correctError;
  String? _wrongError;
  String? _difficultyError;
  String? _windowError;
  String? _thresholdError;

  var _loaded = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void dispose() {
    _correct.dispose();
    _wrong.dispose();
    _difficulty.dispose();
    _window.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repository = LibraryScope.of(context);
    final settings = await repository.loadSettings();
    if (!mounted) return;
    _apply(settings);
    setState(() => _loaded = true);
  }

  void _apply(SchedulerParameters parameters) {
    _correct.text = _formatDouble(parameters.correctFactor);
    _wrong.text = _formatDouble(parameters.wrongFactor);
    _difficulty.text = _formatDouble(parameters.difficultyFactor);
    _window.text = '${parameters.learningWindowSize}';
    _threshold.text = _formatHours(parameters.learnedThreshold);
  }

  Future<void> _save() async {
    if (_busy || !_loaded) return;
    final parsed = _parse();
    if (parsed == null) {
      setState(() {});
      return;
    }
    final repository = LibraryScope.of(context);
    setState(() => _busy = true);
    await repository.saveSettings(parsed);
    if (!mounted) return;
    _apply(parsed);
    setState(() => _busy = false);
  }

  Future<void> _export(BuildContext originContext) async {
    if (_busy || !_loaded) return;
    final origin = _shareOrigin(originContext);
    final repository = LibraryScope.of(context);
    setState(() => _busy = true);
    try {
      final json = await repository.backupJson();
      if (!mounted) return;
      final share = widget.shareBackup ?? shareLibraryBackup;
      await share(json, origin);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export the backup.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_busy || !_loaded) return;
    final pick = widget.pickBackup ?? pickLibraryBackupJson;
    final String? json;
    try {
      json = await pick();
    } catch (_) {
      if (!mounted) return;
      _showImportError();
      return;
    }
    if (!mounted || json == null) return;

    final LibraryBackup backup;
    try {
      backup = parseLibraryBackup(json);
    } on FormatException {
      _showImportError();
      return;
    }

    final repository = LibraryScope.of(context);
    final topics = await repository.listTopics();
    final cards = await repository.listCards();
    if (!mounted) return;
    if (topics.isNotEmpty || cards.isNotEmpty) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Replace the library?',
        message:
            'This replaces every topic, card, and the settings with the backup. '
            'Review history on this device is removed.',
        confirmLabel: 'Replace',
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      await repository.restoreBackup(backup);
      if (!mounted) return;
      _apply(backup.settings);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Backup imported.')));
    } catch (_) {
      if (!mounted) return;
      _showImportError();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showImportError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not import the backup.')),
    );
  }

  /// Returns the parameters, or null and sets field errors.
  SchedulerParameters? _parse() {
    final correct = _readDouble(_correct.text);
    if (correct == null) {
      _correctError = 'Enter a number.';
    } else if (!(correct > 1)) {
      _correctError = 'Must be greater than 1.';
    } else {
      _correctError = null;
    }

    final wrong = _readDouble(_wrong.text);
    if (wrong == null) {
      _wrongError = 'Enter a number.';
    } else if (!(wrong > 0 && wrong < 1)) {
      _wrongError = 'Must be greater than 0 and less than 1.';
    } else {
      _wrongError = null;
    }

    final difficulty = _readDouble(_difficulty.text);
    if (difficulty == null) {
      _difficultyError = 'Enter a number.';
    } else if (!(difficulty >= 0)) {
      _difficultyError = 'Must be zero or greater.';
    } else {
      _difficultyError = null;
    }

    final windowText = _window.text.trim();
    final window = int.tryParse(windowText);
    if (windowText.isEmpty || window == null) {
      _windowError = 'Enter a whole number.';
    } else if (window < 1) {
      _windowError = 'Must be a whole number of at least 1.';
    } else {
      _windowError = null;
    }

    final hours = _readDouble(_threshold.text);
    int? thresholdSeconds;
    if (hours == null) {
      _thresholdError = 'Enter a number.';
    } else {
      thresholdSeconds = (hours * _secondsPerHour).round();
      if (thresholdSeconds < 1) {
        _thresholdError = 'Must be greater than 0.';
        thresholdSeconds = null;
      } else {
        _thresholdError = null;
      }
    }

    if (_correctError != null ||
        _wrongError != null ||
        _difficultyError != null ||
        _windowError != null ||
        _thresholdError != null) {
      return null;
    }
    return SchedulerParameters(
      correctFactor: correct!,
      wrongFactor: wrong!,
      difficultyFactor: difficulty!,
      learningWindowSize: window!,
      learnedThreshold: Duration(seconds: thresholdSeconds!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_loaded)
            TextButton(
              key: const Key('save-settings'),
              onPressed: _busy ? null : _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : SafeArea(
              top: false,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
                children: [
                  _SettingField(
                    fieldKey: const Key('correct-factor'),
                    controller: _correct,
                    label: 'Correct factor',
                    helper: 'Greater than 1. Default 1.5.',
                    error: _correctError,
                    decimal: true,
                  ),
                  _SettingField(
                    fieldKey: const Key('wrong-factor'),
                    controller: _wrong,
                    label: 'Wrong factor',
                    helper: 'Greater than 0 and less than 1. Default 0.5.',
                    error: _wrongError,
                    decimal: true,
                  ),
                  _SettingField(
                    fieldKey: const Key('difficulty-factor'),
                    controller: _difficulty,
                    label: 'Difficulty factor',
                    helper: 'Zero or greater. Default 0.01.',
                    error: _difficultyError,
                    decimal: true,
                  ),
                  _SettingField(
                    fieldKey: const Key('learning-window'),
                    controller: _window,
                    label: 'Learning window',
                    helper: 'Whole number, at least 1. Default 10.',
                    error: _windowError,
                    decimal: false,
                  ),
                  _SettingField(
                    fieldKey: const Key('learned-threshold'),
                    controller: _threshold,
                    label: 'Learned threshold',
                    helper: 'Hours, greater than 0. Default 1.',
                    suffix: 'hours',
                    error: _thresholdError,
                    decimal: true,
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (buttonContext) {
                      return OutlinedButton(
                        key: const Key('export-backup'),
                        onPressed: _busy ? null : () => _export(buttonContext),
                        child: const Text('Export backup'),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Topics, cards, and settings, as a JSON file.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    key: const Key('import-backup'),
                    onPressed: _busy ? null : _import,
                    child: const Text('Import backup'),
                  ),
                ],
              ),
            ),
    );
  }
}

Rect _shareOrigin(BuildContext originContext) {
  final box = originContext.findRenderObject();
  if (box is RenderBox &&
      box.hasSize &&
      box.size.width > 0 &&
      box.size.height > 0) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  return const Rect.fromLTWH(0, 0, 2, 2);
}

class _SettingField extends StatelessWidget {
  const _SettingField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.helper,
    required this.error,
    required this.decimal,
    this.suffix,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final String helper;
  final String? error;
  final bool decimal;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        key: fieldKey,
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          errorText: error,
          suffixText: suffix,
        ),
      ),
    );
  }
}

double? _readDouble(String text) {
  final value = double.tryParse(text.trim());
  if (value == null || value.isNaN || value.isInfinite) return null;
  return value;
}

String _formatDouble(double value) {
  if (value == value.truncateToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}

const _secondsPerHour = Duration.secondsPerMinute * Duration.minutesPerHour;

String _formatHours(Duration duration) {
  final hours = duration.inSeconds / _secondsPerHour;
  if (hours == hours.truncateToDouble()) return hours.toStringAsFixed(0);
  var text = hours.toStringAsFixed(4);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  text = text.replaceFirst(RegExp(r'\.$'), '');
  return text;
}
