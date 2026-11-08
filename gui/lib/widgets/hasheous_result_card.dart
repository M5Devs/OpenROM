// OpenROM — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'package:flutter/material.dart';
import 'package:openrom_core/openrom_core.dart'
    show HasheousGameMatch, HasheousLookupResult;

/// High-contrast illustrated card for a successful Hasheous match.
///
/// Shows the game title, platform/region, and a `Verified in <DAT>` badge with
/// a subtle green/cyan glow.
class HasheousResultCard extends StatelessWidget {
  final HasheousGameMatch match;

  /// Every source database that recognised the hash, best-first.
  final List<String> sources;

  const HasheousResultCard({
    super.key,
    required this.match,
    this.sources = const [],
  });

  /// Convenience builder for a whole lookup result. Renders the match card
  /// when [lookup] matched, an offline banner on error, or a gentle no-match
  /// message otherwise.
  static Widget fromLookup(BuildContext context, HasheousLookupResult lookup) {
    if (lookup.matched && lookup.match != null) {
      return HasheousResultCard(
        match: lookup.match!,
        sources: lookup.sources,
      );
    }
    return lookup.hasError
        ? HasheousErrorBanner(message: lookup.error!)
        : const HasheousNoMatchBanner();
  }

  @override
  Widget build(BuildContext context) {
    const glow = Color(0xFF3DDC97); // green/cyan
    const cyan = Color(0xFF2EC4B6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            glow.withValues(alpha: 0.16),
            cyan.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glow.withValues(alpha: 0.55), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.28),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎮', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  match.gameName.isEmpty ? 'Unknown title' : match.gameName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('🕹️', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  match.region == null || match.region!.isEmpty
                      ? match.platform
                      : '${match.platform} · ${match.region}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ],
          ),
          if (match.romName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              match.romName,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Colors.white54,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              VerifiedBadge(sourceDat: match.sourceDat),
              if (sources.length > 1) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '+ ${sources.length - 1} more',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// `Verified in <DAT>` pill with a green/cyan glow.
class VerifiedBadge extends StatelessWidget {
  final String sourceDat;

  const VerifiedBadge({super.key, required this.sourceDat});

  @override
  Widget build(BuildContext context) {
    const glow = Color(0xFF3DDC97);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: glow.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glow.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(color: glow.withValues(alpha: 0.45), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 15, color: glow),
          const SizedBox(width: 6),
          Text(
            'Verified in $sourceDat',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: glow,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gentle "no match" message shown when Hasheous knows nothing about the hash.
class HasheousNoMatchBanner extends StatelessWidget {
  const HasheousNoMatchBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_off, color: Colors.white54, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No match found in preservation databases.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner shown when the lookup could not reach Hasheous (offline/timeout).
class HasheousErrorBanner extends StatelessWidget {
  final String message;

  const HasheousErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Identification unavailable: $message',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
