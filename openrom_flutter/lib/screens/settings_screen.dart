// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3 + Commons Clause

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/theme_config.dart';
import '../providers/locale_provider.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeConfig theme;
  final ThemeService themeService;
  final LocaleProvider localeProvider;
  final Function(String format, String compression, bool verify, String outputDir, bool sameFolder) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.theme,
    required this.themeService,
    required this.localeProvider,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedFormat = 'CHD';
  String _selectedCompression = 'Normal';
  bool _verifyAfterConversion = false;
  bool _sameFolderAsSource = true;
  String _outputDestination = '';

  final List<String> _formats = ['CHD', 'CSO', 'ECM', 'RVZ', 'XISO'];
  final List<String> _compressionLevels = ['Normal', 'High', 'Max'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedFormat = prefs.getString('default_format') ?? 'CHD';
      _selectedCompression = prefs.getString('default_compression') ?? 'Normal';
      _verifyAfterConversion = prefs.getBool('verify_conversion') ?? false;
      _sameFolderAsSource = prefs.getBool('same_folder') ?? true;
      _outputDestination = prefs.getString('output_dir') ?? '';
    });
    _notifyParent();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_format', _selectedFormat);
    await prefs.setString('default_compression', _selectedCompression);
    await prefs.setBool('verify_conversion', _verifyAfterConversion);
    await prefs.setBool('same_folder', _sameFolderAsSource);
    await prefs.setString('output_dir', _outputDestination);
    _notifyParent();
  }

  void _notifyParent() {
    widget.onSettingsChanged(
      _selectedFormat,
      _selectedCompression,
      _verifyAfterConversion,
      _sameFolderAsSource ? '' : _outputDestination,
      _sameFolderAsSource,
    );
  }

  void _pickOutputDirectory() async {
    final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        _outputDestination = selectedDirectory;
        _sameFolderAsSource = false;
      });
      _saveSettings();
    }
  }

  String _getCompressionLabel(AppLocalizations l10n, String level) {
    switch (level) {
      case 'High':
        return l10n.compressionHigh;
      case 'Max':
        return l10n.compressionMax;
      case 'Normal':
      default:
        return l10n.compressionNormal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsTitle,
            style: TextStyle(
              fontFamily: theme.fontFamily,
              color: theme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Language Selector
          _buildSectionTitle('Language'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(theme.borderRadius),
              border: Border.all(color: theme.accent.withValues(alpha: 0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: widget.localeProvider.locale,
                dropdownColor: theme.surface,
                icon: Icon(Icons.language, color: theme.accent),
                isExpanded: true,
                items: LocaleProvider.supportedLocales.map((locale) {
                  return DropdownMenuItem<Locale>(
                    value: locale,
                    child: Text(
                      LocaleProvider.getNativeName(locale.languageCode),
                      style: TextStyle(color: theme.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) {
                    widget.localeProvider.setLocale(newLocale);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Output Format
          _buildSectionTitle(l10n.outputFormat),
          Wrap(
            spacing: 12,
            children: _formats.map((fmt) {
              final isSelected = _selectedFormat == fmt;
              return ChoiceChip(
                label: Text(fmt),
                selected: isSelected,
                selectedColor: theme.accent,
                backgroundColor: theme.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : theme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFormat = fmt);
                    _saveSettings();
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Compression Level
          _buildSectionTitle(l10n.compressionLevel),
          Wrap(
            spacing: 12,
            children: _compressionLevels.map((level) {
              final isSelected = _selectedCompression == level;
              return ChoiceChip(
                label: Text(_getCompressionLabel(l10n, level)),
                selected: isSelected,
                selectedColor: theme.accent,
                backgroundColor: theme.surface,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : theme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedCompression = level);
                    _saveSettings();
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Verification Switch
          _buildSectionTitle(l10n.postProcessing),
          SwitchListTile(
            title: Text(l10n.verifyAfterConversion, style: TextStyle(color: theme.textPrimary)),
            subtitle: Text('Runs chdman verify on newly created CHD files', style: TextStyle(color: theme.textSecondary)),
            value: _verifyAfterConversion,
            activeColor: theme.accent,
            onChanged: (val) {
              setState(() => _verifyAfterConversion = val);
              _saveSettings();
            },
          ),
          const SizedBox(height: 24),

          // Output Folder
          _buildSectionTitle(l10n.outputDestination),
          CheckboxListTile(
            title: Text('Same folder as source file', style: TextStyle(color: theme.textPrimary)),
            value: _sameFolderAsSource,
            activeColor: theme.accent,
            onChanged: (val) {
              setState(() => _sameFolderAsSource = val ?? true);
              _saveSettings();
            },
          ),
          if (!_sameFolderAsSource) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(theme.borderRadius),
                    ),
                    child: Text(
                      _outputDestination.isEmpty ? 'Select directory...' : _outputDestination,
                      style: TextStyle(color: theme.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _pickOutputDirectory,
                  style: ElevatedButton.styleFrom(backgroundColor: theme.accent),
                  child: Text(l10n.browse, style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),

          // Themes Preview Section
          _buildSectionTitle(l10n.themeScreen),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: widget.themeService.availableThemes.length,
            itemBuilder: (context, index) {
              final t = widget.themeService.availableThemes[index];
              final isSelected = t.name == theme.name;
              return InkWell(
                onTap: () => widget.themeService.setTheme(t),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.background,
                    border: Border.all(
                      color: isSelected ? theme.accent : Colors.white12,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(t.borderRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t.name,
                        style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _colorDot(t.accent),
                          const SizedBox(width: 6),
                          _colorDot(t.surface),
                          const SizedBox(width: 6),
                          _colorDot(t.terminalText),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: widget.theme.accent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
