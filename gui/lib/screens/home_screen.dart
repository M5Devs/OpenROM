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
import '../widgets/terminal_panel.dart';

class HomeScreen extends StatefulWidget {
  final ThemeConfig theme;
  final HomeController controller;

  const HomeScreen({
    super.key,
    required this.theme,
    required this.controller,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    setState(() {});
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
      onFilesDropped: (paths) => controller.addFilesFromPaths(
        paths,
        onError: _handleError,
      ),
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
                        Icon(
                          Icons.drive_folder_upload,
                          size: 64,
                          color: widget.theme.textSecondary,
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
              onClose: () => controller.toggleTerminal(false),
              onClear: controller.clearLogs,
            ),
        ],
      ),
    );
  }
}
