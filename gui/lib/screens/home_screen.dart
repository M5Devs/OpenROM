// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';

import '../controllers/home_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/conversion_job.dart';
import '../models/errors.dart';
import '../models/theme_config.dart';
import '../services/core_bridge.dart';
import '../widgets/drop_zone.dart';
import '../widgets/error_dialog.dart';
import '../widgets/rom_card.dart';
import '../widgets/romeo_mascot.dart';
import '../widgets/terminal_panel.dart';

class HomeScreen extends StatefulWidget {
  final ThemeConfig theme;
  final HomeController controller;

  const HomeScreen({super.key, required this.theme, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _wasConverting = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCoreOnStartup();
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final converting = widget.controller.isConverting;
    // Detect the running -> finished edge and surface a completion dialog once
    // the batch settles. Only celebrate when nothing failed.
    if (_wasConverting && !converting) {
      final jobs = widget.controller.jobs;
      final anyFailed = jobs.any((j) => j.status == JobStatus.failed);
      if (jobs.isNotEmpty && !anyFailed) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showSuccess());
      }
    }
    _wasConverting = converting;
    setState(() {});
  }

  void _showSuccess() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RomeoMascot(asset: RomeoAssets.success, size: 120),
            const SizedBox(height: 16),
            const Text(
              'Batch Completed! All files converted successfully',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(ctx).closeButton),
          ),
        ],
      ),
    );
  }

  Future<void> _checkCoreOnStartup() async {
    try {
      if (!await CoreBridge.coreExists()) {
        throw OpenROMException(OpenROMError.coreNotFound);
      }
    } on OpenROMException catch (e) {
      if (mounted) {
        showOpenROMError(context, e.error, details: e.details);
      }
    }
  }

  void _handleError(OpenROMException e) {
    if (mounted) {
      showOpenROMError(context, e.error, details: e.details);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = widget.controller;
    final jobs = controller.jobs;

    return DropZone(
      theme: widget.theme,
      onFilesDropped: (paths) =>
          controller.addFilesFromPaths(paths, onError: _handleError),
      child: Column(
        children: [
          if (jobs.any(
            (j) => j.status == JobStatus.done || j.status == JobStatus.failed,
          ))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: controller.clearCompleted,
                    icon: const Icon(
                      Icons.cleaning_services_outlined,
                      size: 16,
                    ),
                    label: const Text('Clear completed'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: jobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // A skin may ship its own dropzone illustration; fall
                        // back to the animated ROMéo idle mascot otherwise.
                        if (skinDropzoneArt(widget.theme) != null)
                          DropzoneArtwork(theme: widget.theme, size: 120)
                        else
                          const RomeoMascot(
                            asset: RomeoAssets.idle,
                            size: 120,
                          ),
                        const SizedBox(height: 16),
                        Text(
                          '${l10n.dropZoneHint}, ${l10n.dropZoneSubHint.toLowerCase()}',
                          style: TextStyle(
                            fontFamily: widget.theme.fontFamily,
                            color: widget.theme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    itemCount: jobs.length,
                    // ignore: deprecated_member_use
                    onReorder: controller.reorderJobs,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return RomCard(
                        key: ValueKey(job.id),
                        job: job,
                        theme: widget.theme,
                        onDelete: () => controller.removeJob(index),
                      );
                    },
                  ),
          ),
          if (controller.showTerminal)
            TerminalPanel(
              logs: controller.logs,
              theme: widget.theme,
              isConverting: controller.isConverting,
              onClose: () => controller.toggleTerminal(false),
              onClear: controller.clearLogs,
            ),
        ],
      ),
    );
  }
}
