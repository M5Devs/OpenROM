// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openrom_core/openrom_core.dart';

import '../controllers/plugin_builder_controller.dart';
import '../models/theme_config.dart';

/// Keys used by widget tests to drive the studio.
abstract final class BuilderStudioKeys {
  static const newProject = Key('studio.newProject');
  static const openProject = Key('studio.openProject');
  static const refresh = Key('studio.refresh');
  static const idField = Key('studio.id');
  static const nameField = Key('studio.name');
  static const versionField = Key('studio.version');
  static const minCoreField = Key('studio.minCore');
  static const publisherIdField = Key('studio.publisherId');
  static const publisherNameField = Key('studio.publisherName');
  static const descriptionField = Key('studio.description');
  static const argsField = Key('studio.args');
  static const categoryDropdown = Key('studio.category');
  static const routeField = Key('studio.routeField');
  static const addRoute = Key('studio.addRoute');
  static const save = Key('studio.save');
  static const validate = Key('studio.validate');
  static const build = Key('studio.build');
  static const copyMarketplace = Key('studio.copyMarketplace');
}

/// The Visual `.orplug` Builder Studio.
///
/// A form-driven front end for the same [OrplugBuilder] the `orplug-builder`
/// CLI uses: scaffold, edit the manifest, attach per-platform binaries, then
/// validate and pack. Everything it writes lands in `<projectDir>/plugin.json`,
/// so a project can be started in the GUI and finished from the terminal.
class OrplugBuilderStudio extends StatefulWidget {
  final ThemeConfig theme;
  final PluginBuilderController? controller;

  const OrplugBuilderStudio({
    super.key,
    required this.theme,
    this.controller,
  });

  @override
  State<OrplugBuilderStudio> createState() => _OrplugBuilderStudioState();
}

