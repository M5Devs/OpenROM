// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3
//
// The Arcade / MAME Manager results dashboard: metric chips, a library-health
// bar, a filterable results table and a per-game detail dialog. Split out of
// the Tools tab so it can be widget-tested with a synthetic report.

import 'package:flutter/material.dart';

import '../models/theme_config.dart';
import '../services/tools_service.dart';

/// Filter applied to the results table.
enum ArcadeFilter { all, complete, missingBios, incomplete, missingChd }

/// Maps an audit status to its badge colour.
Color arcadeStatusColor(String status) {
  switch (status) {
    case 'complete':
      return Colors.green;
    case 'missing_bios':
    case 'missing_parent':
      return Colors.amber;
    case 'missing_chd':
      return Colors.lightBlue;
    default:
      return Colors.redAccent;
  }
}

/// Maps an audit status to its badge icon.
IconData arcadeStatusIcon(String status) {
  switch (status) {
    case 'complete':
      return Icons.check_circle;
    case 'missing_bios':
    case 'missing_parent':
      return Icons.warning_amber_rounded;
    case 'missing_chd':
      return Icons.album;
    default:
      return Icons.error_outline;
  }
}

/// One-line summary shown under a game row.
String arcadeSubtitle(ArcadeGameAudit g) {
  switch (g.status) {
    case 'complete':
      return 'Complete · ${g.romsPresent}/${g.romsChecked} ROMs';
    case 'missing_bios':
      return 'Missing BIOS: ${g.missingBios.map((b) => '$b.zip').join(', ')}';
    case 'missing_parent':
      return 'Missing Parent: '
          '${g.missingParents.map((b) => '$b.zip').join(', ')}';
    case 'missing_chd':
      return 'Missing CHD: ${g.missingDisks.map((d) => d.name).join(', ')}';
    case 'missing':
      return 'Set not found (${g.name}.zip)';
    case 'error':
      return 'Unreadable archive';
    default:
      return 'Incomplete · ${g.missingRoms.length} chip(s) missing';
  }
}

/// Dashboard rendered from an [ArcadeAuditReport].
class ArcadeAuditView extends StatefulWidget {
  final ArcadeAuditReport report;
  final ThemeConfig theme;

  const ArcadeAuditView({
    super.key,
    required this.report,
    required this.theme,
  });

  @override
  State<ArcadeAuditView> createState() => _ArcadeAuditViewState();
}

class _ArcadeAuditViewState extends State<ArcadeAuditView> {
  ArcadeFilter _filter = ArcadeFilter.all;

  bool _matchesFilter(ArcadeGameAudit g) {
    switch (_filter) {
      case ArcadeFilter.all:
        return true;
      case ArcadeFilter.complete:
        return g.status == 'complete';
      case ArcadeFilter.missingBios:
        return g.status == 'missing_bios';
      case ArcadeFilter.incomplete:
        return g.status == 'incomplete' || g.status == 'missing';
      case ArcadeFilter.missingChd:
        return g.status == 'missing_chd';
    }
  }

  void _showDetails(ArcadeGameAudit game) {
    final theme = widget.theme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Row(
          children: [
            Icon(
              arcadeStatusIcon(game.status),
              color: arcadeStatusColor(game.status),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${game.description} (${game.name})',
                style: TextStyle(color: theme.textPrimary, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  game.statusLabel.isNotEmpty ? game.statusLabel : game.status,
                  style: TextStyle(
                    color: arcadeStatusColor(game.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  game.detail,
                  style: TextStyle(color: theme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  'ROMs: ${game.romsPresent}/${game.romsChecked} present'
                  '${game.disksChecked > 0 ? ' · CHDs: ${game.disksPresent}/${game.disksChecked}' : ''}',
                  style: TextStyle(color: theme.textPrimary, fontSize: 12),
                ),
                if (game.missingBios.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailHeader('Missing BIOS', theme),
                  ...game.missingBios.map(
                    (b) => _detailRow('$b.zip', 'required BIOS set', theme),
                  ),
                ],
                if (game.missingParents.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailHeader('Missing Parent', theme),
                  ...game.missingParents.map(
                    (b) => _detailRow('$b.zip', 'required parent set', theme),
                  ),
                ],
                if (game.missingRoms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailHeader('Missing / Mismatched ROMs', theme),
                  ...game.missingRoms.map(
                    (m) => _detailRow(
                      m.name,
                      '${m.reason == 'crc_mismatch' ? 'CRC mismatch' : 'missing'}'
                      ' · ${m.expectedSize} bytes'
                      '${m.expectedCrc.isNotEmpty ? ' · crc ${m.expectedCrc}' : ''}'
                      '${m.actualCrc.isNotEmpty ? ' (found ${m.actualCrc})' : ''}',
                      theme,
                    ),
                  ),
                ],
                if (game.missingDisks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _detailHeader('Missing CHD Disks', theme),
                  ...game.missingDisks.map(
                    (m) => _detailRow(m.name, 'required CHD image', theme),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailHeader(String text, ThemeConfig theme) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );

  Widget _detailRow(String name, String meta, ThemeConfig theme) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.remove_circle_outline,
              size: 14,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    meta,
                    style: TextStyle(color: theme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _metricChip(
    String label,
    int count,
    Color color,
    ThemeConfig theme, {
    ArcadeFilter? filter,
  }) {
    final selected = filter != null && _filter == filter;
    return InkWell(
      onTap: filter == null
          ? null
          : () =>
              setState(() => _filter = selected ? ArcadeFilter.all : filter),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.35 : 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: theme.textPrimary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final report = widget.report;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _metricChip('Total Games', report.totalGames, theme.accent, theme),
            _metricChip(
              'Complete',
              report.complete,
              Colors.green,
              theme,
              filter: ArcadeFilter.complete,
            ),
            _metricChip(
              'Missing BIOS',
              report.missingBios,
              Colors.amber,
              theme,
              filter: ArcadeFilter.missingBios,
            ),
            _metricChip(
              'Missing Parent',
              report.missingParent,
              Colors.orange,
              theme,
            ),
            _metricChip(
              'Incomplete',
              report.incomplete + report.missingSet,
              Colors.redAccent,
              theme,
              filter: ArcadeFilter.incomplete,
            ),
            _metricChip(
              'Missing CHD',
              report.missingChd,
              Colors.lightBlue,
              theme,
              filter: ArcadeFilter.missingChd,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'Library health: ${report.healthPercent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (report.healthPercent / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: theme.cardBg,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildTable(report, theme)),
      ],
    );
  }

  Widget _buildTable(ArcadeAuditReport report, ThemeConfig theme) {
    final games = report.games.where(_matchesFilter).toList();
    if (games.isEmpty) {
      return Center(
        child: Text(
          'No games match the current filter.',
          style: TextStyle(color: theme.textSecondary, fontSize: 12),
        ),
      );
    }
    return ListView.builder(
      itemCount: games.length,
      itemBuilder: (context, i) {
        final g = games[i];
        final color = arcadeStatusColor(g.status);
        return ListTile(
          dense: true,
          leading: Icon(arcadeStatusIcon(g.status), size: 18, color: color),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  g.description,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: theme.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                g.name,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          subtitle: Text(
            arcadeSubtitle(g),
            style: TextStyle(fontSize: 11, color: color),
          ),
          trailing: const Icon(Icons.info_outline, size: 16),
          onTap: () => _showDetails(g),
        );
      },
    );
  }
}