class _OrplugBuilderStudioState extends State<OrplugBuilderStudio> {
  late final PluginBuilderController _controller;
  bool _ownsController = false;

  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _versionCtrl = TextEditingController();
  final _minCoreCtrl = TextEditingController();
  final _pubIdCtrl = TextEditingController();
  final _pubNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _argsCtrl = TextEditingController();
  final _routeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PluginBuilderController();
    _ownsController = widget.controller == null;
    _controller.addListener(_onChanged);
    _syncFieldsFromController();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    for (final c in [
      _idCtrl,
      _nameCtrl,
      _versionCtrl,
      _minCoreCtrl,
      _pubIdCtrl,
      _pubNameCtrl,
      _descCtrl,
      _argsCtrl,
      _routeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Pushes controller state into the text fields without stealing the caret
  /// while the user is typing.
  void _syncFieldsFromController() {
    void set(TextEditingController c, String value) {
      if (c.text != value) c.text = value;
    }

    set(_idCtrl, _controller.id);
    set(_nameCtrl, _controller.name);
    set(_versionCtrl, _controller.version);
    set(_minCoreCtrl, _controller.minCoreVersion);
    set(_pubIdCtrl, _controller.publisherId);
    set(_pubNameCtrl, _controller.publisherName);
    set(_descCtrl, _controller.description);
    set(_argsCtrl, _controller.argsTemplate);
  }

  Future<void> _newProject() async {
    final parent = await _pickDirectory('Select where to create the plugin');
    if (parent == null) return;
    final id = _idCtrl.text.trim().isEmpty
        ? 'my-tool'
        : _controller.id.isEmpty
            ? 'my-tool'
            : _controller.id;
    final target = '$parent/$id';
    await _controller.scaffold(target, overwrite: true);
    _syncFieldsFromController();
  }

  Future<void> _openProject() async {
    final dir = await _pickDirectory('Select a plugin project folder');
    if (dir == null) return;
    await _controller.openProject(dir);
    _syncFieldsFromController();
  }

  Future<String?> _pickDirectory(String title) async {
    try {
      final selected = await FilePicker.platform.getDirectoryPath(
        dialogTitle: title,
      );
      if (selected == null || selected.isEmpty) return null;
      return selected;
    } catch (_) {
      return null;
    }
  }

  Future<void> _build() async {
    final ok = await _controller.pack();
    if (ok) {
      _syncFieldsFromController();
      if (mounted) _showPackSuccessDialog();
    }
  }

  void _showPackSuccessDialog() {
    final res = _controller.packResult;
    final theme = widget.theme;
    if (res == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: theme.accent),
            const SizedBox(width: 8),
            Text('Built .orplug', style: TextStyle(color: theme.textPrimary)),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Archive', res.outputPath ?? '—', theme),
              _kv('Size', '${res.archiveSize} bytes', theme),
              _kv('SHA-256', res.archiveSha256 ?? '—', theme, mono: true),
              const SizedBox(height: 12),
              Text(
                'Marketplace entry (paste into the store catalogue):',
                style: TextStyle(color: theme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.terminalBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _controller.marketplaceJson ?? '',
                  style: TextStyle(
                    color: theme.terminalText,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: _controller.marketplaceJson ?? ''),
              );
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Marketplace JSON copied')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy JSON'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, ThemeConfig theme, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(k,
                style: TextStyle(color: theme.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: SelectableText(
              v,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 12,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _header(theme),
        const SizedBox(height: 16),
        _card(theme, 'Identity', [
          Row(
            children: [
              Expanded(
                child: _field(
                  theme,
                  BuilderStudioKeys.idField,
                  'Plugin ID',
                  _idCtrl,
                  hint: 'my-tool',
                  onChanged: (v) => _controller.setIdentity(id: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  theme,
                  BuilderStudioKeys.nameField,
                  'Display Name',
                  _nameCtrl,
                  hint: 'My Tool',
                  onChanged: (v) => _controller.setIdentity(name: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                  theme,
                  BuilderStudioKeys.versionField,
                  'Version (SemVer)',
                  _versionCtrl,
                  hint: '1.0.0',
                  onChanged: _controller.setVersion,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  theme,
                  BuilderStudioKeys.minCoreField,
                  'Min Core Version',
                  _minCoreCtrl,
                  hint: '3.9.0',
                  onChanged: _controller.setMinCoreVersion,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _categoryDropdown(theme)),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        _card(theme, 'Publisher', [
          Row(
            children: [
              Expanded(
                child: _field(
                  theme,
                  BuilderStudioKeys.publisherIdField,
                  'Publisher ID',
                  _pubIdCtrl,
                  onChanged: (v) => _controller.setPublisher(id: v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  theme,
                  BuilderStudioKeys.publisherNameField,
                  'Publisher Name',
                  _pubNameCtrl,
                  onChanged: (v) => _controller.setPublisher(name: v),
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Verified publishers get the blue check in the store',
                child: Column(
                  children: [
                    Text('Verified',
                        style: TextStyle(
                            color: theme.textSecondary, fontSize: 12)),
                    Switch(
                      value: _controller.publisherVerified,
                      activeThumbColor: theme.accent,
                      onChanged: (v) => _controller.setPublisher(verified: v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        _card(theme, 'Description & Routes', [
          _field(
            theme,
            BuilderStudioKeys.descriptionField,
            'Description',
            _descCtrl,
            maxLines: 2,
            onChanged: _controller.setDescription,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  theme,
                  BuilderStudioKeys.routeField,
                  'Add route (e.g. ISO -> WUA)',
                  _routeCtrl,
                  onSubmitted: (v) {
                    _controller.addRoute(v);
                    _routeCtrl.clear();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ElevatedButton(
                  key: BuilderStudioKeys.addRoute,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.cardBg,
                    foregroundColor: theme.textPrimary,
                  ),
                  onPressed: () {
                    _controller.addRoute(_routeCtrl.text);
                    _routeCtrl.clear();
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _controller.routes.isEmpty
                ? [
                    Text('No routes yet.',
                        style: TextStyle(
                            color: theme.textSecondary, fontSize: 12)),
                  ]
                : _controller.routes.map((r) => _routeChip(theme, r)).toList(),
          ),
        ]),
        const SizedBox(height: 12),
        _binariesCard(theme),
        const SizedBox(height: 12),
        _card(theme, 'Execution Arguments', [
          Text(
            'Placeholders: {bin} executable · {in} input · {out} output · '
            '{outdir} output dir · {cue} cue sheet',
            style: TextStyle(color: theme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _field(
            theme,
            BuilderStudioKeys.argsField,
            'Argument template',
            _argsCtrl,
            hint: 'convert --input {in} --output {out}',
            onChanged: _controller.setArgsTemplate,
          ),
        ]),
        const SizedBox(height: 12),
        _actionsCard(theme),
        if (_controller.validation != null) ...[
          const SizedBox(height: 12),
          _validationCard(theme, _controller.validation!),
        ],
      ],
    );
  }

  // ── Sections ───────────────────────────────────────────────────────────────

  Widget _header(ThemeConfig theme) {
    final dir = _controller.projectDir;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.cardBg),
      ),
      child: Row(
        children: [
          Icon(Icons.handyman_outlined, color: theme.accent, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Visual .orplug Builder Studio',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dir.isEmpty
                      ? 'Start a new plugin or open an existing project folder.'
                      : dir,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            key: BuilderStudioKeys.newProject,
            style: OutlinedButton.styleFrom(foregroundColor: theme.accent),
            onPressed: _controller.isBusy ? null : _newProject,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            key: BuilderStudioKeys.openProject,
            style: OutlinedButton.styleFrom(foregroundColor: theme.accent),
            onPressed: _controller.isBusy ? null : _openProject,
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Open'),
          ),
          if (dir.isNotEmpty) ...[
            const SizedBox(width: 8),
            IconButton(
              key: BuilderStudioKeys.refresh,
              tooltip: 'Rescan project',
              onPressed: _controller.isBusy ? null : _controller.refresh,
              icon: Icon(Icons.refresh, color: theme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _categoryDropdown(ThemeConfig theme) {
    final items = {
      ...kStoreCategories,
      if (_controller.category.isNotEmpty &&
          !kStoreCategories.contains(_controller.category))
        _controller.category,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category',
            style: TextStyle(color: theme.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: BuilderStudioKeys.categoryDropdown,
          initialValue: items.contains(_controller.category)
              ? _controller.category
              : items.first,
          dropdownColor: theme.surface,
          style: TextStyle(color: theme.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: theme.cardBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          items: items
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: TextStyle(color: theme.textPrimary)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) _controller.setCategory(v);
          },
        ),
      ],
    );
  }

  Widget _binariesCard(ThemeConfig theme) {
    return _card(theme, 'Binaries', [
      Text(
        'Attach one executable per platform. SHA-256 hashes are computed '
        'automatically when you save or build.',
        style: TextStyle(color: theme.textSecondary, fontSize: 12),
      ),
      const SizedBox(height: 10),
      ...kStudioPlatformKeys.map((key) {
        final bin = _controller.binaries
            .where((b) => b.platformKey == key)
            .cast<StudioBinary?>()
            .firstWhere((_) => true, orElse: () => null);
        return _binaryRow(theme, key, bin);
      }),
    ]);
  }

  Widget _binaryRow(ThemeConfig theme, String key, StudioBinary? bin) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              PluginBuilderController.platformLabel(key),
              style: TextStyle(color: theme.textPrimary, fontSize: 13),
            ),
          ),
          Expanded(
            child: bin == null
                ? Text('not set',
                    style: TextStyle(color: theme.textSecondary, fontSize: 12))
                : Row(
                    children: [
                      Icon(Icons.insert_drive_file_outlined,
                          size: 14, color: theme.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${bin.fileName}  ·  ${bin.sizeLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: theme.textPrimary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: theme.accent),
            onPressed: _controller.isBusy
                ? null
                : () async {
                    await _controller.addBinary(key);
                    _syncFieldsFromController();
                  },
            icon: Icon(bin == null ? Icons.upload_file : Icons.swap_horiz,
                size: 16),
            label: Text(bin == null ? 'Add' : 'Replace'),
          ),
          if (bin != null)
            IconButton(
              tooltip: 'Remove',
              onPressed: _controller.isBusy
                  ? null
                  : () async {
                      await _controller.removeBinary(key);
                      _syncFieldsFromController();
                    },
              icon: Icon(Icons.delete_outline,
                  size: 18, color: theme.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _actionsCard(ThemeConfig theme) {
    final busy = _controller.isBusy;
    return _card(theme, 'Build', [
      Row(
        children: [
          ElevatedButton.icon(
            key: BuilderStudioKeys.save,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.cardBg,
              foregroundColor: theme.textPrimary,
            ),
            onPressed: busy || !_controller.projectLoaded
                ? null
                : () => _controller.saveManifest(),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Manifest'),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            key: BuilderStudioKeys.validate,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.cardBg,
              foregroundColor: theme.textPrimary,
            ),
            onPressed: busy || !_controller.projectLoaded
                ? null
                : _controller.validate,
            icon: const Icon(Icons.rule, size: 18),
            label: const Text('Validate'),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            key: BuilderStudioKeys.build,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accent,
              foregroundColor: Colors.black,
            ),
            onPressed: busy || !_controller.canBuild ? null : _build,
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: const Text('Build .orplug'),
          ),
          const Spacer(),
          if (busy)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: theme.accent),
            ),
        ],
      ),
      if (_controller.statusMessage != null) ...[
        const SizedBox(height: 10),
        Text(_controller.statusMessage!,
            style: TextStyle(color: theme.accent, fontSize: 12)),
      ],
      if (_controller.errorMessage != null) ...[
        const SizedBox(height: 10),
        Text(_controller.errorMessage!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
      ],
      if (_controller.packOutputPath != null &&
          _controller.packResult?.archiveSha256 != null) ...[
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'Last build: ${_controller.packOutputPath}  ·  '
                'sha256 ${_controller.packResult!.archiveSha256}',
                style: TextStyle(color: theme.textSecondary, fontSize: 11),
              ),
            ),
            IconButton(
              key: BuilderStudioKeys.copyMarketplace,
              tooltip: 'Copy marketplace JSON',
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: _controller.marketplaceJson ?? ''),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marketplace JSON copied')),
                );
              },
              icon:
                  Icon(Icons.copy_all_outlined, size: 18, color: theme.accent),
            ),
          ],
        ),
      ],
    ]);
  }

  Widget _validationCard(ThemeConfig theme, PluginValidationResult res) {
    final ok = res.success;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ok ? theme.accent.withValues(alpha: 0.5) : Colors.redAccent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(ok ? Icons.verified_outlined : Icons.error_outline,
                  size: 18, color: ok ? theme.accent : Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                ok ? 'Manifest is valid' : 'Validation issues',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          for (final e in res.errors)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('• $e',
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          for (final w in res.warnings)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('⚠ $w',
                  style: TextStyle(color: theme.textSecondary, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // ── Small building blocks ──────────────────────────────────────────────────

  Widget _card(ThemeConfig theme, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.cardBg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    ThemeConfig theme,
    Key key,
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          key: key,
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: theme.textPrimary, fontSize: 14),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
                color: theme.textSecondary.withValues(alpha: 0.6),
                fontSize: 13),
            filled: true,
            fillColor: theme.cardBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _routeChip(ThemeConfig theme, String route) {
    return Chip(
      label:
          Text(route, style: TextStyle(color: theme.textPrimary, fontSize: 12)),
      backgroundColor: theme.cardBg,
      deleteIcon: Icon(Icons.close, size: 14, color: theme.textSecondary),
      onDeleted: () => _controller.removeRoute(route),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
